#!/bin/bash
set -e

# ============================================================
# TF09 - Script de Criação de Infraestrutura AWS
# Aluno: Vitor Pinheiro Guimaraes | RA: 6324680
# ============================================================

REGION="us-east-1"
PROJECT="tf09-vitor"
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

echo "=========================================="
echo " Criando infraestrutura: $PROJECT"
echo " Região: $REGION"
echo " Seu IP: $MY_IP"
echo "=========================================="

# ---------- VPC ----------
echo "[1/10] Criando VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region $REGION \
  --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$PROJECT-vpc
echo "  VPC criada: $VPC_ID"

# Habilitar DNS na VPC
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support

# ---------- Subnets ----------
echo "[2/10] Criando subnets..."
SUBNET_PUB_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone ${REGION}a \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $SUBNET_PUB_ID --tags Key=Name,Value=$PROJECT-subnet-public

SUBNET_PRIV_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone ${REGION}b \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $SUBNET_PRIV_ID --tags Key=Name,Value=$PROJECT-subnet-private

aws ec2 modify-subnet-attribute --subnet-id $SUBNET_PUB_ID --map-public-ip-on-launch
echo "  Subnet pública: $SUBNET_PUB_ID"
echo "  Subnet privada: $SUBNET_PRIV_ID"

# ---------- Internet Gateway ----------
echo "[3/10] Criando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$PROJECT-igw
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "  IGW criado e anexado: $IGW_ID"

# ---------- Route Tables ----------
echo "[4/10] Configurando Route Tables..."
RTB_PUB_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $RTB_PUB_ID --tags Key=Name,Value=$PROJECT-rtb-public
aws ec2 create-route --route-table-id $RTB_PUB_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $RTB_PUB_ID --subnet-id $SUBNET_PUB_ID
echo "  Route Table pública configurada: $RTB_PUB_ID"

# ---------- Security Group - Web ----------
echo "[5/10] Criando Security Group (Web)..."
SG_WEB_ID=$(aws ec2 create-security-group \
  --group-name $PROJECT-sg-web \
  --description "Web server: HTTP, HTTPS publico, SSH restrito" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
aws ec2 create-tags --resources $SG_WEB_ID --tags Key=Name,Value=$PROJECT-sg-web

aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID \
  --ip-permissions \
  "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0,Description='HTTP publico'}]" \
  "IpProtocol=tcp,FromPort=443,ToPort=443,IpRanges=[{CidrIp=0.0.0.0/0,Description='HTTPS publico'}]" \
  "IpProtocol=tcp,FromPort=5000,ToPort=5000,IpRanges=[{CidrIp=0.0.0.0/0,Description='Flask API'}]" \
  "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=$MY_IP,Description='SSH apenas meu IP'}]"
echo "  SG Web criado: $SG_WEB_ID"

# ---------- Security Group - Database ----------
echo "[6/10] Criando Security Group (Database)..."
SG_DB_ID=$(aws ec2 create-security-group \
  --group-name $PROJECT-sg-db \
  --description "Database: acesso restrito ao web server" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
aws ec2 create-tags --resources $SG_DB_ID --tags Key=Name,Value=$PROJECT-sg-db

aws ec2 authorize-security-group-ingress --group-id $SG_DB_ID \
  --ip-permissions \
  "IpProtocol=tcp,FromPort=5432,ToPort=5432,UserIdGroupPairs=[{GroupId=$SG_WEB_ID,Description='Apenas do web server'}]"
echo "  SG Database criado: $SG_DB_ID"

# ---------- Key Pair ----------
echo "[7/10] Criando Key Pair..."
KEY_NAME="$PROJECT-key"
aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/$KEY_NAME.pem
chmod 400 ~/.ssh/$KEY_NAME.pem
echo "  Chave salva em ~/.ssh/$KEY_NAME.pem"

# ---------- AMI ----------
echo "[8/10] Buscando AMI Amazon Linux 2..."
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)
echo "  AMI encontrada: $AMI_ID"

# ---------- EC2 ----------
echo "[9/10] Lançando instância EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name $KEY_NAME \
  --security-group-ids $SG_WEB_ID \
  --subnet-id $SUBNET_PUB_ID \
  --user-data file://user-data.sh \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT-web}]" \
  --query 'Instances[0].InstanceId' \
  --output text)
echo "  Instância lançada: $INSTANCE_ID"

echo "[10/10] Aguardando instância ficar disponível..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# ---------- Salvar IDs ----------
cat > .infra-ids.env <<EOF
VPC_ID=$VPC_ID
SUBNET_PUB_ID=$SUBNET_PUB_ID
SUBNET_PRIV_ID=$SUBNET_PRIV_ID
IGW_ID=$IGW_ID
RTB_PUB_ID=$RTB_PUB_ID
SG_WEB_ID=$SG_WEB_ID
SG_DB_ID=$SG_DB_ID
KEY_NAME=$KEY_NAME
INSTANCE_ID=$INSTANCE_ID
PUBLIC_IP=$PUBLIC_IP
REGION=$REGION
EOF

echo ""
echo "=========================================="
echo " Infraestrutura criada com sucesso!"
echo "=========================================="
echo " IP Público:  $PUBLIC_IP"
echo " SSH:         ssh -i ~/.ssh/$KEY_NAME.pem ec2-user@$PUBLIC_IP"
echo " Aplicação:   http://$PUBLIC_IP:5000"
echo "=========================================="
