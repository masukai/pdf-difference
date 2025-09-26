import json
import boto3
import base64
import io
from datetime import datetime
import cgi

VAR_NAME = "pdf-difference"
DIRECTORY = "02-pdf-file-after/"

s3 = boto3.resource("s3")


def lambda_handler(event, context):
    bucket = s3.Bucket(VAR_NAME + "-bucket")

    print(event)

    body = base64.b64decode(event["body-json"])
    fp = io.BytesIO(body)

    environ = {"REQUEST_METHOD": "POST"}
    headers = {
        "content-type": event["params"]["header"]["content-type"],
        "content-length": str(len(body)),
    }

    fs = cgi.FieldStorage(fp=fp, environ=environ, headers=headers)
    for f in fs.list:
        print("filename=" + f.filename)
        bucket.put_object(Body=f.value, Key=DIRECTORY + f.filename)

    return {
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "OPTIONS, POST",
        "Content-Type": "multipart/form-data",
        "statusCode": 200,
        "body": json.dumps("アップロード完了"),
    }
