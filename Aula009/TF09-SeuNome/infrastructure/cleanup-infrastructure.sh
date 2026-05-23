#!/bin/bash
# Script para remover infraestrutura criada
# Requer AWS CLI configurado
# Preencha os IDs conforme anotado na criação

# Exemplo de comandos:
# aws ec2 terminate-instances --instance-ids <INSTANCE_ID>
# aws ec2 delete-security-group --group-id <SG_ID>
# aws ec2 delete-subnet --subnet-id <SUBNET_ID>
# aws ec2 detach-internet-gateway --internet-gateway-id <IGW_ID> --vpc-id <VPC_ID>
# aws ec2 delete-internet-gateway --internet-gateway-id <IGW_ID>
# aws ec2 delete-route-table --route-table-id <RT_ID>
# aws ec2 delete-vpc --vpc-id <VPC_ID>

echo "Infraestrutura removida. Preencha os IDs conforme necessário."
