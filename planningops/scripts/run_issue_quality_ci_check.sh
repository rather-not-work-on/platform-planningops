#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHON_BIN="python3"
PRINT_STEPS=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_issue_quality_ci_check.sh [options]

options:
  --python-bin <path>         python interpreter for the live issue-quality check
  --print-steps              print the canonical workflow step inventory
  --print-workflow-invocation print the canonical GitHub workflow invocation
  --help                     show this help text
EOF
}

print_steps() {
  cat <<'EOF'
bash planningops/scripts/test_validate_issue_quality_contract.sh
bash planningops/scripts/test_validate_federated_issue_quality_contract.sh
python3 planningops/scripts/validate_issue_quality.py --strict
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --python-bin)
      PYTHON_BIN="$2"
      shift 2
      ;;
    --print-steps)
      PRINT_STEPS=1
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

if [[ "${PRINT_STEPS}" -eq 1 ]]; then
  print_steps
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_issue_quality_ci_check.sh --python-bin python3"
  exit 0
fi

bash "${ROOT_DIR}/planningops/scripts/test_run_issue_quality_ci_check_contract.sh"

cd "${ROOT_DIR}"
bash planningops/scripts/test_validate_issue_quality_contract.sh
bash planningops/scripts/test_validate_federated_issue_quality_contract.sh
"${PYTHON_BIN}" planningops/scripts/validate_issue_quality.py --strict
