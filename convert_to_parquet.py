## Python Code
import boto3, pandas as pd, io
import pyarrow as pa, pyarrow.parquet as pq

s3 = boto3.client('s3')

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    obj = s3.get_object(Bucket=bucket, Key=key)
    df = pd.read_csv(obj['Body'])

    table = pa.Table.from_pandas(df)
    buffer = io.BytesIO()
    pq.write_table(table, buffer)

    out_key = key.replace("raw/", "processed/").replace(".csv", ".parquet")
    s3.put_object(Bucket=bucket, Key=out_key, Body=buffer.getvalue())
