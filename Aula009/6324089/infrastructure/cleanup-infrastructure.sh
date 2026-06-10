#!/bin/bash

echo "Script de Limpeza!"
read -p "Cole o ID da sua Instância EC2 (ex: i-xxxx): " INSTANCE_ID

echo ""
echo "Rastreado a infraestrutura conectada a essa máquina..."

# Descobre a VPC onde a máquina está
VPC_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].VpcId' --output text)
echo "VPC Encontrada: $VPC_ID"

# Descobre as Subnets dessa VPC
SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)

# Descobre o Internet Gateway dessa VPC
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text)

# Descobre os Security Groups (ignorando o padrão da AWS)
SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text)

echo "Iniciando a destruição em cadeia..."
echo "--------------------------------------------------------"

# 1. Apaga a máquina (e espera ela desligar totalmente)
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
echo "A aguardar que a instância termine (isso demora cerca de 1 a 2 minutos)..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID

# 2. Apaga os Security Groups
for sg in $SGS; do 
    aws ec2 delete-security-group --group-id $sg
done

# 3. Desconecta e apaga o Internet Gateway
if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
fi

# 4. Apaga as Subnets
for sub in $SUBNETS; do 
    aws ec2 delete-subnet --subnet-id $sub
done

# 5. Apaga a VPC e a Chave
aws ec2 delete-vpc --vpc-id $VPC_ID
aws ec2 delete-key-pair --key-name Lab009-KeyPair

echo "Limpeza 100% concluída!"