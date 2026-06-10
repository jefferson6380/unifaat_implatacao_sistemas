'use strict';

/**
 * Lambda — Processamento de imagens
 * Triggered por upload no S3 (bucket de assets).
 * Gera versões redimensionadas e converte para WebP usando Sharp.
 *
 * Variáveis de ambiente:
 *   DEST_BUCKET — bucket de destino para as versões processadas
 */

const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const sharp = require('sharp');
const path  = require('path');

const s3 = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });

const DEST_BUCKET = process.env.DEST_BUCKET || process.env.AWS_S3_BUCKET;

const SIZES = [
  { name: 'thumb',  width: 200,  height: 200,  fit: 'cover'    },
  { name: 'medium', width: 600,  height: 400,  fit: 'inside'   },
  { name: 'large',  width: 1200, height: 800,  fit: 'inside'   },
];

const ALLOWED_MIME = new Set(['image/jpeg', 'image/png', 'image/webp', 'image/gif']);

async function streamToBuffer(stream) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    stream.on('data', chunk => chunks.push(chunk));
    stream.on('end', () => resolve(Buffer.concat(chunks)));
    stream.on('error', reject);
  });
}

exports.handler = async (event) => {
  const results = [];

  for (const record of event.Records) {
    const srcBucket = record.s3.bucket.name;
    const srcKey    = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));

    console.log(`Processing: s3://${srcBucket}/${srcKey}`);

    // Ignorar arquivos já processados (evitar loop)
    if (srcKey.startsWith('processed/')) {
      console.log('Skipping already-processed file.');
      continue;
    }

    // Verificar tipo via extensão (header content-type vem no HeadObject)
    const ext = path.extname(srcKey).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext)) {
      console.log(`Skipping non-image file: ${srcKey}`);
      continue;
    }

    // Baixar imagem original
    let srcBuffer;
    try {
      const getRes = await s3.send(new GetObjectCommand({ Bucket: srcBucket, Key: srcKey }));
      if (!ALLOWED_MIME.has(getRes.ContentType || '')) {
        console.log(`Skipping unsupported content-type: ${getRes.ContentType}`);
        continue;
      }
      srcBuffer = await streamToBuffer(getRes.Body);
    } catch (err) {
      console.error(`Failed to download ${srcKey}:`, err.message);
      continue;
    }

    // Metadados da imagem original
    let metadata;
    try {
      metadata = await sharp(srcBuffer).metadata();
    } catch (err) {
      console.error(`Invalid image ${srcKey}:`, err.message);
      continue;
    }

    const baseName  = path.basename(srcKey, path.extname(srcKey));
    const destBucket = DEST_BUCKET || srcBucket;

    // Processar cada tamanho
    for (const size of SIZES) {
      // Pular se original já é menor que o tamanho alvo
      if (metadata.width <= size.width && metadata.height <= size.height) continue;

      try {
        const processed = await sharp(srcBuffer)
          .resize(size.width, size.height, { fit: size.fit, withoutEnlargement: true })
          .webp({ quality: 82 })
          .toBuffer();

        const destKey = `processed/${size.name}/${baseName}.webp`;

        await s3.send(new PutObjectCommand({
          Bucket:      destBucket,
          Key:         destKey,
          Body:        processed,
          ContentType: 'image/webp',
          CacheControl: 'public,max-age=31536000',
          Metadata: {
            'original-key': srcKey,
            'size-variant':  size.name,
          },
        }));

        results.push({ key: destKey, size: size.name, bytes: processed.length });
        console.log(`  ✓ ${size.name}: ${destKey} (${(processed.length / 1024).toFixed(1)} KB)`);
      } catch (err) {
        console.error(`  ✗ Failed to process ${size.name}:`, err.message);
      }
    }
  }

  return { processed: results.length, files: results };
};
