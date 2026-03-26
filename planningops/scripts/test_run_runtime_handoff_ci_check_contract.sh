#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_runtime_handoff_ci_check.sh"

python3 - <<'PY' "${SCRIPT_PATH}"
import subprocess
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
script = script_path.read_text(encoding="utf-8")
steps = subprocess.check_output(
    ["bash", str(script_path), "--print-steps"],
    text=True,
).splitlines()
local_invocation = subprocess.check_output(
    ["bash", str(script_path), "--print-local-invocation"],
    text=True,
).strip()
workflow_invocation = subprocess.check_output(
    ["bash", str(script_path), "--print-workflow-invocation"],
    text=True,
).strip()
help_output = subprocess.check_output(
    ["bash", str(script_path), "--help"],
    text=True,
)

expected = [
    "planningops/scripts/test_run_runtime_handoff_ci_check_contract.sh",
    "planningops/scripts/test_supervisor_handoff_bridge_wiring.sh",
    "planningops/scripts/test_autonomous_supervisor_loop_contract.sh",
    "monday/scripts/integrate_planningops_handoff.py",
    "planningops/scripts/test_resolve_supervisor_operator_handoff_validation.sh",
    "planningops/scripts/test_resolve_supervisor_operator_handoff_bundle.sh",
    "planningops/scripts/test_validate_supervisor_operator_handoff_bundle.sh",
    "planningops/scripts/test_assess_supervisor_operator_handoff_bundle_readiness.sh",
    "planningops/scripts/test_validate_supervisor_operator_handoff_bundle_readiness.sh",
    "planningops/scripts/test_doctor_supervisor_operator_handoff_bundle.sh",
    "planningops/scripts/test_gate_supervisor_operator_handoff_bundle.sh",
    "planningops/scripts/test_supervisor_handoff_to_monday_status_bridge.sh",
    "planningops/scripts/test_supervisor_handoff_to_monday_goal_completion_bridge.sh",
    "planningops/scripts/test_supervisor_handoff_to_monday_goal_completion_scheduler_bridge.sh",
    "planningops/scripts/test_worker_outcome_reflection_cycle.sh",
    "planningops/scripts/test_worker_outcome_reflection_cycle_scheduler_report.sh",
    "planningops/scripts/test_reflection_goal_completion_handoff_cycle.sh",
    "planningops/scripts/test_reflection_delivery_cycle.sh",
    "planningops/scripts/test_scheduled_reflection_delivery_cycle.sh",
    "planningops/scripts/test_reflection_cycle_orchestration_contract.sh",
    "planningops/scripts/test_reflection_delivery_cycle_contract.sh",
    "planningops/scripts/test_scheduled_reflection_delivery_cycle_contract.sh",
    "planningops/scripts/test_local_delivery_cycle_orchestration_contract.sh",
    "planningops/scripts/test_scheduled_delivery_queue_admission_contract.sh",
    "planningops/scripts/test_scheduled_queue_admission_handoff_contract.sh",
    "planningops/scripts/test_scheduler_native_worker_outcome_selection_contract.sh",
    "planningops/scripts/test_scheduled_worker_outcome_handoff_contract.sh",
    "planningops/scripts/test_reflection_action_handoff_contract.sh",
    "planningops/scripts/test_scheduled_delivery_cycle_handoff_contract.sh",
    "planningops/scripts/test_local_delivery_cycle_entrypoint_contract.sh",
    "planningops/scripts/test_local_operator_target_resolution_contract.sh",
    "planningops/scripts/test_local_outbox_dispatch_handoff_contract.sh",
    "planningops/scripts/test_local_dispatch_cycle_handoff_contract.sh",
    "planningops/scripts/test_active_goal_registry_contract.sh",
    "planningops/scripts/test_transition_goal_state_contract.sh",
    "planningops/scripts/test_supervisor_operator_handoff_contract.sh",
    "planningops/scripts/test_validate_supervisor_operator_handoff_contract.sh",
    "planningops/scripts/test_federated_ci_summary_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_contract.sh",
    "planningops/scripts/test_reconcile_federated_ci_summary_tmp.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_assess_federated_ci_summary_readiness.sh",
    "planningops/scripts/test_validate_federated_ci_summary_readiness_contract.sh",
    "planningops/scripts/test_doctor_federated_ci_summary.sh",
    "planningops/scripts/test_gate_federated_ci_summary.sh",
    "planningops/scripts/test_uap_automation_operations_summary_contract.sh",
]

assert steps == expected, "printed runtime-handoff step inventory drifted"
assert local_invocation == 'bash planningops/scripts/run_runtime_handoff_ci_check.sh --run-id ${RUN_ID}-runtime --monday-root ../monday --python-bin \\"${PYTHON_BIN}\\"', "local runtime-handoff invocation drifted"
assert workflow_invocation == "bash planningops/scripts/run_runtime_handoff_ci_check.sh --run-id ci-runtime-${{ github.run_id }} --monday-root monday --planningops-last-run planningops/artifacts/loop-runner/last-run.json", "workflow runtime-handoff invocation drifted"
assert "usage: run_runtime_handoff_ci_check.sh [options]" in help_output, "runtime-handoff help usage missing"
assert "--run-id <id>" in help_output, "runtime-handoff help missing run-id flag"
assert "--monday-root <path>" in help_output, "runtime-handoff help missing monday-root flag"
assert "--planningops-last-run <path>" in help_output, "runtime-handoff help missing planningops-last-run flag"
assert "--python-bin <path>" in help_output, "runtime-handoff help missing python-bin flag"
assert "--print-steps" in help_output, "runtime-handoff help missing print-steps flag"
assert "--print-local-invocation" in help_output, "runtime-handoff help missing print-local-invocation flag"
assert "--print-workflow-invocation" in help_output, "runtime-handoff help missing print-workflow-invocation flag"
assert 'printf \'%s\\n\' "${STEPS[@]}"' in script, "runtime-handoff print-steps output missing"
assert 'scripts/integrate_planningops_handoff.py' in script, "runtime-handoff integrate step missing"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_supervisor_handoff_bridge_wiring.sh"' in script, "runtime-handoff wiring regression missing"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_autonomous_supervisor_loop_contract.sh"' in script, "runtime-handoff supervisor contract regression missing"
assert 'IDEMPOTENCY_PATH="artifacts/integration/${RUN_ID}-idempotency.json"' in script, "runtime-handoff idempotency path missing"
assert 'TRANSITION_LOG_PATH="artifacts/integration/${RUN_ID}-scheduler.ndjson"' in script, "runtime-handoff transition log path missing"
PY

echo "runtime handoff ci check contract ok"
