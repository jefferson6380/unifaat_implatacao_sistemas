#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$BASE_DIR/infrastructure/vars.sh" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/infrastructure/vars.sh"
elif [[ -f "$BASE_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/.env"
else
  echo "Arquivo de variaveis nao encontrado. Use infrastructure/vars.example.sh"
  exit 1
fi

: "${WEBSITE_BUCKET:?WEBSITE_BUCKET obrigatorio}"
: "${ASSETS_BUCKET:?ASSETS_BUCKET obrigatorio}"

if [[ -n "${ALIAS_DOMAIN:-}" ]]; then
  ALLOWED_ORIGIN="https://$ALIAS_DOMAIN"
else
  ALLOWED_ORIGIN="*"
fi

# Website bucket: leitura publica somente para objetos
aws s3api put-public-access-block \
  --bucket "$WEBSITE_BUCKET" \
  --public-access-block-configuration BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

WEBSITE_POLICY_FILE="$(mktemp)"
cat > "$WEBSITE_POLICY_FILE" << JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$WEBSITE_BUCKET/*"
    }
  ]
}
JSON

aws s3api put-bucket-policy \
  --bucket "$WEBSITE_BUCKET" \
  --policy "file://$WEBSITE_POLICY_FILE"
rm -f "$WEBSITE_POLICY_FILE"

# Assets bucket: manter bloqueio publico
aws s3api put-public-access-block \
  --bucket "$ASSETS_BUCKET" \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# CORS para uploads via browser/API
CORS_FILE="$(mktemp)"
cat > "$CORS_FILE" << JSON
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST"],
      "AllowedOrigins": ["$ALLOWED_ORIGIN"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}
JSON

aws s3api put-bucket-cors \
  --bucket "$ASSETS_BUCKET" \
  --cors-configuration "file://$CORS_FILE"
rm -f "$CORS_FILE"

# Criptografia server-side AES256
aws s3api put-bucket-encryption \
  --bucket "$WEBSITE_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws s3api put-bucket-encryption \
  --bucket "$ASSETS_BUCKET" \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Policies e CORS aplicados com sucesso."
