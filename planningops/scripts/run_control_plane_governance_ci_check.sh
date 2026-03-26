#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PYTHON_BIN="python3"
ROOT_PATH="."
MEMORY_OUTPUT="planningops/artifacts/validation/memory-gate-report.json"
INVENTORY_OUTPUT="planningops/artifacts/validation/inventory-issue-lifecycle-report.json"
INVENTORY_ISSUES_FILE=""
PRINT_STEPS=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_control_plane_governance_ci_check.sh [options]

options:
  --python-bin <path>         python interpreter for the live governance validators
  --root <path>               repo root used for memory and inventory governance checks
  --memory-output <path>      output path for memory_compactor.py
  --inventory-output <path>   output path for inventory_issue_lifecycle.py audit
  --inventory-issues-file <path> optional issue fixture for inventory_issue_lifecycle.py audit
  --print-steps               print the canonical workflow step inventory
  --print-workflow-invocation print the canonical GitHub workflow invocation
  --help                      show this help text
EOF
}

print_steps() {
  cat <<'EOF'
bash planningops/scripts/test_validate_artifact_storage_policy_contract.sh
python3 planningops/scripts/validate_artifact_storage_policy.py --strict
bash planningops/scripts/test_control_tower_ontology_contract.sh
bash planningops/scripts/test_ontology_entity_map_contract.sh
bash planningops/scripts/test_memory_tier_contract.sh
bash planningops/scripts/test_memory_compactor_contract.sh
bash planningops/scripts/test_memory_archive_contract.sh
bash planningops/scripts/test_memory_rehydrate_contract.sh
bash planningops/scripts/test_inventory_issue_lifecycle_contract.sh
bash planningops/scripts/test_autonomous_scheduler_queue_control_plane_contract.sh
python3 planningops/scripts/memory_compactor.py --mode check --root . --rules planningops/config/memory-tier-rules.json --output planningops/artifacts/validation/memory-gate-report.json --strict
python3 planningops/scripts/inventory_issue_lifecycle.py audit --repo rather-not-work-on/platform-planningops --strict --output planningops/artifacts/validation/inventory-issue-lifecycle-report.json
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --python-bin)
      PYTHON_BIN="$2"
      shift 2
      ;;
    --root)
      ROOT_PATH="$2"
      shift 2
      ;;
    --memory-output)
      MEMORY_OUTPUT="$2"
      shift 2
      ;;
    --inventory-output)
      INVENTORY_OUTPUT="$2"
      shift 2
      ;;
    --inventory-issues-file)
      INVENTORY_ISSUES_FILE="$2"
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
  printf '%s\n' "bash planningops/scripts/run_control_plane_governance_ci_check.sh --python-bin python3"
  exit 0
fi

bash "${ROOT_DIR}/planningops/scripts/test_run_control_plane_governance_ci_check_contract.sh"

cd "${ROOT_DIR}"
bash planningops/scripts/test_validate_artifact_storage_policy_contract.sh
"${PYTHON_BIN}" planningops/scripts/validate_artifact_storage_policy.py --strict
bash planningops/scripts/test_control_tower_ontology_contract.sh
bash planningops/scripts/test_ontology_entity_map_contract.sh
bash planningops/scripts/test_memory_tier_contract.sh
bash planningops/scripts/test_memory_compactor_contract.sh
bash planningops/scripts/test_memory_archive_contract.sh
bash planningops/scripts/test_memory_rehydrate_contract.sh
bash planningops/scripts/test_inventory_issue_lifecycle_contract.sh
bash planningops/scripts/test_autonomous_scheduler_queue_control_plane_contract.sh
"${PYTHON_BIN}" planningops/scripts/memory_compactor.py \
  --mode check \
  --root "${ROOT_PATH}" \
  --rules planningops/config/memory-tier-rules.json \
  --output "${MEMORY_OUTPUT}" \
  --strict
INVENTORY_ARGS=(
  audit
  --root "${ROOT_PATH}"
  --repo rather-not-work-on/platform-planningops
  --strict
  --output "${INVENTORY_OUTPUT}"
)
if [[ -n "${INVENTORY_ISSUES_FILE}" ]]; then
  INVENTORY_ARGS+=(--issues-file "${INVENTORY_ISSUES_FILE}")
fi
"${PYTHON_BIN}" planningops/scripts/inventory_issue_lifecycle.py "${INVENTORY_ARGS[@]}"
