#!/usr/bin/env bash
# Cria distribuição CloudFront para o portfólio

set -euo pipefail

RA="${RA:-6324548}"
REGION="${AWS_REGION:-us-east-1}"
WEBSITE_BUCKET="portfolio-website-${RA}"
CALLER_REF="portfolio-${RA}-$(date +%s)"

echo "==> Configurando CloudFront para bucket: ${WEBSITE_BUCKET}"

# ── Criar Origin Access Control (OAC) ─────────────────────
echo "==> Criando Origin Access Control..."
OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config "{
    \"Name\": \"oac-portfolio-${RA}\",
    \"Description\": \"OAC para portfólio ${RA}\",
    \"SigningProtocol\": \"sigv4\",
    \"SigningBehavior\": \"always\",
    \"OriginAccessControlOriginType\": \"s3\"
  }" \
  --query 'OriginAccessControl.Id' \
  --output text)

echo "==> OAC criado: ${OAC_ID}"

# ── Criar distribuição CloudFront ─────────────────────────
echo "==> Criando distribuição CloudFront..."

DISTRIBUTION=$(aws cloudfront create-distribution \
  --distribution-config "{
    \"CallerReference\": \"${CALLER_REF}\",
    \"Comment\": \"Portfólio Luiz Felipe Souza RA ${RA}\",
    \"DefaultRootObject\": \"index.html\",
    \"Origins\": {
      \"Quantity\": 1,
      \"Items\": [
        {
          \"Id\": \"S3-${WEBSITE_BUCKET}\",
          \"DomainName\": \"${WEBSITE_BUCKET}.s3.${REGION}.amazonaws.com\",
          \"S3OriginConfig\": {
            \"OriginAccessIdentity\": \"\"
          },
          \"OriginAccessControlId\": \"${OAC_ID}\"
        }
      ]
    },
    \"DefaultCacheBehavior\": {
      \"TargetOriginId\": \"S3-${WEBSITE_BUCKET}\",
      \"ViewerProtocolPolicy\": \"redirect-to-https\",
      \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
      \"Compress\": true,
      \"AllowedMethods\": {
        \"Quantity\": 2,
        \"Items\": [\"GET\", \"HEAD\"],
        \"CachedMethods\": {
          \"Quantity\": 2,
          \"Items\": [\"GET\", \"HEAD\"]
        }
      }
    },
    \"CacheBehaviors\": {
      \"Quantity\": 2,
      \"Items\": [
        {
          \"PathPattern\": \"*.css\",
          \"TargetOriginId\": \"S3-${WEBSITE_BUCKET}\",
          \"ViewerProtocolPolicy\": \"redirect-to-https\",
          \"CachePolicyId\": \"4135ea2d-6df8-44a3-9df3-4b5a84be39ad\",
          \"Compress\": true,
          \"AllowedMethods\": {
            \"Quantity\": 2,
            \"Items\": [\"GET\", \"HEAD\"],
            \"CachedMethods\": {
              \"Quantity\": 2,
              \"Items\": [\"GET\", \"HEAD\"]
            }
          }
        },
        {
          \"PathPattern\": \"*.js\",
          \"TargetOriginId\": \"S3-${WEBSITE_BUCKET}\",
          \"ViewerProtocolPolicy\": \"redirect-to-https\",
          \"CachePolicyId\": \"4135ea2d-6df8-44a3-9df3-4b5a84be39ad\",
          \"Compress\": true,
          \"AllowedMethods\": {
            \"Quantity\": 2,
            \"Items\": [\"GET\", \"HEAD\"],
            \"CachedMethods\": {
              \"Quantity\": 2,
              \"Items\": [\"GET\", \"HEAD\"]
            }
          }
        }
      ]
    },
    \"CustomErrorResponses\": {
      \"Quantity\": 1,
      \"Items\": [
        {
          \"ErrorCode\": 404,
          \"ResponsePagePath\": \"/404.html\",
          \"ResponseCode\": \"404\",
          \"ErrorCachingMinTTL\": 60
        }
      ]
    },
    \"Enabled\": true,
    \"HttpVersion\": \"http2and3\",
    \"PriceClass\": \"PriceClass_100\"
  }")

CF_DOMAIN=$(echo "${DISTRIBUTION}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Distribution']['DomainName'])")
CF_ID=$(echo "${DISTRIBUTION}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['Distribution']['Id'])")

echo ""
echo "✅ CloudFront configurado!"
echo "   Distribution ID : ${CF_ID}"
echo "   Domain          : https://${CF_DOMAIN}"
echo "   OAC ID          : ${OAC_ID}"
echo ""
echo "⏳ Deploy leva ~15 minutos para propagar globalmente."
echo ""
echo "Próximos passos:"
echo "  1. Execute: CF_DISTRIBUTION_ID=${CF_ID} bash configure-policies.sh"
echo "  2. Acesse: https://${CF_DOMAIN}"
echo ""
echo "Salve estas informações:"
echo "  export CF_DISTRIBUTION_ID=${CF_ID}"
echo "  export CF_DOMAIN=${CF_DOMAIN}"
