import boto3
import os
import json

dynamo = boto3.resource("dynamodb")

def lambda_handler(event, context):
    _ = context
    table_name = os.environ.get("FILES_TABLE")
    if not table_name:
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": "Table name is not configured"
            })
        }
    table = dynamo.Table(table_name)
    file_id = event['pathParameters']['fileId']
    res = table.get_item(
        Key={
            "fileId": file_id,
            "userId": "demo-user"
        }
    )
    if 'Item' not in res:
        return {
            "statusCode": 404,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "error": "File not found"
            })
        }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(res["Item"])
    }
