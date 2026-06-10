#!/bin/bash
# cleanup-infrastructure.sh
# TF09 - Allison Henrique da Silva Oliveira - RA: 6324603
# Remove toda a infraestrutura criada para evitar custos

set -e

if [ ! -f "infrastructure-ids.env" ]; then
  echo "Arquivo infrastructure-ids.env não encontrado!"
  exit 1
fi

source infrastructure-ids.env

echo "=== TF09 - Removendo Infraestrutura AWS ==="
echo "ATENÇÃO: Esta ação é irreversível!"
read -p "Confirmar remoção? (yes/no): " CONFIRM
[ "$CONFIRM" != "yes" ] && echo "Cancelado." && exit 0

# ─── EC2 ───────────────────────────────────────────────────────────────────────
echo "[1/7] Terminando instância EC2: $INSTANCE_ID"
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
echo "  Aguardando término..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "  Instância terminada."

# ─── KEY PAIR ──────────────────────────────────────────────────────────────────
echo "[2/7] Removendo Key Pair..."
aws ec2 delete-key-pair --key-name portfolio-key
rm -f portfolio-key.pem
echo "  Key Pair removido."

# ─── SECURITY GROUPS ───────────────────────────────────────────────────────────
echo "[3/7] Removendo Security Groups..."
aws ec2 delete-security-group --group-id $SG_DB_ID
aws ec2 delete-security-group --group-id $SG_WEB_ID
echo "  Security Groups removidos."

# ─── ROUTE TABLES ──────────────────────────────────────────────────────────────
echo "[4/7] Removendo Route Tables..."
# Desassociar antes de deletar
ASSOC_PUB=$(aws ec2 describe-route-tables \
  --route-table-ids $PUBLIC_RT_ID \
  --query 'RouteTables[0].Associations[0].RouteTableAssociationId' \
  --output text 2>/dev/null || echo "")
[ -n "$ASSOC_PUB" ] && [ "$ASSOC_PUB" != "None" ] && \
  aws ec2 disassociate-route-table --association-id $ASSOC_PUB

ASSOC_PRIV=$(aws ec2 describe-route-tables \
  --route-table-ids $PRIVATE_RT_ID \
  --query 'RouteTables[0].Associations[0].RouteTableAssociationId' \
  --output text 2>/dev/null || echo "")
[ -n "$ASSOC_PRIV" ] && [ "$ASSOC_PRIV" != "None" ] && \
  aws ec2 disassociate-route-table --association-id $ASSOC_PRIV

aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID
aws ec2 delete-route-table --route-table-id $PRIVATE_RT_ID
echo "  Route Tables removidas."

# ─── INTERNET GATEWAY ──────────────────────────────────────────────────────────
echo "[5/7] Removendo Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
echo "  IGW removido."

# ─── SUBNETS ───────────────────────────────────────────────────────────────────
echo "[6/7] Removendo Subnets..."
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID
echo "  Subnets removidas."

# ─── VPC ───────────────────────────────────────────────────────────────────────
echo "[7/7] Removendo VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "  VPC removida."

rm -f infrastructure-ids.env

echo ""
echo "=== Infraestrutura removida com sucesso! ==="
echo "Verifique o AWS Console para confirmar que não há recursos órfãos."
