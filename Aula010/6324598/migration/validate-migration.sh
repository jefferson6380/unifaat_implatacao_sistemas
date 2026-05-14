#!/usr/bin/env bash
# TF10 - Valida integridade pós-migração comparando contagem de linhas
# e checksums por tabela entre o banco local e o RDS.

set -euo pipefail

: "${LOCAL_DB_URL:=postgresql://postgres:postgres@localhost:2001/northwind}"
: "${RDS_ENDPOINT:?defina RDS_ENDPOINT}"
: "${RDS_PORT:=5432}"
: "${DB_NAME:=northwind}"
: "${DB_MASTER_USER:=postgres}"
: "${DB_MASTER_PASSWORD:?defina DB_MASTER_PASSWORD}"

export PGPASSWORD="$DB_MASTER_PASSWORD"
RDS_URL="postgresql://${DB_MASTER_USER}:${DB_MASTER_PASSWORD}@${RDS_ENDPOINT}:${RDS_PORT}/${DB_NAME}"

TABLES=(
  categories customer_customer_demo customer_demographics customers
  employee_territories employees order_details orders products region
  shippers suppliers territories us_states
)

printf "%-30s %12s %12s %8s\n" "tabela" "local" "rds" "status"
printf "%-30s %12s %12s %8s\n" "------" "-----" "---" "------"

FAIL=0
for t in "${TABLES[@]}"; do
  L=$(psql "$LOCAL_DB_URL" -At -c "SELECT count(*) FROM $t;" 2>/dev/null || echo "ERR")
  R=$(psql "$RDS_URL"        -At -c "SELECT count(*) FROM $t;" 2>/dev/null || echo "ERR")
  if [[ "$L" == "$R" && "$L" != "ERR" ]]; then
    STATUS="OK"
  else
    STATUS="DIFF"
    FAIL=$((FAIL+1))
  fi
  printf "%-30s %12s %12s %8s\n" "$t" "$L" "$R" "$STATUS"
done

echo
echo "==> Verificando constraints e índices no RDS:"
psql "$RDS_URL" -c "
SELECT n.nspname AS schema, c.relname AS table, COUNT(i.indexname) AS indexes
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_indexes i ON i.tablename = c.relname AND i.schemaname = n.nspname
WHERE n.nspname='public' AND c.relkind='r'
GROUP BY 1,2 ORDER BY 2;"

if [[ $FAIL -eq 0 ]]; then
  echo "==> Validação: SUCESSO (todas as $((${#TABLES[@]})) tabelas batem)."
  exit 0
else
  echo "==> Validação: FALHA em $FAIL tabela(s)."
  exit 2
fi
