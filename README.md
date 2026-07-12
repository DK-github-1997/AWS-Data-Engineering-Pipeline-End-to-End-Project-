
# AWS Data Engineering Pipeline 
##Project Structure 

End-to-end pipeline using S3, Lambda, Glue, Redshift, Step Functions, Tableau.
 
aws-data-engineering-pipeline/
│
├── README.md 
├── architecture/
│   └── architecture-diagram.png
│
├── lambda/
│   ├── convert_to_parquet.py
│   └── requirements.txt
│
├── glue/
│   ├── glue_job_scd1.py
│   ├── glue_job_scd2.py
│   └── utils.py
│
├── step-functions/
│   └── pipeline_orchestration.json
│
├── sql/
│   ├── staging_tables.sql
│   ├── curated_tables.sql
│   └── transformations.sql
│
├── scripts/
│   ├── upload_to_s3.sh
│   └── trigger_pipeline.sh
│
├── config/
│   └── config.yaml
│
├── tests/
│   └── test_data_quality.sql
│
└── requirements.txt
