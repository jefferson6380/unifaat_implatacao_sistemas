/**
 * image-processor/index.js
 * Lambda acionada por eventos S3 PutObject no bucket de assets.
 * Redimensiona imagens enviadas e gera versões WebP otimizadas.
 *
 * Trigger: S3 — Event: s3:ObjectCreated:*
 * Pasta monitorada: uploads/
 * Saída gerada: processed/ (WebP + thumbnail)
 */

const { S3Client, GetObjectCommand, PutObjectCommand } = require('@aws-sdk/client-s3');
const sharp = require('sharp');
const path  = require('path');

const s3 = new S3Client({ region: process.env.AWS_REGION });

const SIZES = [
  { name: 'thumb',  width: 300,  height: 200  },
  { name: 'medium', width: 800,  height: 600  },
  { name: 'large',  width: 1920, height: 1080 },
];

const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

exports.handler = async (event) => {
  const results = [];

  for (const record of event.Records) {
    const bucket  = record.s3.bucket.name;
    const key     = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));

    /* Ignora arquivos fora da pasta uploads/ e arquivos já processados */
    if (!key.startsWith('uploads/') || key.startsWith('processed/')) {
      console.log(`Ignorando: ${key}`);
      continue;
    }

    console.log(`Processando: s3://${bucket}/${key}`);

    try {
      /* 1. Baixar original */
      const getCmd  = new GetObjectCommand({ Bucket: bucket, Key: key });
      const s3Obj   = await s3.send(getCmd);
      const chunks  = [];

      for await (const chunk of s3Obj.Body) chunks.push(chunk);
      const buffer  = Buffer.concat(chunks);

      const contentType = s3Obj.ContentType || 'image/jpeg';
      if (!ALLOWED_TYPES.includes(contentType)) {
        console.warn(`Tipo não suportado: ${contentType} — ignorando`);
        continue;
      }

      /* 2. Gerar variantes */
      const baseName = path.basename(key, path.extname(key));
      const processed = [];

      for (const { name, width, height } of SIZES) {
        const outKey = `processed/${baseName}-${name}.webp`;

        const resized = await sharp(buffer)
          .resize(width, height, { fit: 'inside', withoutEnlargement: true })
          .webp({ quality: 85 })
          .toBuffer();

        await s3.send(new PutObjectCommand({
          Bucket:      bucket,
          Key:         outKey,
          Body:        resized,
          ContentType: 'image/webp',
          CacheControl: 'max-age=31536000',
          Metadata: {
            'original-key': key,
            'size-variant': name,
          },
        }));

        console.log(`  ✓ Gerado: ${outKey} (${resized.length} bytes)`);
        processed.push({ size: name, key: outKey, bytes: resized.length });
      }

      results.push({ source: key, processed });
    } catch (err) {
      console.error(`Erro ao processar ${key}:`, err);
      results.push({ source: key, error: err.message });
    }
  }

  return {
    statusCode: 200,
    body: JSON.stringify({ results }),
  };
};
