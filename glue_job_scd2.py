
from pyspark.sql import SparkSession
from pyspark.sql.functions import current_date, lit

spark = SparkSession.builder.appName("SCD2").getOrCreate()
df = spark.read.parquet("s3://bucket/staging/")
df = df.withColumn("start_date", current_date())        .withColumn("end_date", lit(None))        .withColumn("is_active", lit(True))
df.write.mode("append").parquet("s3://bucket/curated/")
