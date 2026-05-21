#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

resolve_aws_cmd() {
  if command -v aws >/dev/null 2>&1; then
    command -v aws
    return 0
  fi

  local candidates=(
    "/c/Program Files/Amazon/AWSCLIV2/aws.exe"
    "/c/Program Files/Amazon/AWSCLI/bin/aws.exe"
  )

  local aws_path
  for aws_path in "${candidates[@]}"; do
    if [[ -x "${aws_path}" ]]; then
      echo "${aws_path}"
      return 0
    fi
  done

  return 1
}

require_var() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    echo "Variavel obrigatoria ausente: ${var_name}" >&2
    exit 1
  fi
}

AWS_CMD="$(resolve_aws_cmd || true)"

if [[ -z "${AWS_CMD}" ]]; then
  echo "AWS CLI nao encontrada. Instale e configure antes de continuar." >&2
  exit 1
fi

AWS_REGION="${AWS_REGION:-us-east-1}"
DB_INSTANCE_IDENTIFIER="${DB_INSTANCE_IDENTIFIER:-}"
DB_ENGINE="${DB_ENGINE:-postgres}"
DB_ENGINE_VERSION="${DB_ENGINE_VERSION:-16.3}"
DB_INSTANCE_CLASS="${DB_INSTANCE_CLASS:-db.t3.micro}"
DB_ALLOCATED_STORAGE="${DB_ALLOCATED_STORAGE:-20}"
DB_STORAGE_TYPE="${DB_STORAGE_TYPE:-gp3}"
DB_NAME="${DB_NAME:-}"
DB_MASTER_USERNAME="${DB_MASTER_USERNAME:-}"
DB_MASTER_PASSWORD="${DB_MASTER_PASSWORD:-}"
DB_PORT="${DB_PORT:-5432}"
DB_SUBNET_GROUP_NAME="${DB_SUBNET_GROUP_NAME:-}"
DB_VPC_SECURITY_GROUP_IDS="${DB_VPC_SECURITY_GROUP_IDS:-}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
MULTI_AZ="${MULTI_AZ:-true}"
PUBLICLY_ACCESSIBLE="${PUBLICLY_ACCESSIBLE:-false}"
DELETION_PROTECTION="${DELETION_PROTECTION:-false}"
PERFORMANCE_INSIGHTS_ENABLED="${PERFORMANCE_INSIGHTS_ENABLED:-true}"
WAIT_FOR_AVAILABLE="${WAIT_FOR_AVAILABLE:-true}"
TAG_OWNER="${TAG_OWNER:-aluno}"
TAG_PROJECT="${TAG_PROJECT:-tf10-rds-migration}"

require_var "DB_INSTANCE_IDENTIFIER"
require_var "DB_NAME"
require_var "DB_MASTER_USERNAME"
require_var "DB_MASTER_PASSWORD"
require_var "DB_SUBNET_GROUP_NAME"
require_var "DB_VPC_SECURITY_GROUP_IDS"

if "${AWS_CMD}" rds describe-db-instances \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" >/dev/null 2>&1; then
  echo "Instancia ${DB_INSTANCE_IDENTIFIER} ja existe. Nada a fazer."
  exit 0
fi

IFS=',' read -r -a SG_ARRAY <<< "${DB_VPC_SECURITY_GROUP_IDS}"

CREATE_CMD=(
  rds create-db-instance
  --region "${AWS_REGION}"
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}"
  --engine "${DB_ENGINE}"
  --engine-version "${DB_ENGINE_VERSION}"
  --db-instance-class "${DB_INSTANCE_CLASS}"
  --allocated-storage "${DB_ALLOCATED_STORAGE}"
  --storage-type "${DB_STORAGE_TYPE}"
  --db-name "${DB_NAME}"
  --master-username "${DB_MASTER_USERNAME}"
  --master-user-password "${DB_MASTER_PASSWORD}"
  --port "${DB_PORT}"
  --backup-retention-period "${BACKUP_RETENTION_DAYS}"
  --db-subnet-group-name "${DB_SUBNET_GROUP_NAME}"
  --vpc-security-group-ids
)

for sg_id in "${SG_ARRAY[@]}"; do
  CREATE_CMD+=("${sg_id}")
done

if [[ "${MULTI_AZ}" == "true" ]]; then
  CREATE_CMD+=(--multi-az)
else
  CREATE_CMD+=(--no-multi-az)
fi

if [[ "${PUBLICLY_ACCESSIBLE}" == "true" ]]; then
  CREATE_CMD+=(--publicly-accessible)
else
  CREATE_CMD+=(--no-publicly-accessible)
fi

if [[ "${DELETION_PROTECTION}" == "true" ]]; then
  CREATE_CMD+=(--deletion-protection)
else
  CREATE_CMD+=(--no-deletion-protection)
fi

if [[ "${PERFORMANCE_INSIGHTS_ENABLED}" == "true" ]]; then
  CREATE_CMD+=(--enable-performance-insights)
else
  CREATE_CMD+=(--no-enable-performance-insights)
fi

CREATE_CMD+=(
  --tags "Key=Owner,Value=${TAG_OWNER}" "Key=Project,Value=${TAG_PROJECT}" "Key=Environment,Value=academico"
)

echo "Criando instancia RDS ${DB_INSTANCE_IDENTIFIER} em ${AWS_REGION}..."
"${AWS_CMD}" "${CREATE_CMD[@]}"

if [[ "${WAIT_FOR_AVAILABLE}" == "true" ]]; then
  echo "Aguardando instancia ficar disponivel..."
  "${AWS_CMD}" rds wait db-instance-available \
    --region "${AWS_REGION}" \
    --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}"
fi

DB_ENDPOINT="$("${AWS_CMD}" rds describe-db-instances \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
  --query "DBInstances[0].Endpoint.Address" \
  --output text)"

echo "Instancia criada com sucesso."
echo "Endpoint: ${DB_ENDPOINT}:${DB_PORT}"
