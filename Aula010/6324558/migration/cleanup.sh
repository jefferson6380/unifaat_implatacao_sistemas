#!/bin/bash
# cleanup.sh - Exclusão da instância RDS para evitar custos
# Disciplina: Implementação de Sistemas - UniFAAT

# Carrega variáveis do .env
source "$(dirname "$0")/../.env"

echo "----------------------------------------------------------"
echo "ATENÇÃO: Este script irá DELETAR a instância RDS."
echo "Instância: $DB_ID"
echo "----------------------------------------------------------"

read -p "Deseja continuar? (s/n): " CONFIRM

if [ "$CONFIRM" != "s" ]; then
    echo "Operação cancelada."
    exit 0
fi

echo "----------------------------------------------------------"
echo "DELETANDO INSTÂNCIA RDS..."
echo "----------------------------------------------------------"

aws rds delete-db-instance \
    --db-instance-identifier "$DB_ID" \
    --skip-final-snapshot \
    --delete-automated-backups \
    --region "$AWS_REGION"

# Verifica resultado
if [ $? -eq 0 ]; then
    echo "----------------------------------------------------------"
    echo "Comando de exclusão enviado com sucesso."
    echo "Acompanhe o status no Console AWS."
    echo "----------------------------------------------------------"
else
    echo "----------------------------------------------------------"
    echo "ERRO ao tentar deletar a instância."
    echo "----------------------------------------------------------"
    exit 1
fi