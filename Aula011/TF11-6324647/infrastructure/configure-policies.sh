#!/bin/bash
# configure-policies.sh - Configura headers de segurança e faz deploy do website

set -euo pipefail

BUCKET_WEBSITE="portfolio-gabriel-santiago-www"
BUCKET_ASSETS="portfolio-gabriel-santiago-assets"
WEBSITE_DIR="../website"

# ── 1. SYNC WEBSITE → S3 com cache headers corretos ────────────
echo "▶ Fazendo deploy do website para S3"

# HTML: sem cache (sempre fresh)
aws s3 sync "$WEBSITE_DIR" "s3://$BUCKET_WEBSITE" \
  --exclude "*.css" --exclude "*.js" --exclude "images/*" \
  --cache-control "no-cache, no-store, must-revalidate" \
  --content-type "text/html; charset=utf-8" \
  --delete

# CSS/JS: cache longo (versionar nomes em produção)
aws s3 sync "$WEBSITE_DIR/css" "s3://$BUCKET_WEBSITE/css" \
  --cache-control "public, max-age=31536000, immutable" \
  --content-type "text/css"

aws s3 sync "$WEBSITE_DIR/js" "s3://$BUCKET_WEBSITE/js" \
  --cache-control "public, max-age=31536000, immutable" \
  --content-type "application/javascript"

# Imagens: cache de 7 dias
aws s3 sync "$WEBSITE_DIR/images" "s3://$BUCKET_WEBSITE/images" \
  --cache-control "public, max-age=604800"

aws s3 sync "$WEBSITE_DIR/docs" "s3://$BUCKET_WEBSITE/docs" \
  --cache-control "public, max-age=86400"

echo "   ✓ Deploy concluído"

# ── 2. CORS NO BUCKET DE ASSETS ─────────────────────────────────
echo "▶ Configurando CORS no bucket de assets"
aws s3api put-bucket-cors \
  --bucket "$BUCKET_ASSETS" \
  --cors-configuration '{
    "CORSRules": [{
      "AllowedOrigins": ["https://*.cloudfront.net"],
      "AllowedMethods": ["GET", "PUT"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3600
    }]
  }'

# ── 3. INVALIDAR CACHE CLOUDFRONT ──────────────────────────────
if [ -n "${DISTRIBUTION_ID:-}" ]; then
  echo "▶ Invalidando cache CloudFront"
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*"
  echo "   ✓ Invalidação criada"
fi

echo ""
echo "✅ Políticas e deploy concluídos!"
