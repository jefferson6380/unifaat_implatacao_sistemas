#!/usr/bin/env bash
set -euo pipefail

export AWS_REGION="us-east-1"
export WEBSITE_BUCKET="tf11-6324064-website"
export ASSETS_BUCKET="tf11-6324064-assets"

# PriceClass_100 = menor custo; PriceClass_200 = intermedio; PriceClass_All = global
export CLOUDFRONT_PRICE_CLASS="PriceClass_100"

# Opcional: ACM em us-east-1 para dominio custom
export ACM_CERT_ARN=""

# Opcional: dominio alternativo
export ALIAS_DOMAIN=""

# APIs opcionais
export CONTACT_API_URL=""
export UPLOAD_API_URL=""
export GALLERY_API_URL=""
