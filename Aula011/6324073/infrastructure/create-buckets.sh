#!/bin/bash
# =============================================================
# create-buckets.sh
# Cria e configura os buckets S3 para o portfólio
# =============================================================

set -euo pipefail

REGION="us-east-1"
RA="6324073"
WEBSITE_BUCKET="portfolio-lfs-website-${RA}"
ASSETS_BUCKET="portfolio-lfs-assets-${RA}"

echo "=== Criando buckets S3 ==="
echo "Região: ${REGION}"
echo "Bucket website: ${WEBSITE_BUCKET}"
echo "Bucket assets:  ${ASSETS_BUCKET}"
echo ""

# ----------------------------------------------------------------
# 1. Bucket principal (website estático)
# ----------------------------------------------------------------
echo "[1/8] Criando bucket website..."
aws s3api create-bucket \
  --bucket "${WEBSITE_BUCKET}" \
  --region "${REGION}"

# Desabilitar bloqueio de acesso público (necessário para website estático)
echo "[2/8] Removendo bloqueio de acesso público do website bucket..."
aws s3api put-public-access-block \
  --bucket "${WEBSITE_BUCKET}" \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Configurar hospedagem de website estático
echo "[3/8] Configurando static website hosting..."
aws s3api put-bucket-website \
  --bucket "${WEBSITE_BUCKET}" \
  --website-configuration '{
    "IndexDocument": {"Suffix": "index.html"},
    "ErrorDocument": {"Key": "404.html"}
  }'

# Política pública de leitura (necessária para acesso via CloudFront)
echo "[4/8] Aplicando bucket policy (leitura pública)..."
aws s3api put-bucket-policy \
  --bucket "${WEBSITE_BUCKET}" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\": \"PublicReadGetObject\",
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${WEBSITE_BUCKET}/*\"
    }]
  }"

# Habilitar versionamento
echo "[5/8] Habilitando versionamento no bucket website..."
aws s3api put-bucket-versioning \
  --bucket "${WEBSITE_BUCKET}" \
  --versioning-configuration Status=Enabled

# Lifecycle policy para versões antigas (reduz custos)
echo "[6/8] Configurando lifecycle policy..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "${WEBSITE_BUCKET}" \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "delete-old-versions",
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {"NoncurrentDays": 30},
      "Filter": {"Prefix": ""}
    }]
  }'

# ----------------------------------------------------------------
# 2. Bucket de assets (imagens, documentos)
# ----------------------------------------------------------------
echo "[7/8] Criando bucket de assets..."
aws s3api create-bucket \
  --bucket "${ASSETS_BUCKET}" \
  --region "${REGION}"

aws s3api put-public-access-block \
  --bucket "${ASSETS_BUCKET}" \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

aws s3api put-bucket-policy \
  --bucket "${ASSETS_BUCKET}" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\": \"PublicReadGetObject\",
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${ASSETS_BUCKET}/*\"
    }]
  }"

# CORS para permitir uploads via JavaScript
echo "[8/8] Configurando CORS no bucket de assets..."
aws s3api put-bucket-cors \
  --bucket "${ASSETS_BUCKET}" \
  --cors-configuration '{
    "CORSRules": [{
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }]
  }'

# ----------------------------------------------------------------
# 3. Upload do conteúdo do website
# ----------------------------------------------------------------
echo ""
echo "=== Fazendo upload do website para S3 ==="
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSITE_DIR="${SCRIPT_DIR}/../website"

aws s3 sync "${WEBSITE_DIR}" "s3://${WEBSITE_BUCKET}" \
  --exclude "*.DS_Store" \
  --cache-control "max-age=86400" \
  --metadata-directive REPLACE

# Cache mais curto para HTML (garante atualizações rápidas)
aws s3 sync "${WEBSITE_DIR}" "s3://${WEBSITE_BUCKET}" \
  --exclude "*" \
  --include "*.html" \
  --cache-control "no-cache,max-age=0" \
  --metadata-directive REPLACE

# ----------------------------------------------------------------
# Resultado
# ----------------------------------------------------------------
WEBSITE_URL="http://${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"

echo ""
echo "======================================================"
echo "✅ Buckets criados e configurados com sucesso!"
echo "======================================================"
echo "Website S3 URL: ${WEBSITE_URL}"
echo "Assets Bucket:  s3://${ASSETS_BUCKET}"
echo ""
echo "Próximo passo: execute setup-cloudfront.sh"
echo "======================================================"
