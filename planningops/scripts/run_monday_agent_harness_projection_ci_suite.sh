#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_MONDAY_ROOT="${ROOT_DIR}/../monday"
DEFAULT_MISSION_ID="monday-harness-projection"

usage() {
  cat <<EOF
usage: run_monday_agent_harness_projection_ci_suite.sh [options]

options:
  --summary-run-id <id>   override the federated summary run id used during final sync
  --monday-root <path>    monday workspace root to publish and sync against
  --mission-id <id>       mission id used when reseeding monday projection artifacts
  --print-tests           print the canonical ordered monday projection regression inventory
  --help                  show this help text
EOF
}

MONDAY_ROOT="${DEFAULT_MONDAY_ROOT}"
MISSION_ID="${DEFAULT_MISSION_ID}"
SUMMARY_RUN_ID=""
PRINT_TESTS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --monday-root)
      MONDAY_ROOT="$2"
      shift 2
      ;;
    --mission-id)
      MISSION_ID="$2"
      shift 2
      ;;
    --summary-run-id)
      SUMMARY_RUN_ID="$2"
      shift 2
      ;;
    --print-tests)
      PRINT_TESTS=1
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

TESTS=(
  "planningops/scripts/test_validate_monday_agent_harness_projection.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle.sh"
  "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle.sh"
  "planningops/scripts/test_monday_agent_harness_projection_bridge.sh"
  "planningops/scripts/test_monday_agent_harness_projection_contract_doc.sh"
  "planningops/scripts/test_materialize_monday_agent_harness_projection_surfaces.sh"
  "planningops/scripts/test_sync_monday_agent_harness_projection_latest.sh"
)

if [[ "${PRINT_TESTS}" -eq 1 ]]; then
  printf '%s\n' "${TESTS[@]}"
  exit 0
fi

for test_script in "${TESTS[@]}"; do
  printf '[monday-harness-projection] %s\n' "${test_script}"
  bash "${ROOT_DIR}/${test_script}"
done

SYNC_ARGS=(
  --monday-root "${MONDAY_ROOT}"
  --mission-id "${MISSION_ID}"
)
if [[ -n "${SUMMARY_RUN_ID}" ]]; then
  SYNC_ARGS=(--summary-run-id "${SUMMARY_RUN_ID}" "${SYNC_ARGS[@]}")
fi

printf '[monday-harness-projection] sync latest\n'
bash "${ROOT_DIR}/planningops/scripts/sync_monday_agent_harness_projection_latest.sh" "${SYNC_ARGS[@]}"
