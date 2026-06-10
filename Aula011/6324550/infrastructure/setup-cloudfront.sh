#!/bin/bash
# setup-cloudfront.sh
# Autor: Bruno Pereira dos Santos - RA 6324550
# Descrição: Cria e configura distribuição CloudFront para o portfólio

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carregar variáveis do script anterior
if [ -f "$SCRIPT_DIR/.env.infra" ]; then
  source "$SCRIPT_DIR/.env.infra"
else
  echo "ERRO: Execute create-buckets.sh primeiro."
  exit 1
fi

echo "======================================"
echo " Configurando CloudFront"
echo " Aluno: Bruno Pereira dos Santos"
echo " RA: 6324550"
echo "======================================"

ORIGIN_DOMAIN="${WEBSITE_BUCKET}.s3-website-${REGION}.amazonaws.com"
CALLER_REF="portfolio-6324550-$(date +%s)"

echo "[1/3] Criando distribuição CloudFront..."

DISTRIBUTION=$(aws cloudfront create-distribution --distribution-config "{
  \"CallerReference\": \"$CALLER_REF\",
  \"Comment\": \"Portfolio Bruno Pereira dos Santos - RA 6324550\",
  \"DefaultRootObject\": \"index.html\",
  \"Origins\": {
    \"Quantity\": 1,
    \"Items\": [{
      \"Id\": \"S3-${WEBSITE_BUCKET}\",
      \"DomainName\": \"$ORIGIN_DOMAIN\",
      \"CustomOriginConfig\": {
        \"HTTPPort\": 80,
        \"HTTPSPort\": 443,
        \"OriginProtocolPolicy\": \"http-only\"
      }
    }]
  },
  \"DefaultCacheBehavior\": {
    \"TargetOriginId\": \"S3-${WEBSITE_BUCKET}\",
    \"ViewerProtocolPolicy\": \"redirect-to-https\",
    \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
    \"Compress\": true,
    \"AllowedMethods\": {
      \"Quantity\": 2,
      \"Items\": [\"GET\", \"HEAD\"],
      \"CachedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"]}
    }
  },
  \"CacheBehaviors\": {
    \"Quantity\": 2,
    \"Items\": [
      {
        \"PathPattern\": \"*.html\",
        \"TargetOriginId\": \"S3-${WEBSITE_BUCKET}\",
        \"ViewerProtocolPolicy\": \"redirect-to-https\",
        \"CachePolicyId\": \"4135ea2d-6df8-44a3-9df3-4b5a84be39ad\",
        \"Compress\": true,
        \"AllowedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"], \"CachedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"]}}
      },
      {
        \"PathPattern\": \"/images/*\",
        \"TargetOriginId\": \"S3-${WEBSITE_BUCKET}\",
        \"ViewerProtocolPolicy\": \"redirect-to-https\",
        \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
        \"Compress\": true,
        \"AllowedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"], \"CachedMethods\": {\"Quantity\": 2, \"Items\": [\"GET\", \"HEAD\"]}}
      }
    ]
  },
  \"CustomErrorResponses\": {
    \"Quantity\": 1,
    \"Items\": [{
      \"ErrorCode\": 404,
      \"ResponsePagePath\": \"/error.html\",
      \"ResponseCode\": \"404\",
      \"ErrorCachingMinTTL\": 300
    }]
  },
  \"Enabled\": true,
  \"HttpVersion\": \"http2and3\",
  \"IsIPV6Enabled\": true,
  \"PriceClass\": \"PriceClass_100\"
}")

DISTRIBUTION_ID=$(echo "$DISTRIBUTION" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Distribution']['Id'])")
CLOUDFRONT_DOMAIN=$(echo "$DISTRIBUTION" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Distribution']['DomainName'])")

echo "  Distribuição criada: $DISTRIBUTION_ID"
echo "  Domínio: $CLOUDFRONT_DOMAIN"

echo "[2/3] Aguardando distribuição ser implantada (pode levar 5-15 min)..."
echo "  Use: aws cloudfront wait distribution-deployed --id $DISTRIBUTION_ID"

echo "[3/3] Atualizando variáveis de ambiente..."
cat >> "$SCRIPT_DIR/.env.infra" << EOF
DISTRIBUTION_ID=$DISTRIBUTION_ID
CLOUDFRONT_DOMAIN=$CLOUDFRONT_DOMAIN
CLOUDFRONT_URL=https://$CLOUDFRONT_DOMAIN
EOF

echo ""
echo "======================================"
echo " CloudFront configurado!"
echo "======================================"
echo " Distribution ID : $DISTRIBUTION_ID"
echo " Website URL     : https://$CLOUDFRONT_DOMAIN"
echo ""
echo " ATENÇÃO: O deploy pode levar até 15 minutos."
echo " Próximo passo: execute configure-policies.sh"
echo "======================================"
