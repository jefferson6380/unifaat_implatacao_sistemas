#!/bin/bash
# setup-cloudfront.sh - Cria distribuição CloudFront para o portfólio

set -euo pipefail

BUCKET_WEBSITE="portfolio-gabriel-santiago-www"
REGION="us-east-1"

# ── 1. CRIAR ORIGIN ACCESS CONTROL ─────────────────────────────
echo "▶ Criando Origin Access Control (OAC)"
OAC_ID=$(aws cloudfront create-origin-access-control \
  --origin-access-control-config "{
    \"Name\": \"OAC-Portfolio\",
    \"Description\": \"OAC para portfolio S3\",
    \"SigningProtocol\": \"sigv4\",
    \"SigningBehavior\": \"always\",
    \"OriginAccessControlOriginType\": \"s3\"
  }" \
  --query 'OriginAccessControl.Id' --output text)

echo "   OAC ID: $OAC_ID"

# ── 2. CRIAR DISTRIBUIÇÃO CLOUDFRONT ───────────────────────────
echo "▶ Criando distribuição CloudFront"

DISTRIBUTION_ID=$(aws cloudfront create-distribution \
  --distribution-config "{
    \"CallerReference\": \"portfolio-$(date +%s)\",
    \"Comment\": \"Portfólio Gabriel Santiago\",
    \"Enabled\": true,
    \"DefaultRootObject\": \"index.html\",
    \"Origins\": {
      \"Quantity\": 1,
      \"Items\": [{
        \"Id\": \"S3-Portfolio\",
        \"DomainName\": \"${BUCKET_WEBSITE}.s3.${REGION}.amazonaws.com\",
        \"OriginAccessControlId\": \"${OAC_ID}\",
        \"S3OriginConfig\": { \"OriginAccessIdentity\": \"\" }
      }]
    },
    \"DefaultCacheBehavior\": {
      \"TargetOriginId\": \"S3-Portfolio\",
      \"ViewerProtocolPolicy\": \"redirect-to-https\",
      \"Compress\": true,
      \"CachePolicyId\": \"658327ea-f89d-4fab-a63d-7e88639e58f6\",
      \"AllowedMethods\": {
        \"Quantity\": 2,
        \"Items\": [\"GET\", \"HEAD\"]
      },
      \"ResponseHeadersPolicyId\": \"67f7725c-6f97-4210-82d7-5512b31e9d03\"
    },
    \"CustomErrorResponses\": {
      \"Quantity\": 1,
      \"Items\": [{
        \"ErrorCode\": 404,
        \"ResponsePagePath\": \"/error.html\",
        \"ResponseCode\": \"404\",
        \"ErrorCachingMinTTL\": 60
      }]
    },
    \"PriceClass\": \"PriceClass_All\",
    \"HttpVersion\": \"http2and3\"
  }" \
  --query 'Distribution.Id' --output text)

echo "   Distribution ID: $DISTRIBUTION_ID"

# ── 3. DOMÍNIO CLOUDFRONT ───────────────────────────────────────
CF_DOMAIN=$(aws cloudfront get-distribution \
  --id "$DISTRIBUTION_ID" \
  --query 'Distribution.DomainName' --output text)

# ── 4. ATUALIZAR BUCKET POLICY ──────────────────────────────────
echo "▶ Atualizando bucket policy para permitir CloudFront"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws s3api put-bucket-policy \
  --bucket "$BUCKET_WEBSITE" \
  --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
      \"Sid\": \"AllowCloudFrontOAC\",
      \"Effect\": \"Allow\",
      \"Principal\": {
        \"Service\": \"cloudfront.amazonaws.com\"
      },
      \"Action\": \"s3:GetObject\",
      \"Resource\": \"arn:aws:s3:::${BUCKET_WEBSITE}/*\",
      \"Condition\": {
        \"StringEquals\": {
          \"AWS:SourceArn\": \"arn:aws:cloudfront::${ACCOUNT_ID}:distribution/${DISTRIBUTION_ID}\"
        }
      }
    }]
  }"

echo ""
echo "✅ CloudFront configurado com sucesso!"
echo "   Distribution ID : $DISTRIBUTION_ID"
echo "   Domínio         : https://$CF_DOMAIN"
echo ""
echo "⏳ A distribuição leva ~15 minutos para propagar globalmente."
