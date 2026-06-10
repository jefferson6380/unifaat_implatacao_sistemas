#!/bin/bash
# cleanup-infrastructure.sh - Remove todos os recursos AWS criados
set -e

if [ ! -f .infra-ids.env ]; then
  echo "Arquivo .infra-ids.env não encontrado. Execute create-infrastructure.sh primeiro."
  exit 1
fi

source .infra-ids.env

echo "==> Terminando instância EC2..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION
echo "Instância terminada."

echo "==> Removendo Key Pair..."
aws ec2 delete-key-pair --key-name ${PROJECT}-keypair --region $REGION
rm -f ${PROJECT}-keypair.pem

echo "==> Removendo Security Groups..."
aws ec2 delete-security-group --group-id $SG_DB --region $REGION
aws ec2 delete-security-group --group-id $SG_WEB --region $REGION

echo "==> Removendo Route Tables..."
aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables \
    --route-table-ids $PUBLIC_RT \
    --query 'RouteTables[0].Associations[0].RouteTableAssociationId' \
    --output text) --region $REGION
aws ec2 delete-route-table --route-table-id $PUBLIC_RT --region $REGION

aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables \
    --route-table-ids $PRIVATE_RT \
    --query 'RouteTables[0].Associations[0].RouteTableAssociationId' \
    --output text) --region $REGION
aws ec2 delete-route-table --route-table-id $PRIVATE_RT --region $REGION

echo "==> Desanexando e removendo Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION

echo "==> Removendo Subnets..."
aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET --region $REGION
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET --region $REGION

echo "==> Removendo VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION

rm -f .infra-ids.env

echo ""
echo "============================================"
echo " Todos os recursos removidos com sucesso!"
echo " Verifique o console AWS para confirmar."
echo "============================================"
