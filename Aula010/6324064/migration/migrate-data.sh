#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

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

resolve_pg_tool() {
  local tool_name="$1"

  if command -v "${tool_name}" >/dev/null 2>&1; then
    command -v "${tool_name}"
    return 0
  fi

  local candidates=(
    "/c/Program Files/PostgreSQL/18/bin/${tool_name}.exe"
    "/c/Program Files/PostgreSQL/17/bin/${tool_name}.exe"
    "/c/Program Files/PostgreSQL/16/bin/${tool_name}.exe"
    "/c/Program Files/PostgreSQL/15/bin/${tool_name}.exe"
    "/c/Program Files/PostgreSQL/14/bin/${tool_name}.exe"
  )

  local tool_path
  for tool_path in "${candidates[@]}"; do
    if [[ -x "${tool_path}" ]]; then
      echo "${tool_path}"
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

PG_DUMP_CMD="$(resolve_pg_tool pg_dump || true)"
PSQL_CMD="$(resolve_pg_tool psql || true)"

if [[ -z "${PG_DUMP_CMD}" ]]; then
  echo "Comando obrigatorio nao encontrado: pg_dump" >&2
  exit 1
fi

if [[ -z "${PSQL_CMD}" ]]; then
  echo "Comando obrigatorio nao encontrado: psql" >&2
  exit 1
fi

AWS_CMD="$(resolve_aws_cmd || true)"

AWS_REGION="${AWS_REGION:-us-east-1}"
DB_INSTANCE_IDENTIFIER="${DB_INSTANCE_IDENTIFIER:-}"

LOCAL_DB_HOST="${LOCAL_DB_HOST:-localhost}"
LOCAL_DB_PORT="${LOCAL_DB_PORT:-5432}"
LOCAL_DB_NAME="${LOCAL_DB_NAME:-}"
LOCAL_DB_USER="${LOCAL_DB_USER:-}"
LOCAL_DB_PASSWORD="${LOCAL_DB_PASSWORD:-}"

RDS_ENDPOINT="${RDS_ENDPOINT:-}"
RDS_DB_PORT="${RDS_DB_PORT:-5432}"
RDS_DB_NAME="${RDS_DB_NAME:-${DB_NAME:-}}"
RDS_DB_USER="${RDS_DB_USER:-${DB_MASTER_USERNAME:-}}"
RDS_DB_PASSWORD="${RDS_DB_PASSWORD:-${DB_MASTER_PASSWORD:-}}"
RDS_SSLMODE="${RDS_SSLMODE:-require}"

require_var "LOCAL_DB_NAME"
require_var "LOCAL_DB_USER"
require_var "LOCAL_DB_PASSWORD"
require_var "RDS_DB_NAME"
require_var "RDS_DB_USER"
require_var "RDS_DB_PASSWORD"

if [[ -z "${RDS_ENDPOINT}" ]]; then
  require_var "DB_INSTANCE_IDENTIFIER"
  if [[ -z "${AWS_CMD}" ]]; then
    echo "AWS CLI nao encontrada para descobrir RDS_ENDPOINT automaticamente." >&2
    echo "Defina RDS_ENDPOINT no .env e tente novamente." >&2
    exit 1
  fi

  RDS_ENDPOINT="$("${AWS_CMD}" rds describe-db-instances \
    --region "${AWS_REGION}" \
    --db-instance-identifier "${DB_INSTANCE_IDENTIFIER}" \
    --query "DBInstances[0].Endpoint.Address" \
    --output text)"
fi

mkdir -p "${ARTIFACTS_DIR}"
FULL_BACKUP="${ARTIFACTS_DIR}/local-full-${TIMESTAMP}.dump"
SCHEMA_DUMP="${ARTIFACTS_DIR}/schema-${TIMESTAMP}.sql"
DATA_DUMP="${ARTIFACTS_DIR}/data-${TIMESTAMP}.sql"

echo "[1/5] Gerando backup completo do banco local..."
PGPASSWORD="${LOCAL_DB_PASSWORD}" "${PG_DUMP_CMD}" \
  -h "${LOCAL_DB_HOST}" \
  -p "${LOCAL_DB_PORT}" \
  -U "${LOCAL_DB_USER}" \
  -d "${LOCAL_DB_NAME}" \
  -Fc \
  -f "${FULL_BACKUP}"

echo "[2/5] Exportando schema..."
PGPASSWORD="${LOCAL_DB_PASSWORD}" "${PG_DUMP_CMD}" \
  -h "${LOCAL_DB_HOST}" \
  -p "${LOCAL_DB_PORT}" \
  -U "${LOCAL_DB_USER}" \
  -d "${LOCAL_DB_NAME}" \
  --schema-only \
  --no-owner \
  --no-privileges \
  > "${SCHEMA_DUMP}"

echo "[3/5] Exportando dados..."
PGPASSWORD="${LOCAL_DB_PASSWORD}" "${PG_DUMP_CMD}" \
  -h "${LOCAL_DB_HOST}" \
  -p "${LOCAL_DB_PORT}" \
  -U "${LOCAL_DB_USER}" \
  -d "${LOCAL_DB_NAME}" \
  --data-only \
  --no-owner \
  --no-privileges \
  --rows-per-insert=500 \
  > "${DATA_DUMP}"

# PostgreSQL mais novo pode gerar SET transaction_timeout, que nao existe em versoes antigas.
sed -i '/^SET transaction_timeout =/d' "${SCHEMA_DUMP}" "${DATA_DUMP}"

echo "[4/5] Importando schema no RDS..."
PGPASSWORD="${RDS_DB_PASSWORD}" PGSSLMODE="${RDS_SSLMODE}" "${PSQL_CMD}" \
  -v ON_ERROR_STOP=1 \
  -h "${RDS_ENDPOINT}" \
  -p "${RDS_DB_PORT}" \
  -U "${RDS_DB_USER}" \
  -d "${RDS_DB_NAME}" \
  -f "${SCHEMA_DUMP}"

echo "[5/5] Importando dados no RDS..."
PGPASSWORD="${RDS_DB_PASSWORD}" PGSSLMODE="${RDS_SSLMODE}" "${PSQL_CMD}" \
  -v ON_ERROR_STOP=1 \
  -h "${RDS_ENDPOINT}" \
  -p "${RDS_DB_PORT}" \
  -U "${RDS_DB_USER}" \
  -d "${RDS_DB_NAME}" \
  -f "${DATA_DUMP}"

PGPASSWORD="${RDS_DB_PASSWORD}" PGSSLMODE="${RDS_SSLMODE}" "${PSQL_CMD}" \
  -v ON_ERROR_STOP=1 \
  -h "${RDS_ENDPOINT}" \
  -p "${RDS_DB_PORT}" \
  -U "${RDS_DB_USER}" \
  -d "${RDS_DB_NAME}" \
  -c "ANALYZE;"

echo "Migracao concluida com sucesso."
echo "Backup local: ${FULL_BACKUP}"
echo "Schema dump: ${SCHEMA_DUMP}"
echo "Data dump: ${DATA_DUMP}"
