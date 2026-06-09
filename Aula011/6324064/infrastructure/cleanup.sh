#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -f "$BASE_DIR/infrastructure/vars.sh" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/infrastructure/vars.sh"
elif [[ -f "$BASE_DIR/.env" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/.env"
fi

if [[ -f "$BASE_DIR/infrastructure/cloudfront-output.env" ]]; then
  # shellcheck disable=SC1091
  source "$BASE_DIR/infrastructure/cloudfront-output.env"
fi

DISTRIBUTION_ID="${DISTRIBUTION_ID:-${1:-}}"

empty_and_delete_bucket() {
  local bucket="$1"
  if [[ -z "$bucket" ]]; then
    return
  fi

  echo "Esvaziando bucket: $bucket"
  aws s3 rm "s3://$bucket" --recursive || true
  aws s3api delete-bucket --bucket "$bucket" || true
}

if [[ -n "$DISTRIBUTION_ID" ]]; then
  echo "Iniciando limpeza do CloudFront: $DISTRIBUTION_ID"

  CFG_FILE="$(mktemp)"
  CFG_DISABLED_FILE="$(mktemp)"

  E_TAG="$(aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" --query 'ETag' --output text)"
  aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" --query 'DistributionConfig' --output json > "$CFG_FILE"

  sed 's/"Enabled": true/"Enabled": false/' "$CFG_FILE" > "$CFG_DISABLED_FILE"

  aws cloudfront update-distribution \
    --id "$DISTRIBUTION_ID" \
    --if-match "$E_TAG" \
    --distribution-config "file://$CFG_DISABLED_FILE" >/dev/null

  echo "Aguardando distribuicao ser aplicada para remover..."
  aws cloudfront wait distribution-deployed --id "$DISTRIBUTION_ID"

  E_TAG2="$(aws cloudfront get-distribution-config --id "$DISTRIBUTION_ID" --query 'ETag' --output text)"
  aws cloudfront delete-distribution --id "$DISTRIBUTION_ID" --if-match "$E_TAG2"

  rm -f "$CFG_FILE" "$CFG_DISABLED_FILE"
fi

empty_and_delete_bucket "${WEBSITE_BUCKET:-}"
empty_and_delete_bucket "${ASSETS_BUCKET:-}"

echo "Cleanup finalizado."
