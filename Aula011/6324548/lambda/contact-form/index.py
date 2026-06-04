"""
Lambda: contact-form
Trigger: API Gateway POST /contact
Ação: validar dados, salvar no DynamoDB, enviar email via SES
"""

import json
import os
import re
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
ses = boto3.client('ses', region_name=os.environ.get('AWS_REGION', 'us-east-1'))

TABLE_NAME = os.environ.get('DYNAMO_TABLE', 'portfolio-contacts')
FROM_EMAIL = os.environ.get('FROM_EMAIL', 'luizfelipe.souza@althaia.com.br')
TO_EMAIL = os.environ.get('TO_EMAIL', 'luizfelipe.souza@althaia.com.br')

CORS_HEADERS = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'OPTIONS,POST',
    'Content-Type': 'application/json',
}


def lambda_handler(event, context):
    # Preflight CORS
    if event.get('httpMethod') == 'OPTIONS':
        return {'statusCode': 200, 'headers': CORS_HEADERS, 'body': ''}

    try:
        body = json.loads(event.get('body') or '{}')
    except json.JSONDecodeError:
        return response(400, {'message': 'JSON inválido'})

    # Validação
    errors = validate(body)
    if errors:
        return response(400, {'message': 'Dados inválidos', 'errors': errors})

    nome = body['nome'].strip()
    email = body['email'].strip().lower()
    assunto = body['assunto'].strip()
    mensagem = body['mensagem'].strip()

    contact_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    # Salvar no DynamoDB
    try:
        table = dynamodb.Table(TABLE_NAME)
        table.put_item(Item={
            'id': contact_id,
            'timestamp': timestamp,
            'nome': nome,
            'email': email,
            'assunto': assunto,
            'mensagem': mensagem,
            'status': 'novo',
        })
    except ClientError as e:
        print(f'Erro DynamoDB: {e}')
        return response(500, {'message': 'Erro ao salvar mensagem'})

    # Enviar email via SES
    try:
        send_email(nome, email, assunto, mensagem, contact_id, timestamp)
    except ClientError as e:
        print(f'Erro SES (não crítico): {e}')
        # Não retornar erro — mensagem já foi salva no DynamoDB

    return response(200, {
        'message': 'Mensagem recebida com sucesso!',
        'id': contact_id,
    })


def validate(body: dict) -> list:
    errors = []
    nome = body.get('nome', '').strip()
    email = body.get('email', '').strip()
    assunto = body.get('assunto', '').strip()
    mensagem = body.get('mensagem', '').strip()

    if not nome or len(nome) < 2:
        errors.append('Nome inválido (mínimo 2 caracteres)')
    if not email or not re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email):
        errors.append('E-mail inválido')
    if not assunto:
        errors.append('Assunto obrigatório')
    if not mensagem or len(mensagem) < 10:
        errors.append('Mensagem muito curta (mínimo 10 caracteres)')
    if len(nome) > 100 or len(assunto) > 200 or len(mensagem) > 5000:
        errors.append('Dados excedem tamanho máximo permitido')

    return errors


def send_email(nome: str, email: str, assunto: str, mensagem: str,
               contact_id: str, timestamp: str) -> None:
    subject = f'[Portfólio] {assunto} — {nome}'
    body_text = f"""Nova mensagem do portfólio

ID: {contact_id}
Data: {timestamp}
De: {nome} <{email}>
Assunto: {assunto}

Mensagem:
{mensagem}
"""
    body_html = f"""<html><body style="font-family:sans-serif;max-width:600px;margin:auto;padding:20px">
<h2 style="color:#58a6ff">Nova mensagem do portfólio</h2>
<table style="width:100%;border-collapse:collapse">
  <tr><td style="padding:8px;color:#888;width:100px">ID</td><td>{contact_id}</td></tr>
  <tr><td style="padding:8px;color:#888">Data</td><td>{timestamp}</td></tr>
  <tr><td style="padding:8px;color:#888">De</td><td>{nome} &lt;{email}&gt;</td></tr>
  <tr><td style="padding:8px;color:#888">Assunto</td><td>{assunto}</td></tr>
</table>
<h3>Mensagem:</h3>
<div style="background:#f6f8fa;padding:16px;border-radius:8px;white-space:pre-wrap">{mensagem}</div>
</body></html>"""

    ses.send_email(
        Source=FROM_EMAIL,
        Destination={'ToAddresses': [TO_EMAIL]},
        Message={
            'Subject': {'Data': subject},
            'Body': {
                'Text': {'Data': body_text},
                'Html': {'Data': body_html},
            },
        },
        ReplyToAddresses=[email],
    )


def response(status: int, body: dict) -> dict:
    return {
        'statusCode': status,
        'headers': CORS_HEADERS,
        'body': json.dumps(body),
    }
