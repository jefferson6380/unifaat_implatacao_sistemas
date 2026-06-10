/**
 * contact-form/index.js
 * Lambda chamada via API Gateway (POST /contact).
 * Salva mensagem no DynamoDB e envia notificação por e-mail via SES.
 *
 * Variáveis de ambiente necessárias:
 *   TABLE_NAME        — nome da tabela DynamoDB
 *   FROM_EMAIL        — e-mail verificado no SES (remetente)
 *   TO_EMAIL          — e-mail de destino das notificações
 *   ALLOWED_ORIGIN    — domínio CloudFront (CORS)
 */

const { DynamoDBClient, PutItemCommand } = require('@aws-sdk/client-dynamodb');
const { SESClient, SendEmailCommand }    = require('@aws-sdk/client-ses');
const { randomUUID }                     = require('crypto');

const dynamo = new DynamoDBClient({ region: process.env.AWS_REGION });
const ses    = new SESClient({ region: process.env.AWS_REGION });

const TABLE_NAME     = process.env.TABLE_NAME     || 'portfolio-contacts-6324073';
const FROM_EMAIL     = process.env.FROM_EMAIL     || 'leosano2006@gmail.com';
const TO_EMAIL       = process.env.TO_EMAIL       || 'leosano2006@gmail.com';
const ALLOWED_ORIGIN = process.env.ALLOWED_ORIGIN || '*';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin':  ALLOWED_ORIGIN,
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
};

exports.handler = async (event) => {
  /* Preflight CORS */
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers: CORS_HEADERS, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return json(405, { error: 'Método não permitido' });
  }

  /* Parse e validação */
  let body;
  try {
    body = JSON.parse(event.body || '{}');
  } catch {
    return json(400, { error: 'JSON inválido' });
  }

  const { nome, email, assunto, mensagem } = body;

  const errors = [];
  if (!nome     || nome.trim().length < 2)       errors.push('Nome inválido');
  if (!email    || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) errors.push('E-mail inválido');
  if (!assunto  || assunto.trim().length === 0)   errors.push('Assunto obrigatório');
  if (!mensagem || mensagem.trim().length < 20)   errors.push('Mensagem muito curta (mín. 20 caracteres)');

  if (errors.length > 0) {
    return json(422, { error: 'Dados inválidos', details: errors });
  }

  const id        = randomUUID();
  const timestamp = new Date().toISOString();
  const ip        = event.requestContext?.identity?.sourceIp || 'desconhecido';

  /* Salvar no DynamoDB */
  try {
    await dynamo.send(new PutItemCommand({
      TableName: TABLE_NAME,
      Item: {
        id:        { S: id },
        timestamp: { S: timestamp },
        nome:      { S: nome.trim() },
        email:     { S: email.trim().toLowerCase() },
        assunto:   { S: assunto.trim() },
        mensagem:  { S: mensagem.trim() },
        ip:        { S: ip },
        status:    { S: 'novo' },
      },
    }));
    console.log(`Contato salvo: ${id} — ${email}`);
  } catch (err) {
    console.error('Erro ao salvar no DynamoDB:', err);
    return json(500, { error: 'Erro interno ao processar sua mensagem.' });
  }

  /* Enviar notificação via SES */
  try {
    await ses.send(new SendEmailCommand({
      Source: FROM_EMAIL,
      Destination: { ToAddresses: [TO_EMAIL] },
      Message: {
        Subject: {
          Data: `[Portfólio] Nova mensagem: ${assunto} — ${nome}`,
          Charset: 'UTF-8',
        },
        Body: {
          Text: {
            Data: [
              `Nova mensagem recebida no portfólio`,
              ``,
              `ID:        ${id}`,
              `Data:      ${new Date(timestamp).toLocaleString('pt-BR')}`,
              `Nome:      ${nome}`,
              `E-mail:    ${email}`,
              `Assunto:   ${assunto}`,
              ``,
              `Mensagem:`,
              mensagem,
              ``,
              `---`,
              `IP de origem: ${ip}`,
            ].join('\n'),
            Charset: 'UTF-8',
          },
          Html: {
            Data: `
              <html><body style="font-family:sans-serif;max-width:600px;margin:0 auto;">
              <h2 style="color:#0a192f;">Nova mensagem no portfólio</h2>
              <table style="width:100%;border-collapse:collapse;">
                <tr><td style="padding:8px;color:#666;width:100px;">Nome</td><td style="padding:8px;">${escapeHtml(nome)}</td></tr>
                <tr style="background:#f9f9f9;"><td style="padding:8px;color:#666;">E-mail</td><td style="padding:8px;"><a href="mailto:${escapeHtml(email)}">${escapeHtml(email)}</a></td></tr>
                <tr><td style="padding:8px;color:#666;">Assunto</td><td style="padding:8px;">${escapeHtml(assunto)}</td></tr>
              </table>
              <h3 style="margin-top:20px;">Mensagem</h3>
              <p style="background:#f5f5f5;padding:16px;border-radius:4px;">${escapeHtml(mensagem).replace(/\n/g, '<br>')}</p>
              <hr><p style="color:#999;font-size:12px;">ID: ${id} · IP: ${ip}</p>
              </body></html>
            `,
            Charset: 'UTF-8',
          },
        },
      },
    }));
    console.log(`E-mail enviado para ${TO_EMAIL}`);
  } catch (err) {
    /* Falha no SES não deve impedir resposta ao usuário */
    console.error('Erro ao enviar e-mail via SES:', err.message);
  }

  return json(200, {
    success: true,
    message: 'Mensagem recebida com sucesso! Responderei em breve.',
    id,
  });
};

/* Helpers */
function json(statusCode, body) {
  return { statusCode, headers: CORS_HEADERS, body: JSON.stringify(body) };
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
