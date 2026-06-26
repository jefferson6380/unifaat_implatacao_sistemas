import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import sharp from "sharp";

const s3 = new S3Client({ region: process.env.AWS_REGION || "us-east-1" });

const streamToBuffer = async (stream) => {
  const chunks = [];
  for await (const chunk of stream) chunks.push(chunk);
  return Buffer.concat(chunks);
};

export const handler = async (event) => {
  const record = event?.Records?.[0];
  if (!record) return { statusCode: 200, body: "No records" };

  const bucket = record.s3.bucket.name;
  const key = decodeURIComponent(record.s3.object.key.replace(/\+/g, " "));

  if (!key.startsWith("uploads/raw/")) {
    return { statusCode: 200, body: "Ignored key" };
  }

  const targetKey = key
    .replace("uploads/raw/", "uploads/optimized/")
    .replace(/\.(png|jpg|jpeg|webp)$/i, ".webp");

  const sourceObj = await s3.send(
    new GetObjectCommand({
      Bucket: bucket,
      Key: key
    })
  );

  const sourceBuffer = await streamToBuffer(sourceObj.Body);

  const outputBuffer = await sharp(sourceBuffer)
    .resize({ width: 1280, height: 800, fit: "inside", withoutEnlargement: true })
    .webp({ quality: 72 })
    .toBuffer();

  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: targetKey,
      Body: outputBuffer,
      ContentType: "image/webp",
      CacheControl: "public,max-age=31536000,immutable"
    })
  );

  return {
    statusCode: 200,
    body: JSON.stringify({
      source: key,
      output: targetKey,
      bytes: outputBuffer.length
    })
  };
};
