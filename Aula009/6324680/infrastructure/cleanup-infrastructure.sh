#!/bin/bash
set -e

# ============================================================
# TF09 - Script de Limpeza de Infraestrutura AWS
# Aluno: Vitor Pinheiro Guimaraes | RA: 6324680
# ============================================================

if [ ! -f .infra-ids.env ]; then
  echo "Arquivo .infra-ids.env não encontrado. Execute create-infrastructure.sh primeiro."
  exit 1
fi

source .infra-ids.env

echo "=========================================="
echo " ATENÇÃO: Destruindo toda a infraestrutura"
echo "=========================================="
read -p " Confirma? (sim/não): " CONFIRM
if [ "$CONFIRM" != "sim" ]; then
  echo "Operação cancelada."
  exit 0
fi

echo "[1/7] Terminando instância EC2..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID --region $REGION
echo "  Instância terminada."

echo "[2/7] Removendo Key Pair..."
aws ec2 delete-key-pair --key-name $KEY_NAME --region $REGION
rm -f ~/.ssh/$KEY_NAME.pem
echo "  Key Pair removido."

echo "[3/7] Removendo Security Groups..."
aws ec2 delete-security-group --group-id $SG_DB_ID --region $REGION
aws ec2 delete-security-group --group-id $SG_WEB_ID --region $REGION
echo "  Security Groups removidos."

echo "[4/7] Removendo Route Table..."
aws ec2 disassociate-route-table \
  --association-id $(aws ec2 describe-route-tables \
    --route-table-ids $RTB_PUB_ID \
    --query 'RouteTables[0].Associations[0].RouteTableAssociationId' \
    --output text) --region $REGION 2>/dev/null || true
aws ec2 delete-route-table --route-table-id $RTB_PUB_ID --region $REGION
echo "  Route Table removida."

echo "[5/7] Desconectando e removendo Internet Gateway..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region $REGION
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region $REGION
echo "  IGW removido."

echo "[6/7] Removendo Subnets..."
aws ec2 delete-subnet --subnet-id $SUBNET_PUB_ID --region $REGION
aws ec2 delete-subnet --subnet-id $SUBNET_PRIV_ID --region $REGION
echo "  Subnets removidas."

echo "[7/7] Removendo VPC..."
aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION
echo "  VPC removida."

rm -f .infra-ids.env

echo ""
echo "=========================================="
echo " Limpeza concluída. Nenhum recurso ativo."
echo "=========================================="
