#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_MISSION_ID="monday-harness-projection"
PRINT_STEPS=0
PRINT_LOCAL_INVOCATION=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_monday_agent_harness_projection_ci_check.sh [options] [suite-options]

options:
  --print-steps               print the canonical ordered wrapper step inventory
  --print-local-invocation    print the canonical local matrix invocation
  --print-workflow-invocation print the canonical GitHub workflow invocation
  --help                      show this help text

suite-options:
  passed through to run_monday_agent_harness_projection_ci_suite.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --print-steps)
      PRINT_STEPS=1
      shift
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
      break
      ;;
  esac
done

STEPS=(
  "planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh"
  "planningops/scripts/test_monday_agent_harness_projection_helper_wiring.sh"
  "planningops/scripts/test_run_monday_agent_harness_projection_ci_suite_contract.sh"
  "planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh"
)

if [[ "${PRINT_STEPS}" -eq 1 ]]; then
  printf '%s\n' "${STEPS[@]}"
  exit 0
fi

if [[ "${PRINT_LOCAL_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_monday_agent_harness_projection_ci_check.sh --summary-run-id \${RUN_ID} --monday-root ../monday --mission-id ${DEFAULT_MISSION_ID}"
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_monday_agent_harness_projection_ci_check.sh --summary-run-id ci-\${{ github.run_id }} --monday-root monday --mission-id ${DEFAULT_MISSION_ID}"
  exit 0
fi

bash "${ROOT_DIR}/planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh"
bash "${ROOT_DIR}/planningops/scripts/test_monday_agent_harness_projection_helper_wiring.sh"
bash "${ROOT_DIR}/planningops/scripts/test_run_monday_agent_harness_projection_ci_suite_contract.sh"
bash "${ROOT_DIR}/planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh" "$@"
