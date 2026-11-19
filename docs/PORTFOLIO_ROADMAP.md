# AWS Data Engineering Portfolio Roadmap

## Positioning
Production-style batch data engineering with S3, Lambda, Glue, Step Functions, Redshift, SQL data quality, dimensional modelling, and operational controls.

## Existing evidence to retain
- End-to-end S3 → Lambda → Glue → Redshift → Step Functions pipeline structure.
- `tests/curated_customer_key_quality_check.sql`: curated customer key quality gate.
- `aws-redshift-sql-optimization`: query tuning, distribution/sort keys, and EXPLAIN analysis.
- `Sales-Data-Warehouse-Analytics-Project`: layered Staging → Curated → Consumption model.

Do not copy the customer-key test or Redshift tuning guide into this repository. Add complementary controls and link to the specialist repositories.

## Project roadmap
| Priority | Project | Evidence to publish |
|---|---|---|
| 1 | Batch control totals and source-target reconciliation | Redshift SQL, sample batch, expected PASS/FAIL results |
| 2 | Glue incremental load with late-arriving records | PySpark job, watermark strategy, retry/idempotency notes |
| 3 | Step Functions failure handling | ASL definition, retry/catch paths, operational notes |
| 4 | SCD Type 2 dimension processing | Effective dates, current flag, change detection and tests |
| 5 | Data pipeline observability | CloudWatch metrics/logging, run audit, alert thresholds |

## Standard project structure
```
architecture/
glue/
lambda/
step-functions/
sql/
tests/
sample_data/
docs/
```

## Production engineering principles
- Separate raw, staging, curated, and consumption responsibilities.
- Make batch processing restartable and idempotent.
- Validate keys, row counts, control totals, and business rules before publishing.
- Parameterize environment-specific values; never commit AWS keys or secrets.
- Document cost, partitioning, distribution, sort, and query-plan decisions.

## Definition of done
Publish runnable source, synthetic sample data, architecture, configuration assumptions, expected outputs, negative tests, and deployment/rollback notes. Mark AWS deployment and runtime validation separately from static source review.
