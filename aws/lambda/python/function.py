import boto3
import json

s3_client = boto3.client('s3')

def lambda_handler(event, context):
    bucket_name = event['bucket_name']
    bucket_key = event['bucket_key']
    body = event['body']

    status_code = put_object_into_s3(bucket_name, bucket_key, body)
    return {
        'statusCode': status_code,
        'body': json.dumps('S3 Access.')
    }

# Define subsegments manually
def put_object_into_s3(bucket_name, bucket_key, body):
    response = s3_client.put_object(Bucket=bucket_name, Key=bucket_key, Body=body)
    status_code = response['ResponseMetadata']['HTTPStatusCode']
    return status_code

            

