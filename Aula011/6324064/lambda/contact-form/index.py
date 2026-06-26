import json
import os
import re
import time
import uuid
from decimal import Decimal

import boto3

DDB_TABLE = os.getenv("CONTACTS_TABLE", "tf11-contacts-6324064")
SES_FROM_EMAIL = os.getenv("SES_FROM_EMAIL", "")
SES_TO_EMAIL = os.getenv("SES_TO_EMAIL", "")
ALLOWED_ORIGIN = os.getenv("ALLOWED_ORIGIN", "*")

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

dynamodb = boto3.resource("dynamodb")
ses = boto3.client("ses")


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": ALLOWED_ORIGIN,
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST",
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }


def validate(payload):
    name = str(payload.get("name", "")).strip()
    email = str(payload.get("email", "")).strip().lower()
    subject = str(payload.get("subject", "")).strip()
    message = str(payload.get("message", "")).strip()

    if len(name) < 3:
        return "Nome invalido"
    if not EMAIL_RE.match(email):
        return "Email invalido"
    if len(subject) < 3:
        return "Assunto invalido"
    if len(message) < 10:
        return "Mensagem muito curta"

    return ""


def handler(event, context):
    if event.get("httpMethod") == "OPTIONS":
        return response(200, {"ok": True})

    try:
        payload = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return response(400, {"ok": False, "error": "JSON invalido"})

    error = validate(payload)
    if error:
        return response(400, {"ok": False, "error": error})

    item = {
        "pk": f"contact#{int(time.time())}#{uuid.uuid4()}",
        "createdAt": int(time.time()),
        "name": payload["name"].strip(),
        "email": payload["email"].strip().lower(),
        "subject": payload["subject"].strip(),
        "message": payload["message"].strip(),
        "ttl": int(time.time()) + (60 * 60 * 24 * 365),
        "version": Decimal("1"),
    }

    table = dynamodb.Table(DDB_TABLE)
    table.put_item(Item=item)

    if SES_FROM_EMAIL and SES_TO_EMAIL:
        ses.send_email(
            Source=SES_FROM_EMAIL,
            Destination={"ToAddresses": [SES_TO_EMAIL]},
            Message={
                "Subject": {"Data": f"[TF11] {item['subject']}"},
                "Body": {
                    "Text": {
                        "Data": (
                            f"Nome: {item['name']}\n"
                            f"Email: {item['email']}\n"
                            f"Mensagem:\n{item['message']}"
                        )
                    }
                },
            },
        )

    return response(201, {"ok": True, "id": item["pk"]})
