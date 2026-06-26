#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$BASE_DIR/infrastructure/vars.sh" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/infrastructure/vars.sh"
elif [[ -f "$BASE_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/.env"
else
  echo "Arquivo de variaveis nao encontrado. Use infrastructure/vars.example.sh"
  exit 1
fi

: "${AWS_REGION:?AWS_REGION obrigatorio}"
: "${WEBSITE_BUCKET:?WEBSITE_BUCKET obrigatorio}"

CALLER_REF="tf11-6324064-$(date +%s)"
WEBSITE_ENDPOINT="$WEBSITE_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
PRICE_CLASS="${CLOUDFRONT_PRICE_CLASS:-PriceClass_100}"

DIST_CONFIG_FILE="$(mktemp)"

if [[ -n "${ACM_CERT_ARN:-}" && -n "${ALIAS_DOMAIN:-}" ]]; then
cat > "$DIST_CONFIG_FILE" << JSON
{
  "CallerReference": "$CALLER_REF",
  "Comment": "TF11 RA 6324064",
  "Enabled": true,
  "PriceClass": "$PRICE_CLASS",
  "DefaultRootObject": "index.html",
  "Aliases": {
    "Quantity": 1,
    "Items": ["$ALIAS_DOMAIN"]
  },
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "s3-website-origin",
        "DomainName": "$WEBSITE_ENDPOINT",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "s3-website-origin",
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
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "ResponseHeadersPolicyId": "67f7725c-6f97-4210-82d7-5512b31e9d03"
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/error.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": false,
    "ACMCertificateArn": "$ACM_CERT_ARN",
    "SSLSupportMethod": "sni-only",
    "MinimumProtocolVersion": "TLSv1.2_2021"
  }
}
JSON
else
cat > "$DIST_CONFIG_FILE" << JSON
{
  "CallerReference": "$CALLER_REF",
  "Comment": "TF11 RA 6324064",
  "Enabled": true,
  "PriceClass": "$PRICE_CLASS",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "s3-website-origin",
        "DomainName": "$WEBSITE_ENDPOINT",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "s3-website-origin",
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
    "CachePolicyId": "658327ea-f89d-4fab-a63d-7e88639e58f6",
    "ResponseHeadersPolicyId": "67f7725c-6f97-4210-82d7-5512b31e9d03"
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/error.html",
        "ResponseCode": "200",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true
  }
}
JSON
fi

read -r DIST_ID DIST_DOMAIN <<< "$(aws cloudfront create-distribution \
  --distribution-config "file://$DIST_CONFIG_FILE" \
  --query 'Distribution.[Id,DomainName]' \
  --output text)"

rm -f "$DIST_CONFIG_FILE"

cat > "$BASE_DIR/infrastructure/cloudfront-output.env" << EOF
DISTRIBUTION_ID=$DIST_ID
DISTRIBUTION_DOMAIN=$DIST_DOMAIN
EOF

echo "CloudFront criado."
echo "Distribution ID: $DIST_ID"
echo "Domain: https://$DIST_DOMAIN"
echo "Salvo em infrastructure/cloudfront-output.env"
