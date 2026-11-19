-- Redshift SQL: source-to-curated batch control totals
-- Purpose: reconcile row counts, distinct business keys, and monetary totals
-- before a batch is made available to downstream reporting.
--
-- Assumed tables/columns (adjust to the project DDL if names differ):
--   staging.sales_order(batch_id, order_id, net_amount)
--   curated.fact_sales(batch_id, order_id, net_amount)
-- Replace the example batch literal (1001) with the batch being validated.
-- Read-only query: it does not update, delete, or publish records.

WITH source_batch AS (
    SELECT order_id, net_amount
    FROM staging.sales_order
    WHERE batch_id = 1001
),
target_batch AS (
    SELECT order_id, net_amount
    FROM curated.fact_sales
    WHERE batch_id = :batch_id
),
source_metrics AS (
    SELECT
        COUNT(*) AS row_count,
        COUNT(DISTINCT order_id) AS distinct_order_count,
        SUM(COALESCE(net_amount, 0)) AS net_amount_total,
        SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_key_count,
        SUM(CASE WHEN net_amount IS NULL THEN 1 ELSE 0 END) AS null_amount_count
    FROM source_batch
),
target_metrics AS (
    SELECT
        COUNT(*) AS row_count,
        COUNT(DISTINCT order_id) AS distinct_order_count,
        SUM(COALESCE(net_amount, 0)) AS net_amount_total,
        SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_key_count,
        SUM(CASE WHEN net_amount IS NULL THEN 1 ELSE 0 END) AS null_amount_count
    FROM target_batch
),
source_duplicate_keys AS (
    SELECT COUNT(*) AS duplicate_key_count
    FROM (
        SELECT order_id
        FROM source_batch
        WHERE order_id IS NOT NULL
        GROUP BY order_id
        HAVING COUNT(*) > 1
    ) d
),
target_duplicate_keys AS (
    SELECT COUNT(*) AS duplicate_key_count
    FROM (
        SELECT order_id
        FROM target_batch
        WHERE order_id IS NOT NULL
        GROUP BY order_id
        HAVING COUNT(*) > 1
    ) d
),
checks AS (
    SELECT
        'SOURCE_BATCH_NOT_EMPTY' AS check_name,
        CASE WHEN s.row_count > 0 THEN 0 ELSE 1 END AS issue_count,
        'BLOCKER' AS severity,
        s.row_count AS source_value,
        t.row_count AS target_value
    FROM source_metrics s CROSS JOIN target_metrics t

    UNION ALL

    SELECT
        'ROW_COUNT_MISMATCH',
        CASE WHEN s.row_count = t.row_count THEN 0 ELSE 1 END,
        'BLOCKER',
        s.row_count,
        t.row_count
    FROM source_metrics s CROSS JOIN target_metrics t

    UNION ALL

    SELECT
        'DISTINCT_ORDER_COUNT_MISMATCH',
        CASE WHEN s.distinct_order_count = t.distinct_order_count THEN 0 ELSE 1 END,
        'BLOCKER',
        s.distinct_order_count,
        t.distinct_order_count
    FROM source_metrics s CROSS JOIN target_metrics t

    UNION ALL

    SELECT
        'NET_AMOUNT_TOTAL_MISMATCH',
        CASE WHEN ABS(COALESCE(s.net_amount_total, 0) - COALESCE(t.net_amount_total, 0)) <= 0.01
             THEN 0 ELSE 1 END,
        'BLOCKER',
        CAST(COALESCE(s.net_amount_total, 0) AS DECIMAL(18,2)),
        CAST(COALESCE(t.net_amount_total, 0) AS DECIMAL(18,2))
    FROM source_metrics s CROSS JOIN target_metrics t

    UNION ALL

    SELECT
        'SOURCE_DUPLICATE_ORDER_KEYS',
        d.duplicate_key_count,
        'BLOCKER',
        d.duplicate_key_count,
        0
    FROM source_duplicate_keys d

    UNION ALL

    SELECT
        'TARGET_DUPLICATE_ORDER_KEYS',
        d.duplicate_key_count,
        'BLOCKER',
        d.duplicate_key_count,
        0
    FROM target_duplicate_keys d

    UNION ALL

    SELECT
        'SOURCE_NULL_BUSINESS_KEYS',
        s.null_key_count,
        'BLOCKER',
        s.null_key_count,
        0
    FROM source_metrics s CROSS JOIN target_metrics t

    UNION ALL

    SELECT
        'SOURCE_NULL_NET_AMOUNTS',
        s.null_amount_count,
        'BLOCKER',
        s.null_amount_count,
        0
    FROM source_metrics s CROSS JOIN target_metrics t
)
SELECT
    check_name,
    source_value,
    target_value,
    issue_count,
    severity,
    CASE
        WHEN issue_count = 0 THEN 'PASS'
        WHEN severity = 'BLOCKER' THEN 'BLOCK_PUBLISH'
        ELSE 'REVIEW'
    END AS check_result
FROM checks
ORDER BY
    CASE severity WHEN 'BLOCKER' THEN 1 ELSE 2 END,
    check_name;

-- Operational notes:
-- 1. Run after the Glue write completes and before downstream consumption.
-- 2. Confirm both tables are filtered to the same immutable batch identifier.
-- 3. A matching total alone does not prove row-level correctness; combine this
--    control with key-level and business-rule checks.
-- 4. Duplicate business keys are checked independently on both sides.
-- 5. A BLOCK_PUBLISH result should stop publication pending investigation.
