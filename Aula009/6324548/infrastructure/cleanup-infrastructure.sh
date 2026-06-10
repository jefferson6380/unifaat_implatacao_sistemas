#!/bin/bash
# cleanup-infrastructure.sh

REGION="us-east-1"
PROJECT_TAG="TF09-Portfolio"

echo "=== INICIANDO LIMPEZA DA INFRAESTRUTURA: $PROJECT_TAG ==="

# 1. Obter IDs
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$PROJECT_TAG-VPC" --query "Vpcs[0].VpcId" --output text --region $REGION)

if [ "$VPC_ID" == "None" ] || [ -z "$VPC_ID" ]; then
    echo "Nenhuma VPC encontrada com a tag Name=$PROJECT_TAG-VPC."
    exit 0
fi

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$PROJECT_TAG-WebServer" "Name=instance-state-name,Values=running,stopped" --query "Reservations[0].Instances[0].InstanceId" --output text --region $REGION)

# 2. Encerrar Instância
if [ "$INSTANCE_ID" != "None" ] && [ -n "$INSTANCE_ID" ]; then
    echo "Terminando Instância EC2: $INSTANCE_ID"
    aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION > /dev/null
    echo "Aguardando término da instância..."
    aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION
fi

# 3. Remover Key Pair
aws ec2 delete-key-pair --key-name "$PROJECT_TAG-Key" --region $REGION
rm -f "$PROJECT_TAG-Key.pem"

# 4. Remover IGW e Rotas e Subnets
IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region $REGION)
if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
    echo "Desanexando e Removendo IGW: $IGW_ID"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
fi

# Remover Route Tables Customizadas atreladas a VPC
RTS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" --output text --region $REGION)
for rt in $RTS; do
    if [ "$rt" != "None" ] && [ -n "$rt" ]; then
        echo "Excluindo Route Table Customizada: $rt"
        aws ec2 delete-route-table --route-table-id $rt --region $REGION
    fi
done

SUBNETS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text --region $REGION)
for subnet in $SUBNETS; do
    echo "Excluindo Subnet: $subnet"
    aws ec2 delete-subnet --subnet-id $subnet --region $REGION
done

# 5. Security Groups
SGS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=web-sg" --query "SecurityGroups[*].GroupId" --output text --region $REGION)
for sg in $SGS; do
    echo "Excluindo Security Group: $sg"
    aws ec2 delete-security-group --group-id $sg --region $REGION
done

# 6. VPC
echo "Excluindo VPC: $VPC_ID"
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

echo "=== LIMPEZA CONCLUÍDA ==="
