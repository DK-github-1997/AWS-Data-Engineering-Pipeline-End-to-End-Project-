-- Incremental-load validation sample
-- Purpose: detect records where the curated layer has not received the
-- latest source update. Useful as a post-ETL reconciliation check.

WITH latest_source AS (
    SELECT
        customer_id,
        MAX(updated_at) AS source_updated_at
    FROM staging.customer
    GROUP BY customer_id
),
latest_curated AS (
    SELECT
        customer_id,
        MAX(updated_at) AS curated_updated_at
    FROM curated.customer
    GROUP BY customer_id
)
SELECT
    s.customer_id,
    s.source_updated_at,
    c.curated_updated_at,
    CASE
        WHEN c.customer_id IS NULL THEN 'MISSING_IN_CURATED'
        WHEN c.curated_updated_at < s.source_updated_at THEN 'STALE_IN_CURATED'
        ELSE 'IN_SYNC'
    END AS validation_status
FROM latest_source s
LEFT JOIN latest_curated c
    ON c.customer_id = s.customer_id
WHERE c.customer_id IS NULL
   OR c.curated_updated_at < s.source_updated_at
ORDER BY s.source_updated_at DESC;
