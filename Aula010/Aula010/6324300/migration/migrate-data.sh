#!/bin/bash

echo "Exportando banco local..."

docker exec postgres-erp pg_dump -U postgres erp > backup.sql

echo "Importando para RDS..."

psql -h ENDPOINT -U postgres -d erp < backup.sql