-- Curated customer business-key quality gate
-- Run after the Glue load and before downstream reporting or publication.
-- Returns only exceptions: NULL customer IDs or duplicate customer IDs.
-- An empty result set means this check passed; this query does not modify data.

WITH customer_key_issues AS (
    SELECT
        customer_id,
        COUNT(*) AS row_count,
        CASE
            WHEN customer_id IS NULL THEN 'NULL_BUSINESS_KEY'
            ELSE 'DUPLICATE_BUSINESS_KEY'
        END AS issue_type
    FROM curated.customer
    GROUP BY customer_id
    HAVING customer_id IS NULL
        OR COUNT(*) > 1
)
SELECT
    customer_id,
    row_count,
    issue_type,
    CASE
        WHEN issue_type = 'NULL_BUSINESS_KEY'
            THEN 'Reject or quarantine rows with a missing customer ID'
        ELSE 'Review the Glue upsert/deduplication logic before publishing'
    END AS recommended_action
FROM customer_key_issues
ORDER BY issue_type, customer_id;
