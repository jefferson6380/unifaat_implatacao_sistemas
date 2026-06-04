#!/usr/bin/env bash
# Configura bucket policies e security headers

set -euo pipefail

RA="${RA:-6324548}"
REGION="${AWS_REGION:-us-east-1}"
WEBSITE_BUCKET="portfolio-website-${RA}"
ASSETS_BUCKET="portfolio-assets-${RA}"

# OAC (Origin Access Control) ID — preenchido após setup-cloudfront.sh
# Deixar vazio antes de ter o CloudFront; o script cria policy provisória
CF_DISTRIBUTION_ID="${CF_DISTRIBUTION_ID:-}"

echo "==> Configurando políticas de segurança"

# ── Bucket policy: website (acesso só via CloudFront OAC) ──
if [ -n "${CF_DISTRIBUTION_ID}" ]; then
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  WEBSITE_POLICY="{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Sid\": \"AllowCloudFrontServicePrincipal\",
        \"Effect\": \"Allow\",
        \"Principal\": {
          \"Service\": \"cloudfront.amazonaws.com\"
        },
        \"Action\": \"s3:GetObject\",
        \"Resource\": \"arn:aws:s3:::${WEBSITE_BUCKET}/*\",
        \"Condition\": {
          \"StringEquals\": {
            \"AWS:SourceArn\": \"arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${CF_DISTRIBUTION_ID}\"
          }
        }
      }
    ]
  }"
else
  echo "Aviso: CF_DISTRIBUTION_ID não definido. Policy provisória (somente leitura pública)."
  echo "Após criar o CloudFront, re-execute com CF_DISTRIBUTION_ID=<id>"
  WEBSITE_POLICY="{
    \"Version\": \"2012-10-17\",
    \"Statement\": [
      {
        \"Sid\": \"PublicReadTemporary\",
        \"Effect\": \"Allow\",
        \"Principal\": \"*\",
        \"Action\": \"s3:GetObject\",
        \"Resource\": \"arn:aws:s3:::${WEBSITE_BUCKET}/*\"
      }
    ]
  }"
fi

aws s3api put-bucket-policy \
  --bucket "${WEBSITE_BUCKET}" \
  --policy "${WEBSITE_POLICY}"

echo "==> Policy do bucket website configurada"

# ── Bucket policy: assets ─────────────────────────────────
ASSETS_POLICY="{
  \"Version\": \"2012-10-17\",
  \"Statement\": [
    {
      \"Sid\": \"AllowPublicRead\",
      \"Effect\": \"Allow\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${ASSETS_BUCKET}/*\"
    },
    {
      \"Sid\": \"DenyHotlinking\",
      \"Effect\": \"Deny\",
      \"Principal\": \"*\",
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${ASSETS_BUCKET}/*\",
      \"Condition\": {
        \"StringLike\": {
          \"aws:Referer\": \"\"
        }
      }
    }
  ]
}"

aws s3api put-bucket-policy \
  --bucket "${ASSETS_BUCKET}" \
  --policy "${ASSETS_POLICY}"

echo "==> Policy do bucket assets configurada"

# ── Response Headers Policy (Security Headers) via CloudFront ──
# Criar política de headers de segurança
HEADERS_POLICY_NAME="portfolio-security-headers-${RA}"

HEADERS_CONFIG="{
  \"Comment\": \"Security headers para portfólio ${RA}\",
  \"Name\": \"${HEADERS_POLICY_NAME}\",
  \"SecurityHeadersConfig\": {
    \"XSSProtection\": {
      \"Override\": true,
      \"Protection\": true,
      \"ModeBlock\": true
    },
    \"FrameOptions\": {
      \"Override\": true,
      \"FrameOption\": \"DENY\"
    },
    \"ReferrerPolicy\": {
      \"Override\": true,
      \"ReferrerPolicy\": \"strict-origin-when-cross-origin\"
    },
    \"ContentTypeOptions\": {
      \"Override\": true
    },
    \"StrictTransportSecurity\": {
      \"Override\": true,
      \"IncludeSubdomains\": true,
      \"Preload\": true,
      \"AccessControlMaxAgeSec\": 63072000
    }
  },
  \"CustomHeadersConfig\": {
    \"Quantity\": 1,
    \"Items\": [
      {
        \"Header\": \"Cache-Control\",
        \"Value\": \"no-cache\",
        \"Override\": false
      }
    ]
  }
}"

EXISTING_POLICY=$(aws cloudfront list-response-headers-policies \
  --query "ResponseHeadersPolicyList.Items[?ResponseHeadersPolicy.ResponseHeadersPolicyConfig.Name=='${HEADERS_POLICY_NAME}'].ResponseHeadersPolicy.Id" \
  --output text 2>/dev/null || echo "")

if [ -z "${EXISTING_POLICY}" ]; then
  aws cloudfront create-response-headers-policy \
    --response-headers-policy-config "${HEADERS_CONFIG}" \
    --query 'ResponseHeadersPolicy.Id' \
    --output text
  echo "==> Response headers policy criada"
else
  echo "==> Response headers policy já existe: ${EXISTING_POLICY}"
fi

echo ""
echo "✅ Políticas configuradas!"
echo "   Website bucket : ${WEBSITE_BUCKET}"
echo "   Assets bucket  : ${ASSETS_BUCKET}"
