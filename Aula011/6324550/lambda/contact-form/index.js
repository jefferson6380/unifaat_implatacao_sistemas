// contact-form/index.js
// Lambda: Recebe dados do formulário, salva no DynamoDB e envia email via SES
// Autor: Bruno Pereira dos Santos - RA 6324550

const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const crypto = require('crypto');

const dynamo = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const ses = new SESClient({ region: process.env.AWS_REGION || 'us-east-1' });

const TABLE_NAME = process.env.DYNAMODB_TABLE || 'portfolio-contacts-6324550';
const FROM_EMAIL = process.env.SES_FROM_EMAIL || 'noreply@example.com';
const TO_EMAIL = process.env.SES_TO_EMAIL || 'bruno@example.com';

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'POST,OPTIONS',
  'Content-Type': 'application/json'
};

function sanitize(str = '') {
  return String(str).replace(/[<>]/g, '').trim().slice(0, 1000);
}

function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  try {
    const body = JSON.parse(event.body || '{}');
    const { name, email, subject, message } = body;

    // Validação
    if (!name || !email || !subject || !message) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'Todos os campos são obrigatórios.' }) };
    }
    if (!validateEmail(email)) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'E-mail inválido.' }) };
    }

    const id = crypto.randomUUID();
    const timestamp = new Date().toISOString();

    // Salvar no DynamoDB
    await dynamo.send(new PutItemCommand({
      TableName: TABLE_NAME,
      Item: {
        id: { S: id },
        name: { S: sanitize(name) },
        email: { S: sanitize(email) },
        subject: { S: sanitize(subject) },
        message: { S: sanitize(message) },
        timestamp: { S: timestamp },
        status: { S: 'new' }
      }
    }));

    // Enviar notificação por email (SES)
    try {
      await ses.send(new SendEmailCommand({
        Source: FROM_EMAIL,
        Destination: { ToAddresses: [TO_EMAIL] },
        Message: {
          Subject: { Data: `[Portfolio] Nova mensagem: ${sanitize(subject)}` },
          Body: {
            Text: {
              Data: `Nova mensagem recebida no portfólio de Bruno Pereira dos Santos (RA 6324550)\n\nNome: ${sanitize(name)}\nEmail: ${sanitize(email)}\nAssunto: ${sanitize(subject)}\n\nMensagem:\n${sanitize(message)}\n\nTimestamp: ${timestamp}\nID: ${id}`
            }
          }
        }
      }));
    } catch (sesErr) {
      // Não bloquear resposta se SES falhar
      console.warn('SES notification failed:', sesErr.message);
    }

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ success: true, id, message: 'Mensagem recebida com sucesso!' })
    };
  } catch (err) {
    console.error('Contact form error:', err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: 'Erro interno. Tente novamente.' }) };
  }
};
