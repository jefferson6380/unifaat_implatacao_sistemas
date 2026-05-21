#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts"
ENV_FILE="${ENV_FILE:-${ROOT_DIR}/.env}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
REPORT_FILE="${ARTIFACTS_DIR}/validation-${TIMESTAMP}.txt"

if [[ -f "${ENV_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
fi

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

PSQL_CMD="$(resolve_pg_tool psql || true)"

if [[ -z "${PSQL_CMD}" ]]; then
  echo "psql nao encontrado." >&2
  exit 1
fi

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
require_var "RDS_ENDPOINT"
require_var "RDS_DB_NAME"
require_var "RDS_DB_USER"
require_var "RDS_DB_PASSWORD"

mkdir -p "${ARTIFACTS_DIR}"

query_local() {
  local sql="$1"
  PGPASSWORD="${LOCAL_DB_PASSWORD}" "${PSQL_CMD}" \
    -h "${LOCAL_DB_HOST}" \
    -p "${LOCAL_DB_PORT}" \
    -U "${LOCAL_DB_USER}" \
    -d "${LOCAL_DB_NAME}" \
    -At -c "${sql}"
}

query_rds() {
  local sql="$1"
  PGPASSWORD="${RDS_DB_PASSWORD}" PGSSLMODE="${RDS_SSLMODE}" "${PSQL_CMD}" \
    -h "${RDS_ENDPOINT}" \
    -p "${RDS_DB_PORT}" \
    -U "${RDS_DB_USER}" \
    -d "${RDS_DB_NAME}" \
    -At -c "${sql}"
}

echo "Iniciando validacao da migracao..."

echo "Relatorio de validacao - ${TIMESTAMP}" > "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

LOCAL_TABLE_COUNT="$(query_local "SELECT count(*) FROM pg_tables WHERE schemaname='public';")"
RDS_TABLE_COUNT="$(query_rds "SELECT count(*) FROM pg_tables WHERE schemaname='public';")"

echo "Quantidade de tabelas (public):" >> "${REPORT_FILE}"
echo "- Local: ${LOCAL_TABLE_COUNT}" >> "${REPORT_FILE}"
echo "- RDS:   ${RDS_TABLE_COUNT}" >> "${REPORT_FILE}"

declare -i mismatch_count=0

if [[ "${LOCAL_TABLE_COUNT}" != "${RDS_TABLE_COUNT}" ]]; then
  mismatch_count+=1
  echo "[ERRO] Quantidade de tabelas divergente." | tee -a "${REPORT_FILE}"
fi

echo "" >> "${REPORT_FILE}"
echo "Comparacao de contagem por tabela:" >> "${REPORT_FILE}"

TABLES="$(query_local "SELECT format('%I.%I', schemaname, tablename) FROM pg_tables WHERE schemaname='public' ORDER BY tablename;")"

while IFS= read -r table_name; do
  [[ -z "${table_name}" ]] && continue
  local_count="$(query_local "SELECT count(*) FROM ${table_name};")"
  rds_count="$(query_rds "SELECT count(*) FROM ${table_name};")"

  if [[ "${local_count}" == "${rds_count}" ]]; then
    printf '[OK] %s -> %s linhas\n' "${table_name}" "${local_count}" | tee -a "${REPORT_FILE}" >/dev/null
  else
    mismatch_count+=1
    printf '[ERRO] %s -> local=%s rds=%s\n' "${table_name}" "${local_count}" "${rds_count}" | tee -a "${REPORT_FILE}" >/dev/null
  fi
done <<< "${TABLES}"

LOCAL_INDEX_COUNT="$(query_local "SELECT count(*) FROM pg_indexes WHERE schemaname='public';")"
RDS_INDEX_COUNT="$(query_rds "SELECT count(*) FROM pg_indexes WHERE schemaname='public';")"

echo "" >> "${REPORT_FILE}"
echo "Quantidade de indices (public):" >> "${REPORT_FILE}"
echo "- Local: ${LOCAL_INDEX_COUNT}" >> "${REPORT_FILE}"
echo "- RDS:   ${RDS_INDEX_COUNT}" >> "${REPORT_FILE}"

if [[ "${LOCAL_INDEX_COUNT}" != "${RDS_INDEX_COUNT}" ]]; then
  mismatch_count+=1
  echo "[ERRO] Quantidade de indices divergente." | tee -a "${REPORT_FILE}"
fi

echo "" >> "${REPORT_FILE}"
if (( mismatch_count == 0 )); then
  echo "Validacao concluida sem divergencias." | tee -a "${REPORT_FILE}"
  echo "Relatorio salvo em: ${REPORT_FILE}"
  exit 0
fi

echo "Validacao concluida com ${mismatch_count} divergencia(s)." | tee -a "${REPORT_FILE}"
echo "Relatorio salvo em: ${REPORT_FILE}"
exit 1
