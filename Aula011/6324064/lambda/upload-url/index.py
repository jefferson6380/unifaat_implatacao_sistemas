import json
import os
import re
import time
from urllib.parse import quote

import boto3

s3 = boto3.client("s3")

ASSETS_BUCKET = os.getenv("ASSETS_BUCKET", "")
ALLOWED_ORIGIN = os.getenv("ALLOWED_ORIGIN", "*")
MAX_RESULTS = int(os.getenv("MAX_RESULTS", "30"))

SAFE_NAME = re.compile(r"[^a-zA-Z0-9._-]")
ALLOWED_TYPES = {
    "image/png": ".png",
    "image/jpeg": ".jpg",
    "image/webp": ".webp",
}


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,GET,POST",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }


def parse_body(event):
    raw = event.get("body")
    if not raw:
        return {}
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        return {}


def sanitize_file_name(file_name, fallback_ext):
    base = SAFE_NAME.sub("-", file_name.strip())
    if not base:
        base = f"upload-{int(time.time())}{fallback_ext}"
    if "." not in base:
        base += fallback_ext
    return base[:120]


def list_gallery_items():
    result = s3.list_objects_v2(
        Bucket=ASSETS_BUCKET,
        Prefix="uploads/optimized/",
        MaxKeys=MAX_RESULTS,
    )

    items = []
    for obj in result.get("Contents", []):
        key = obj.get("Key", "")
        if not key or key.endswith("/"):
            continue
        items.append(
            {
                "title": key.split("/")[-1],
                "url": f"https://{ASSETS_BUCKET}.s3.amazonaws.com/{quote(key)}",
                "lastModified": obj.get("LastModified").isoformat() if obj.get("LastModified") else "",
                "size": obj.get("Size", 0),
            }
        )

    items.sort(key=lambda x: x.get("lastModified", ""), reverse=True)
    return items


def create_upload_url(payload):
    content_type = str(payload.get("contentType", "")).strip().lower()
    file_name = str(payload.get("fileName", "")).strip()

    if content_type not in ALLOWED_TYPES:
        return response(400, {"ok": False, "error": "contentType nao permitido"})

    ext = ALLOWED_TYPES[content_type]
    safe_name = sanitize_file_name(file_name, ext)
    key = f"uploads/raw/{int(time.time())}-{safe_name}"

    presigned_url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": ASSETS_BUCKET,
            "Key": key,
            "ContentType": content_type,
        },
        ExpiresIn=900,
    )

    return response(
        200,
        {
            "ok": True,
            "key": key,
            "presignedUrl": presigned_url,
            "fileUrl": f"https://{ASSETS_BUCKET}.s3.amazonaws.com/{quote(key)}",
        },
    )


def handler(event, context):
    if not ASSETS_BUCKET:
        return response(500, {"ok": False, "error": "ASSETS_BUCKET nao configurado"})

    method = event.get("httpMethod")
    if not method:
        method = event.get("requestContext", {}).get("http", {}).get("method", "")
    method = method.upper()

    if method == "OPTIONS":
        return response(200, {"ok": True})

    if method == "GET":
        try:
            items = list_gallery_items()
            return response(200, {"ok": True, "items": items})
        except Exception as exc:
            return response(500, {"ok": False, "error": str(exc)})

    if method == "POST":
        payload = parse_body(event)
        return create_upload_url(payload)

    return response(405, {"ok": False, "error": "Metodo nao suportado"})
