import boto3
import datetime
import json
import os
import uuid

s3 = boto3.client('s3')
dynamo = boto3.resource('dynamodb')

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
    files_table = os.environ.get('FILES_TABLE', None)
    if files_table is None:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': "Files metadata table is not configured"
            })
        }
    timestamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%d-%H%M%S")
    upload_prefix = f"uploads/{timestamp}-{file_name}"
    presigned_post = s3.generate_presigned_post(
        Bucket=bucket_name,
        Key=upload_prefix,
        ExpiresIn=3600 # presigned post url is valid only for 1 hour
    )

    table = dynamo.Table(files_table)
    file_id = str(uuid.uuid4())
    table.put_item(
      Item={
          'userId': 'demo-user',  # Hardcoded for now (Sprint 4 will use real auth)
          'fileId': file_id,
          'fileName': file_name,
          's3Key': upload_prefix,
          'uploadedAt': datetime.datetime.now(datetime.timezone.utc).isoformat()
      }
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
            'fileId': file_id,
        })
    }
