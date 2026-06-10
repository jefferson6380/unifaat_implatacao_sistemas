#!/bin/bash
# create-infrastructure.sh
# TF09 - Allison Henrique da Silva Oliveira - RA: 6324603
# Cria toda a infraestrutura AWS necessária para o portfólio

set -e

REGION="us-east-1"
PROJECT="portfolio-tf09"
YOUR_IP=$(curl -s https://checkip.amazonaws.com)/32

echo "=== TF09 - Criando Infraestrutura AWS ==="
echo "Região: $REGION"
echo "Seu IP: $YOUR_IP"
echo ""

# ─── VPC ───────────────────────────────────────────────────────────────────────
echo "[1/10] Criando VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region $REGION \
  --query 'Vpc.VpcId' --output text)

aws ec2 create-tags --resources $VPC_ID \
  --tags Key=Name,Value=$PROJECT-vpc Key=Project,Value=$PROJECT
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "  VPC criada: $VPC_ID"

# ─── SUBNETS ───────────────────────────────────────────────────────────────────
echo "[2/10] Criando subnets..."
PUBLIC_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${REGION}a \
  --query 'Subnet.SubnetId' --output text)

aws ec2 create-tags --resources $PUBLIC_SUBNET_ID \
  --tags Key=Name,Value=$PROJECT-public-subnet

PRIVATE_SUBNET_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone ${REGION}b \
  --query 'Subnet.SubnetId' --output text)

aws ec2 create-tags --resources $PRIVATE_SUBNET_ID \
  --tags Key=Name,Value=$PROJECT-private-subnet

aws ec2 modify-subnet-attribute \
  --subnet-id $PUBLIC_SUBNET_ID \
  --map-public-ip-on-launch
echo "  Subnet pública: $PUBLIC_SUBNET_ID"
echo "  Subnet privada: $PRIVATE_SUBNET_ID"

# ─── INTERNET GATEWAY ──────────────────────────────────────────────────────────
echo "[3/10] Criando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 create-tags --resources $IGW_ID \
  --tags Key=Name,Value=$PROJECT-igw
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "  IGW criado e associado: $IGW_ID"

# ─── ROUTE TABLES ──────────────────────────────────────────────────────────────
echo "[4/10] Configurando Route Tables..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-tags --resources $PUBLIC_RT_ID \
  --tags Key=Name,Value=$PROJECT-public-rt
aws ec2 create-route \
  --route-table-id $PUBLIC_RT_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID
aws ec2 associate-route-table \
  --route-table-id $PUBLIC_RT_ID \
  --subnet-id $PUBLIC_SUBNET_ID

PRIVATE_RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-tags --resources $PRIVATE_RT_ID \
  --tags Key=Name,Value=$PROJECT-private-rt
aws ec2 associate-route-table \
  --route-table-id $PRIVATE_RT_ID \
  --subnet-id $PRIVATE_SUBNET_ID
echo "  Route Tables configuradas"

# ─── SECURITY GROUP - WEB SERVER ───────────────────────────────────────────────
echo "[5/10] Criando Security Group Web Server..."
SG_WEB_ID=$(aws ec2 create-security-group \
  --group-name $PROJECT-sg-webserver \
  --description "SG Web Server - Portfolio TF09" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 create-tags --resources $SG_WEB_ID \
  --tags Key=Name,Value=$PROJECT-sg-webserver

# SSH apenas do seu IP
aws ec2 authorize-security-group-ingress \
  --group-id $SG_WEB_ID \
  --protocol tcp --port 22 --cidr $YOUR_IP

# HTTP público
aws ec2 authorize-security-group-ingress \
  --group-id $SG_WEB_ID \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

# HTTPS público
aws ec2 authorize-security-group-ingress \
  --group-id $SG_WEB_ID \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# API porta 3000
aws ec2 authorize-security-group-ingress \
  --group-id $SG_WEB_ID \
  --protocol tcp --port 3000 --cidr 0.0.0.0/0

echo "  SG Web Server criado: $SG_WEB_ID"

# ─── SECURITY GROUP - DATABASE ─────────────────────────────────────────────────
echo "[6/10] Criando Security Group Database..."
SG_DB_ID=$(aws ec2 create-security-group \
  --group-name $PROJECT-sg-database \
  --description "SG Database - Portfolio TF09" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 create-tags --resources $SG_DB_ID \
  --tags Key=Name,Value=$PROJECT-sg-database

# PostgreSQL apenas do web server
aws ec2 authorize-security-group-ingress \
  --group-id $SG_DB_ID \
  --protocol tcp --port 5432 \
  --source-group $SG_WEB_ID

# Remover regra de saída padrão e restringir à VPC
aws ec2 revoke-security-group-egress \
  --group-id $SG_DB_ID \
  --protocol -1 --port -1 --cidr 0.0.0.0/0 2>/dev/null || true

aws ec2 authorize-security-group-egress \
  --group-id $SG_DB_ID \
  --protocol -1 --port -1 --cidr 10.0.0.0/16

echo "  SG Database criado: $SG_DB_ID"

# ─── KEY PAIR ──────────────────────────────────────────────────────────────────
echo "[7/10] Criando Key Pair..."
aws ec2 create-key-pair \
  --key-name portfolio-key \
  --query 'KeyMaterial' \
  --output text > portfolio-key.pem
chmod 400 portfolio-key.pem
echo "  Key Pair criado: portfolio-key.pem (guarde com segurança!)"

# ─── AMI AMAZON LINUX 2 ────────────────────────────────────────────────────────
echo "[8/10] Buscando AMI Amazon Linux 2..."
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)
echo "  AMI: $AMI_ID"

# ─── EC2 INSTANCE ──────────────────────────────────────────────────────────────
echo "[9/10] Lançando instância EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name portfolio-key \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $SG_WEB_ID \
  --associate-public-ip-address \
  --user-data file://user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT-ec2},{Key=Project,Value=$PROJECT}]" \
  --query 'Instances[0].InstanceId' --output text)

echo "  Instância lançada: $INSTANCE_ID"
echo "  Aguardando instância ficar running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# ─── SALVAR IDs ────────────────────────────────────────────────────────────────
echo "[10/10] Salvando IDs dos recursos..."
cat > infrastructure-ids.env << EOF
VPC_ID=$VPC_ID
PUBLIC_SUBNET_ID=$PUBLIC_SUBNET_ID
PRIVATE_SUBNET_ID=$PRIVATE_SUBNET_ID
IGW_ID=$IGW_ID
PUBLIC_RT_ID=$PUBLIC_RT_ID
PRIVATE_RT_ID=$PRIVATE_RT_ID
SG_WEB_ID=$SG_WEB_ID
SG_DB_ID=$SG_DB_ID
INSTANCE_ID=$INSTANCE_ID
PUBLIC_IP=$PUBLIC_IP
REGION=$REGION
EOF

echo ""
echo "=== Infraestrutura criada com sucesso! ==="
echo ""
echo "IP Público da EC2: $PUBLIC_IP"
echo "SSH: ssh -i portfolio-key.pem ec2-user@$PUBLIC_IP"
echo "App: http://$PUBLIC_IP"
echo "API: http://$PUBLIC_IP:3000"
echo "Health: http://$PUBLIC_IP:3000/health"
echo ""
echo "IDs salvos em: infrastructure-ids.env"
