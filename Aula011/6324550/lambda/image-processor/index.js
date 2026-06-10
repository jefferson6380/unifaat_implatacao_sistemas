// image-processor/index.js
// Lambda: Processa uploads de imagens e gera URL pré-assinada para S3
// Autor: Bruno Pereira dos Santos - RA 6324550

const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const crypto = require('crypto');
const path = require('path');

const s3 = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });
const ASSETS_BUCKET = process.env.ASSETS_BUCKET;
const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
const MAX_SIZE_MB = 5;

const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'POST,OPTIONS',
  'Content-Type': 'application/json'
};

exports.handler = async (event) => {
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }

  try {
    const body = JSON.parse(event.body || '{}');
    const { fileName, fileType } = body;

    if (!fileName || !fileType) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'fileName e fileType são obrigatórios.' }) };
    }

    if (!ALLOWED_TYPES.includes(fileType)) {
      return { statusCode: 400, headers, body: JSON.stringify({ error: 'Tipo de arquivo não permitido.' }) };
    }

    const ext = path.extname(fileName).toLowerCase() || '.jpg';
    const uniqueKey = `uploads/${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext}`;

    const command = new PutObjectCommand({
      Bucket: ASSETS_BUCKET,
      Key: uniqueKey,
      ContentType: fileType,
      Metadata: {
        'original-name': fileName,
        'uploaded-by': 'portfolio-6324550'
      }
    });

    const uploadUrl = await getSignedUrl(s3, command, { expiresIn: 300 });
    const fileUrl = `https://${ASSETS_BUCKET}.s3.amazonaws.com/${uniqueKey}`;

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ uploadUrl, fileUrl, key: uniqueKey })
    };
  } catch (err) {
    console.error('Image processor error:', err);
    return { statusCode: 500, headers, body: JSON.stringify({ error: 'Erro interno no servidor.' }) };
  }
};
