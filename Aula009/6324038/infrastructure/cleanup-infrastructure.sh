#!/bin/bash
# TF09 - Script de limpeza de infraestrutura AWS

set -e

if [ ! -f ".env.infrastructure" ]; then
    echo "Arquivo .env.infrastructure não encontrado. Execute create-infrastructure.sh primeiro."
    exit 1
fi

# shellcheck source=.env.infrastructure
source .env.infrastructure

echo "=== Limpando infraestrutura TF09 ==="
echo "ATENÇÃO: Esta ação é irreversível!"
read -p "Confirmar limpeza? (yes/no): " CONFIRM
[ "$CONFIRM" != "yes" ] && echo "Cancelado." && exit 0

# ── Terminar instâncias ───────────────────────────────────────────────────────
echo "Terminando instâncias..."
aws ec2 terminate-instances --instance-ids $WEB_INSTANCE_ID $DB_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $WEB_INSTANCE_ID $DB_INSTANCE_ID
echo "Instâncias terminadas."

# ── Security Groups ───────────────────────────────────────────────────────────
echo "Removendo Security Groups..."
aws ec2 delete-security-group --group-id $WEB_SG_ID
aws ec2 delete-security-group --group-id $DB_SG_ID

# ── Internet Gateway ──────────────────────────────────────────────────────────
echo "Removendo Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# ── Subnets ───────────────────────────────────────────────────────────────────
echo "Removendo Subnets..."
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID

# ── Route Table ───────────────────────────────────────────────────────────────
echo "Removendo Route Table..."
aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID

# ── VPC ───────────────────────────────────────────────────────────────────────
echo "Removendo VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID

# ── Key Pair ──────────────────────────────────────────────────────────────────
echo "Removendo Key Pair..."
aws ec2 delete-key-pair --key-name $KEY_NAME
rm -f ${KEY_NAME}.pem

# ── Limpar arquivo de estado ──────────────────────────────────────────────────
rm -f .env.infrastructure

echo ""
echo "=== Limpeza concluída! Todos os recursos foram removidos. ==="
echo "Verifique o console AWS para confirmar que não há recursos órfãos."
