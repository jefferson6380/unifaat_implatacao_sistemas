#!/bin/bash
# configure-policies.sh
# Autor: Bruno Pereira dos Santos - RA 6324550
# Descrição: Configura CloudWatch, alertas e billing para o portfólio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env.infra" ]; then
  source "$SCRIPT_DIR/.env.infra"
else
  echo "ERRO: Execute create-buckets.sh primeiro."
  exit 1
fi

ALERT_EMAIL="${1:-seu@email.com}"

echo "======================================"
echo " Configurando Políticas e Monitoramento"
echo " Aluno: Bruno Pereira dos Santos - RA 6324550"
echo "======================================"

# ===== SNS Topic para alertas =====
echo "[1/4] Criando SNS topic para alertas..."
TOPIC_ARN=$(aws sns create-topic --name "portfolio-6324550-alerts" --query TopicArn --output text)
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "$ALERT_EMAIL"
echo "  Topic: $TOPIC_ARN"
echo "  ATENÇÃO: Confirme a assinatura no email: $ALERT_EMAIL"

# ===== Billing Alarm =====
echo "[2/4] Criando alarme de billing (limite: \$10)..."
aws cloudwatch put-metric-alarm \
  --alarm-name "portfolio-6324550-billing-alert" \
  --alarm-description "Alerta de custo - Portfolio Bruno RA 6324550" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --alarm-actions "$TOPIC_ARN" \
  --treat-missing-data notBreaching \
  --region us-east-1

# ===== CloudWatch Dashboard =====
echo "[3/4] Criando CloudWatch dashboard..."
if [ -n "${DISTRIBUTION_ID:-}" ]; then
  aws cloudwatch put-dashboard --dashboard-name "Portfolio-6324550" --dashboard-body "{
    \"widgets\": [
      {
        \"type\": \"metric\",
        \"x\": 0, \"y\": 0, \"width\": 8, \"height\": 6,
        \"properties\": {
          \"title\": \"CloudFront Requests\",
          \"region\": \"us-east-1\",
          \"metrics\": [[\"AWS/CloudFront\", \"Requests\", \"DistributionId\", \"$DISTRIBUTION_ID\", \"Region\", \"Global\"]],
          \"period\": 3600,
          \"stat\": \"Sum\",
          \"view\": \"timeSeries\",
          \"annotations\": {\"horizontal\": []}
        }
      },
      {
        \"type\": \"metric\",
        \"x\": 8, \"y\": 0, \"width\": 8, \"height\": 6,
        \"properties\": {
          \"title\": \"Cache Hit Rate\",
          \"region\": \"us-east-1\",
          \"metrics\": [[\"AWS/CloudFront\", \"CacheHitRate\", \"DistributionId\", \"$DISTRIBUTION_ID\", \"Region\", \"Global\"]],
          \"period\": 3600,
          \"stat\": \"Average\",
          \"view\": \"timeSeries\",
          \"annotations\": {\"horizontal\": []}
        }
      },
      {
        \"type\": \"metric\",
        \"x\": 16, \"y\": 0, \"width\": 8, \"height\": 6,
        \"properties\": {
          \"title\": \"4xx / 5xx Errors\",
          \"region\": \"us-east-1\",
          \"metrics\": [
            [\"AWS/CloudFront\", \"4xxErrorRate\", \"DistributionId\", \"$DISTRIBUTION_ID\", \"Region\", \"Global\"],
            [\"AWS/CloudFront\", \"5xxErrorRate\", \"DistributionId\", \"$DISTRIBUTION_ID\", \"Region\", \"Global\"]
          ],
          \"period\": 3600,
          \"stat\": \"Average\",
          \"view\": \"timeSeries\",
          \"annotations\": {\"horizontal\": []}
        }
      }
    ]
  }"
  echo "  Dashboard criado: Portfolio-6324550"
fi

# ===== S3 Logging =====
echo "[4/4] Habilitando logs de acesso S3..."
LOG_BUCKET="${ASSETS_BUCKET}"
aws s3api put-bucket-logging --bucket "$WEBSITE_BUCKET" --bucket-logging-status "{
  \"LoggingEnabled\": {
    \"TargetBucket\": \"$LOG_BUCKET\",
    \"TargetPrefix\": \"s3-access-logs/\"
  }
}"

cat >> "$SCRIPT_DIR/.env.infra" << EOF
TOPIC_ARN=$TOPIC_ARN
ALERT_EMAIL=$ALERT_EMAIL
EOF

echo ""
echo "======================================"
echo " Políticas configuradas com sucesso!"
echo "======================================"
echo " Billing Alert : \$10 -> $ALERT_EMAIL"
echo " Dashboard     : Portfolio-6324550 (CloudWatch)"
echo " SNS Topic     : $TOPIC_ARN"
echo "======================================"
