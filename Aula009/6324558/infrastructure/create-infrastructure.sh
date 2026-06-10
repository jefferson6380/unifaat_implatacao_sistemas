#!/bin/bash
set -e

# TF09 - Vinicius Gigante - RA 6324558
# Script de criação de infraestrutura AWS

REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
PUB_SUBNET_CIDR="10.0.1.0/24"
PRIV_SUBNET_CIDR="10.0.2.0/24"
KEY_NAME="tf09-key"
AMI_ID="ami-0c02fb55956c7d316"  # Amazon Linux 2 us-east-1
INSTANCE_TYPE="t3.micro"
MY_IP=$(curl -s http://checkip.amazonaws.com)/32

echo "=== TF09 - Criando Infraestrutura ==="
echo "IP detectado para SSH: $MY_IP"

# 1. VPC
echo "[1/8] Criando VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block $VPC_CIDR \
  --region $REGION \
  --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value="tf09-vpc" --region $REGION
echo "VPC criada: $VPC_ID"

# 2. Subnets
echo "[2/8] Criando subnets..."
PUB_SUB_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PUB_SUBNET_CIDR \
  --availability-zone ${REGION}a \
  --region $REGION \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUB_SUB_ID --tags Key=Name,Value="tf09-subnet-publica" --region $REGION

PRIV_SUB_ID=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block $PRIV_SUBNET_CIDR \
  --availability-zone ${REGION}a \
  --region $REGION \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PRIV_SUB_ID --tags Key=Name,Value="tf09-subnet-privada" --region $REGION
echo "Subnet pública: $PUB_SUB_ID | Subnet privada: $PRIV_SUB_ID"

# 3. Internet Gateway
echo "[3/8] Criando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --region $REGION \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value="tf09-igw" --region $REGION
echo "IGW criado: $IGW_ID"

# 4. Route Table pública
echo "[4/8] Configurando rotas..."
RT_ID=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION
aws ec2 associate-route-table --subnet-id $PUB_SUB_ID --route-table-id $RT_ID --region $REGION
aws ec2 create-tags --resources $RT_ID --tags Key=Name,Value="tf09-rt-publica" --region $REGION

# 5. Security Group Web
echo "[5/8] Criando Security Groups..."
SG_WEB_ID=$(aws ec2 create-security-group \
  --group-name "tf09-sg-web" \
  --description "SG Web Server TF09" \
  --vpc-id $VPC_ID \
  --region $REGION \
  --query 'GroupId' --output text)
# HTTP público
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
# SSH restrito ao IP do aluno
aws ec2 authorize-security-group-ingress --group-id $SG_WEB_ID --protocol tcp --port 22 --cidr $MY_IP --region $REGION
echo "SG Web: $SG_WEB_ID (SSH restrito a $MY_IP)"

# 6. Key Pair
echo "[6/8] Criando Key Pair..."
aws ec2 create-key-pair \
  --key-name $KEY_NAME \
  --region $REGION \
  --query 'KeyMaterial' --output text > ${KEY_NAME}.pem
chmod 400 ${KEY_NAME}.pem
echo "Chave salva em ${KEY_NAME}.pem"

# 7. EC2
echo "[7/8] Criando instância EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_WEB_ID \
  --subnet-id $PUB_SUB_ID \
  --associate-public-ip-address \
  --region $REGION \
  --user-data '#!/bin/bash
yum update -y
yum install -y docker git
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose' \
  --query 'Instances[0].InstanceId' --output text)
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Name,Value="tf09-ec2" --region $REGION
echo "Instância criada: $INSTANCE_ID"

# 8. Aguardar IP público
echo "[8/8] Aguardando instância inicializar..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --region $REGION \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo ""
echo "=== Infraestrutura criada com sucesso ==="
echo "VPC:           $VPC_ID"
echo "Subnet Pública: $PUB_SUB_ID"
echo "Subnet Privada: $PRIV_SUB_ID"
echo "IGW:           $IGW_ID"
echo "SG Web:        $SG_WEB_ID"
echo "EC2:           $INSTANCE_ID"
echo "IP Público:    $PUBLIC_IP"
echo ""
echo "Para conectar via SSH:"
echo "ssh -i ${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
echo ""
echo "Salve estes IDs para o cleanup-infrastructure.sh"

# Salva IDs para o cleanup
cat > tf09-ids.env << ENVEOF
VPC_ID=$VPC_ID
PUB_SUB_ID=$PUB_SUB_ID
PRIV_SUB_ID=$PRIV_SUB_ID
IGW_ID=$IGW_ID
RT_ID=$RT_ID
SG_WEB_ID=$SG_WEB_ID
INSTANCE_ID=$INSTANCE_ID
KEY_NAME=$KEY_NAME
REGION=$REGION
ENVEOF
echo "IDs salvos em tf09-ids.env"