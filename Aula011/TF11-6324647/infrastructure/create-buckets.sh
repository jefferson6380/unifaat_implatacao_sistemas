#!/bin/bash
# create-buckets.sh - Cria e configura os buckets S3 do portfólio

set -euo pipefail

# ── CONFIGURAÇÕES ───────────────────────────────────────────────
BUCKET_WEBSITE="portfolio-gabriel-santiago-www"
BUCKET_ASSETS="portfolio-gabriel-santiago-assets"
REGION="us-east-1"

echo "▶ Criando bucket principal: $BUCKET_WEBSITE"
aws s3api create-bucket \
  --bucket "$BUCKET_WEBSITE" \
  --region "$REGION"

echo "▶ Criando bucket de assets: $BUCKET_ASSETS"
aws s3api create-bucket \
  --bucket "$BUCKET_ASSETS" \
  --region "$REGION"

# ── BLOQUEAR ACESSO PÚBLICO (acesso via CloudFront) ─────────────
for BUCKET in "$BUCKET_WEBSITE" "$BUCKET_ASSETS"; do
  echo "▶ Bloqueando acesso público direto: $BUCKET"
  aws s3api put-public-access-block \
    --bucket "$BUCKET" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
done

# ── VERSIONAMENTO ───────────────────────────────────────────────
echo "▶ Habilitando versionamento"
for BUCKET in "$BUCKET_WEBSITE" "$BUCKET_ASSETS"; do
  aws s3api put-bucket-versioning \
    --bucket "$BUCKET" \
    --versioning-configuration Status=Enabled
done

# ── LIFECYCLE POLICY ────────────────────────────────────────────
echo "▶ Configurando lifecycle policy (versões antigas)"
LIFECYCLE_FILE="$(pwd)/lifecycle.json"
LIFECYCLE_FILE_WIN="$(cygpath -w "$LIFECYCLE_FILE")"
cat > "$LIFECYCLE_FILE" <<'EOF'
{
  "Rules": [{
    "ID": "delete-old-versions",
    "Status": "Enabled",
    "Filter": { "Prefix": "" },
    "NoncurrentVersionExpiration": { "NoncurrentDays": 30 }
  }]
}
EOF
aws s3api put-bucket-lifecycle-configuration \
  --bucket "$BUCKET_WEBSITE" \
  --lifecycle-configuration file://"$LIFECYCLE_FILE_WIN"
rm -f "$LIFECYCLE_FILE"

# ── LOGS DE ACESSO ──────────────────────────────────────────────
BUCKET_LOGS="${BUCKET_WEBSITE}-logs"
echo "▶ Criando bucket de logs: $BUCKET_LOGS"
aws s3api create-bucket \
  --bucket "$BUCKET_LOGS" \
  --region "$REGION"

aws s3api put-bucket-logging \
  --bucket "$BUCKET_WEBSITE" \
  --bucket-logging-status "{
    \"LoggingEnabled\": {
      \"TargetBucket\": \"$BUCKET_LOGS\",
      \"TargetPrefix\": \"access-logs/\"
    }
  }"

echo ""
echo "✅ Buckets criados com sucesso!"
echo "   Website : $BUCKET_WEBSITE"
echo "   Assets  : $BUCKET_ASSETS"
echo "   Logs    : $BUCKET_LOGS"
