#!/bin/bash
# migrate-data.sh

source "$(dirname "$0")/../.env"

# 1. Configurações de Caminho e Usuário
SQL_FILE="$(dirname "$0")/northwind_backup.sql"
export PGPASSWORD="$DB_PASSWORD"

echo "Obtendo endpoint do RDS..."

# 2. Busca o endpoint (Direto e sem rodeios)
ENDPOINT=$(aws rds describe-db-instances \
    --db-instance-identifier "$DB_ID" \
    --query 'DBInstances[0].Endpoint.Address' \
    --output text)

# 3. Validação Simples
if [[ "$ENDPOINT" == "None" || -z "$ENDPOINT" ]]; then
    echo "ERRO: Instância $DB_ID não disponível."
    exit 1
fi

echo "Migrando dados para: $ENDPOINT"

# 4. Execução (Usando o modo quiet -q para não poluir o terminal)
psql -h "$ENDPOINT" -U "postgres" -d "$DB_NAME" -q < "$SQL_FILE"

if [ $? -eq 0 ]; then
    echo "SUCESSO: Banco de dados migrado."
else
    echo "ERRO: Falha na migração."
    exit 1
fi