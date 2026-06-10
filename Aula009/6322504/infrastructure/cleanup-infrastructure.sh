#!/bin/bash
# TF09 - Script de limpeza de infraestrutura AWS
# Aluno: Luan Teixeira | RA: 6322504

set -e

AWS="aws"

echo "=== TF09 - Limpando infraestrutura AWS ==="

# Buscar recursos por tags
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=TF09-VPC" --query 'Vpcs[0].VpcId' --output text)
if [ "$VPC_ID" = "None" ] || [ -z "$VPC_ID" ]; then
    echo "Nenhuma VPC TF09 encontrada."
    exit 0
fi

# Terminar instâncias
echo "[1/6] Terminando instâncias..."
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,stopped" \
    --query 'Reservations[].Instances[].InstanceId' --output text)
if [ -n "$INSTANCE_IDS" ]; then
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS
    echo "Instâncias terminadas: $INSTANCE_IDS"
fi

# Deletar Security Groups
echo "[2/6] Deletando Security Groups..."
for SG in $(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
    aws ec2 delete-security-group --group-id $SG 2>/dev/null || true
    echo "SG deletado: $SG"
done

# Desanexar e deletar IGW
echo "[3/6] Deletando Internet Gateway..."
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query 'InternetGateways[0].InternetGatewayId' --output text)
if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
    echo "IGW deletado: $IGW_ID"
fi

# Deletar Subnets
echo "[4/6] Deletando Subnets..."
for SUBNET in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'Subnets[].SubnetId' --output text); do
    aws ec2 delete-subnet --subnet-id $SUBNET
    echo "Subnet deletada: $SUBNET"
done

# Deletar Key Pair
echo "[5/6] Deletando Key Pair..."
aws ec2 delete-key-pair --key-name TF09-KeyPair 2>/dev/null || true
rm -f TF09-KeyPair.pem
echo "Key Pair removido"

# Deletar VPC
echo "[6/6] Deletando VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "VPC deletada: $VPC_ID"

echo ""
echo "=== LIMPEZA CONCLUÍDA - Todos os recursos removidos ==="
