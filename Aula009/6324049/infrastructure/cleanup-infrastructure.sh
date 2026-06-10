#!/bin/bash
# TF09 - Script de Limpeza de Infraestrutura

set -e

echo "=== Iniciando limpeza da infraestrutura TF09 ==="

source infra_ids.sh

# EC2
echo "[1/8] Terminando instancia EC2..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION

echo "Aguardando instancia terminar..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION

echo "EC2 terminada!"

# Key Pair
echo "[2/8] Deletando Key Pair..."
aws ec2 delete-key-pair --key-name TF09-KeyPair --region $REGION

rm -f TF09-KeyPair.pem

echo "Key Pair deletada!"

# Security Groups
echo "[3/8] Deletando Security Groups..."

aws ec2 delete-security-group \
--group-id $SG_DB_ID \
--region $REGION

aws ec2 delete-security-group \
--group-id $SG_WEB_ID \
--region $REGION

echo "Security Groups deletados!"

# Route Table Association
echo "[4/8] Removendo associacao da Route Table..."

ASSOC_ID=$(aws ec2 describe-route-tables \
--route-table-ids $RT_ID \
--query "RouteTables[0].Associations[?Main==\`false\`].RouteTableAssociationId" \
--output text \
--region $REGION)

aws ec2 disassociate-route-table \
--association-id $ASSOC_ID \
--region $REGION

echo "Associacao removida!"

# Route Table
echo "[5/8] Deletando Route Table..."

aws ec2 delete-route-table \
--route-table-id $RT_ID \
--region $REGION

echo "Route Table deletada!"

# Subnets
echo "[6/8] Deletando Subnets..."

aws ec2 delete-subnet \
--subnet-id $PUBLIC_SUBNET_ID \
--region $REGION

aws ec2 delete-subnet \
--subnet-id $PRIVATE_SUBNET_ID \
--region $REGION

echo "Subnets deletadas!"

# Internet Gateway
echo "[7/8] Deletando Internet Gateway..."

aws ec2 detach-internet-gateway \
--internet-gateway-id $IGW_ID \
--vpc-id $VPC_ID \
--region $REGION

aws ec2 delete-internet-gateway \
--internet-gateway-id $IGW_ID \
--region $REGION

echo "Internet Gateway deletado!"

# VPC
echo "[8/8] Deletando VPC..."

aws ec2 delete-vpc \
--vpc-id $VPC_ID \
--region $REGION

echo "VPC deletada!"

echo ""
echo "=== Limpeza concluida com sucesso! ==="