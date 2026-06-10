#!/usr/bin/env bash
# TF10 - Cria instância RDS PostgreSQL Multi-AZ para migração do Northwind
# Autor: Yago Canton (RA 6324598)

set -euo pipefail

: "${AWS_REGION:=us-east-1}"
: "${DB_INSTANCE_ID:=northwind-rds}"
: "${DB_NAME:=northwind}"
: "${DB_MASTER_USER:=postgres}"
: "${DB_MASTER_PASSWORD:?defina DB_MASTER_PASSWORD no ambiente}"
: "${DB_INSTANCE_CLASS:=db.t3.micro}"
: "${DB_ENGINE_VERSION:=14.12}"
: "${DB_STORAGE_GB:=20}"
: "${DB_STORAGE_TYPE:=gp3}"
: "${DB_BACKUP_RETENTION:=7}"
: "${SG_NAME:=tf10-rds-sg}"
: "${MULTI_AZ:=true}"
: "${DB_PARAM_GROUP:=tf10-pg14-custom}"

echo "==> Região: $AWS_REGION"
echo "==> Identificador da instância: $DB_INSTANCE_ID"

# 1. Descobre VPC default
VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' --output text)
echo "==> VPC default: $VPC_ID"

# 2. Cria Security Group (idempotente)
SG_ID=$(aws ec2 describe-security-groups --region "$AWS_REGION" \
  --filters Name=group-name,Values="$SG_NAME" Name=vpc-id,Values="$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "None")

if [[ "$SG_ID" == "None" || -z "$SG_ID" ]]; then
  SG_ID=$(aws ec2 create-security-group --region "$AWS_REGION" \
    --group-name "$SG_NAME" \
    --description "TF10 RDS PostgreSQL access" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' --output text)
  echo "==> Security Group criado: $SG_ID"

  # Libera 5432 apenas para o IP público atual (princípio do menor privilégio)
  MY_IP=$(curl -fsS https://checkip.amazonaws.com | tr -d '\n')
  aws ec2 authorize-security-group-ingress --region "$AWS_REGION" \
    --group-id "$SG_ID" \
    --protocol tcp --port 5432 \
    --cidr "${MY_IP}/32" >/dev/null
  echo "==> Ingress 5432 liberado para ${MY_IP}/32"
else
  echo "==> Security Group já existe: $SG_ID"
fi

# 3. Parameter Group customizado (idempotente)
PG_EXISTS=$(aws rds describe-db-parameter-groups --region "$AWS_REGION" \
  --db-parameter-group-name "$DB_PARAM_GROUP" \
  --query 'DBParameterGroups[0].DBParameterGroupName' --output text 2>/dev/null || echo "None")
if [[ "$PG_EXISTS" == "None" || -z "$PG_EXISTS" ]]; then
  aws rds create-db-parameter-group --region "$AWS_REGION" \
    --db-parameter-group-name "$DB_PARAM_GROUP" \
    --db-parameter-group-family postgres14 \
    --description "TF10 custom params" \
    --tags Key=Project,Value=TF10 Key=RA,Value=6324598 >/dev/null
  aws rds modify-db-parameter-group --region "$AWS_REGION" \
    --db-parameter-group-name "$DB_PARAM_GROUP" \
    --parameters \
      "ParameterName=work_mem,ParameterValue=8192,ApplyMethod=pending-reboot" \
      "ParameterName=log_min_duration_statement,ParameterValue=500,ApplyMethod=immediate" \
      "ParameterName=log_connections,ParameterValue=1,ApplyMethod=immediate" \
      "ParameterName=log_disconnections,ParameterValue=1,ApplyMethod=immediate" >/dev/null
  echo "==> Parameter Group criado: $DB_PARAM_GROUP"
else
  echo "==> Parameter Group já existe: $DB_PARAM_GROUP"
fi

# 4. Cria a instância RDS se ainda não existir
STATUS=$(aws rds describe-db-instances --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --query 'DBInstances[0].DBInstanceStatus' --output text 2>/dev/null || echo "missing")

if [[ "$STATUS" == "missing" ]]; then
  echo "==> Criando instância RDS..."
  aws rds create-db-instance --region "$AWS_REGION" \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --db-instance-class "$DB_INSTANCE_CLASS" \
    --engine postgres \
    --engine-version "$DB_ENGINE_VERSION" \
    --master-username "$DB_MASTER_USER" \
    --master-user-password "$DB_MASTER_PASSWORD" \
    --allocated-storage "$DB_STORAGE_GB" \
    --storage-type "$DB_STORAGE_TYPE" \
    --db-name "$DB_NAME" \
    --vpc-security-group-ids "$SG_ID" \
    --backup-retention-period "$DB_BACKUP_RETENTION" \
    --multi-az \
    --storage-encrypted \
    --enable-performance-insights \
    --performance-insights-retention-period 7 \
    --publicly-accessible \
    --copy-tags-to-snapshot \
    --deletion-protection \
    --db-parameter-group-name "$DB_PARAM_GROUP" \
    --tags Key=Project,Value=TF10 Key=RA,Value=6324598 >/dev/null
  echo "==> create-db-instance enviado"
else
  echo "==> Instância já existe (status: $STATUS)"
fi

# 5. Aguarda available
echo "==> Aguardando status 'available' (pode levar 10-15 minutos)..."
aws rds wait db-instance-available --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID"

# 6. Imprime endpoint
ENDPOINT=$(aws rds describe-db-instances --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --query 'DBInstances[0].Endpoint.Address' --output text)
PORT=$(aws rds describe-db-instances --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --query 'DBInstances[0].Endpoint.Port' --output text)

echo "==> RDS pronto"
echo "    Endpoint: $ENDPOINT"
echo "    Porta:    $PORT"
echo
echo "Exporte para os próximos scripts:"
echo "  export RDS_ENDPOINT=$ENDPOINT"
echo "  export RDS_PORT=$PORT"
