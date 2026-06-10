#!/bin/bash
# cleanup.sh - Remove todos os recursos AWS criados para o TF10

set -e

source .rds-env 2>/dev/null || { echo "Arquivo .rds-env não encontrado, informe os IDs manualmente"; exit 1; }

echo "=== Limpeza de recursos TF10 - Northwind RDS ==="
echo "ATENÇÃO: Esta ação é irreversível!"
read -p "Confirmar limpeza? (yes/no): " CONFIRM
[ "$CONFIRM" != "yes" ] && echo "Cancelado." && exit 0

# 1. Criar snapshot final antes de deletar
echo "[1/5] Criando snapshot final..."
aws rds create-db-snapshot \
  --db-instance-identifier northwind-rds \
  --db-snapshot-identifier northwind-final-snapshot-$(date +%Y%m%d) 2>/dev/null || true

# 2. Deletar instância RDS
echo "[2/5] Deletando instância RDS..."
aws rds delete-db-instance \
  --db-instance-identifier northwind-rds \
  --skip-final-snapshot 2>/dev/null || echo "Instância já deletada ou não encontrada"

echo "Aguardando deleção da instância..."
aws rds wait db-instance-deleted --db-instance-identifier northwind-rds 2>/dev/null || true

# 3. Deletar DB Subnet Group
echo "[3/5] Deletando DB Subnet Group..."
aws rds delete-db-subnet-group \
  --db-subnet-group-name northwind-db-subnet 2>/dev/null || echo "Subnet group já deletado"

# 4. Deletar Security Group
echo "[4/5] Deletando Security Group..."
aws ec2 delete-security-group \
  --group-id $RDS_SG 2>/dev/null || echo "Security group já deletado"

# 5. Deletar Subnets
echo "[5/5] Deletando subnets..."
aws ec2 delete-subnet --subnet-id $SUBNET_1A 2>/dev/null || true
aws ec2 delete-subnet --subnet-id $SUBNET_1B 2>/dev/null || true

rm -f .rds-env northwind_dump.sql

echo "✅ Limpeza concluída! Verifique o AWS Cost Explorer para confirmar zero custos."
