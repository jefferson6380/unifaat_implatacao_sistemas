#!/usr/bin/env bash
# Configura bucket policies e headers de segurança
set -euo pipefail

REGION="us-east-1"
WEBSITE_BUCKET="natan-portifolio-website-6324696"
ASSETS_BUCKET="natan-portifolio-assets-6324696"

echo "======================================"
echo " TF11 — Configurando Políticas S3"
echo " Aluno: Natan Borges Leme (6324696)"
echo "======================================"

# ----------------------------
# 1. Desabilitar block public access APENAS para o website bucket
#    (assets ficam privados — acesso apenas via CloudFront OAC)
# ----------------------------
echo ""
echo "[1/4] Configurando acesso público no bucket de website..."
aws s3api put-public-access-block \
  --bucket "$WEBSITE_BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
echo "  ✓ Block public access desabilitado para o website bucket."

echo ""
echo "[2/4] Mantendo assets bucket privado (acesso via CloudFront OAC)..."
aws s3api put-public-access-block \
  --bucket "$ASSETS_BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
echo "  ✓ Assets bucket permanece privado."

# ----------------------------
# 3. Bucket policy — website público (leitura)
# ----------------------------
echo ""
echo "[3/4] Aplicando bucket policy no website bucket..."
cat > /tmp/website-policy.json << POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${WEBSITE_BUCKET}/*"
    }
  ]
}
POLICY

aws s3api put-bucket-policy \
  --bucket "$WEBSITE_BUCKET" \
  --policy file:///tmp/website-policy.json
echo "  ✓ Bucket policy aplicada (leitura pública)."

# ----------------------------
# 4. CORS para assets bucket (permite uploads do domínio CloudFront)
# ----------------------------
echo ""
echo "[4/4] Configurando CORS no bucket de assets..."
cat > /tmp/cors-config.json << CORS
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3600
    }
  ]
}
CORS

aws s3api put-bucket-cors \
  --bucket "$ASSETS_BUCKET" \
  --cors-configuration file:///tmp/cors-config.json
echo "  ✓ CORS configurado no assets bucket."

# Limpar arquivos temporários
rm -f /tmp/website-policy.json /tmp/cors-config.json

echo ""
echo "======================================"
echo " ✅ Políticas configuradas!"
echo "======================================"
echo " Próximo passo: execute setup-cloudfront.sh"
echo "======================================"
