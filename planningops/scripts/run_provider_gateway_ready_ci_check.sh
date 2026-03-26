#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_PROVIDER_ROOT="${ROOT_DIR}/../platform-provider-gateway"
RUN_ID=""
PROVIDER_ROOT="${DEFAULT_PROVIDER_ROOT}"
PRINT_LOCAL_INVOCATION=0

usage() {
  cat <<EOF
usage: run_provider_gateway_ready_ci_check.sh [options]

options:
  --run-id <id>             provider-gateway-ready run id passed to the LiteLLM launcher
  --provider-root <path>    provider gateway workspace root
  --print-local-invocation  print the canonical local matrix invocation
  --help                    show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --provider-root)
      PROVIDER_ROOT="$2"
      shift 2
      ;;
    --print-local-invocation)
      PRINT_LOCAL_INVOCATION=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${PRINT_LOCAL_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_provider_gateway_ready_ci_check.sh --run-id \${RUN_ID}-provider-gateway-ready --provider-root ../platform-provider-gateway"
  exit 0
fi

if [[ -z "${RUN_ID}" ]]; then
  echo "--run-id is required" >&2
  usage >&2
  exit 1
fi

resolve_from_root() {
  if [[ "$1" = /* ]]; then
    printf '%s\n' "$1"
  else
    printf '%s/%s\n' "${ROOT_DIR}" "$1"
  fi
}

cleanup() {
  if [[ -d "${PROVIDER_ROOT}" ]]; then
    (
      cd "${PROVIDER_ROOT}"
      bash scripts/litellm_stack_launcher.sh --mode stop >/dev/null 2>&1 || true
    )
  fi
}

PROVIDER_ROOT="$(resolve_from_root "${PROVIDER_ROOT}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_provider_gateway_ready_ci_check_contract.sh"

trap cleanup EXIT

cd "${PROVIDER_ROOT}"
bash scripts/litellm_stack_launcher.sh --mode start --run-id "${RUN_ID}"
npm run gate:litellm-stack-ready
