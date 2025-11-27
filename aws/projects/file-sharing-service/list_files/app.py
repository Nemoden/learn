import boto3
import json
import os

dynamo = boto3.resource("dynamodb")

def lambda_handler(event, context):
    """
    Lists files (read from dynamo)
    """
    _, _ = context, event
    table_name = os.environ["FILES_TABLE"]
    if not table_name:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Files table is not configured"})
        }

    table = dynamo.Table(table_name)
    res = table.query(
        KeyConditionExpression = "userId = :uid",
        ExpressionAttributeValues = {
            ":uid": "demo-user"
        }
    )
    items = res["Items"]
    items.sort(key=lambda x: x.get("uploadedAt", ""), reverse=True)
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps({
            "items": items,
            "count": len(items)
        })
    }
