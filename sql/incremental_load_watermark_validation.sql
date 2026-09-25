-- Incremental load watermark validation
-- Portfolio example: validate that an ETL pipeline loaded the expected
-- business-date window without gaps or unexpected future records.

WITH expected_window AS (
    SELECT
        MIN(business_date) AS expected_start_date,
        MAX(business_date) AS expected_end_date
    FROM source_transactions
    WHERE business_date >= TRUNC(SYSDATE) - 7
      AND business_date < TRUNC(SYSDATE)
),
target_window AS (
    SELECT
        MIN(business_date) AS target_start_date,
        MAX(business_date) AS target_end_date,
        COUNT(*) AS target_row_count
    FROM target_transactions
    WHERE business_date >= TRUNC(SYSDATE) - 7
      AND business_date < TRUNC(SYSDATE)
)
SELECT
    e.expected_start_date,
    e.expected_end_date,
    t.target_start_date,
    t.target_end_date,
    t.target_row_count,
    CASE
        WHEN t.target_row_count = 0 THEN 'FAIL - NO DATA'
        WHEN t.target_start_date > e.expected_start_date
          OR t.target_end_date < e.expected_end_date
            THEN 'FAIL - WATERMARK GAP'
        ELSE 'PASS'
    END AS validation_status
FROM expected_window e
CROSS JOIN target_window t;