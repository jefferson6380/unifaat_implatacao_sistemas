#!/usr/bin/env bash
# Cria e configura buckets S3 para o portfólio

set -euo pipefail

RA="${RA:-6324548}"
REGION="${AWS_REGION:-us-east-1}"
WEBSITE_BUCKET="portfolio-website-${RA}"
ASSETS_BUCKET="portfolio-assets-${RA}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSITE_DIR="${SCRIPT_DIR}/../website"

echo "==> Criando buckets para RA: ${RA} na região: ${REGION}"

# ── Criar buckets ──────────────────────────────────────────
aws s3api create-bucket \
  --bucket "${WEBSITE_BUCKET}" \
  --region "${REGION}" \
  $([ "${REGION}" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=${REGION}" || echo "") \
  2>/dev/null || echo "Bucket ${WEBSITE_BUCKET} já existe"

aws s3api create-bucket \
  --bucket "${ASSETS_BUCKET}" \
  --region "${REGION}" \
  $([ "${REGION}" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=${REGION}" || echo "") \
  2>/dev/null || echo "Bucket ${ASSETS_BUCKET} já existe"

echo "==> Buckets criados"

# ── Bloquear acesso público (acesso será via CloudFront OAC) ──
for BUCKET in "${WEBSITE_BUCKET}" "${ASSETS_BUCKET}"; do
  aws s3api put-public-access-block \
    --bucket "${BUCKET}" \
    --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
done

echo "==> Acesso público bloqueado"

# ── Habilitar versionamento ────────────────────────────────
for BUCKET in "${WEBSITE_BUCKET}" "${ASSETS_BUCKET}"; do
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET}" \
    --versioning-configuration Status=Enabled
done

echo "==> Versionamento habilitado"

# ── Lifecycle policy (mover para S3-IA após 30 dias) ──────
LIFECYCLE_POLICY='{
  "Rules": [
    {
      "ID": "mover-para-ia",
      "Status": "Enabled",
      "Prefix": "",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        }
      ],
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 7,
          "StorageClass": "STANDARD_IA"
        }
      ],
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 90
      }
    }
  ]
}'

for BUCKET in "${WEBSITE_BUCKET}" "${ASSETS_BUCKET}"; do
  aws s3api put-bucket-lifecycle-configuration \
    --bucket "${BUCKET}" \
    --lifecycle-configuration "${LIFECYCLE_POLICY}"
done

echo "==> Lifecycle policies configuradas"

# ── Habilitar logs de acesso ──────────────────────────────
LOGS_BUCKET="${WEBSITE_BUCKET}-logs"
aws s3api create-bucket \
  --bucket "${LOGS_BUCKET}" \
  --region "${REGION}" \
  $([ "${REGION}" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=${REGION}" || echo "") \
  2>/dev/null || true

aws s3api put-bucket-acl \
  --bucket "${LOGS_BUCKET}" \
  --acl log-delivery-write 2>/dev/null || true

aws s3api put-bucket-logging \
  --bucket "${WEBSITE_BUCKET}" \
  --bucket-logging-status "{
    \"LoggingEnabled\": {
      \"TargetBucket\": \"${LOGS_BUCKET}\",
      \"TargetPrefix\": \"website-access-logs/\"
    }
  }" 2>/dev/null || echo "Aviso: logging pode requerer permissões adicionais"

echo "==> Logs configurados"

# ── Upload dos arquivos do site ───────────────────────────
if [ -d "${WEBSITE_DIR}" ]; then
  echo "==> Fazendo upload dos arquivos do website..."

  # HTML sem cache (CloudFront serve com cache-control via response headers policy)
  aws s3 sync "${WEBSITE_DIR}" "s3://${WEBSITE_BUCKET}/" \
    --exclude "*.DS_Store" \
    --exclude "Thumbs.db"

  # Definir content-type e cache-control por extensão
  aws s3 cp "s3://${WEBSITE_BUCKET}/" "s3://${WEBSITE_BUCKET}/" \
    --recursive \
    --exclude "*" \
    --include "*.html" \
    --content-type "text/html; charset=utf-8" \
    --cache-control "no-cache, no-store, must-revalidate" \
    --metadata-directive REPLACE 2>/dev/null || true

  aws s3 cp "s3://${WEBSITE_BUCKET}/" "s3://${WEBSITE_BUCKET}/" \
    --recursive \
    --exclude "*" \
    --include "*.css" \
    --content-type "text/css" \
    --cache-control "max-age=86400" \
    --metadata-directive REPLACE 2>/dev/null || true

  aws s3 cp "s3://${WEBSITE_BUCKET}/" "s3://${WEBSITE_BUCKET}/" \
    --recursive \
    --exclude "*" \
    --include "*.js" \
    --content-type "application/javascript" \
    --cache-control "max-age=86400" \
    --metadata-directive REPLACE 2>/dev/null || true

  echo "==> Upload concluído"
else
  echo "Aviso: diretório ${WEBSITE_DIR} não encontrado. Pule o upload."
fi

# ── CORS no bucket de assets ──────────────────────────────
aws s3api put-bucket-cors \
  --bucket "${ASSETS_BUCKET}" \
  --cors-configuration '{
    "CORSRules": [
      {
        "AllowedHeaders": ["*"],
        "AllowedMethods": ["GET", "PUT", "POST"],
        "AllowedOrigins": ["*"],
        "MaxAgeSeconds": 3000
      }
    ]
  }'

echo "==> CORS configurado no bucket de assets"
echo ""
echo "✅ Buckets configurados com sucesso!"
echo "   Website bucket : ${WEBSITE_BUCKET}"
echo "   Assets bucket  : ${ASSETS_BUCKET}"
echo ""
echo "Próximo passo: execute configure-policies.sh e depois setup-cloudfront.sh"

# Exportar nomes para outros scripts
export WEBSITE_BUCKET ASSETS_BUCKET REGION
