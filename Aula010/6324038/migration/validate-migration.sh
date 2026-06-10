#!/bin/bash
# validate-migration.sh - Validação da integridade dos dados migrados

set -e

source .rds-env 2>/dev/null || { echo "Execute create-rds.sh primeiro"; exit 1; }

LOCAL_HOST="localhost"
LOCAL_PORT="2001"
LOCAL_USER="postgres"
LOCAL_DB="northwind"
RDS_USER="postgres"
RDS_DB="northwind"

echo "=== Validando migração Northwind ==="

# Função para contar registros em uma tabela
count_table() {
  local host=$1; local port=$2; local user=$3; local pass=$4; local db=$5; local table=$6
  PGPASSWORD=$pass psql -h $host -p $port -U $user -d $db -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' '
}

TABLES=("customers" "orders" "order_details" "products" "employees" "suppliers" "categories" "shippers")

echo ""
echo "Tabela                | Local  | RDS    | Status"
echo "----------------------|--------|--------|-------"

ALL_OK=true
for TABLE in "${TABLES[@]}"; do
  LOCAL_COUNT=$(count_table $LOCAL_HOST $LOCAL_PORT $LOCAL_USER "postgres" $LOCAL_DB $TABLE)
  RDS_COUNT=$(count_table $RDS_ENDPOINT 5432 $RDS_USER "Northwind@2026!" $RDS_DB $TABLE)

  if [ "$LOCAL_COUNT" = "$RDS_COUNT" ]; then
    STATUS="✅ OK"
  else
    STATUS="❌ DIVERGE"
    ALL_OK=false
  fi

  printf "%-22s| %-7s| %-7s| %s\n" "$TABLE" "$LOCAL_COUNT" "$RDS_COUNT" "$STATUS"
done

echo ""
if $ALL_OK; then
  echo "✅ Migração validada com sucesso! Todos os registros conferem."
else
  echo "❌ Divergências encontradas. Verifique os dados antes de prosseguir."
  exit 1
fi

# Validar constraints e índices
echo ""
echo "=== Verificando constraints no RDS ==="
PGPASSWORD="Northwind@2026!" psql -h $RDS_ENDPOINT -p 5432 -U $RDS_USER -d $RDS_DB -c "
SELECT conname, contype, conrelid::regclass AS tabela
FROM pg_constraint
WHERE contype IN ('p','f','u')
ORDER BY conrelid::regclass, contype;
"
