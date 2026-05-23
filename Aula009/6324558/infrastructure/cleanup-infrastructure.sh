#!/bin/bash
set -e

# TF09 - Vinicius Gigante - RA 6324558
# Script de limpeza de infraestrutura AWS

if [ ! -f tf09-ids.env ]; then
  echo "Arquivo tf09-ids.env não encontrado. Execute create-infrastructure.sh primeiro."
  exit 1
fi

source tf09-ids.env

echo "=== TF09 - Removendo Infraestrutura ==="

# 1. Terminar EC2
echo "[1/6] Terminando instância EC2..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION
echo "EC2 terminada."

# 2. Deletar Key Pair
echo "[2/6] Deletando Key Pair..."
aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
rm -f ${KEY_NAME}.pem
echo "Key Pair deletado."

# 3. Deletar Security Group
echo "[3/6] Deletando Security Group..."
aws ec2 delete-security-group --group-id $SG_WEB_ID --region $REGION
echo "SG deletado."

# 4. Desassociar e deletar Route Table
echo "[4/6] Removendo Route Table..."
ASSOC_ID=$(aws ec2 describe-route-tables \
  --route-table-ids $RT_ID \
  --region $REGION \
  --query 'RouteTables[0].Associations[0].RouteTableAssociationId' --output text)
aws ec2 disassociate-route-table --association-id $ASSOC_ID --region $REGION
aws ec2 delete-route-table --route-table-id $RT_ID --region $REGION

# 5. Deletar IGW e Subnets
echo "[5/6] Removendo IGW e Subnets..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
aws ec2 delete-subnet --subnet-id $PUB_SUB_ID --region $REGION
aws ec2 delete-subnet --subnet-id $PRIV_SUB_ID --region $REGION

# 6. Deletar VPC
echo "[6/6] Deletando VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

rm -f tf09-ids.env

echo ""
echo "=== Infraestrutura removida com sucesso. Custo zerado. ==="