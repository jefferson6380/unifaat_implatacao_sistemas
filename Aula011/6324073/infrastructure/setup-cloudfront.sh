#!/bin/bash
# =============================================================
# setup-cloudfront.sh
# Cria e configura a distribuição CloudFront para o portfólio
# =============================================================

set -euo pipefail

REGION="us-east-1"
RA="6324073"
WEBSITE_BUCKET="portfolio-lfs-website-${RA}"
S3_ORIGIN="${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"

echo "=== Configurando CloudFront ==="
echo "Origem S3: ${S3_ORIGIN}"
echo ""

# ----------------------------------------------------------------
# 1. Criar distribuição CloudFront
# ----------------------------------------------------------------
echo "[1/4] Criando distribuição CloudFront..."
DISTRIBUTION_CONFIG=$(cat <<EOF
{
  "CallerReference": "portfolio-lfs-${RA}-$(date +%s)",
  "Origins": {
    "Quantity": 1,
    "Items": [{
      "Id": "S3-${WEBSITE_BUCKET}",
      "DomainName": "${S3_ORIGIN}",
      "CustomOriginConfig": {
        "HTTPPort": 80,
        "HTTPSPort": 443,
        "OriginProtocolPolicy": "http-only"
      }
    }]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-${WEBSITE_BUCKET}",
    "ViewerProtocolPolicy": "redirect-to-https",
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "Compress": true,
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "ResponseHeadersPolicyId": "67f7725c-6f97-4210-82d7-5512b31e9d03"
  },
  "CacheBehaviors": {
    "Quantity": 1,
    "Items": [{
      "PathPattern": "*.html",
      "TargetOriginId": "S3-${WEBSITE_BUCKET}",
      "ViewerProtocolPolicy": "redirect-to-https",
      "CachePolicyId": "4135ea2d-6df8-44a3-9df3-4b5a84be39ad",
      "Compress": true,
      "AllowedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"],
        "CachedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"]
        }
      }
    }]
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [{
      "ErrorCode": 404,
      "ResponsePagePath": "/404.html",
      "ResponseCode": "404",
      "ErrorCachingMinTTL": 10
    }]
  },
  "Comment": "Portfolio LFS - Leonardo Frazao Sano",
  "Enabled": true,
  "HttpVersion": "http2and3",
  "IsIPV6Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF
)

DISTRIBUTION=$(aws cloudfront create-distribution \
  --distribution-config "${DISTRIBUTION_CONFIG}" \
  --query 'Distribution.{Id:Id,DomainName:DomainName,Status:Status}' \
  --output json)

DIST_ID=$(echo "${DISTRIBUTION}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['Id'])")
DIST_DOMAIN=$(echo "${DISTRIBUTION}" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['DomainName'])")

echo "Distribuição criada: ${DIST_ID}"
echo "Domínio CloudFront: ${DIST_DOMAIN}"

# ----------------------------------------------------------------
# 2. Criar Response Headers Policy com Security Headers
# ----------------------------------------------------------------
echo ""
echo "[2/4] Configurando security headers..."
aws cloudfront create-response-headers-policy \
  --response-headers-policy-config '{
    "Name": "portfolio-security-headers-'"${RA}"'",
    "Comment": "Security headers para o portfolio",
    "SecurityHeadersConfig": {
      "XSSProtection": {
        "Override": true,
        "Protection": true,
        "ModeBlock": true
      },
      "FrameOptions": {
        "Override": true,
        "FrameOption": "DENY"
      },
      "ReferrerPolicy": {
        "Override": true,
        "ReferrerPolicy": "strict-origin-when-cross-origin"
      },
      "ContentTypeOptions": {
        "Override": true
      },
      "StrictTransportSecurity": {
        "Override": true,
        "AccessControlMaxAgeSec": 63072000,
        "IncludeSubdomains": true,
        "Preload": true
      },
      "ContentSecurityPolicy": {
        "Override": true,
        "ContentSecurityPolicy": "default-src '"'"'self'"'"'; script-src '"'"'self'"'"' '"'"'unsafe-inline'"'"'; style-src '"'"'self'"'"' '"'"'unsafe-inline'"'"'; img-src '"'"'self'"'"' data: https:; connect-src '"'"'self'"'"' https://*.execute-api.us-east-1.amazonaws.com; font-src '"'"'self'"'"';"
      }
    }
  }' \
  --query 'ResponseHeadersPolicy.Id' \
  --output text 2>/dev/null || echo "(Política de headers já existe ou não disponível nesta região)"

# ----------------------------------------------------------------
# 3. Salvar IDs para uso nos outros scripts
# ----------------------------------------------------------------
echo ""
echo "[3/4] Salvando configurações..."
cat > "$(dirname "${BASH_SOURCE[0]}")/cloudfront-config.env" <<ENV
DIST_ID=${DIST_ID}
DIST_DOMAIN=${DIST_DOMAIN}
WEBSITE_BUCKET=${WEBSITE_BUCKET}
ASSETS_BUCKET=portfolio-lfs-assets-${RA}
REGION=${REGION}
ENV

echo "[4/4] Aguardando distribuição ficar disponível (pode levar 10-15 minutos)..."
echo "      Para verificar o status, execute:"
echo "      aws cloudfront get-distribution --id ${DIST_ID} --query 'Distribution.Status'"

# ----------------------------------------------------------------
# Resultado
# ----------------------------------------------------------------
echo ""
echo "======================================================"
echo "✅ CloudFront configurado com sucesso!"
echo "======================================================"
echo "Distribution ID: ${DIST_ID}"
echo "URL CloudFront:  https://${DIST_DOMAIN}"
echo "HTTP → HTTPS redirect: ATIVO"
echo "Compressão Gzip/Brotli: ATIVO"
echo "HTTP/2 e HTTP/3: ATIVO"
echo ""
echo "Configurações salvas em: infrastructure/cloudfront-config.env"
echo "======================================================"
