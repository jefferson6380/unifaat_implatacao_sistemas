#!/bin/bash
# Testes de verificação para o projeto TF09
# Execute na sua máquina (para testes externos) e na EC2 (para testes internos)

# 1. Infraestrutura AWS
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=cidr,Values=10.0.0.0/16" --query 'Vpcs[0].VpcId' --output text)
echo "VPC_ID: $VPC_ID"

echo "Subnets:"
aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}'

echo "Internet Gateways:"
aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId'

echo "Route Tables:"
aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[*].RouteTableId'

echo "Security Groups:"
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName}'

# 2. Testes na EC2
if [ "$SSH_CONNECTION" != "" ]; then
  echo "Testando containers Docker..."
  docker ps

  echo "Testando health check backend..."
  curl -s http://localhost:3000/api/health || echo "Falha no health check"

  echo "Testando API de projetos..."
  curl -s http://localhost:3000/api/projects || echo "Falha na API de projetos"

  echo "Testando frontend..."
  curl -s http://localhost | head -20

  echo "Testando banco de dados via Docker..."
  DB_CONTAINER=$(docker ps --filter ancestor=mysql:8.0 --format '{{.Names}}')
  if [ "$DB_CONTAINER" != "" ]; then
    docker exec -i $DB_CONTAINER mysql -uadmin -psenha_segura -e 'USE portfolio; SELECT * FROM projetos;'
  else
    echo "Container do banco não encontrado."
  fi
else
  echo "Testes externos:"
  echo "Testando health check externo..."
  curl -s http://<IP_DA_EC2>/api/health || echo "Falha no health check externo"

  echo "Testando frontend externo..."
  curl -s http://<IP_DA_EC2> | head -20

  echo "Testando acesso ao banco de dados (deve falhar):"
  mysql -h <IP_DA_EC2> -uadmin -psenha_segura -e 'SHOW DATABASES;' || echo "Acesso ao banco bloqueado (OK)"
fi

echo "Testes concluídos. Tire prints dos resultados para evidências."
