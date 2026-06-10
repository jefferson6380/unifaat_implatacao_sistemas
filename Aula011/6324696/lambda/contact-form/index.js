'use strict';

/**
 * Lambda — Formulário de contato
 * Recebe dados do API Gateway, valida, salva no DynamoDB e envia e-mail via SES.
 *
 * Variáveis de ambiente necessárias:
 *   TABLE_NAME   — nome da tabela DynamoDB
 *   SES_FROM     — endereço remetente verificado no SES
 *   NOTIFY_EMAIL — e-mail que receberá as notificações
 */

const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { SESClient, SendEmailCommand }    = require('@aws-sdk/client-ses');
const { randomUUID }                     = require('crypto');

const dynamo = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const ses    = new SESClient({ region: process.env.AWS_REGION || 'us-east-1' });

const TABLE_NAME   = process.env.TABLE_NAME   || 'portfolio-contacts';
const SES_FROM     = process.env.SES_FROM     || 'lemenatan@gmail.com';
const NOTIFY_EMAIL = process.env.NOTIFY_EMAIL || 'lemenatan@gmail.com';

const ALLOWED_ORIGINS = [
  'https://REPLACE_CLOUDFRONT_DOMAIN',
  'http://localhost:3000',
];

function corsHeaders(origin) {
  const allowed = ALLOWED_ORIGINS.includes(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin':  allowed,
    'Access-Control-Allow-Methods': 'POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Strict-Transport-Security':    'max-age=63072000; includeSubDomains; preload',
    'X-Content-Type-Options':       'nosniff',
    'X-Frame-Options':              'DENY',
  };
}

function response(statusCode, body, origin = '') {
  return {
    statusCode,
    headers: { ...corsHeaders(origin), 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  };
}

function validate(data) {
  const { name, email, subject, message } = data;
  if (!name    || name.trim().length < 2)       return 'Nome inválido';
  if (!email   || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return 'E-mail inválido';
  if (!subject || subject.trim().length < 1)    return 'Assunto obrigatório';
  if (!message || message.trim().length < 10)   return 'Mensagem muito curta';
  return null;
}

exports.handler = async (event) => {
  const origin = (event.headers || {}).origin || '';

  // Preflight
  if (event.httpMethod === 'OPTIONS') {
    return response(200, {}, origin);
  }

  if (event.httpMethod !== 'POST') {
    return response(405, { message: 'Method Not Allowed' }, origin);
  }

  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return response(400, { message: 'JSON inválido' }, origin);
  }

  // Honeypot anti-spam
  if (body.website) {
    return response(200, { message: 'ok' }, origin); // silencia bots
  }

  const validationError = validate(body);
  if (validationError) {
    return response(400, { message: validationError }, origin);
  }

  const id        = randomUUID();
  const timestamp = new Date().toISOString();

  const item = {
    id:        { S: id },
    name:      { S: body.name.trim() },
    email:     { S: body.email.trim().toLowerCase() },
    subject:   { S: body.subject.trim() },
    message:   { S: body.message.trim() },
    createdAt: { S: timestamp },
    status:    { S: 'pending' },
  };

  try {
    // Persiste no DynamoDB
    await dynamo.send(new PutItemCommand({
      TableName: TABLE_NAME,
      Item: item,
    }));

    // Notifica por e-mail via SES (não-bloqueante — falha silenciosa se e-mail não verificado)
    try {
      await ses.send(new SendEmailCommand({
        Source: SES_FROM,
        Destination: { ToAddresses: [NOTIFY_EMAIL] },
        Message: {
          Subject: {
            Data: `[Portfólio] Nova mensagem: ${body.subject}`,
            Charset: 'UTF-8',
          },
          Body: {
            Text: {
              Charset: 'UTF-8',
              Data: [
                `Nova mensagem recebida no portfólio!`,
                ``,
                `ID      : ${id}`,
                `Data    : ${timestamp}`,
                `Nome    : ${body.name}`,
                `E-mail  : ${body.email}`,
                `Assunto : ${body.subject}`,
                ``,
                `Mensagem:`,
                `${body.message}`,
              ].join('\n'),
            },
          },
        },
      }));
    } catch (sesErr) {
      console.warn('SES notification failed (non-critical):', sesErr.message);
    }

    return response(200, { message: 'Mensagem enviada com sucesso!', id }, origin);
  } catch (err) {
    console.error('Error processing contact form:', JSON.stringify({ err: err.message, id }));
    return response(500, { message: 'Erro interno. Tente novamente.' }, origin);
  }
};
