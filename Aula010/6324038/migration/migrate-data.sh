#!/bin/bash
# migrate-data.sh - Migração do banco Northwind local (Docker) para RDS

set -e

source .rds-env 2>/dev/null || { echo "Execute create-rds.sh primeiro"; exit 1; }

LOCAL_HOST="localhost"
LOCAL_PORT="2001"
LOCAL_USER="postgres"
LOCAL_DB="northwind"
RDS_USER="postgres"
RDS_DB="northwind"

echo "=== Iniciando migração Northwind: Docker → RDS ==="
echo "Origem: $LOCAL_HOST:$LOCAL_PORT/$LOCAL_DB"
echo "Destino: $RDS_ENDPOINT/$RDS_DB"

# 1. Dump do banco local
echo "[1/3] Exportando banco local..."
PGPASSWORD=postgres pg_dump \
  -h $LOCAL_HOST \
  -p $LOCAL_PORT \
  -U $LOCAL_USER \
  -d $LOCAL_DB \
  --no-owner \
  --no-acl \
  -f northwind_dump.sql

echo "Dump gerado: northwind_dump.sql ($(wc -l < northwind_dump.sql) linhas)"

# 2. Importar no RDS
echo "[2/3] Importando no RDS..."
PGPASSWORD="Northwind@2026!" psql \
  -h $RDS_ENDPOINT \
  -p 5432 \
  -U $RDS_USER \
  -d $RDS_DB \
  -f northwind_dump.sql

echo "[3/3] Migração concluída!"
