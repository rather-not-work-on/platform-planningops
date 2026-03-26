#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_MATRIX_PATH="$ROOT_DIR/planningops/scripts/federation/federated_ci_matrix_local.sh"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_runtime_handoff_ci_check.sh"
STATUS_BRIDGE_PATH="$ROOT_DIR/planningops/scripts/test_supervisor_handoff_to_monday_status_bridge.sh"
GOAL_BRIDGE_PATH="$ROOT_DIR/planningops/scripts/test_supervisor_handoff_to_monday_goal_completion_bridge.sh"
SCHEDULER_BRIDGE_PATH="$ROOT_DIR/planningops/scripts/test_supervisor_handoff_to_monday_goal_completion_scheduler_bridge.sh"

python3 - <<'PY' "$LOCAL_MATRIX_PATH" "$WORKFLOW_PATH" "$HELPER_PATH" "$STATUS_BRIDGE_PATH" "$GOAL_BRIDGE_PATH" "$SCHEDULER_BRIDGE_PATH"
import subprocess
import sys
from pathlib import Path

local_matrix = Path(sys.argv[1]).read_text(encoding="utf-8")
workflow = Path(sys.argv[2]).read_text(encoding="utf-8")
helper_path = Path(sys.argv[3])
status_bridge = Path(sys.argv[4]).read_text(encoding="utf-8")
goal_bridge = Path(sys.argv[5]).read_text(encoding="utf-8")
scheduler_bridge = Path(sys.argv[6]).read_text(encoding="utf-8")

helper_steps = subprocess.check_output(
    ["bash", str(helper_path), "--print-steps"],
    text=True,
).splitlines()
local_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-local-invocation"],
    text=True,
).strip()
workflow_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-workflow-invocation"],
    text=True,
).strip()

runtime_handoff_block = local_matrix.split('run_check "runtime-handoff" "runtime" \\', 1)[1].split('run_check "runtime-operations-ready" "runtime" \\', 1)[0]
workflow_runtime_handoff = workflow.split("  runtime-handoff:", 1)[1].split("  monday-harness-projection:", 1)[0]

required_snippets = [
    "test_autonomous_supervisor_loop_contract.sh",
    "test_resolve_supervisor_operator_handoff_validation.sh",
    "test_resolve_supervisor_operator_handoff_bundle.sh",
    "test_validate_supervisor_operator_handoff_bundle.sh",
    "test_assess_supervisor_operator_handoff_bundle_readiness.sh",
    "test_validate_supervisor_operator_handoff_bundle_readiness.sh",
    "test_doctor_supervisor_operator_handoff_bundle.sh",
    "test_gate_supervisor_operator_handoff_bundle.sh",
    "test_supervisor_handoff_to_monday_status_bridge.sh",
    "test_supervisor_handoff_to_monday_goal_completion_bridge.sh",
    "test_supervisor_handoff_to_monday_goal_completion_scheduler_bridge.sh",
    "test_worker_outcome_reflection_cycle.sh",
    "test_worker_outcome_reflection_cycle_scheduler_report.sh",
    "test_reflection_goal_completion_handoff_cycle.sh",
    "test_reflection_delivery_cycle.sh",
    "test_scheduled_reflection_delivery_cycle.sh",
    "test_reflection_cycle_orchestration_contract.sh",
    "test_reflection_delivery_cycle_contract.sh",
    "test_scheduled_reflection_delivery_cycle_contract.sh",
    "test_local_delivery_cycle_orchestration_contract.sh",
    "test_scheduled_delivery_queue_admission_contract.sh",
    "test_scheduled_queue_admission_handoff_contract.sh",
    "test_scheduler_native_worker_outcome_selection_contract.sh",
    "test_scheduled_worker_outcome_handoff_contract.sh",
    "test_reflection_action_handoff_contract.sh",
    "test_scheduled_delivery_cycle_handoff_contract.sh",
    "test_local_delivery_cycle_entrypoint_contract.sh",
    "test_local_operator_target_resolution_contract.sh",
    "test_local_outbox_dispatch_handoff_contract.sh",
    "test_local_dispatch_cycle_handoff_contract.sh",
    "test_active_goal_registry_contract.sh",
    "test_transition_goal_state_contract.sh",
    "test_supervisor_operator_handoff_contract.sh",
    "test_validate_supervisor_operator_handoff_contract.sh",
    "test_federated_ci_summary_contract.sh",
    "test_validate_federated_ci_summary_contract.sh",
    "test_reconcile_federated_ci_summary_tmp.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile.sh",
    "test_gate_federated_ci_summary_tmp_reconcile.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "test_assess_federated_ci_summary_readiness.sh",
    "test_validate_federated_ci_summary_readiness_contract.sh",
    "test_doctor_federated_ci_summary.sh",
    "test_gate_federated_ci_summary.sh",
    "test_uap_automation_operations_summary_contract.sh",
]
for required_snippet in required_snippets:
    assert any(required_snippet in step for step in helper_steps), f"runtime-handoff helper step inventory missing: {required_snippet}"
assert "monday/scripts/integrate_planningops_handoff.py" in helper_steps, "runtime-handoff helper missing integration baseline"
assert local_invocation in runtime_handoff_block, "local runtime-handoff block missing helper invocation"
assert workflow_invocation in workflow_runtime_handoff, "workflow runtime-handoff block missing helper invocation"
assert runtime_handoff_block.count(local_invocation) == 1, "local runtime-handoff helper invocation should appear once"
assert workflow_runtime_handoff.count(workflow_invocation) == 1, "workflow runtime-handoff helper invocation should appear once"
for helper_step in helper_steps:
    if helper_step == "monday/scripts/integrate_planningops_handoff.py":
        assert "integrate_planningops_handoff.py" not in runtime_handoff_block, "local runtime-handoff block should not inline monday integration"
        assert "integrate_planningops_handoff.py" not in workflow_runtime_handoff, "workflow runtime-handoff block should not inline monday integration"
        continue
    step_name = helper_step.split("/")[-1]
    assert step_name not in runtime_handoff_block, f"local runtime-handoff block should not inline helper step: {step_name}"
    assert step_name not in workflow_runtime_handoff, f"workflow runtime-handoff block should not inline helper step: {step_name}"
for script_text, label in [
    (status_bridge, "status bridge"),
    (goal_bridge, "goal-completion bridge"),
    (scheduler_bridge, "goal-completion scheduler bridge"),
]:
    assert "resolve_operator_priority_preview.py" in script_text, f"{label} missing canonical priority preview resolver"
    assert "resolve_operator_priority_display_packet.py" in script_text, f"{label} missing canonical priority display packet resolver"
    assert "resolve_supervisor_operator_handoff_validation.py" in script_text, f"{label} missing canonical handoff validation resolver"
    assert "resolve_supervisor_operator_handoff_bundle.py" in script_text, f"{label} missing canonical handoff bundle resolver"
    assert "validate_supervisor_operator_handoff_bundle.py" in script_text, f"{label} missing canonical handoff bundle validator"
    assert "assess_supervisor_operator_handoff_bundle_readiness.py" in script_text, f"{label} missing canonical handoff bundle readiness assessment"
    assert "validate_supervisor_operator_handoff_bundle_readiness.py" in script_text, f"{label} missing canonical handoff bundle readiness validator"
    assert "doctor_supervisor_operator_handoff_bundle.py" in script_text, f"{label} missing canonical handoff bundle doctor"
    assert "gate_supervisor_operator_handoff_bundle.sh" in script_text, f"{label} missing canonical handoff bundle gate"
    assert "canonical_preview" in script_text, f"{label} missing canonical preview equality assertion"
    assert "canonical_display_packet" in script_text, f"{label} missing canonical display packet equality assertion"
    assert "_bundle" in script_text, f"{label} missing canonical bundle equality assertion"
    assert "_bundle_validation" in script_text, f"{label} missing canonical bundle validation assertion"
    assert "_bundle_readiness" in script_text, f"{label} missing canonical bundle readiness assertion"
    assert "_bundle_readiness_validation" in script_text, f"{label} missing canonical bundle readiness validation assertion"
    assert "_bundle_doctor_readiness" in script_text, f"{label} missing canonical doctor readiness assertion"
    assert "_bundle_doctor_readiness_validation" in script_text, f"{label} missing canonical doctor readiness validation assertion"
    assert "operator_handoff_validation_path" in script_text, f"{label} missing canonical handoff validation assertion"
PY

echo "supervisor handoff bridge wiring ok"
