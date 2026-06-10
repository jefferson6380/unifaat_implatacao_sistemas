"""
Lambda: image-processor
Trigger: S3 PutObject no bucket portfolio-assets-{RA}
Ação: resize para 800px de largura + converter para WebP
"""

import json
import os
import io
import urllib.parse
import boto3

# Pillow disponível via Lambda Layer
try:
    from PIL import Image
    PILLOW_AVAILABLE = True
except ImportError:
    PILLOW_AVAILABLE = False

s3 = boto3.client('s3')

MAX_WIDTH = 800
QUALITY = 85
PROCESSED_PREFIX = 'processed/'


def lambda_handler(event, context):
    if not PILLOW_AVAILABLE:
        return error_response(500, 'Pillow não disponível. Configure o Lambda Layer.')

    for record in event.get('Records', []):
        bucket = record['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(record['s3']['object']['key'])

        # Ignorar arquivos já processados para evitar loop
        if key.startswith(PROCESSED_PREFIX):
            print(f'Ignorando arquivo já processado: {key}')
            continue

        # Ignorar arquivos que não são imagens
        ext = key.lower().split('.')[-1]
        if ext not in ('jpg', 'jpeg', 'png', 'gif', 'bmp', 'tiff', 'webp'):
            print(f'Arquivo ignorado (não é imagem): {key}')
            continue

        try:
            process_image(bucket, key)
        except Exception as e:
            print(f'Erro ao processar {key}: {e}')
            raise

    return {'statusCode': 200, 'body': json.dumps('Processamento concluído')}


def process_image(bucket: str, key: str) -> None:
    print(f'Processando: s3://{bucket}/{key}')

    # Baixar imagem original
    response = s3.get_object(Bucket=bucket, Key=key)
    image_data = response['Body'].read()

    # Abrir com Pillow
    with Image.open(io.BytesIO(image_data)) as img:
        # Converter para RGB se necessário (ex: PNG com transparência → WebP)
        if img.mode in ('RGBA', 'P', 'LA'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')

        # Resize mantendo proporção
        width, height = img.size
        if width > MAX_WIDTH:
            new_height = int((MAX_WIDTH / width) * height)
            img = img.resize((MAX_WIDTH, new_height), Image.LANCZOS)
            print(f'Redimensionado: {width}x{height} → {MAX_WIDTH}x{new_height}')

        # Salvar como WebP em memória
        output = io.BytesIO()
        img.save(output, format='WEBP', quality=QUALITY, method=6)
        output.seek(0)
        size_kb = output.getbuffer().nbytes / 1024
        print(f'Tamanho final: {size_kb:.1f} KB')

    # Determinar chave de destino
    base_name = os.path.splitext(os.path.basename(key))[0]
    output_key = f'{PROCESSED_PREFIX}{base_name}.webp'

    # Upload da imagem processada
    s3.put_object(
        Bucket=bucket,
        Key=output_key,
        Body=output.getvalue(),
        ContentType='image/webp',
        CacheControl='max-age=604800',
        Metadata={
            'original-key': key,
            'original-size': str(len(image_data)),
            'processed-size': str(output.getbuffer().nbytes),
        }
    )

    print(f'Upload concluído: s3://{bucket}/{output_key}')


def error_response(status: int, message: str) -> dict:
    return {
        'statusCode': status,
        'body': json.dumps({'error': message})
    }
