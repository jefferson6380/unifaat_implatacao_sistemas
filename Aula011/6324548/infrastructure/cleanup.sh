#!/usr/bin/env bash
# Remove TODOS os recursos do portfólio na AWS
# ATENÇÃO: Esta ação é irreversível!

set -euo pipefail

RA="${RA:-6324548}"
REGION="${AWS_REGION:-us-east-1}"
WEBSITE_BUCKET="portfolio-website-${RA}"
ASSETS_BUCKET="portfolio-assets-${RA}"
LOGS_BUCKET="${WEBSITE_BUCKET}-logs"
CF_DISTRIBUTION_ID="${CF_DISTRIBUTION_ID:-}"
LAMBDA_IMAGE="portfolio-image-processor-${RA}"
LAMBDA_CONTACT="portfolio-contact-form-${RA}"
API_NAME="portfolio-api-${RA}"
DYNAMO_TABLE="portfolio-contacts"

echo "============================================"
echo "  ATENÇÃO: Removendo recursos do portfólio"
echo "  RA: ${RA}"
echo "============================================"
read -p "Confirma remoção? (digite 'sim' para confirmar): " CONFIRM
[ "${CONFIRM}" = "sim" ] || { echo "Cancelado."; exit 0; }

# ── 1. Desabilitar e deletar CloudFront ──────────────────
if [ -n "${CF_DISTRIBUTION_ID}" ]; then
  echo "==> Desabilitando distribuição CloudFront ${CF_DISTRIBUTION_ID}..."

  ETAG=$(aws cloudfront get-distribution-config \
    --id "${CF_DISTRIBUTION_ID}" \
    --query 'ETag' --output text)

  CONFIG=$(aws cloudfront get-distribution-config \
    --id "${CF_DISTRIBUTION_ID}" \
    --query 'DistributionConfig' --output json)

  DISABLED_CONFIG=$(echo "${CONFIG}" | python3 -c "
import sys, json
c = json.load(sys.stdin)
c['Enabled'] = False
print(json.dumps(c))
")

  aws cloudfront update-distribution \
    --id "${CF_DISTRIBUTION_ID}" \
    --distribution-config "${DISABLED_CONFIG}" \
    --if-match "${ETAG}" > /dev/null

  echo "==> Aguardando desabilitação (pode demorar alguns minutos)..."
  aws cloudfront wait distribution-deployed --id "${CF_DISTRIBUTION_ID}"

  ETAG=$(aws cloudfront get-distribution \
    --id "${CF_DISTRIBUTION_ID}" \
    --query 'ETag' --output text)

  aws cloudfront delete-distribution \
    --id "${CF_DISTRIBUTION_ID}" \
    --if-match "${ETAG}"

  echo "==> CloudFront removido"
else
  echo "Aviso: CF_DISTRIBUTION_ID não definido. Pulando remoção do CloudFront."
fi

# ── 2. Esvaziar e deletar buckets ─────────────────────────
for BUCKET in "${WEBSITE_BUCKET}" "${ASSETS_BUCKET}" "${LOGS_BUCKET}"; do
  if aws s3api head-bucket --bucket "${BUCKET}" 2>/dev/null; then
    echo "==> Esvaziando ${BUCKET}..."

    # Remover todas as versões e delete markers
    aws s3api list-object-versions \
      --bucket "${BUCKET}" \
      --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
      --output json 2>/dev/null | \
    python3 -c "
import sys, json, subprocess
data = json.load(sys.stdin)
objs = data.get('Objects') or []
if objs:
    batch = {'Objects': objs, 'Quiet': True}
    subprocess.run(['aws','s3api','delete-objects','--bucket','${BUCKET}','--delete',json.dumps(batch)])
    print(f'  Removidos {len(objs)} versões/objetos')
" 2>/dev/null || true

    aws s3 rm "s3://${BUCKET}/" --recursive 2>/dev/null || true
    aws s3api delete-bucket --bucket "${BUCKET}" --region "${REGION}"
    echo "==> Bucket ${BUCKET} removido"
  fi
done

# ── 3. Remover Lambda functions ───────────────────────────
for FN in "${LAMBDA_IMAGE}" "${LAMBDA_CONTACT}"; do
  if aws lambda get-function --function-name "${FN}" 2>/dev/null; then
    aws lambda delete-function --function-name "${FN}"
    echo "==> Lambda ${FN} removida"
  fi
done

# ── 4. Remover API Gateway ────────────────────────────────
API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='${API_NAME}'].id" \
  --output text 2>/dev/null || echo "")

if [ -n "${API_ID}" ]; then
  aws apigateway delete-rest-api --rest-api-id "${API_ID}"
  echo "==> API Gateway ${API_NAME} removida"
fi

# ── 5. Remover DynamoDB ───────────────────────────────────
if aws dynamodb describe-table --table-name "${DYNAMO_TABLE}" 2>/dev/null; then
  aws dynamodb delete-table --table-name "${DYNAMO_TABLE}"
  echo "==> Tabela DynamoDB ${DYNAMO_TABLE} removida"
fi

echo ""
echo "✅ Limpeza concluída. Verifique o AWS Billing para confirmar zero custos residuais."
