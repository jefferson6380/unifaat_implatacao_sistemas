#!/usr/bin/env bash
# Cria a distribuição CloudFront para o portfólio
set -euo pipefail

REGION="us-east-1"
WEBSITE_BUCKET="natan-portifolio-website-6324696"
COMMENT="Portfolio Natan Borges Leme RA 6324696 - TF11"

echo "======================================"
echo " TF11 — Configurando CloudFront"
echo " Aluno: Natan Borges Leme (6324696)"
echo "======================================"

ORIGIN_DOMAIN="${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"

echo ""
echo "[1/3] Criando distribuição CloudFront..."
echo "  Origin: $ORIGIN_DOMAIN"

DIST_CONFIG=$(cat << EOF
{
  "CallerReference": "portfolio-6324696-$(date +%s)",
  "Comment": "$COMMENT",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-website-origin",
        "DomainName": "$ORIGIN_DOMAIN",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-website-origin",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {"Forward": "none"}
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000
  },
  "CacheBehaviors": {
    "Quantity": 2,
    "Items": [
      {
        "PathPattern": "*.html",
        "TargetOriginId": "S3-website-origin",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"],
          "CachedMethods": {"Quantity": 2, "Items": ["GET", "HEAD"]}
        },
        "Compress": true,
        "ForwardedValues": {"QueryString": false, "Cookies": {"Forward": "none"}},
        "MinTTL": 0,
        "DefaultTTL": 0,
        "MaxTTL": 300
      },
      {
        "PathPattern": "images/*",
        "TargetOriginId": "S3-website-origin",
        "ViewerProtocolPolicy": "redirect-to-https",
        "AllowedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"],
          "CachedMethods": {"Quantity": 2, "Items": ["GET", "HEAD"]}
        },
        "Compress": true,
        "ForwardedValues": {"QueryString": false, "Cookies": {"Forward": "none"}},
        "MinTTL": 0,
        "DefaultTTL": 604800,
        "MaxTTL": 31536000
      }
    ]
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/404.html",
        "ResponseCode": "404",
        "ErrorCachingMinTTL": 10
      }
    ]
  },
  "PriceClass": "PriceClass_100",
  "Enabled": true,
  "HttpVersion": "http2and3",
  "IsIPV6Enabled": true,
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true,
    "MinimumProtocolVersion": "TLSv1.2_2021"
  },
  "Restrictions": {
    "GeoRestriction": {
      "RestrictionType": "none",
      "Quantity": 0
    }
  }
}
EOF
)

DIST_OUTPUT=$(aws cloudfront create-distribution \
  --distribution-config "$DIST_CONFIG" \
  --region "$REGION" \
  --output json)

DIST_ID=$(echo "$DIST_OUTPUT"     | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Distribution']['Id'])")
DIST_DOMAIN=$(echo "$DIST_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Distribution']['DomainName'])")

echo "  ✓ Distribuição criada!"
echo "  ID     : $DIST_ID"
echo "  Domínio: $DIST_DOMAIN"

# ----------------------------
# 2. Salvar variáveis para uso posterior
# ----------------------------
echo ""
echo "[2/3] Salvando configurações em .env.deploy..."
cat > "$(dirname "$0")/.env.deploy" << ENVFILE
DIST_ID=$DIST_ID
DIST_DOMAIN=$DIST_DOMAIN
WEBSITE_BUCKET=$WEBSITE_BUCKET
REGION=$REGION
ENVFILE
echo "  ✓ .env.deploy criado."

# ----------------------------
# 3. Upload do website
# ----------------------------
echo ""
echo "[3/3] Fazendo upload dos arquivos do website para S3..."
WEBSITE_DIR="$(dirname "$0")/../website"
aws s3 sync "$WEBSITE_DIR" "s3://$WEBSITE_BUCKET" \
  --delete \
  --exclude ".DS_Store" \
  --exclude "*.map" \
  --cache-control "public,max-age=86400" \
  --metadata-directive REPLACE

# HTML sem cache longo
aws s3 cp "$WEBSITE_DIR/index.html"      "s3://$WEBSITE_BUCKET/index.html"      --cache-control "no-cache,no-store,must-revalidate" --content-type "text/html; charset=utf-8"
aws s3 cp "$WEBSITE_DIR/projetos.html"   "s3://$WEBSITE_BUCKET/projetos.html"   --cache-control "no-cache,no-store,must-revalidate" --content-type "text/html; charset=utf-8"
aws s3 cp "$WEBSITE_DIR/experiencia.html" "s3://$WEBSITE_BUCKET/experiencia.html" --cache-control "no-cache,no-store,must-revalidate" --content-type "text/html; charset=utf-8"
aws s3 cp "$WEBSITE_DIR/contato.html"    "s3://$WEBSITE_BUCKET/contato.html"    --cache-control "no-cache,no-store,must-revalidate" --content-type "text/html; charset=utf-8"
aws s3 cp "$WEBSITE_DIR/404.html"        "s3://$WEBSITE_BUCKET/404.html"        --cache-control "no-cache" --content-type "text/html; charset=utf-8"

echo "  ✓ Upload concluído."

echo ""
echo "======================================"
echo " ✅ CloudFront configurado com sucesso!"
echo "======================================"
echo " URL CloudFront : https://$DIST_DOMAIN"
echo " URL S3 direto  : http://${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"
echo ""
echo " ⚠️  A distribuição leva ~15min para propagar globalmente."
echo " ⚠️  Use 'aws cloudfront wait distribution-deployed --id $DIST_ID' para aguardar."
echo ""
echo " Próximo passo: execute a lambda (pasta lambda/) e registre as URLs nos arquivos JS."
echo "======================================"
