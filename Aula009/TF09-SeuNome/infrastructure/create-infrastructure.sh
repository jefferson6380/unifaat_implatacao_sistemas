#!/bin/bash
# Script para criar infraestrutura AWS para o portfólio
# Requer AWS CLI configurado

# 1. Criar VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Lab009-VPC}]' --query 'Vpc.VpcId' --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# 2. Criar Subnets
PUB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Lab009-Public}]' --query 'Subnet.SubnetId' --output text)
PRIV_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Lab009-Private}]' --query 'Subnet.SubnetId' --output text)

# 3. Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID

# 4. Route Tables
PUB_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 associate-route-table --route-table-id $PUB_RT_ID --subnet-id $PUB_SUBNET_ID
aws ec2 create-route --route-table-id $PUB_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID

# 5. Security Groups
WEB_SG_ID=$(aws ec2 create-security-group --group-name Lab009-WebSG --description "Web SG" --vpc-id $VPC_ID --query 'GroupId' --output text)
DB_SG_ID=$(aws ec2 create-security-group --group-name Lab009-DbSG --description "DB SG" --vpc-id $VPC_ID --query 'GroupId' --output text)

# 6. Regras de Security Group
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr [SEU_IP]/32
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $WEB_SG_ID

# 7. Criar par de chaves SSH
aws ec2 create-key-pair --key-name Lab009Key --query 'KeyMaterial' --output text > Lab009Key.pem
chmod 400 Lab009Key.pem

# 8. Instância EC2
# (Exemplo, personalize conforme sua AMI e configurações)
# aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name Lab009Key --security-group-ids $WEB_SG_ID --subnet-id $PUB_SUBNET_ID --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Lab009-WebServer}]'

echo "Infraestrutura criada. Anote os IDs e personalize conforme necessário."
