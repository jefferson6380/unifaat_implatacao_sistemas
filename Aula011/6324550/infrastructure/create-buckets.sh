#!/bin/bash
# create-buckets.sh
# Autor: Bruno Pereira dos Santos - RA 6324550
# Descrição: Cria e configura os buckets S3 para hospedagem do portfólio

set -euo pipefail

REGION="us-east-1"
WEBSITE_BUCKET="portfolio-bruno-6324550"
ASSETS_BUCKET="portfolio-bruno-6324550-assets"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "======================================"
echo " Criando infraestrutura S3"
echo " Aluno: Bruno Pereira dos Santos"
echo " RA: 6324550"
echo "======================================"

# ===== BUCKET PRINCIPAL (Website) =====
echo "[1/6] Criando bucket principal: $WEBSITE_BUCKET"
if aws s3 ls "s3://$WEBSITE_BUCKET" 2>/dev/null; then
  echo "  Bucket já existe. Continuando..."
else
  if [ "$REGION" == "us-east-1" ]; then
    aws s3api create-bucket --bucket "$WEBSITE_BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$WEBSITE_BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "  Bucket criado com sucesso."
fi

echo "[2/6] Desabilitando Block Public Access no bucket principal"
aws s3api put-public-access-block \
  --bucket "$WEBSITE_BUCKET" \
  --public-access-block-configuration \
    BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

echo "[3/6] Configurando static website hosting"
aws s3api put-bucket-website --bucket "$WEBSITE_BUCKET" --website-configuration '{
  "IndexDocument": {"Suffix": "index.html"},
  "ErrorDocument": {"Key": "error.html"}
}'

echo "[4/6] Aplicando bucket policy pública"
aws s3api put-bucket-policy --bucket "$WEBSITE_BUCKET" --policy "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Sid\": \"PublicReadGetObject\",
    \"Effect\": \"Allow\",
    \"Principal\": \"*\",
    \"Action\": \"s3:GetObject\",
    \"Resource\": \"arn:aws:s3:::${WEBSITE_BUCKET}/*\"
  }]
}"

echo "[5/6] Habilitando versionamento no bucket principal"
aws s3api put-bucket-versioning --bucket "$WEBSITE_BUCKET" \
  --versioning-configuration Status=Enabled

echo "[6/6] Configurando lifecycle policy"
aws s3api put-bucket-lifecycle-configuration --bucket "$WEBSITE_BUCKET" --lifecycle-configuration '{
  "Rules": [{
    "ID": "delete-old-versions",
    "Status": "Enabled",
    "NoncurrentVersionExpiration": {"NoncurrentDays": 30},
    "Filter": {"Prefix": ""}
  }]
}'

# ===== BUCKET DE ASSETS =====
echo ""
echo "[A1/4] Criando bucket de assets: $ASSETS_BUCKET"
if aws s3 ls "s3://$ASSETS_BUCKET" 2>/dev/null; then
  echo "  Bucket já existe. Continuando..."
else
  if [ "$REGION" == "us-east-1" ]; then
    aws s3api create-bucket --bucket "$ASSETS_BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$ASSETS_BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

echo "[A2/4] Configurando CORS no bucket de assets"
aws s3api put-bucket-cors --bucket "$ASSETS_BUCKET" --cors-configuration '{
  "CORSRules": [{
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST"],
    "AllowedOrigins": ["*"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }]
}'

echo "[A3/4] Habilitando versionamento no bucket de assets"
aws s3api put-bucket-versioning --bucket "$ASSETS_BUCKET" \
  --versioning-configuration Status=Enabled

echo "[A4/4] Habilitando logs de acesso"
aws s3api put-bucket-logging --bucket "$WEBSITE_BUCKET" --bucket-logging-status "{
  \"LoggingEnabled\": {
    \"TargetBucket\": \"${ASSETS_BUCKET}\",
    \"TargetPrefix\": \"access-logs/\"
  }
}"

# ===== UPLOAD DOS ARQUIVOS DO WEBSITE =====
echo ""
echo "[UPLOAD] Fazendo upload dos arquivos do website..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEBSITE_DIR="$SCRIPT_DIR/../website"

if [ -d "$WEBSITE_DIR" ]; then
  aws s3 sync "$WEBSITE_DIR" "s3://$WEBSITE_BUCKET" \
    --exclude "*.DS_Store" \
    --cache-control "max-age=86400" \
    --delete

  # HTML sem cache longo
  aws s3 cp "$WEBSITE_DIR/index.html" "s3://$WEBSITE_BUCKET/index.html" \
    --content-type "text/html" \
    --cache-control "no-cache, no-store, must-revalidate"

  aws s3 cp "$WEBSITE_DIR/error.html" "s3://$WEBSITE_BUCKET/error.html" \
    --content-type "text/html" \
    --cache-control "no-cache"

  echo "  Upload concluído!"
else
  echo "  AVISO: Pasta website não encontrada. Execute o upload manualmente."
fi

echo ""
echo "======================================"
echo " Configuração S3 concluída!"
echo "======================================"
echo " Website URL: http://${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"
echo " Assets Bucket: s3://${ASSETS_BUCKET}"
echo ""
echo " Próximo passo: execute setup-cloudfront.sh"
echo "======================================"

# Salvar variáveis para próximos scripts
cat > "$SCRIPT_DIR/.env.infra" << EOF
WEBSITE_BUCKET=$WEBSITE_BUCKET
ASSETS_BUCKET=$ASSETS_BUCKET
REGION=$REGION
ACCOUNT_ID=$ACCOUNT_ID
WEBSITE_S3_URL=http://${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com
EOF
echo " Variáveis salvas em .env.infra"
