import json
from urllib.parse import unquote_plus

import boto3

s3 = boto3.client("s3")


# Este processador gera uma copia otimizada logica em outro prefixo.
# Em ambiente real, pode ser estendido com Pillow/Sharp para resize fisico.
def handler(event, context):
    record = (event.get("Records") or [{}])[0]
    bucket = record.get("s3", {}).get("bucket", {}).get("name")
    raw_key = record.get("s3", {}).get("object", {}).get("key")

    if not bucket or not raw_key:
        return {"statusCode": 200, "body": "No records"}

    key = unquote_plus(raw_key)
    if not key.startswith("uploads/raw/"):
        return {"statusCode": 200, "body": "Ignored key"}

    target_key = key.replace("uploads/raw/", "uploads/optimized/", 1)

    source = {"Bucket": bucket, "Key": key}
    head = s3.head_object(Bucket=bucket, Key=key)

    s3.copy_object(
        Bucket=bucket,
        CopySource=source,
        Key=target_key,
        ContentType=head.get("ContentType", "application/octet-stream"),
        CacheControl="public,max-age=31536000,immutable",
        MetadataDirective="REPLACE",
        Metadata={
            "processed-by": "tf11-image-processor",
            "source-key": key,
        },
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "source": key,
            "output": target_key,
            "contentType": head.get("ContentType", ""),
        }),
    }
