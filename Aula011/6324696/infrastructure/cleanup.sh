#!/usr/bin/env bash
# ATENÇÃO: Remove TODOS os recursos AWS criados pelo TF11
# Execute apenas após a avaliação!
set -euo pipefail

REGION="us-east-1"
WEBSITE_BUCKET="natan-portifolio-website-6324696"
ASSETS_BUCKET="natan-portifolio-assets-6324696"
LOGS_BUCKET="${WEBSITE_BUCKET}-logs"
ENV_FILE="$(dirname "$0")/.env.deploy"

echo "======================================"
echo " TF11 — LIMPEZA DE RECURSOS AWS"
echo " Aluno: Natan Borges Leme (6324696)"
echo "======================================"
echo ""
echo " ⚠️  ATENÇÃO: Esta operação é IRREVERSÍVEL!"
echo " Todos os buckets S3 e a distribuição CloudFront serão deletados."
echo ""
read -r -p " Digite 'CONFIRMAR' para prosseguir: " CONFIRM
if [ "$CONFIRM" != "CONFIRMAR" ]; then
  echo " Operação cancelada."
  exit 0
fi

# ----------------------------
# 1. Desabilitar e deletar CloudFront
# ----------------------------
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  if [ -n "${DIST_ID:-}" ]; then
    echo ""
    echo "[1/4] Desabilitando distribuição CloudFront: $DIST_ID"
    # Obter ETag atual
    ETAG=$(aws cloudfront get-distribution-config --id "$DIST_ID" --query 'ETag' --output text)
    CONFIG=$(aws cloudfront get-distribution-config --id "$DIST_ID" --query 'DistributionConfig' --output json)
    DISABLED_CONFIG=$(echo "$CONFIG" | python3 -c "import sys,json; c=json.load(sys.stdin); c['Enabled']=False; print(json.dumps(c))")
    NEW_ETAG=$(aws cloudfront update-distribution \
      --id "$DIST_ID" \
      --distribution-config "$DISABLED_CONFIG" \
      --if-match "$ETAG" \
      --query 'ETag' --output text)
    echo "  → Aguardando distribuição desabilitar (~5min)..."
    aws cloudfront wait distribution-deployed --id "$DIST_ID"
    aws cloudfront delete-distribution --id "$DIST_ID" --if-match "$NEW_ETAG"
    echo "  ✓ CloudFront deletado."
  fi
else
  echo "[1/4] .env.deploy não encontrado, pulando CloudFront."
fi

# ----------------------------
# 2-4. Esvaziar e deletar buckets
# ----------------------------
empty_and_delete() {
  local BUCKET="$1"
  echo ""
  echo "Processando bucket: $BUCKET"
  if ! aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    echo "  → Bucket não existe, pulando."
    return
  fi
  echo "  → Removendo todos os objetos e versões..."
  # Remove objetos (incluindo versões e marcadores de delete)
  aws s3api list-object-versions --bucket "$BUCKET" --output json \
    | python3 -c "
import sys, json, subprocess
data = json.load(sys.stdin)
for key in ('Versions', 'DeleteMarkers'):
  for obj in data.get(key, []):
    subprocess.run(['aws','s3api','delete-object',
      '--bucket','$BUCKET',
      '--key', obj['Key'],
      '--version-id', obj['VersionId']], check=True)
print('  ✓ Versões removidas.')
" 2>/dev/null || true
  aws s3 rm "s3://$BUCKET" --recursive 2>/dev/null || true
  aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION"
  echo "  ✓ Bucket deletado."
}

echo ""
echo "[2/4] Limpando bucket de website..."
empty_and_delete "$WEBSITE_BUCKET"

echo "[3/4] Limpando bucket de assets..."
empty_and_delete "$ASSETS_BUCKET"

echo "[4/4] Limpando bucket de logs..."
empty_and_delete "$LOGS_BUCKET"

# Limpar env
rm -f "$ENV_FILE"

echo ""
echo "======================================"
echo " ✅ Limpeza concluída!"
echo " Verifique no console AWS que não há recursos residuais."
echo " AWS Billing → Cost Explorer para confirmar $0 de custos futuros."
echo "======================================"
