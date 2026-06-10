#!/bin/bash
# cleanup.sh - Remove todos os recursos AWS do portfólio

set -euo pipefail

BUCKET_WEBSITE="portfolio-gabriel-santiago-www"
BUCKET_ASSETS="portfolio-gabriel-santiago-assets"

echo "⚠️  Este script irá REMOVER todos os recursos do portfólio."
read -r -p "Tem certeza? (sim/não): " CONFIRM
[[ "$CONFIRM" != "sim" ]] && { echo "Operação cancelada."; exit 0; }

# ── 1. DESABILITAR DISTRIBUIÇÃO CLOUDFRONT ──────────────────────
if [ -n "${DISTRIBUTION_ID:-}" ]; then
  echo "▶ Desabilitando distribuição CloudFront: $DISTRIBUTION_ID"
  ETAG=$(aws cloudfront get-distribution-config \
    --id "$DISTRIBUTION_ID" --query 'ETag' --output text)

  aws cloudfront get-distribution-config \
    --id "$DISTRIBUTION_ID" \
    --query 'DistributionConfig' | \
    python3 -c "import sys, json; c=json.load(sys.stdin); c['Enabled']=False; print(json.dumps(c))" > /tmp/cf-config.json

  aws cloudfront update-distribution \
    --id "$DISTRIBUTION_ID" \
    --if-match "$ETAG" \
    --distribution-config file:///tmp/cf-config.json

  echo "   ✓ Distribuição desabilitada (aguarde ~15 min para excluir)"
fi

# ── 2. ESVAZIAR E EXCLUIR BUCKETS ──────────────────────────────
for BUCKET in "$BUCKET_WEBSITE" "$BUCKET_ASSETS" "${BUCKET_WEBSITE}-logs"; do
  if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    echo "▶ Esvaziando bucket: $BUCKET"
    aws s3 rm "s3://$BUCKET" --recursive
    # Remover versões antigas se versionamento estiver ativo
    aws s3api list-object-versions --bucket "$BUCKET" \
      --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text 2>/dev/null | \
      while read -r KEY VID; do
        aws s3api delete-object --bucket "$BUCKET" --key "$KEY" --version-id "$VID"
      done
    echo "▶ Excluindo bucket: $BUCKET"
    aws s3api delete-bucket --bucket "$BUCKET"
  fi
done

echo ""
echo "✅ Limpeza concluída!"
echo "   Lembre-se de excluir manualmente a distribuição CloudFront após ela ficar Disabled."
