#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_WORKSPACE_ROOT="${ROOT_DIR}/.."
DEFAULT_BOOTSTRAP_MODE="auto"
DEFAULT_PYTHON_BIN="python3"
RUN_ID=""
WORKSPACE_ROOT="${DEFAULT_WORKSPACE_ROOT}"
BOOTSTRAP_MODE="${DEFAULT_BOOTSTRAP_MODE}"
PYTHON_BIN="${DEFAULT_PYTHON_BIN}"
PRINT_LOCAL_INVOCATION=0

usage() {
  cat <<EOF
usage: run_contract_conformance_ci_check.sh [options]

options:
  --run-id <id>             contract-conformance run id passed to the federated checker
  --workspace-root <path>   federated workspace root
  --bootstrap-mode <mode>   cross-repo bootstrap mode
  --python-bin <path>       python executable used to invoke the conformance checker
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
    --workspace-root)
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --bootstrap-mode)
      BOOTSTRAP_MODE="$2"
      shift 2
      ;;
    --python-bin)
      PYTHON_BIN="$2"
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
  printf '%s\n' "bash planningops/scripts/run_contract_conformance_ci_check.sh --run-id \${RUN_ID}-contract --workspace-root .. --bootstrap-mode auto --python-bin \\\"\${PYTHON_BIN}\\\""
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

WORKSPACE_ROOT="$(resolve_from_root "${WORKSPACE_ROOT}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_contract_conformance_ci_check_contract.sh"

"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/federation/cross_repo_conformance_check.py" \
  --workspace-root "${WORKSPACE_ROOT}" \
  --bootstrap-mode "${BOOTSTRAP_MODE}" \
  --run-id "${RUN_ID}"
