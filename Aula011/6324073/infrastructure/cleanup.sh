#!/bin/bash
# =============================================================
# cleanup.sh
# Remove TODOS os recursos AWS criados para o portfólio
# ATENÇÃO: Esta operação é irreversível!
# =============================================================

set -euo pipefail

RA="6324073"
REGION="us-east-1"
WEBSITE_BUCKET="portfolio-lfs-website-${RA}"
ASSETS_BUCKET="portfolio-lfs-assets-${RA}"
LOGS_BUCKET="${WEBSITE_BUCKET}-logs"
TABLE_NAME="portfolio-contacts-${RA}"
LAMBDA_ROLE_NAME="portfolio-lambda-role-${RA}"
IMAGE_LAMBDA="portfolio-image-processor-${RA}"
CONTACT_LAMBDA="portfolio-contact-form-${RA}"

ENV_FILE="$(dirname "${BASH_SOURCE[0]}")/cloudfront-config.env"

echo "========================================================="
echo "  ⚠️  ATENÇÃO: LIMPEZA COMPLETA DOS RECURSOS AWS"
echo "========================================================="
echo ""
echo "Os seguintes recursos serão PERMANENTEMENTE deletados:"
echo "  - Buckets S3: ${WEBSITE_BUCKET}, ${ASSETS_BUCKET}, ${LOGS_BUCKET}"
echo "  - Tabela DynamoDB: ${TABLE_NAME}"
echo "  - Lambda Functions: ${IMAGE_LAMBDA}, ${CONTACT_LAMBDA}"
echo "  - IAM Role: ${LAMBDA_ROLE_NAME}"
echo "  - Distribuição CloudFront (se configurada)"
echo ""
read -p "Digite 'sim' para confirmar: " CONFIRM

if [[ "${CONFIRM}" != "sim" ]]; then
  echo "Operação cancelada."
  exit 0
fi

echo ""
echo "Iniciando limpeza..."

# ----------------------------------------------------------------
# 1. Desabilitar e deletar distribuição CloudFront
# ----------------------------------------------------------------
if [[ -f "${ENV_FILE}" ]]; then
  source "${ENV_FILE}"

  if [[ -n "${DIST_ID:-}" ]]; then
    echo "[1/9] Desabilitando distribuição CloudFront ${DIST_ID}..."

    # Pegar ETag atual
    DIST_INFO=$(aws cloudfront get-distribution-config --id "${DIST_ID}" 2>/dev/null || echo "")
    if [[ -n "${DIST_INFO}" ]]; then
      ETAG=$(echo "${DIST_INFO}" | python3 -c "import json,sys; print(json.load(sys.stdin)['ETag'])")
      CONFIG=$(echo "${DIST_INFO}" | python3 -c "import json,sys; d=json.load(sys.stdin)['DistributionConfig']; d['Enabled']=False; print(json.dumps(d))")

      aws cloudfront update-distribution \
        --id "${DIST_ID}" \
        --distribution-config "${CONFIG}" \
        --if-match "${ETAG}" > /dev/null

      echo "Aguardando desabilitação (pode levar alguns minutos)..."
      aws cloudfront wait distribution-deployed --id "${DIST_ID}" 2>/dev/null || true

      NEW_ETAG=$(aws cloudfront get-distribution --id "${DIST_ID}" --query 'ETag' --output text 2>/dev/null || echo "")
      if [[ -n "${NEW_ETAG}" ]]; then
        aws cloudfront delete-distribution --id "${DIST_ID}" --if-match "${NEW_ETAG}" 2>/dev/null || \
          echo "  (Não foi possível deletar a distribuição automaticamente — delete manualmente no console)"
      fi
    fi
  fi
else
  echo "[1/9] Arquivo cloudfront-config.env não encontrado — pulando CloudFront."
fi

# ----------------------------------------------------------------
# 2. Deletar Lambda Functions
# ----------------------------------------------------------------
echo "[2/9] Deletando Lambda Functions..."
aws lambda delete-function --function-name "${IMAGE_LAMBDA}" 2>/dev/null || \
  echo "  (Lambda ${IMAGE_LAMBDA} não encontrada)"

aws lambda delete-function --function-name "${CONTACT_LAMBDA}" 2>/dev/null || \
  echo "  (Lambda ${CONTACT_LAMBDA} não encontrada)"

# ----------------------------------------------------------------
# 3. Deletar API Gateway
# ----------------------------------------------------------------
echo "[3/9] Removendo API Gateways do portfólio..."
aws apigateway get-rest-apis \
  --query "items[?contains(name,'portfolio-lfs')].id" \
  --output text 2>/dev/null | tr '\t' '\n' | while read -r api_id; do
    [[ -n "${api_id}" ]] && aws apigateway delete-rest-api --rest-api-id "${api_id}" 2>/dev/null && \
      echo "  API ${api_id} deletada"
done

# ----------------------------------------------------------------
# 4. Deletar tabela DynamoDB
# ----------------------------------------------------------------
echo "[4/9] Deletando tabela DynamoDB ${TABLE_NAME}..."
aws dynamodb delete-table \
  --table-name "${TABLE_NAME}" \
  --region "${REGION}" 2>/dev/null || echo "  (Tabela não encontrada)"

# ----------------------------------------------------------------
# 5. Esvaziar e deletar bucket website
# ----------------------------------------------------------------
echo "[5/9] Esvaziando e deletando bucket website..."
aws s3 rm "s3://${WEBSITE_BUCKET}" --recursive 2>/dev/null || true
# Deleta versões (se versionamento habilitado)
aws s3api list-object-versions \
  --bucket "${WEBSITE_BUCKET}" \
  --query 'Versions[].{Key:Key,VersionId:VersionId}' \
  --output json 2>/dev/null | \
  python3 -c "
import json, sys, subprocess
versions = json.load(sys.stdin)
for v in (versions or []):
    subprocess.run(['aws', 's3api', 'delete-object',
      '--bucket', '${WEBSITE_BUCKET}',
      '--key', v['Key'],
      '--version-id', v['VersionId']], capture_output=True)
print(f'  {len(versions or [])} versão(ões) deletada(s)')
" 2>/dev/null || true

aws s3api delete-bucket --bucket "${WEBSITE_BUCKET}" --region "${REGION}" 2>/dev/null || \
  echo "  (Bucket ${WEBSITE_BUCKET} não encontrado)"

# ----------------------------------------------------------------
# 6. Esvaziar e deletar bucket assets
# ----------------------------------------------------------------
echo "[6/9] Esvaziando e deletando bucket de assets..."
aws s3 rm "s3://${ASSETS_BUCKET}" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "${ASSETS_BUCKET}" --region "${REGION}" 2>/dev/null || \
  echo "  (Bucket ${ASSETS_BUCKET} não encontrado)"

# ----------------------------------------------------------------
# 7. Esvaziar e deletar bucket de logs
# ----------------------------------------------------------------
echo "[7/9] Deletando bucket de logs..."
aws s3 rm "s3://${LOGS_BUCKET}" --recursive 2>/dev/null || true
aws s3api delete-bucket --bucket "${LOGS_BUCKET}" --region "${REGION}" 2>/dev/null || \
  echo "  (Bucket ${LOGS_BUCKET} não encontrado)"

# ----------------------------------------------------------------
# 8. Deletar IAM Role
# ----------------------------------------------------------------
echo "[8/9] Deletando IAM Role ${LAMBDA_ROLE_NAME}..."
aws iam delete-role-policy \
  --role-name "${LAMBDA_ROLE_NAME}" \
  --policy-name "portfolio-lambda-policy" 2>/dev/null || true

aws iam delete-role --role-name "${LAMBDA_ROLE_NAME}" 2>/dev/null || \
  echo "  (Role não encontrada)"

# ----------------------------------------------------------------
# 9. Deletar alarmes CloudWatch
# ----------------------------------------------------------------
echo "[9/9] Removendo alarmes CloudWatch..."
aws cloudwatch delete-alarms \
  --alarm-names "portfolio-billing-alert-${RA}" \
  2>/dev/null || echo "  (Alarme não encontrado)"

# Limpar arquivo de configuração
rm -f "${ENV_FILE}"

# ----------------------------------------------------------------
# Resultado
# ----------------------------------------------------------------
echo ""
echo "======================================================"
echo "✅ Limpeza concluída!"
echo "======================================================"
echo "Verifique no console AWS se todos os recursos foram"
echo "removidos corretamente e se não há cobranças pendentes."
echo ""
echo "Console de billing: https://console.aws.amazon.com/billing"
echo "======================================================"
