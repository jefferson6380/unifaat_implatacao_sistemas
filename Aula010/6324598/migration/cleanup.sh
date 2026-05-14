#!/usr/bin/env bash
# TF10 - Remove instância RDS, snapshots manuais, security group e alarmes
# Atenção: ação destrutiva. Use somente após avaliação do PR.

set -euo pipefail

: "${AWS_REGION:=us-east-1}"
: "${DB_INSTANCE_ID:=northwind-rds}"
: "${SG_NAME:=tf10-rds-sg}"
: "${DASHBOARD_NAME:=TF10-Northwind}"
: "${DB_PARAM_GROUP:=tf10-pg14-custom}"

read -r -p "Confirma exclusão da instância $DB_INSTANCE_ID e recursos relacionados? [digite SIM]: " CONFIRM
if [[ "$CONFIRM" != "SIM" ]]; then
  echo "Abortado."
  exit 1
fi

echo "==> Desabilitando deletion protection..."
aws rds modify-db-instance --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --no-deletion-protection \
  --apply-immediately >/dev/null || true

echo "==> Deletando instância RDS (sem snapshot final)..."
aws rds delete-db-instance --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --skip-final-snapshot \
  --delete-automated-backups >/dev/null

echo "==> Aguardando exclusão..."
aws rds wait db-instance-deleted --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" || true

echo "==> Removendo snapshots manuais com tag Project=TF10..."
SNAPS=$(aws rds describe-db-snapshots --region "$AWS_REGION" \
  --snapshot-type manual \
  --query "DBSnapshots[?DBInstanceIdentifier=='$DB_INSTANCE_ID'].DBSnapshotIdentifier" \
  --output text)
for s in $SNAPS; do
  echo "    snapshot: $s"
  aws rds delete-db-snapshot --region "$AWS_REGION" --db-snapshot-identifier "$s" >/dev/null
done

echo "==> Removendo dashboard CloudWatch..."
aws cloudwatch delete-dashboards --region "$AWS_REGION" \
  --dashboard-names "$DASHBOARD_NAME" >/dev/null || true

echo "==> Removendo alarmes TF10-*..."
ALARMS=$(aws cloudwatch describe-alarms --region "$AWS_REGION" \
  --alarm-name-prefix "TF10-" --query 'MetricAlarms[].AlarmName' --output text)
if [[ -n "$ALARMS" ]]; then
  aws cloudwatch delete-alarms --region "$AWS_REGION" --alarm-names $ALARMS
fi

echo "==> Removendo Parameter Group $DB_PARAM_GROUP..."
aws rds delete-db-parameter-group --region "$AWS_REGION" \
  --db-parameter-group-name "$DB_PARAM_GROUP" >/dev/null 2>&1 || true

echo "==> Removendo Security Group $SG_NAME..."
VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
  --filters Name=group-name,Values="$SG_NAME" Name=vpc-id,Values="$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")
if [[ "$SG_ID" != "None" && -n "$SG_ID" ]]; then
  aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$SG_ID"
  echo "    SG removido: $SG_ID"
fi

echo "==> Limpeza concluída. Verifique no console: RDS, CloudWatch, EC2 (Security Groups)."
