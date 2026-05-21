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
  echo "AWS CLI nao encontrada." >&2
  exit 1
fi

AWS_REGION="${AWS_REGION:-us-east-1}"
DB_INSTANCE_IDENTIFIER="${DB_INSTANCE_IDENTIFIER:-}"
SKIP_FINAL_SNAPSHOT="${SKIP_FINAL_SNAPSHOT:-false}"
DELETE_AUTOMATED_BACKUPS="${DELETE_AUTOMATED_BACKUPS:-true}"
WAIT_FOR_DELETE="${WAIT_FOR_DELETE:-true}"

DELETE_SUBNET_GROUP="${DELETE_SUBNET_GROUP:-false}"
DB_SUBNET_GROUP_NAME="${DB_SUBNET_GROUP_NAME:-}"

DELETE_SECURITY_GROUPS="${DELETE_SECURITY_GROUPS:-false}"
DB_VPC_SECURITY_GROUP_IDS="${DB_VPC_SECURITY_GROUP_IDS:-}"

require_var "DB_INSTANCE_IDENTIFIER"

if ! "${AWS_CMD}" rds describe-db-instances \
  --region "${AWS_REGION}" \
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" >/dev/null 2>&1; then
  echo "Instancia ${DB_INSTANCE_IDENTIFIER} nao encontrada. Nada a remover."
  exit 0
fi

DELETE_CMD=(
  rds delete-db-instance
  --region "${AWS_REGION}"
  --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}"
)

if [[ "${SKIP_FINAL_SNAPSHOT}" == "true" ]]; then
  DELETE_CMD+=(--skip-final-snapshot)
else
  FINAL_SNAPSHOT_IDENTIFIER="${FINAL_SNAPSHOT_IDENTIFIER:-${DB_INSTANCE_IDENTIFIER}-final-$(date +%Y%m%d%H%M%S)}"
  DELETE_CMD+=(--final-db-snapshot-identifier "${FINAL_SNAPSHOT_IDENTIFIER}")
fi

if [[ "${DELETE_AUTOMATED_BACKUPS}" == "true" ]]; then
  DELETE_CMD+=(--delete-automated-backups)
else
  DELETE_CMD+=(--no-delete-automated-backups)
fi

echo "Removendo instancia ${DB_INSTANCE_IDENTIFIER}..."
"${AWS_CMD}" "${DELETE_CMD[@]}"

if [[ "${WAIT_FOR_DELETE}" == "true" ]]; then
  echo "Aguardando exclusao da instancia..."
  "${AWS_CMD}" rds wait db-instance-deleted \
    --region "${AWS_REGION}" \
    --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}"
fi

if [[ "${DELETE_SUBNET_GROUP}" == "true" && -n "${DB_SUBNET_GROUP_NAME}" ]]; then
  echo "Tentando remover DB Subnet Group ${DB_SUBNET_GROUP_NAME}..."
  "${AWS_CMD}" rds delete-db-subnet-group \
    --region "${AWS_REGION}" \
    --db-subnet-group-name "${DB_SUBNET_GROUP_NAME}" || true
fi

if [[ "${DELETE_SECURITY_GROUPS}" == "true" && -n "${DB_VPC_SECURITY_GROUP_IDS}" ]]; then
  IFS=',' read -r -a SG_ARRAY <<< "${DB_VPC_SECURITY_GROUP_IDS}"
  for sg_id in "${SG_ARRAY[@]}"; do
    echo "Tentando remover Security Group ${sg_id}..."
    "${AWS_CMD}" ec2 delete-security-group \
      --region "${AWS_REGION}" \
      --group-id "${sg_id}" || true
  done
fi

echo "Limpeza concluida."
