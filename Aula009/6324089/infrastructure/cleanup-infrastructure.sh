#!/bin/bash
# Script de limpeza de recursos - TF09

echo "⚠️ Iniciando a remoção dos recursos AWS..."

# IDs devem ser preenchidos ou passados como variáveis de ambiente
# Exemplo de uso: WEB_INSTANCE_ID=i-xxxx ./cleanup-infrastructure.sh

aws ec2 terminate-instances --instance-ids $WEB_INSTANCE_ID $DB_INSTANCE_ID
echo "Terminando instâncias... aguardando 60s"
sleep 60

aws ec2 delete-security-group --group-id $WEB_SG_ID
aws ec2 delete-security-group --group-id $DB_SG_ID

aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

aws ec2 delete-subnet --subnet-id $PUBLIC_SUBNET_ID
aws ec2 delete-subnet --subnet-id $PRIVATE_SUBNET_ID

aws ec2 delete-vpc --vpc-id $VPC_ID
aws ec2 delete-key-pair --key-name Lab009-KeyPair

echo "✅ Limpeza concluída com sucesso."