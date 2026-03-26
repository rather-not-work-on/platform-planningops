#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_PROVIDER_ROOT="${ROOT_DIR}/../platform-provider-gateway"
DEFAULT_RUNTIME_PROFILE_FILE="planningops/config/runtime-profiles.json"
DEFAULT_PROFILES="local,oracle_cloud"
RUN_ID=""
PROVIDER_ROOT="${DEFAULT_PROVIDER_ROOT}"
RUNTIME_PROFILE_FILE="${DEFAULT_RUNTIME_PROFILE_FILE}"
PROFILES="${DEFAULT_PROFILES}"
PRINT_LOCAL_INVOCATION=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_provider_profile_ci_check.sh [options]

options:
  --run-id <id>                provider-profile run id passed to the launcher dry-run
  --provider-root <path>       provider gateway workspace root
  --runtime-profile-file <path>
                               planningops runtime profiles file consumed by the launcher
  --profiles <csv>             launcher profile set
  --print-local-invocation     print the canonical local matrix invocation
  --print-workflow-invocation  print the canonical GitHub workflow invocation
  --help                       show this help text
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
    --runtime-profile-file)
      RUNTIME_PROFILE_FILE="$2"
      shift 2
      ;;
    --profiles)
      PROFILES="$2"
      shift 2
      ;;
    --print-local-invocation)
      PRINT_LOCAL_INVOCATION=1
      shift
      ;;
    --print-workflow-invocation)
      PRINT_WORKFLOW_INVOCATION=1
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
  printf '%s\n' "bash planningops/scripts/run_provider_profile_ci_check.sh --run-id \${RUN_ID}-provider --provider-root ../platform-provider-gateway --runtime-profile-file planningops/config/runtime-profiles.json --profiles local,oracle_cloud"
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_provider_profile_ci_check.sh --run-id ci-provider-\${{ github.run_id }} --provider-root platform-provider-gateway --runtime-profile-file planningops/config/runtime-profiles.json --profiles local,oracle_cloud"
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

PROVIDER_ROOT="$(resolve_from_root "${PROVIDER_ROOT}")"
RUNTIME_PROFILE_FILE="$(resolve_from_root "${RUNTIME_PROFILE_FILE}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_provider_profile_ci_check_contract.sh"

cd "${PROVIDER_ROOT}"
bash scripts/litellm_stack_launcher.sh \
  --mode dry-run \
  --runtime-profile-file "${RUNTIME_PROFILE_FILE}" \
  --profiles "${PROFILES}" \
  --run-id "${RUN_ID}"
