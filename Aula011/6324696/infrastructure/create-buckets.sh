#!/usr/bin/env bash
# Cria e configura os buckets S3 para o portfólio de Natan Borges Leme (RA 6324696)
set -euo pipefail

# ============================
# CONFIGURAÇÕES — EDITE AQUI
# ============================
REGION="us-east-1"
WEBSITE_BUCKET="natan-portifolio-website-6324696"
ASSETS_BUCKET="natan-portifolio-assets-6324696"
INDEX_DOC="index.html"
ERROR_DOC="404.html"

echo "======================================"
echo " TF11 — Criando buckets S3"
echo " Aluno: Natan Borges Leme (6324696)"
echo "======================================"

# ----------------------------
# 1. Bucket principal (website)
# ----------------------------
echo ""
echo "[1/6] Criando bucket principal: $WEBSITE_BUCKET"
if aws s3api head-bucket --bucket "$WEBSITE_BUCKET" 2>/dev/null; then
  echo "  → Bucket já existe, pulando criação."
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$WEBSITE_BUCKET" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$WEBSITE_BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "  ✓ Bucket criado."
fi

# ----------------------------
# 2. Bucket de assets
# ----------------------------
echo ""
echo "[2/6] Criando bucket de assets: $ASSETS_BUCKET"
if aws s3api head-bucket --bucket "$ASSETS_BUCKET" 2>/dev/null; then
  echo "  → Bucket já existe, pulando criação."
else
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket \
      --bucket "$ASSETS_BUCKET" \
      --region "$REGION"
  else
    aws s3api create-bucket \
      --bucket "$ASSETS_BUCKET" \
      --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
  echo "  ✓ Bucket criado."
fi

# ----------------------------
# 3. Habilitar static website hosting
# ----------------------------
echo ""
echo "[3/6] Configurando static website hosting no bucket principal..."
aws s3api put-bucket-website \
  --bucket "$WEBSITE_BUCKET" \
  --website-configuration "{
    \"IndexDocument\": {\"Suffix\": \"$INDEX_DOC\"},
    \"ErrorDocument\": {\"Key\": \"$ERROR_DOC\"}
  }"
echo "  ✓ Static website hosting habilitado."

# ----------------------------
# 4. Habilitar versionamento
# ----------------------------
echo ""
echo "[4/6] Habilitando versionamento nos buckets..."
aws s3api put-bucket-versioning \
  --bucket "$WEBSITE_BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-versioning \
  --bucket "$ASSETS_BUCKET" \
  --versioning-configuration Status=Enabled
echo "  ✓ Versionamento habilitado em ambos os buckets."

# ----------------------------
# 5. Lifecycle policy (assets — move para IA após 30d, Glacier após 90d)
# ----------------------------
echo ""
echo "[5/6] Configurando lifecycle policy no bucket de assets..."
aws s3api put-bucket-lifecycle-configuration \
  --bucket "$ASSETS_BUCKET" \
  --lifecycle-configuration '{
    "Rules": [
      {
        "ID": "move-to-ia",
        "Status": "Enabled",
        "Filter": {"Prefix": ""},
        "Transitions": [
          {"Days": 30,  "StorageClass": "STANDARD_IA"},
          {"Days": 90,  "StorageClass": "GLACIER"}
        ],
        "NoncurrentVersionTransitions": [
          {"NoncurrentDays": 30, "StorageClass": "STANDARD_IA"}
        ],
        "NoncurrentVersionExpiration": {"NoncurrentDays": 365}
      }
    ]
  }'
echo "  ✓ Lifecycle policy configurada."

# ----------------------------
# 6. Habilitar logging de acesso
# ----------------------------
echo ""
echo "[6/6] Configurando logs de acesso..."
LOGS_BUCKET="${WEBSITE_BUCKET}-logs"
if ! aws s3api head-bucket --bucket "$LOGS_BUCKET" 2>/dev/null; then
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$LOGS_BUCKET" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$LOGS_BUCKET" --region "$REGION" \
      --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi
aws s3api put-bucket-acl --bucket "$LOGS_BUCKET" --acl log-delivery-write 2>/dev/null || true
echo "  ✓ Bucket de logs criado: $LOGS_BUCKET"

# ----------------------------
# RESULTADO
# ----------------------------
WEBSITE_ENDPOINT="${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"
echo ""
echo "======================================"
echo " ✅ Buckets criados com sucesso!"
echo "======================================"
echo " Website bucket : $WEBSITE_BUCKET"
echo " Assets bucket  : $ASSETS_BUCKET"
echo " Logs bucket    : $LOGS_BUCKET"
echo " Website URL    : http://$WEBSITE_ENDPOINT"
echo ""
echo " Próximo passo: execute configure-policies.sh"
echo "======================================"
