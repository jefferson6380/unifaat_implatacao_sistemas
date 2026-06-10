#!/bin/bash
# cleanup.sh
# Autor: Bruno Pereira dos Santos - RA 6324550
# Descrição: Remove todos os recursos AWS criados para o TF11

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env.infra" ]; then
  source "$SCRIPT_DIR/.env.infra"
else
  echo "AVISO: .env.infra não encontrado. Defina variáveis manualmente."
  WEBSITE_BUCKET="${WEBSITE_BUCKET:-portfolio-bruno-6324550}"
  ASSETS_BUCKET="${ASSETS_BUCKET:-portfolio-bruno-6324550-assets}"
  DISTRIBUTION_ID="${DISTRIBUTION_ID:-}"
fi

echo "======================================"
echo " LIMPEZA DE RECURSOS - TF11"
echo " Aluno: Bruno Pereira dos Santos - RA 6324550"
echo "======================================"
echo ""
read -p "ATENÇÃO: Isso removerá TODOS os recursos. Confirmar? (yes/no): " CONFIRM
[ "$CONFIRM" != "yes" ] && echo "Cancelado." && exit 0

# ===== CloudFront =====
if [ -n "${DISTRIBUTION_ID:-}" ]; then
  echo "[1] Desabilitando distribuição CloudFront: $DISTRIBUTION_ID"
  ETAG=$(aws cloudfront get-distribution --id "$DISTRIBUTION_ID" --query ETag --output text)
  CONFIG=$(aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" --query DistributionConfig --output json)
  DISABLED_CONFIG=$(echo "$CONFIG" | python3 -c "import sys,json; c=json.load(sys.stdin); c['Enabled']=False; print(json.dumps(c))")
  NEW_ETAG=$(aws cloudfront update-distribution --id "$DISTRIBUTION_ID" --if-match "$ETAG" \
    --distribution-config "$DISABLED_CONFIG" --query ETag --output text)
  echo "  Aguardando distribuição ser desabilitada..."
  aws cloudfront wait distribution-deployed --id "$DISTRIBUTION_ID"
  echo "  Deletando distribuição..."
  aws cloudfront delete-distribution --id "$DISTRIBUTION_ID" --if-match "$NEW_ETAG"
  echo "  CloudFront removido."
fi

# ===== Lambda =====
echo "[2] Removendo Lambda functions..."
for fn in "portfolio-contact-form-6324550" "portfolio-image-processor-6324550"; do
  aws lambda delete-function --function-name "$fn" 2>/dev/null && echo "  Removida: $fn" || echo "  Não encontrada: $fn"
done

# ===== API Gateway =====
echo "[3] Removendo API Gateway..."
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='portfolio-api-6324550'].id" --output text 2>/dev/null)
if [ -n "$API_ID" ]; then
  aws apigateway delete-rest-api --rest-api-id "$API_ID"
  echo "  API Gateway removido: $API_ID"
fi

# ===== DynamoDB =====
echo "[4] Removendo tabela DynamoDB..."
aws dynamodb delete-table --table-name "portfolio-contacts-6324550" 2>/dev/null && echo "  Tabela removida." || echo "  Tabela não encontrada."

# ===== S3 Buckets =====
echo "[5] Esvaziando e removendo bucket principal: $WEBSITE_BUCKET"
aws s3 rm "s3://$WEBSITE_BUCKET" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$WEBSITE_BUCKET" 2>/dev/null && echo "  Bucket removido." || echo "  Bucket não encontrado."

echo "[6] Esvaziando e removendo bucket de assets: $ASSETS_BUCKET"
aws s3 rm "s3://$ASSETS_BUCKET" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "$ASSETS_BUCKET" 2>/dev/null && echo "  Bucket removido." || echo "  Bucket não encontrado."

# ===== CloudWatch =====
echo "[7] Removendo alarmes e dashboard CloudWatch..."
aws cloudwatch delete-alarms --alarm-names "portfolio-6324550-billing-alert" 2>/dev/null || true
aws cloudwatch delete-dashboards --dashboard-names "Portfolio-6324550" 2>/dev/null || true

# ===== SNS =====
if [ -n "${TOPIC_ARN:-}" ]; then
  echo "[8] Removendo SNS topic..."
  aws sns delete-topic --topic-arn "$TOPIC_ARN" 2>/dev/null || true
fi

# Limpar arquivo de variáveis
rm -f "$SCRIPT_DIR/.env.infra"

echo ""
echo "======================================"
echo " Limpeza concluída!"
echo " Verifique o AWS Billing para confirmar"
echo " que não há custos residuais."
echo "======================================"
