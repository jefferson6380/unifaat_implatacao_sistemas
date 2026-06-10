#!/bin/bash
source "$(dirname "$0")/../.env"

# 1. FORÇAR DESCOBERTA DE IPV4
# O parâmetro -4 obriga o curl a usar apenas IPv4, ignorando o IPv6 da sua máquina.
MY_IP=$(curl -s -4 https://checkip.amazonaws.com)

echo "IP Detectado (IPv4): $MY_IP"

# 2. VPC E SECURITY GROUP
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=is-default,Values=true" --query "Vpcs[0].VpcId" --output text)

SG_ID=$(aws ec2 create-security-group \
    --group-name "RDS-SG-TF10-$(date +%s)" \
    --description "Acesso exclusivo IPv4" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)

# 3. AUTORIZAÇÃO UNILATERAL (IPv4 Only)
# Agora não há erro de sintaxe, pois estamos usando apenas --cidr com IPv4.
aws ec2 authorize-security-group-ingress \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 5432 \
    --cidr "$MY_IP/32"

# 4. CRIAÇÃO DO RDS (IPv4 Only)
# Removendo qualquer menção a 'dual' para evitar o erro de Subnet Group.
aws rds create-db-instance \
    --db-instance-identifier "$DB_ID" \
    --db-instance-class db.t3.micro \
    --engine postgres \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password "$DB_PASSWORD" \
    --db-name "$DB_NAME" \
    --publicly-accessible \
    --vpc-security-group-ids "$SG_ID" \
    --storage-type gp3 \
    --network-type IPV4 \
    --tags Key=Aluno,Value=Vinicius \
    --region "$AWS_REGION"