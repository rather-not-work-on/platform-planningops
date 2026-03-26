#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_O11Y_ROOT="${ROOT_DIR}/../platform-observability-gateway"
RUN_ID=""
O11Y_ROOT="${DEFAULT_O11Y_ROOT}"
PRINT_LOCAL_INVOCATION=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_o11y_replay_ci_check.sh [options]

options:
  --run-id <id>                o11y replay run id passed to the dry-run launcher
  --o11y-root <path>           observability gateway workspace root
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
    --o11y-root)
      O11Y_ROOT="$2"
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
  printf '%s\n' "bash planningops/scripts/run_o11y_replay_ci_check.sh --run-id \${RUN_ID}-o11y --o11y-root ../platform-observability-gateway"
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_o11y_replay_ci_check.sh --run-id ci-o11y-\${{ github.run_id }} --o11y-root platform-observability-gateway"
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

O11Y_ROOT="$(resolve_from_root "${O11Y_ROOT}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_o11y_replay_ci_check_contract.sh"

cd "${O11Y_ROOT}"
bash scripts/langfuse_stack_launcher.sh --mode dry-run --run-id "${RUN_ID}"
