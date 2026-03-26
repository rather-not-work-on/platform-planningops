#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_MONDAY_ROOT="${ROOT_DIR}/../monday"
DEFAULT_PYTHON_BIN="python3"
PRINT_STEPS=0
PRINT_LOCAL_INVOCATION=0
PRINT_WORKFLOW_INVOCATION=0
RUN_ID=""
MONDAY_ROOT="${DEFAULT_MONDAY_ROOT}"
PLANNINGOPS_LAST_RUN=""
PYTHON_BIN="${DEFAULT_PYTHON_BIN}"

usage() {
  cat <<EOF
usage: run_runtime_handoff_ci_check.sh [options]

options:
  --run-id <id>                runtime handoff run id used for monday integration artifacts
  --monday-root <path>         monday workspace root to execute integration in
  --planningops-last-run <path>
                               optional planningops last-run artifact for workflow-backed integration
  --python-bin <path>          python executable for monday integrate_planningops_handoff.py
  --print-steps                print the canonical ordered runtime-handoff step inventory
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
    --monday-root)
      MONDAY_ROOT="$2"
      shift 2
      ;;
    --planningops-last-run)
      PLANNINGOPS_LAST_RUN="$2"
      shift 2
      ;;
    --python-bin)
      PYTHON_BIN="$2"
      shift 2
      ;;
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
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

STEPS=(
  "planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh"
  "planningops/scripts/test_supervisor_handoff_bridge_wiring.sh"
  "planningops/scripts/test_autonomous_supervisor_loop_contract.sh"
  "monday/scripts/integrate_planningops_handoff.py"
  "planningops/scripts/test_resolve_supervisor_operator_handoff_validation.sh"
  "planningops/scripts/test_resolve_supervisor_operator_handoff_bundle.sh"
  "planningops/scripts/test_validate_supervisor_operator_handoff_bundle.sh"
  "planningops/scripts/test_assess_supervisor_operator_handoff_bundle_readiness.sh"
  "planningops/scripts/test_validate_supervisor_operator_handoff_bundle_readiness.sh"
  "planningops/scripts/test_doctor_supervisor_operator_handoff_bundle.sh"
  "planningops/scripts/test_gate_supervisor_operator_handoff_bundle.sh"
  "planningops/scripts/test_supervisor_handoff_to_monday_status_bridge.sh"
  "planningops/scripts/test_supervisor_handoff_to_monday_goal_completion_bridge.sh"
  "planningops/scripts/test_supervisor_handoff_to_monday_goal_completion_scheduler_bridge.sh"
  "planningops/scripts/test_worker_outcome_reflection_cycle.sh"
  "planningops/scripts/test_worker_outcome_reflection_cycle_scheduler_report.sh"
  "planningops/scripts/test_reflection_goal_completion_handoff_cycle.sh"
  "planningops/scripts/test_reflection_delivery_cycle.sh"
  "planningops/scripts/test_scheduled_reflection_delivery_cycle.sh"
  "planningops/scripts/test_reflection_cycle_orchestration_contract.sh"
  "planningops/scripts/test_reflection_delivery_cycle_contract.sh"
  "planningops/scripts/test_scheduled_reflection_delivery_cycle_contract.sh"
  "planningops/scripts/test_local_delivery_cycle_orchestration_contract.sh"
  "planningops/scripts/test_scheduled_delivery_queue_admission_contract.sh"
  "planningops/scripts/test_scheduled_queue_admission_handoff_contract.sh"
  "planningops/scripts/test_scheduler_native_worker_outcome_selection_contract.sh"
  "planningops/scripts/test_scheduled_worker_outcome_handoff_contract.sh"
  "planningops/scripts/test_reflection_action_handoff_contract.sh"
  "planningops/scripts/test_scheduled_delivery_cycle_handoff_contract.sh"
  "planningops/scripts/test_local_delivery_cycle_entrypoint_contract.sh"
  "planningops/scripts/test_local_operator_target_resolution_contract.sh"
  "planningops/scripts/test_local_outbox_dispatch_handoff_contract.sh"
  "planningops/scripts/test_local_dispatch_cycle_handoff_contract.sh"
  "planningops/scripts/test_active_goal_registry_contract.sh"
  "planningops/scripts/test_transition_goal_state_contract.sh"
  "planningops/scripts/test_supervisor_operator_handoff_contract.sh"
  "planningops/scripts/test_validate_supervisor_operator_handoff_contract.sh"
  "planningops/scripts/test_federated_ci_summary_contract.sh"
  "planningops/scripts/test_validate_federated_ci_summary_contract.sh"
  "planningops/scripts/test_reconcile_federated_ci_summary_tmp.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh"
  "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh"
  "planningops/scripts/test_assess_federated_ci_summary_readiness.sh"
  "planningops/scripts/test_validate_federated_ci_summary_readiness_contract.sh"
  "planningops/scripts/test_doctor_federated_ci_summary.sh"
  "planningops/scripts/test_gate_federated_ci_summary.sh"
  "planningops/scripts/test_uap_automation_operations_summary_contract.sh"
)

if [[ "${PRINT_STEPS}" -eq 1 ]]; then
  printf '%s\n' "${STEPS[@]}"
  exit 0
fi

if [[ "${PRINT_LOCAL_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_runtime_handoff_ci_check.sh --run-id \${RUN_ID}-runtime --monday-root ../monday --python-bin \\\"\${PYTHON_BIN}\\\""
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_runtime_handoff_ci_check.sh --run-id ci-runtime-\${{ github.run_id }} --monday-root monday --planningops-last-run planningops/artifacts/loop-runner/last-run.json"
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

MONDAY_ROOT="$(resolve_from_root "${MONDAY_ROOT}")"
if [[ -n "${PLANNINGOPS_LAST_RUN}" ]]; then
  PLANNINGOPS_LAST_RUN="$(resolve_from_root "${PLANNINGOPS_LAST_RUN}")"
fi

IDEMPOTENCY_PATH="artifacts/integration/${RUN_ID}-idempotency.json"
TRANSITION_LOG_PATH="artifacts/integration/${RUN_ID}-scheduler.ndjson"

bash "${ROOT_DIR}/planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh"
bash "${ROOT_DIR}/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh"
bash "${ROOT_DIR}/planningops/scripts/test_autonomous_supervisor_loop_contract.sh"

cd "${MONDAY_ROOT}"
rm -f "${IDEMPOTENCY_PATH}" "${TRANSITION_LOG_PATH}"

INTEGRATE_CMD=(
  "${PYTHON_BIN}"
  "scripts/integrate_planningops_handoff.py"
  "--run-id" "${RUN_ID}"
  "--idempotency" "${IDEMPOTENCY_PATH}"
  "--transition-log" "${TRANSITION_LOG_PATH}"
)
if [[ -n "${PLANNINGOPS_LAST_RUN}" ]]; then
  INTEGRATE_CMD+=(--planningops-last-run "${PLANNINGOPS_LAST_RUN}")
fi
"${INTEGRATE_CMD[@]}"

cd "${ROOT_DIR}"
for step in "${STEPS[@]:4}"; do
  bash "${ROOT_DIR}/${step}"
done
