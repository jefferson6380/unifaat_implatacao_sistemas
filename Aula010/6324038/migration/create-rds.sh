#!/bin/bash
# create-rds.sh - Criação da infraestrutura RDS PostgreSQL para o banco Northwind

set -e

VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' --output text)

echo "Usando VPC: $VPC_ID"

# Criar subnets em duas AZs
SUBNET_1A=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.10.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=RDS-Northwind-1a}]' \
  --query 'Subnet.SubnetId' --output text)

SUBNET_1B=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=RDS-Northwind-1b}]' \
  --query 'Subnet.SubnetId' --output text)

echo "Subnets criadas: $SUBNET_1A, $SUBNET_1B"

# Criar DB Subnet Group
aws rds create-db-subnet-group \
  --db-subnet-group-name northwind-db-subnet \
  --db-subnet-group-description "DB Subnet Group para Northwind RDS" \
  --subnet-ids $SUBNET_1A $SUBNET_1B \
  --tags Key=Name,Value=Northwind-DBSubnetGroup

# Criar Security Group para RDS
RDS_SG=$(aws ec2 create-security-group \
  --group-name Northwind-RDS-SG \
  --description "Security Group para RDS Northwind" \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=Northwind-RDS-SG}]' \
  --query 'GroupId' --output text)

echo "Security Group criado: $RDS_SG"

# Permitir PostgreSQL (5432) apenas do IP atual (para migração)
MY_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG \
  --protocol tcp \
  --port 5432 \
  --cidr "${MY_IP}/32" \
  --description "PostgreSQL from migration host"

# Criar instância RDS PostgreSQL
aws rds create-db-instance \
  --db-instance-identifier northwind-rds \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version "14.17" \
  --master-username postgres \
  --master-user-password "Northwind@2026!" \
  --allocated-storage 20 \
  --storage-type gp2 \
  --db-name northwind \
  --db-subnet-group-name northwind-db-subnet \
  --vpc-security-group-ids $RDS_SG \
  --publicly-accessible \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --enable-cloudwatch-logs-exports '["postgresql","upgrade"]' \
  --tags Key=Name,Value=Northwind-RDS Key=Course,Value=ADS Key=RA,Value=6324038

echo "Instância RDS criando... aguarde 10-15 minutos."
echo "Monitorar com: aws rds describe-db-instances --db-instance-identifier northwind-rds --query 'DBInstances[0].DBInstanceStatus'"

# Aguardar instância ficar disponível
aws rds wait db-instance-available --db-instance-identifier northwind-rds

RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier northwind-rds \
  --query 'DBInstances[0].Endpoint.Address' --output text)

echo "RDS disponível! Endpoint: $RDS_ENDPOINT"
echo "RDS_ENDPOINT=$RDS_ENDPOINT" > .rds-env
echo "RDS_SG=$RDS_SG" >> .rds-env
echo "SUBNET_1A=$SUBNET_1A" >> .rds-env
echo "SUBNET_1B=$SUBNET_1B" >> .rds-env
