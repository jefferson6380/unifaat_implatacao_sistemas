#!/bin/bash
# create-infrastructure.sh - Cria toda a infraestrutura AWS para o portfólio
set -e

REGION="us-east-1"
PROJECT="portfolio"
YOUR_IP=$(curl -s https://checkip.amazonaws.com)/32

echo "==> Criando VPC..."
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --region $REGION \
  --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value=${PROJECT}-vpc
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
echo "VPC: $VPC_ID"

echo "==> Criando Subnets..."
PUBLIC_SUBNET=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 \
  --availability-zone ${REGION}a \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PUBLIC_SUBNET --tags Key=Name,Value=${PROJECT}-public-subnet

PRIVATE_SUBNET=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 \
  --availability-zone ${REGION}b \
  --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $PRIVATE_SUBNET --tags Key=Name,Value=${PROJECT}-private-subnet
echo "Public Subnet: $PUBLIC_SUBNET | Private Subnet: $PRIVATE_SUBNET"

echo "==> Criando Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
  --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value=${PROJECT}-igw
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "IGW: $IGW_ID"

echo "==> Configurando Route Tables..."
PUBLIC_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PUBLIC_RT --tags Key=Name,Value=${PROJECT}-public-rt
aws ec2 create-route --route-table-id $PUBLIC_RT \
  --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUBLIC_RT --subnet-id $PUBLIC_SUBNET

PRIVATE_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-tags --resources $PRIVATE_RT --tags Key=Name,Value=${PROJECT}-private-rt
aws ec2 associate-route-table --route-table-id $PRIVATE_RT --subnet-id $PRIVATE_SUBNET
echo "Public RT: $PUBLIC_RT | Private RT: $PRIVATE_RT"

echo "==> Criando Security Groups..."
SG_WEB=$(aws ec2 create-security-group \
  --group-name ${PROJECT}-sg-webserver \
  --description "Web server security group" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
aws ec2 create-tags --resources $SG_WEB --tags Key=Name,Value=${PROJECT}-sg-webserver

# SSH restrito ao IP do administrador
aws ec2 authorize-security-group-ingress --group-id $SG_WEB \
  --protocol tcp --port 22 --cidr $YOUR_IP
# HTTP e HTTPS públicos
aws ec2 authorize-security-group-ingress --group-id $SG_WEB \
  --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_WEB \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

SG_DB=$(aws ec2 create-security-group \
  --group-name ${PROJECT}-sg-database \
  --description "Database security group - acesso restrito ao web server" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)
aws ec2 create-tags --resources $SG_DB --tags Key=Name,Value=${PROJECT}-sg-database

# DB acessível apenas pelo SG do web server
aws ec2 authorize-security-group-ingress --group-id $SG_DB \
  --protocol tcp --port 5432 --source-group $SG_WEB
echo "SG Web: $SG_WEB | SG DB: $SG_DB"

echo "==> Criando Key Pair..."
aws ec2 create-key-pair \
  --key-name ${PROJECT}-keypair \
  --query 'KeyMaterial' --output text > ${PROJECT}-keypair.pem
chmod 400 ${PROJECT}-keypair.pem
echo "Key Pair salvo em: ${PROJECT}-keypair.pem"

echo "==> Buscando AMI Amazon Linux 2..."
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)
echo "AMI: $AMI_ID"

echo "==> Lançando instância EC2..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --key-name ${PROJECT}-keypair \
  --security-group-ids $SG_WEB \
  --subnet-id $PUBLIC_SUBNET \
  --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT}-webserver}]" \
  --user-data file://user-data.sh \
  --query 'Instances[0].InstanceId' --output text)
echo "Instance ID: $INSTANCE_ID"

echo "==> Aguardando instância ficar running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo ""
echo "============================================"
echo " Infraestrutura criada com sucesso!"
echo "============================================"
echo " VPC:            $VPC_ID"
echo " Public Subnet:  $PUBLIC_SUBNET"
echo " Private Subnet: $PRIVATE_SUBNET"
echo " IGW:            $IGW_ID"
echo " SG Web:         $SG_WEB"
echo " SG DB:          $SG_DB"
echo " EC2 Instance:   $INSTANCE_ID"
echo " Public IP:      $PUBLIC_IP"
echo " SSH:            ssh -i ${PROJECT}-keypair.pem ec2-user@$PUBLIC_IP"
echo " App URL:        http://$PUBLIC_IP"
echo "============================================"

# Salvar IDs para o script de cleanup
cat > .infra-ids.env <<EOF
VPC_ID=$VPC_ID
PUBLIC_SUBNET=$PUBLIC_SUBNET
PRIVATE_SUBNET=$PRIVATE_SUBNET
IGW_ID=$IGW_ID
PUBLIC_RT=$PUBLIC_RT
PRIVATE_RT=$PRIVATE_RT
SG_WEB=$SG_WEB
SG_DB=$SG_DB
INSTANCE_ID=$INSTANCE_ID
REGION=$REGION
PROJECT=$PROJECT
EOF
echo "IDs salvos em .infra-ids.env"
