#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_CONTRACTS_ROOT="${ROOT_DIR}/../platform-contracts"
DEFAULT_PYTHON_BIN="python3"
DEFAULT_VENV_ROOT="planningops/runtime-artifacts/tooling/platform-contracts-ci"
CONTRACTS_ROOT="${DEFAULT_CONTRACTS_ROOT}"
PYTHON_BIN="${DEFAULT_PYTHON_BIN}"
VENV_ROOT="${DEFAULT_VENV_ROOT}"
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_platform_contracts_ci_check.sh [options]

options:
  --contracts-root <path>      platform-contracts workspace root
  --python-bin <path>          python executable used for install and validation commands
  --venv-root <path>           repo-local virtualenv root used for managed dependency installs
  --print-workflow-invocation  print the canonical GitHub workflow invocation
  --help                       show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contracts-root)
      CONTRACTS_ROOT="$2"
      shift 2
      ;;
    --python-bin)
      PYTHON_BIN="$2"
      shift 2
      ;;
    --venv-root)
      VENV_ROOT="$2"
      shift 2
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

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_platform_contracts_ci_check.sh --contracts-root platform-contracts --python-bin python3"
  exit 0
fi

resolve_from_root() {
  if [[ "$1" = /* ]]; then
    printf '%s\n' "$1"
  else
    printf '%s/%s\n' "${ROOT_DIR}" "$1"
  fi
}

CONTRACTS_ROOT="$(resolve_from_root "${CONTRACTS_ROOT}")"
VENV_ROOT="$(resolve_from_root "${VENV_ROOT}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_platform_contracts_ci_check_contract.sh"

if [[ ! -x "${VENV_ROOT}/bin/python" ]]; then
  rm -rf "${VENV_ROOT}"
  "${PYTHON_BIN}" -m venv "${VENV_ROOT}"
fi

cd "${CONTRACTS_ROOT}"
"${VENV_ROOT}/bin/python" -m pip install --upgrade pip
"${VENV_ROOT}/bin/python" -m pip install -r requirements-dev.txt
"${VENV_ROOT}/bin/python" scripts/validate_contracts.py --root .
"${VENV_ROOT}/bin/python" scripts/classify_schema_change.py --enforce-expected
