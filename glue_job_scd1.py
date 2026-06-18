## SCD Type 1 Code ##
## Author By DK1997 
## 18 Jun 2026 
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("SCD1").getOrCreate()
df = spark.read.parquet("s3://bucket/processed/")
df.dropDuplicates(["id"]).write.mode("overwrite").parquet("s3://bucket/curated/")
