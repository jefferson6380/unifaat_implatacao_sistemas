#!/usr/bin/env bash
# TF10 - Cria snapshot manual nomeado da instância RDS.
# Uso: bash snapshot.sh [<sufixo>]

set -euo pipefail

: "${AWS_REGION:=us-east-1}"
: "${DB_INSTANCE_ID:=northwind-rds}"

SUFFIX="${1:-$(date +%Y%m%d-%H%M%S)}"
SNAP_ID="tf10-northwind-${SUFFIX}"

echo "==> Criando snapshot manual: $SNAP_ID"
aws rds create-db-snapshot --region "$AWS_REGION" \
  --db-instance-identifier "$DB_INSTANCE_ID" \
  --db-snapshot-identifier "$SNAP_ID" \
  --tags Key=Project,Value=TF10 Key=RA,Value=6324598 >/dev/null

echo "==> Aguardando snapshot ficar 'available'..."
aws rds wait db-snapshot-available --region "$AWS_REGION" \
  --db-snapshot-identifier "$SNAP_ID"

aws rds describe-db-snapshots --region "$AWS_REGION" \
  --db-snapshot-identifier "$SNAP_ID" \
  --query 'DBSnapshots[0].{Id:DBSnapshotIdentifier,Status:Status,Size:AllocatedStorage,Created:SnapshotCreateTime}'

echo "==> Snapshot pronto. Identificador: $SNAP_ID"
