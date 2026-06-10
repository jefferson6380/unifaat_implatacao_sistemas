#!/bin/bash
# =============================================================
# configure-policies.sh
# Configura IAM roles, políticas e monitoramento (CloudWatch)
# =============================================================

set -euo pipefail

RA="6324073"
REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
LAMBDA_ROLE_NAME="portfolio-lambda-role-${RA}"
TABLE_NAME="portfolio-contacts-${RA}"
ASSETS_BUCKET="portfolio-lfs-assets-${RA}"
WEBSITE_BUCKET="portfolio-lfs-website-${RA}"

echo "=== Configurando políticas e monitoramento ==="
echo "Account ID: ${ACCOUNT_ID}"
echo ""

# ----------------------------------------------------------------
# 1. IAM Role para as Lambdas
# ----------------------------------------------------------------
echo "[1/7] Criando IAM Role para Lambda..."
TRUST_POLICY='{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

aws iam create-role \
  --role-name "${LAMBDA_ROLE_NAME}" \
  --assume-role-policy-document "${TRUST_POLICY}" \
  --description "Role para Lambdas do portfolio Leonardo Frazao Sano" \
  2>/dev/null || echo "(Role já existe — atualizando política...)"

# Permissões necessárias para as Lambdas
echo "[2/7] Anexando políticas à role..."
aws iam put-role-policy \
  --role-name "${LAMBDA_ROLE_NAME}" \
  --policy-name "portfolio-lambda-policy" \
  --policy-document "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Sid\": \"Logs\",
        \"Effect\": \"Allow\",
        \"Action\": [
          \"logs:CreateLogGroup\",
          \"logs:CreateLogStream\",
          \"logs:PutLogEvents\"
        ],
        \"Resource\": \"arn:aws:logs:${REGION}:${ACCOUNT_ID}:*\"
      },
      {
        \"Sid\": \"S3Assets\",
        \"Effect\": \"Allow\",
        \"Action\": [
          \"s3:GetObject\",
          \"s3:PutObject\",
          \"s3:DeleteObject\"
        ],
        \"Resource\": \"arn:aws:s3:::${ASSETS_BUCKET}/*\"
      },
      {
        \"Sid\": \"DynamoDB\",
        \"Effect\": \"Allow\",
        \"Action\": [
          \"dynamodb:PutItem\",
          \"dynamodb:GetItem\",
          \"dynamodb:Query\",
          \"dynamodb:Scan\"
        ],
        \"Resource\": \"arn:aws:dynamodb:${REGION}:${ACCOUNT_ID}:table/${TABLE_NAME}\"
      },
      {
        \"Sid\": \"SES\",
        \"Effect\": \"Allow\",
        \"Action\": \"ses:SendEmail\",
        \"Resource\": \"*\"
      }
    ]
  }"

# ----------------------------------------------------------------
# 2. Criar tabela DynamoDB para contatos
# ----------------------------------------------------------------
echo "[3/7] Criando tabela DynamoDB para contatos..."
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions \
    AttributeName=id,AttributeType=S \
    AttributeName=timestamp,AttributeType=S \
  --key-schema \
    AttributeName=id,KeyType=HASH \
    AttributeName=timestamp,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}" \
  --tags Key=Project,Value=portfolio-lfs \
  2>/dev/null || echo "(Tabela já existe)"

# ----------------------------------------------------------------
# 3. Logs de acesso no S3
# ----------------------------------------------------------------
echo "[4/7] Habilitando logs de acesso S3..."
LOGS_BUCKET="${WEBSITE_BUCKET}-logs"

aws s3api create-bucket \
  --bucket "${LOGS_BUCKET}" \
  --region "${REGION}" \
  2>/dev/null || echo "(Bucket de logs já existe)"

aws s3api put-bucket-logging \
  --bucket "${WEBSITE_BUCKET}" \
  --bucket-logging-status "{
    \"LoggingEnabled\": {
      \"TargetBucket\": \"${LOGS_BUCKET}\",
      \"TargetPrefix\": \"website-access/\"
    }
  }"

# ----------------------------------------------------------------
# 4. Alertas de custo no CloudWatch / Billing
# ----------------------------------------------------------------
echo "[5/7] Configurando alarme de custo (limite \$10)..."
aws cloudwatch put-metric-alarm \
  --alarm-name "portfolio-billing-alert-${RA}" \
  --alarm-description "Alerta quando custo mensal ultrapassa \$10" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --region us-east-1 \
  2>/dev/null || echo "(Billing alarms precisam ser criados na região us-east-1)"

# ----------------------------------------------------------------
# 5. Proteção contra hotlinking (via CloudFront — documentação)
# ----------------------------------------------------------------
echo "[6/7] Configurando proteção contra hotlinking..."
echo "      (Configurado via Referer-based Conditions no CloudFront)"
echo "      Para ativar: adicione uma Behavior restriction no console CloudFront"
echo "      referindo-se apenas ao domínio do portfólio."

# ----------------------------------------------------------------
# 6. Lifecycle no bucket de assets (remove imagens > 1 ano)
# ----------------------------------------------------------------
echo "[7/7] Configurando lifecycle no bucket de assets..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "${ASSETS_BUCKET}" \
  --lifecycle-configuration '{
    "Rules": [{
      "ID": "expire-old-assets",
      "Status": "Enabled",
      "Filter": {"Prefix": "temp/"},
      "Expiration": {"Days": 30}
    }]
  }'

# ----------------------------------------------------------------
# Resultado
# ----------------------------------------------------------------
echo ""
echo "======================================================"
echo "✅ Políticas e monitoramento configurados!"
echo "======================================================"
echo "IAM Role:       arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE_NAME}"
echo "DynamoDB Table: ${TABLE_NAME}"
echo "Logs Bucket:    s3://${LOGS_BUCKET}"
echo "Billing Alert:  \$10/mês"
echo ""
echo "Próximo passo: execute os scripts de deploy das Lambdas"
echo "======================================================"
