#!/bin/bash
# TF09 - Script de Criação de Infraestrutura
# Aluno: Danilo Lenardi de Almeida
# RA: 6324049

set -e

echo "=== Criando infraestrutura TF09 ==="

# Variaveis
REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PUBLIC_SUBNET_CIDR="10.0.1.0/24"
PRIVATE_SUBNET_CIDR="10.0.2.0/24"

# VPC
echo "[1/8] Criando VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --region $REGION --query "Vpc.VpcId" --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=TF09-VPC --region $REGION
echo "VPC criada: $VPC_ID"

# Subnets
echo "[2/8] Criando Subnet Publica..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PUBLIC_SUBNET_CIDR --availability-zone ${REGION}a --query "Subnet.SubnetId" --output text --region $REGION)
aws ec2 create-tags --resources $PUBLIC_SUBNET_ID --tags Key=Name,Value=TF09-Subnet-Publica --region $REGION
echo "Subnet Publica criada: $PUBLIC_SUBNET_ID"

echo "[3/8] Criando Subnet Privada..."
PRIVATE_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $PRIVATE_SUBNET_CIDR --availability-zone ${REGION}b --query "Subnet.SubnetId" --output text --region $REGION)
aws ec2 create-tags --resources $PRIVATE_SUBNET_ID --tags Key=Name,Value=TF09-Subnet-Privada --region $REGION
echo "Subnet Privada criada: $PRIVATE_SUBNET_ID"

# Internet Gateway
echo "[4/8] Criando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text --region $REGION)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=TF09-IGW --region $REGION
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
echo "Internet Gateway criado: $IGW_ID"

# Route Table
echo "[5/8] Criando Route Table..."
RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query "RouteTable.RouteTableId" --output text --region $REGION)
aws ec2 create-tags --resources $RT_ID --tags Key=Name,Value=TF09-RouteTable-Publica --region $REGION
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $PUBLIC_SUBNET_ID --region $REGION
echo "Route Table criada: $RT_ID"

# Security Groups
echo "[6/8] Criando Security Groups..."
MY_IP=$(curl -s https://checkip.amazonaws.com)
SG_WEB_ID=$(aws ec2 create-security-group --group-name TF09-SG-Web --description "Security Group para Web Server TF09" --vpc-id $VPC_ID --query "GroupId" --output text --region $REGION)
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 5000 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 22 --cidr ${MY_IP}/32 --region $REGION
echo "SG Web criado: $SG_WEB_ID"

SG_DB_ID=$(aws ec2 create-security-group --group-name TF09-SG-Database --description "Security Group para Database TF09" --vpc-id $VPC_ID --query "GroupId" --output text --region $REGION)
aws ec2 authorize-security-group-ingress --group-id $SG_DB_ID --protocol tcp --port 5432 --source-group $SG_WEB_ID --region $REGION
echo "SG Database criado: $SG_DB_ID"

# Key Pair
echo "[7/8] Criando Key Pair..."

rm -f TF09-KeyPair.pem

aws ec2 create-key-pair \
--key-name TF09-KeyPair \
--query "KeyMaterial" \
--output text \
--region $REGION > ./TF09-KeyPair.pem

chmod 400 TF09-KeyPair.pem

echo "Key Pair criada: TF09-KeyPair.pem"

# EC2
echo "[8/8] Criando instancia EC2..."

AMI_ID=$(aws ec2 describe-images \
--owners 099720109477 \
--filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" "Name=state,Values=available" \
--query "sort_by(Images, &CreationDate)[-1].ImageId" \
--output text \
--region $REGION)

INSTANCE_ID=$(aws ec2 run-instances \
--image-id $AMI_ID \
--instance-type t3.micro \
--key-name TF09-KeyPair \
--security-group-ids $SG_WEB_ID \
--subnet-id $PUBLIC_SUBNET_ID \
--associate-public-ip-address \
--user-data file://$(pwd)/user-data.sh \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TF09-EC2}]' \
--query "Instances[0].InstanceId" \
--output text \
--region $REGION)

echo "EC2 criada: $INSTANCE_ID"

echo ""
echo "=== Infraestrutura criada com sucesso! ==="
echo "VPC: $VPC_ID"
echo "Subnet Publica: $PUBLIC_SUBNET_ID"
echo "Subnet Privada: $PRIVATE_SUBNET_ID"
echo "Internet Gateway: $IGW_ID"
echo "Route Table: $RT_ID"
echo "SG Web: $SG_WEB_ID"
echo "SG Database: $SG_DB_ID"
echo "EC2: $INSTANCE_ID"

echo "IP Publico da EC2: $PUBLIC_IP"

cat > infra_ids.sh <<EOF
REGION="$REGION"
VPC_ID="$VPC_ID"
INSTANCE_ID="$INSTANCE_ID"
IGW_ID="$IGW_ID"
PUBLIC_SUBNET_ID="$PUBLIC_SUBNET_ID"
PRIVATE_SUBNET_ID="$PRIVATE_SUBNET_ID"
RT_ID="$RT_ID"
SG_WEB_ID="$SG_WEB_ID"
SG_DB_ID="$SG_DB_ID"
EOF
