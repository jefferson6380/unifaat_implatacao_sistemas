#!/bin/bash

echo "Validando tabelas..."

psql -h ENDPOINT -U postgres -d erp -c "\dt"