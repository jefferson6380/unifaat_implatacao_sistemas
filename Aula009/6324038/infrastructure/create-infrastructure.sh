#!/bin/bash
# TF09 - Script de criação de infraestrutura AWS
# Portfólio Pessoal na AWS

set -e

PROJECT="TF09-Portfolio"
REGION="us-east-1"
KEY_NAME="${PROJECT}-KeyPair"

echo "=== Criando infraestrutura: $PROJECT ==="

# ── VPC ──────────────────────────────────────────────────────────────────────
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --region $REGION \
    --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=${PROJECT}-VPC}]" \
    --query 'Vpc.VpcId' --output text)
echo "VPC criada: $VPC_ID"

aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames

# ── Subnets ───────────────────────────────────────────────────────────────────
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${REGION}a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT}-Public-Subnet}]" \
    --query 'Subnet.SubnetId' --output text)
echo "Subnet pública: $PUBLIC_SUBNET_ID"

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ${REGION}a \
    --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=${PROJECT}-Private-Subnet}]" \
    --query 'Subnet.SubnetId' --output text)
echo "Subnet privada: $PRIVATE_SUBNET_ID"

aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch

# ── Internet Gateway ──────────────────────────────────────────────────────────
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=${PROJECT}-IGW}]" \
    --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "Internet Gateway: $IGW_ID"

# ── Route Table pública ───────────────────────────────────────────────────────
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=${PROJECT}-Public-RT}]" \
    --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $PUBLIC_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT_ID --subnet-id $PUBLIC_SUBNET_ID
echo "Route Table pública: $PUBLIC_RT_ID"

# ── Security Group: Web Server ────────────────────────────────────────────────
WEB_SG_ID=$(aws ec2 create-security-group \
    --group-name "${PROJECT}-WebServer-SG" \
    --description "SG para Web Server - HTTP/HTTPS público, SSH restrito" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT}-WebServer-SG}]" \
    --query 'GroupId' --output text)
echo "Web SG: $WEB_SG_ID"

MY_IP=$(curl -s https://checkip.amazonaws.com)
echo "Seu IP: $MY_IP"

# SSH apenas do IP do administrador
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID \
    --protocol tcp --port 22 --cidr ${MY_IP}/32

# HTTP e HTTPS públicos
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID \
    --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID \
    --protocol tcp --port 443 --cidr 0.0.0.0/0

# ── Security Group: Database ──────────────────────────────────────────────────
DB_SG_ID=$(aws ec2 create-security-group \
    --group-name "${PROJECT}-Database-SG" \
    --description "SG para Database - acesso restrito ao Web Server SG" \
    --vpc-id $VPC_ID \
    --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=${PROJECT}-Database-SG}]" \
    --query 'GroupId' --output text)
echo "DB SG: $DB_SG_ID"

# MySQL apenas do Web Server SG (menor privilégio)
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID \
    --protocol tcp --port 3306 --source-group $WEB_SG_ID

# ── Key Pair ──────────────────────────────────────────────────────────────────
aws ec2 create-key-pair \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo "Key Pair criado: ${KEY_NAME}.pem"

# ── AMI Amazon Linux 2 ────────────────────────────────────────────────────────
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)
echo "AMI: $AMI_ID"

# ── EC2: Web Server ───────────────────────────────────────────────────────────
WEB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name $KEY_NAME \
    --security-group-ids $WEB_SG_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --user-data file://web-server-userdata.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT}-WebServer}]" \
    --query 'Instances[0].InstanceId' --output text)
echo "Web Server: $WEB_INSTANCE_ID (aguardando...)"
aws ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID

WEB_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $WEB_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo "Web Server IP público: $WEB_PUBLIC_IP"

# ── EC2: Database Server ──────────────────────────────────────────────────────
DB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type t3.micro \
    --key-name $KEY_NAME \
    --security-group-ids $DB_SG_ID \
    --subnet-id $PRIVATE_SUBNET_ID \
    --user-data file://db-server-userdata.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT}-Database}]" \
    --query 'Instances[0].InstanceId' --output text)
echo "Database: $DB_INSTANCE_ID (aguardando...)"
aws ec2 wait instance-running --instance-ids $DB_INSTANCE_ID

DB_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $DB_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
echo "Database IP privado: $DB_PRIVATE_IP"

# ── Salvar IDs para cleanup ───────────────────────────────────────────────────
cat > .env.infrastructure << EOF
VPC_ID=$VPC_ID
PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID
PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID
IGW_ID=$IGW_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
WEB_SG_ID=$WEB_SG_ID
DB_SG_ID=$DB_SG_ID
WEB_INSTANCE_ID=$WEB_INSTANCE_ID
DB_INSTANCE_ID=$DB_INSTANCE_ID
WEB_PUBLIC_IP=$WEB_PUBLIC_IP
DB_PRIVATE_IP=$DB_PRIVATE_IP
KEY_NAME=$KEY_NAME
EOF

echo ""
echo "=== Infraestrutura criada com sucesso! ==="
echo "Acesse: http://$WEB_PUBLIC_IP"
echo "SSH:    ssh -i ${KEY_NAME}.pem ec2-user@$WEB_PUBLIC_IP"
echo "IDs salvos em .env.infrastructure"
