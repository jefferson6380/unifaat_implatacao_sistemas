import boto3
import json
import os
import urllib.parse
from io import BytesIO

# pip install Pillow (layer obrigatória)
from PIL import Image

s3 = boto3.client('s3')

BUCKET_ASSETS = os.environ['BUCKET_ASSETS']
MAX_WIDTH = int(os.environ.get('MAX_WIDTH', '1200'))
MAX_HEIGHT = int(os.environ.get('MAX_HEIGHT', '800'))
THUMB_SIZE = (300, 300)
ALLOWED_TYPES = {'image/jpeg', 'image/png', 'image/webp', 'image/gif'}


def lambda_handler(event, context):
    """
    Acionado por S3 trigger (PUT) ou diretamente via API Gateway.
    Redimensiona a imagem original e gera thumbnail.
    """
    # Trigger via S3
    if 'Records' in event:
        return _process_s3_trigger(event)

    # Chamada via API Gateway para gerar URL pré-assinada
    return _generate_presigned_url(event)


def _process_s3_trigger(event):
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])

        if not key.startswith('uploads/'):
            continue

        obj = s3.get_object(Bucket=bucket, Key=key)
        content_type = obj['ContentType']

        if content_type not in ALLOWED_TYPES:
            print(f"Tipo não permitido: {content_type} — {key}")
            continue

        img = Image.open(BytesIO(obj['Body'].read()))

        # Imagem principal redimensionada
        img.thumbnail((MAX_WIDTH, MAX_HEIGHT), Image.LANCZOS)
        _upload_image(img, bucket, key.replace('uploads/', 'processed/'), content_type)

        # Thumbnail
        thumb = img.copy()
        thumb.thumbnail(THUMB_SIZE, Image.LANCZOS)
        _upload_image(thumb, bucket, key.replace('uploads/', 'thumbnails/'), content_type)

        print(f"Processado: {key}")

    return {'statusCode': 200}


def _upload_image(img, bucket, key, content_type):
    buf = BytesIO()
    fmt = 'WEBP' if content_type == 'image/webp' else img.format or 'JPEG'
    img.save(buf, format=fmt, optimize=True, quality=85)
    buf.seek(0)
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=buf,
        ContentType=content_type,
        CacheControl='public, max-age=604800'
    )


def _generate_presigned_url(event):
    params = event.get('queryStringParameters') or {}
    filename = params.get('filename', 'upload.jpg')
    content_type = params.get('type', 'image/jpeg')

    if content_type not in ALLOWED_TYPES:
        return _response(400, {'error': 'Tipo de arquivo não permitido'})

    key = f"uploads/{filename}"
    url = s3.generate_presigned_url(
        'put_object',
        Params={'Bucket': BUCKET_ASSETS, 'Key': key, 'ContentType': content_type},
        ExpiresIn=300
    )

    return _response(200, {'uploadUrl': url, 'key': key})


def _response(status, body):
    return {
        'statusCode': status,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(body)
    }
