import boto3
import datetime
import json
import os

s3 = boto3.client('s3')

def lambda_handler(event, context):
    _ = context
    body = json.loads(event['body'])
    file_name = body.get('fileName', None)
    if file_name is None:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': "fileName must be provided in the request"
            })
        }
    bucket_name = os.environ.get('BUCKET_NAME', None)
    if bucket_name is None:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': "Bucket is not configured"
            })
        }
    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H%M%S")
    upload_prefix = f"uploads/{timestamp}-{file_name}"
    presigned_post = s3.generate_presigned_post(
        Bucket=bucket_name,
        Key=upload_prefix,
        ExpiresIn=3600 # presigned post url is valid only for 1 hour
    )
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        'body': json.dumps({
            'uploadUrl': presigned_post['url'],
            'fields': presigned_post['fields'],
            's3Key': upload_prefix,
        })
    }
