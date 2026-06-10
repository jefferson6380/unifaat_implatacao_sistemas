#!/usr/bin/env bash
# TF10 - Migra schema + dados do PostgreSQL local para RDS
# Estratégia: dump SQL + restore (downtime curto, simples e auditável)

set -euo pipefail

: "${LOCAL_DB_URL:=postgresql://postgres:postgres@localhost:2001/northwind}"
: "${RDS_ENDPOINT:?defina RDS_ENDPOINT}"
: "${RDS_PORT:=5432}"
: "${DB_NAME:=northwind}"
: "${DB_MASTER_USER:=postgres}"
: "${DB_MASTER_PASSWORD:?defina DB_MASTER_PASSWORD}"

DUMP_DIR="$(dirname "$0")/../dumps"
mkdir -p "$DUMP_DIR"
TS=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="$DUMP_DIR/northwind_${TS}.dump"
LOG_FILE="$DUMP_DIR/migrate_${TS}.log"

export PGPASSWORD="$DB_MASTER_PASSWORD"
RDS_URL="postgresql://${DB_MASTER_USER}:${DB_MASTER_PASSWORD}@${RDS_ENDPOINT}:${RDS_PORT}/${DB_NAME}"

echo "==> [1/4] Backup do banco local em formato custom..." | tee "$LOG_FILE"
pg_dump --no-owner --no-privileges --format=custom \
  --dbname="$LOCAL_DB_URL" \
  --file="$DUMP_FILE" 2>&1 | tee -a "$LOG_FILE"
echo "    dump salvo em: $DUMP_FILE" | tee -a "$LOG_FILE"

echo "==> [2/4] Teste de conexão com RDS..." | tee -a "$LOG_FILE"
psql "$RDS_URL" -c "SELECT version();" | tee -a "$LOG_FILE"

echo "==> [3/4] Restore no RDS (drop+create antes para idempotência)..." | tee -a "$LOG_FILE"
psql "$RDS_URL" <<'SQL' | tee -a "$LOG_FILE"
DROP TABLE IF EXISTS customer_customer_demo, customer_demographics,
  employee_territories, order_details, orders, customers, products,
  shippers, suppliers, territories, us_states, categories, region, employees
  CASCADE;
SQL

pg_restore --no-owner --no-privileges --clean --if-exists --exit-on-error \
  --dbname="$RDS_URL" "$DUMP_FILE" 2>&1 | tee -a "$LOG_FILE" || {
    echo "==> pg_restore reportou erro; verifique $LOG_FILE" >&2
    exit 1
  }

echo "==> [4/4] Análise de tabelas (ANALYZE) para estatísticas frescas..." | tee -a "$LOG_FILE"
psql "$RDS_URL" -c "ANALYZE;" | tee -a "$LOG_FILE"

echo "==> Migração concluída."
echo "    Log:   $LOG_FILE"
echo "    Próximo passo: bash migration/validate-migration.sh"
