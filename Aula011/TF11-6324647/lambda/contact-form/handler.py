import boto3
import json
import os
import re
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
ses = boto3.client('ses', region_name=os.environ.get('SES_REGION', 'us-east-1'))

TABLE_NAME = os.environ['DYNAMODB_TABLE']
FROM_EMAIL = os.environ['FROM_EMAIL']
TO_EMAIL   = os.environ['TO_EMAIL']

EMAIL_RE = re.compile(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')

CORS_HEADERS = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type'
}


def lambda_handler(event, context):
    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': ''}

    try:
        body = json.loads(event.get('body', '{}'))
    except json.JSONDecodeError:
        return _response(400, {'error': 'Payload inválido'})

    # Validação
    errors = _validate(body)
    if errors:
        return _response(400, {'error': errors})

    item = {
        'id': str(uuid.uuid4()),
        'name': body['name'].strip(),
        'email': body['email'].strip().lower(),
        'subject': body['subject'].strip(),
        'message': body['message'].strip(),
        'timestamp': datetime.utcnow().isoformat(),
        'status': 'novo',
        'ip': event.get('requestContext', {}).get('identity', {}).get('sourceIp', 'unknown')
    }

    # Salvar no DynamoDB
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(Item=item)

    # Notificação por email via SES
    _send_notification(item)

    return _response(200, {'message': 'Mensagem enviada com sucesso', 'id': item['id']})


def _validate(body):
    required = ['name', 'email', 'subject', 'message']
    for field in required:
        if not body.get(field, '').strip():
            return f'Campo obrigatório ausente: {field}'
    if not EMAIL_RE.match(body['email']):
        return 'Email inválido'
    if len(body['message']) < 10:
        return 'Mensagem muito curta (mínimo 10 caracteres)'
    return None


def _send_notification(item):
    try:
        ses.send_email(
            Source=FROM_EMAIL,
            Destination={'ToAddresses': [TO_EMAIL]},
            Message={
                'Subject': {'Data': f"[Portfólio] {item['subject']} — {item['name']}"},
                'Body': {
                    'Text': {
                        'Data': (
                            f"Nome: {item['name']}\n"
                            f"Email: {item['email']}\n"
                            f"Assunto: {item['subject']}\n\n"
                            f"Mensagem:\n{item['message']}\n\n"
                            f"ID: {item['id']}\n"
                            f"Data: {item['timestamp']}"
                        )
                    }
                }
            }
        )
    except Exception as e:
        print(f"Erro ao enviar email (não crítico): {e}")


def _response(status, body):
    return {
        'statusCode': status,
        'headers': CORS_HEADERS,
        'body': json.dumps(body)
    }
