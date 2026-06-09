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
: "${ASSETS_BUCKET:?ASSETS_BUCKET obrigatorio}"

create_bucket() {
  local bucket="$1"

  if aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
    echo "Bucket ja existe: $bucket"
    return 0
  fi

  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "$bucket"
  else
    aws s3api create-bucket \
      --bucket "$bucket" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION"
  fi

  echo "Bucket criado: $bucket"
}

create_bucket "$WEBSITE_BUCKET"
create_bucket "$ASSETS_BUCKET"

aws s3api put-bucket-versioning \
  --bucket "$WEBSITE_BUCKET" \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-versioning \
  --bucket "$ASSETS_BUCKET" \
  --versioning-configuration Status=Enabled

aws s3 website "s3://$WEBSITE_BUCKET" \
  --index-document index.html \
  --error-document error.html

LIFECYCLE_FILE="$(mktemp)"
cat > "$LIFECYCLE_FILE" << JSON
{
  "Rules": [
    {
      "ID": "move-old-assets-to-ia",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "uploads/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        }
      ],
      "NoncurrentVersionTransitions": [
        {
          "NoncurrentDays": 30,
          "StorageClass": "STANDARD_IA"
        }
      ]
    }
  ]
}
JSON

aws s3api put-bucket-lifecycle-configuration \
  --bucket "$ASSETS_BUCKET" \
  --lifecycle-configuration "file://$LIFECYCLE_FILE"

rm -f "$LIFECYCLE_FILE"

echo "Buckets configurados com sucesso."
echo "Website endpoint: http://$WEBSITE_BUCKET.s3-website-$AWS_REGION.amazonaws.com"
