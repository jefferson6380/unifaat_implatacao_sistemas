#!/bin/bash
# TF09 - Script de criação de infraestrutura AWS
# Aluno: Luan Teixeira | RA: 6322504

set -e

AWS="aws"
REGION="us-east-1"

echo "=== TF09 - Criando infraestrutura AWS ==="

# VPC
echo "[1/8] Criando VPC..."
VPC_ID=$($AWS ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=TF09-VPC}]' \
    --query 'Vpc.VpcId' --output text)
$AWS ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "VPC criada: $VPC_ID"

# Subnets
echo "[2/8] Criando subnets..."
PUBLIC_SUBNET_ID=$($AWS ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone ${REGION}a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=TF09-Public-Subnet}]' \
    --query 'Subnet.SubnetId' --output text)
$AWS ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch

PRIVATE_SUBNET_ID=$($AWS ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone ${REGION}a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=TF09-Private-Subnet}]' \
    --query 'Subnet.SubnetId' --output text)
echo "Subnets criadas: Pública=$PUBLIC_SUBNET_ID | Privada=$PRIVATE_SUBNET_ID"

# Internet Gateway
echo "[3/8] Criando Internet Gateway..."
IGW_ID=$($AWS ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=TF09-IGW}]' \
    --query 'InternetGateway.InternetGatewayId' --output text)
$AWS ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "IGW criado e anexado: $IGW_ID"

# Route Table
echo "[4/8] Configurando Route Tables..."
ROUTE_TABLE_ID=$($AWS ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[0].RouteTableId' --output text)
$AWS ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID > /dev/null
$AWS ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --subnet-id $PUBLIC_SUBNET_ID > /dev/null
echo "Rotas configuradas"

# Key Pair
echo "[5/8] Criando Key Pair..."
$AWS ec2 create-key-pair --key-name TF09-KeyPair --query 'KeyMaterial' --output text > TF09-KeyPair.pem
chmod 400 TF09-KeyPair.pem
echo "Key Pair criado: TF09-KeyPair.pem"

# Security Groups
echo "[6/8] Criando Security Groups..."
WEB_SG_ID=$($AWS ec2 create-security-group \
    --group-name TF09-WebServer-SG \
    --description "TF09 Web Server Security Group" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)

MY_IP=$(curl -s https://checkip.amazonaws.com)
$AWS ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr $MY_IP/32
$AWS ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
$AWS ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0
$AWS ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0

DB_SG_ID=$($AWS ec2 create-security-group \
    --group-name TF09-Database-SG \
    --description "TF09 Database Security Group" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)
$AWS ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 3306 --source-group $WEB_SG_ID
$AWS ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 22 --source-group $WEB_SG_ID
echo "Security Groups: Web=$WEB_SG_ID | DB=$DB_SG_ID"

# AMI
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

# Instâncias
echo "[7/8] Lançando instâncias EC2..."
WEB_INSTANCE_ID=$($AWS ec2 run-instances \
    --image-id $AMI_ID --count 1 --instance-type t3.micro \
    --key-name TF09-KeyPair \
    --security-group-ids $WEB_SG_ID \
    --subnet-id $PUBLIC_SUBNET_ID \
    --user-data file://web-userdata.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TF09-WebServer}]' \
    --query 'Instances[0].InstanceId' --output text)

DB_INSTANCE_ID=$($AWS ec2 run-instances \
    --image-id $AMI_ID --count 1 --instance-type t3.micro \
    --key-name TF09-KeyPair \
    --security-group-ids $DB_SG_ID \
    --subnet-id $PRIVATE_SUBNET_ID \
    --user-data file://db-userdata.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TF09-Database}]' \
    --query 'Instances[0].InstanceId' --output text)

echo "[8/8] Aguardando instâncias..."
$AWS ec2 wait instance-running --instance-ids $WEB_INSTANCE_ID $DB_INSTANCE_ID

WEB_IP=$($AWS ec2 describe-instances --instance-ids $WEB_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
DB_IP=$($AWS ec2 describe-instances --instance-ids $DB_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)

echo ""
echo "=== INFRAESTRUTURA CRIADA COM SUCESSO ==="
echo "VPC ID:           $VPC_ID"
echo "Subnet Pública:   $PUBLIC_SUBNET_ID"
echo "Subnet Privada:   $PRIVATE_SUBNET_ID"
echo "Web Server IP:    $WEB_IP"
echo "Database IP:      $DB_IP (privado)"
echo ""
echo "Conectar: ssh -i TF09-KeyPair.pem ec2-user@$WEB_IP"
