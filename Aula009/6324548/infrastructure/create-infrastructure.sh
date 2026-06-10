#!/bin/bash
# create-infrastructure.sh

REGION="us-east-1"
PROJECT_TAG="TF09-Portfolio"
CIDR_VPC="10.200.0.0/16"
CIDR_PUB_SUBNET="10.200.1.0/24"
CIDR_PRIV_SUBNET="10.200.2.0/24"
INSTANCE_TYPE="t2.micro"
AMI_ID="ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS us-east-1

echo "=== Iniciando criacao da infraestrutura para $PROJECT_TAG ==="

# 1. VPC
echo "Criando VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $CIDR_VPC --query 'Vpc.VpcId' --output text --region $REGION)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=$PROJECT_TAG-VPC --region $REGION
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames '{"Value":true}'

# 2. Subnets
echo "Criando Subnets..."
PUB_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $CIDR_PUB_SUBNET --availability-zone ${REGION}a --query 'Subnet.SubnetId' --output text --region $REGION)
aws ec2 create-tags --resources $PUB_SUBNET_ID --tags Key=Name,Value=$PROJECT_TAG-Public-Subnet --region $REGION

PRIV_SUBNET_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $CIDR_PRIV_SUBNET --availability-zone ${REGION}b --query 'Subnet.SubnetId' --output text --region $REGION)
aws ec2 create-tags --resources $PRIV_SUBNET_ID --tags Key=Name,Value=$PROJECT_TAG-Private-Subnet --region $REGION

# 3. Internet Gateway
echo "Criando IGW..."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --region $REGION)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=$PROJECT_TAG-IGW --region $REGION
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID --region $REGION

# 4. Route Table Public
echo "Configurando Rotas..."
PUB_RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text --region $REGION)
aws ec2 create-tags --resources $PUB_RT_ID --tags Key=Name,Value=$PROJECT_TAG-Public-RT --region $REGION
aws ec2 create-route --route-table-id $PUB_RT_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --region $REGION > /dev/null
aws ec2 associate-route-table --subnet-id $PUB_SUBNET_ID --route-table-id $PUB_RT_ID --region $REGION > /dev/null

# 5. Security Groups
echo "Criando Security Groups..."
WEB_SG_ID=$(aws ec2 create-security-group --group-name "web-sg" --description "Permitir HTTP e SSH" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
aws ec2 create-tags --resources $WEB_SG_ID --tags Key=Name,Value=$PROJECT_TAG-Web-SG --region $REGION

DB_SG_ID=$(aws ec2 create-security-group --group-name "db-sg" --description "Database SG Restrito ao Web SG" --vpc-id $VPC_ID --query 'GroupId' --output text --region $REGION)
aws ec2 create-tags --resources $DB_SG_ID --tags Key=Name,Value=$PROJECT_TAG-DB-SG --region $REGION

# Regras de Ingress SG
MY_IP=$(curl -s http://checkip.amazonaws.com)/32
echo "Restringindo SSH para o IP: $MY_IP"
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 3000 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-id $WEB_SG_ID --protocol tcp --port 22 --cidr $MY_IP --region $REGION

# Regra Menor Privilégio: DB SG só aceita acesso vindo do Web SG na porta do banco
aws ec2 authorize-security-group-ingress --group-id $DB_SG_ID --protocol tcp --port 5432 --source-group $WEB_SG_ID --region $REGION

# 6. Key Pair
echo "Gerando KeyPair..."
aws ec2 create-key-pair --key-name "$PROJECT_TAG-Key" --query 'KeyMaterial' --output text --region $REGION > "$PROJECT_TAG-Key.pem"
chmod 400 "$PROJECT_TAG-Key.pem"

# 7. EC2 Instance com User Data (Instala Docker e clona App)
echo "Lançando EC2 Instance..."
cat <<EOF > user-data.sh
#!/bin/bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose git
systemctl start docker
systemctl enable docker
EOF

INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --count 1 \
    --instance-type $INSTANCE_TYPE \
    --key-name "$PROJECT_TAG-Key" \
    --security-group-ids $WEB_SG_ID \
    --subnet-id $PUB_SUBNET_ID \
    --associate-public-ip-address \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$PROJECT_TAG-WebServer}]" \
    --user-data file://user-data.sh \
    --query 'Instances[0].InstanceId' \
    --output text \
    --region $REGION)

echo "Aguardando inicialização da instância..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region $REGION)

echo "=== INFRAESTRUTURA CRIADA COM SUCESSO! ==="
echo "VPC ID: $VPC_ID"
echo "Instância EC2 ID: $INSTANCE_ID"
echo "IP Público EC2: http://$PUBLIC_IP"
echo "Chave SSH salva localmente como: $PROJECT_TAG-Key.pem"
rm user-data.sh
