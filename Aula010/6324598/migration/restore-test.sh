#!/usr/bin/env bash
# TF10 - Restaura snapshot manual em uma instância temporária, valida tabelas e remove.
# Estimativa: 10-15 minutos. Custo aproximado: < USD 0.10 (instância destruída no fim).

set -euo pipefail

: "${AWS_REGION:=us-east-1}"
: "${SNAP_ID:?defina SNAP_ID com o nome do snapshot manual a restaurar}"
: "${RESTORE_ID:=northwind-rds-restore-test}"
: "${DB_INSTANCE_CLASS:=db.t3.micro}"
: "${DB_MASTER_PASSWORD:?defina DB_MASTER_PASSWORD}"
: "${DB_NAME:=northwind}"
: "${DB_MASTER_USER:=postgres}"

# 1. Restore
SG_ID=$(aws rds describe-db-instances --region "$AWS_REGION" \
  --db-instance-identifier northwind-rds \
  --query 'DBInstances[0].VpcSecurityGroups[0].VpcSecurityGroupId' --output text)

echo "==> Restaurando snapshot $SNAP_ID em instância $RESTORE_ID..."
aws rds restore-db-instance-from-db-snapshot --region "$AWS_REGION" \
  --db-instance-identifier "$RESTORE_ID" \
  --db-snapshot-identifier "$SNAP_ID" \
  --db-instance-class "$DB_INSTANCE_CLASS" \
  --no-multi-az \
  --publicly-accessible \
  --vpc-security-group-ids "$SG_ID" \
  --tags Key=Project,Value=TF10 Key=RA,Value=6324598 \
  --copy-tags-to-snapshot >/dev/null

echo "==> Aguardando 'available' (~10 min)..."
aws rds wait db-instance-available --region "$AWS_REGION" \
  --db-instance-identifier "$RESTORE_ID"

RESTORE_ENDPOINT=$(aws rds describe-db-instances --region "$AWS_REGION" \
  --db-instance-identifier "$RESTORE_ID" \
  --query 'DBInstances[0].Endpoint.Address' --output text)

# 2. Validação
export PGPASSWORD="$DB_MASTER_PASSWORD"
RESTORE_URL="postgresql://${DB_MASTER_USER}:${DB_MASTER_PASSWORD}@${RESTORE_ENDPOINT}:5432/${DB_NAME}"

echo "==> Validando contagens..."
psql "$RESTORE_URL" -c "
SELECT relname AS tabela, n_live_tup AS linhas
FROM pg_stat_user_tables
ORDER BY 1;"

echo "==> Validação básica concluída. Removendo instância temporária..."

# 3. Limpeza
aws rds delete-db-instance --region "$AWS_REGION" \
  --db-instance-identifier "$RESTORE_ID" \
  --skip-final-snapshot \
  --delete-automated-backups >/dev/null

aws rds wait db-instance-deleted --region "$AWS_REGION" \
  --db-instance-identifier "$RESTORE_ID"

echo "==> Instância de restore removida. Teste concluído com sucesso."
