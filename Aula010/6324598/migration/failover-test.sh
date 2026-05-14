#!/usr/bin/env bash
# TF10 - Dispara failover Multi-AZ e mede tempo até a instância voltar a 'available'.

set -euo pipefail

: "${AWS_REGION:=us-east-1}"
: "${DB_INSTANCE_ID:=northwind-rds}"

START=$(date +%s)
echo "==> Disparando reboot --force-failover em $DB_INSTANCE_ID"
aws rds reboot-db-instance --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --force-failover >/dev/null

echo "==> Aguardando volta para 'available'..."
aws rds wait db-instance-available --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID"
END=$(date +%s)
ELAPSED=$((END-START))

echo "==> Failover concluído em ${ELAPSED}s (RTO medido)."

echo
echo "==> Eventos relevantes (últimos 30 min):"
aws rds describe-events --region "$AWS_REGION" \
  --source-identifier "$DB_INSTANCE_ID" --source-type db-instance \
  --duration 30 --query 'Events[*].{Date:Date,Message:Message}' --output table
