#!/bin/bash
# force-cleanup.sh
set -e

# Desativa o paginador da AWS CLI para evitar que o script trave
export AWS_PAGER=""

REGION="us-east-1"
PROJECT_NAME="tf09-portfolio"

echo "Buscando VPC do projeto..."
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$PROJECT_NAME-vpc" --region $REGION --query "Vpcs[0].VpcId" --output text)

if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
    echo "VPC encontrada: $VPC_ID. Iniciando limpeza forcada..."

    echo "0. Encerrando Instâncias EC2..."
    INSTANCE_IDS=$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$VPC_ID" "Name=instance-state-name,Values=running,pending,stopped" --region $REGION --query "Reservations[*].Instances[*].InstanceId" --output text)
    if [ -n "$INSTANCE_IDS" ] && [ "$INSTANCE_IDS" != "None" ]; then
        echo "Terminando instâncias: $INSTANCE_IDS"
        aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION > /dev/null
        echo "Aguardando término das instâncias..."
        aws ec2 wait instance-terminated --instance-ids $INSTANCE_IDS --region $REGION
    else
        echo "Nenhuma instância rodando encontrada."
    fi

    echo "1. Deletando Security Groups..."
    # Tenta deletar o SG de DB primeiro por causa da dependência do Web SG
    DB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PROJECT_NAME-db-sg" --region $REGION --query "SecurityGroups[0].GroupId" --output text)
    WEB_SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PROJECT_NAME-web-sg" --region $REGION --query "SecurityGroups[0].GroupId" --output text)
    
    if [ "$DB_SG_ID" != "None" ]; then 
        echo "Deletando DB Security Group: $DB_SG_ID"
        aws ec2 delete-security-group --group-id $DB_SG_ID --region $REGION || true
    fi
    if [ "$WEB_SG_ID" != "None" ]; then 
        echo "Deletando Web Security Group: $WEB_SG_ID"
        aws ec2 delete-security-group --group-id $WEB_SG_ID --region $REGION || true
    fi

    echo "2. Deletando Subnets..."
    PUBLIC_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PROJECT_NAME-public-subnet" --region $REGION --query "Subnets[0].SubnetId" --output text)
    PRIVATE_SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PROJECT_NAME-private-subnet" --region $REGION --query "Subnets[0].SubnetId" --output text)
    if [ "$PUBLIC_SUBNET_ID" != "None" ]; then aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID --region $REGION || true; fi
    if [ "$PRIVATE_SUBNET_ID" != "None" ]; then aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID --region $REGION || true; fi

    echo "3. Deletando Route Tables..."
    PUBLIC_RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PROJECT_NAME-public-rt" --region $REGION --query "RouteTables[0].RouteTableId" --output text)
    PRIVATE_RT_ID=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=$PROJECT_NAME-private-rt" --region $REGION --query "RouteTables[0].RouteTableId" --output text)
    if [ "$PUBLIC_RT_ID" != "None" ]; then aws ec2 delete-route-table --route-table-id $PUBLIC_RT_ID --region $REGION || true; fi
    if [ "$PRIVATE_RT_ID" != "None" ]; then aws ec2 delete-route-table --route-table-id $PRIVATE_RT_ID --region $REGION || true; fi

    echo "4. Detach e Delete Internet Gateway..."
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --region $REGION --query "InternetGateways[0].InternetGatewayId" --output text)
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION || true
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION || true
    fi

    echo "5. Deletando VPC..."
    aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION || true
else
    echo "Nenhuma VPC encontrada."
fi

echo "6. Deletando Key Pair se existir..."
aws ec2 delete-key-pair --key-name "$PROJECT_NAME-key" --region $REGION || true
rm -f "$HOME/.ssh/$PROJECT_NAME-key.pem"

echo "Limpeza forçada concluída."