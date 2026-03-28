#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
RESOLVER_PATH="$ROOT_DIR/planningops/scripts/resolve_plain_python_compat_manifest.py"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh"
CHECK_PATH="$ROOT_DIR/planningops/scripts/run_monday_agent_harness_projection_ci_check.sh"
PLATFORM_CONTRACTS_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_platform_contracts_ci_check.sh"
FEDERATED_CONFORMANCE_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_federated_conformance_ci_check.sh"
FEDERATED_SUMMARY_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_federated_summary_ci_check.sh"
RUNTIME_HANDOFF_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_runtime_handoff_ci_check.sh"
PROVIDER_PROFILE_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_provider_profile_ci_check.sh"
O11Y_REPLAY_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_o11y_replay_ci_check.sh"
PLAIN_PYTHON_WORKFLOW_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_plain_python_compat_workflow_chain.sh"
ISSUE_QUALITY_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_issue_quality_ci_check.sh"
EXTERNAL_ARTIFACT_RESIDENCY_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_external_artifact_residency_ci_check.sh"
CONTROL_PLANE_GOVERNANCE_HELPER_PATH="$ROOT_DIR/planningops/scripts/run_control_plane_governance_ci_check.sh"

python3 - <<'PY' "$WORKFLOW_PATH" "$RESOLVER_PATH" "$HELPER_PATH" "$CHECK_PATH" "$PLATFORM_CONTRACTS_HELPER_PATH" "$FEDERATED_CONFORMANCE_HELPER_PATH" "$FEDERATED_SUMMARY_HELPER_PATH" "$RUNTIME_HANDOFF_HELPER_PATH" "$PROVIDER_PROFILE_HELPER_PATH" "$O11Y_REPLAY_HELPER_PATH" "$PLAIN_PYTHON_WORKFLOW_HELPER_PATH" "$ISSUE_QUALITY_HELPER_PATH" "$EXTERNAL_ARTIFACT_RESIDENCY_HELPER_PATH" "$CONTROL_PLANE_GOVERNANCE_HELPER_PATH"
import json
import subprocess
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
resolver_path = Path(sys.argv[2])
helper_path = Path(sys.argv[3])
check_path = Path(sys.argv[4])
platform_contracts_helper_path = Path(sys.argv[5])
federated_conformance_helper_path = Path(sys.argv[6])
federated_summary_helper_path = Path(sys.argv[7])
runtime_handoff_helper_path = Path(sys.argv[8])
provider_profile_helper_path = Path(sys.argv[9])
o11y_replay_helper_path = Path(sys.argv[10])
plain_python_workflow_helper_path = Path(sys.argv[11])
issue_quality_helper_path = Path(sys.argv[12])
external_artifact_residency_helper_path = Path(sys.argv[13])
control_plane_governance_helper_path = Path(sys.argv[14])
contract_conformance_job = workflow.split("  contract-conformance:", 1)[1].split("  provider-profile:", 1)[0]
federated_conformance = workflow.split("  federated-conformance:", 1)[1].split("  loop-guardrails:", 1)[0]
loop_guardrails = workflow.split("  loop-guardrails:", 1)[1].split("  federated-summary:", 1)[0]
guardrails = json.loads(
    subprocess.check_output(
        ["python3", str(resolver_path), "--mode", "guardrails"],
        text=True,
    )
)
helper_tests = subprocess.check_output(
    ["bash", str(helper_path), "--print-tests"],
    text=True,
).splitlines()
workflow_invocation = subprocess.check_output(
    ["bash", str(check_path), "--print-workflow-invocation"],
    text=True,
).strip()
platform_contracts_workflow_invocation = subprocess.check_output(
    ["bash", str(platform_contracts_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
federated_conformance_workflow_invocation = subprocess.check_output(
    ["bash", str(federated_conformance_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
federated_summary_workflow_invocation = subprocess.check_output(
    ["bash", str(federated_summary_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
runtime_handoff_workflow_invocation = subprocess.check_output(
    ["bash", str(runtime_handoff_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
provider_profile_workflow_invocation = subprocess.check_output(
    ["bash", str(provider_profile_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
o11y_replay_workflow_invocation = subprocess.check_output(
    ["bash", str(o11y_replay_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
plain_python_workflow_invocation = subprocess.check_output(
    ["bash", str(plain_python_workflow_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
plain_python_workflow_steps = subprocess.check_output(
    ["bash", str(plain_python_workflow_helper_path), "--print-steps"],
    text=True,
).splitlines()
issue_quality_workflow_invocation = subprocess.check_output(
    ["bash", str(issue_quality_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
issue_quality_workflow_steps = subprocess.check_output(
    ["bash", str(issue_quality_helper_path), "--print-steps"],
    text=True,
).splitlines()
external_artifact_residency_workflow_invocation = subprocess.check_output(
    ["bash", str(external_artifact_residency_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
external_artifact_residency_workflow_steps = subprocess.check_output(
    ["bash", str(external_artifact_residency_helper_path), "--print-steps"],
    text=True,
).splitlines()
control_plane_governance_workflow_invocation = subprocess.check_output(
    ["bash", str(control_plane_governance_helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
control_plane_governance_workflow_steps = subprocess.check_output(
    ["bash", str(control_plane_governance_helper_path), "--print-steps"],
    text=True,
).splitlines()

assert "federated-summary:" in workflow, "missing federated-summary job"
assert "run_federated_summary_ci_check.sh" in workflow, "federated-summary helper missing"
assert "planningops/artifacts/ci/federated-ci-summary.json" in workflow, "latest summary artifact missing"
assert "planningops/artifacts/ci/ci-${{ github.run_id }}.json" in workflow, "stamped summary artifact missing"
assert "planningops/artifacts/validation/ci-${{ github.run_id }}-summary-validation.json" in workflow, "summary validation artifact missing"
assert "planningops/artifacts/validation/federated-ci-summary-validation.json" in workflow, "latest summary validation artifact missing"
assert "planningops/artifacts/validation/ci-${{ github.run_id }}-summary-readiness.json" in workflow, "stamped summary readiness artifact missing"
assert "planningops/artifacts/validation/federated-ci-summary-readiness.json" in workflow, "latest summary readiness artifact missing"
assert "planningops/artifacts/validation/ci-${{ github.run_id }}-summary-readiness-validation.json" in workflow, "stamped summary readiness validation artifact missing"
assert "planningops/artifacts/validation/federated-ci-summary-readiness-validation.json" in workflow, "latest summary readiness validation artifact missing"
assert "test_reconcile_federated_ci_summary_tmp.sh" in workflow, "summary checkpoint reconcile regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_contract.sh" in workflow, "summary checkpoint reconcile validation regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile.sh" in workflow, "summary checkpoint reconcile resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle.sh" in workflow, "summary checkpoint reconcile bundle validation regression missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle.sh" in workflow, "summary checkpoint reconcile bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle.sh" in workflow, "summary checkpoint reconcile bundle gate regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status-validation contract missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle validation regression missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle gate regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status-validation contract missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status-validation contract missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle gate regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status-validation contract missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle gate regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_STATUS_bundle_validation_contract.sh" not in workflow, "unexpected invalid summary checkpoint contract token present"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status-validation contract missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle gate regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_STATUS_bundle_validation_contract.sh" not in workflow, "unexpected invalid summary checkpoint validator token present"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status-validation contract missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle gate regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status-validation contract missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle gate regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status contract missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status-validation contract missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status gate regression missing"
assert "test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status resolver regression missing"
assert "test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh" in workflow, "summary checkpoint reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation regression missing"
assert "test_doctor_federated_ci_summary_tmp_reconcile.sh" in workflow, "summary checkpoint reconcile doctor regression missing"
assert "test_gate_federated_ci_summary_tmp_reconcile.sh" in workflow, "summary checkpoint reconcile gate regression missing"
assert "test_federated_ci_summary_contract_doc.sh" in workflow, "summary contract doc regression missing"
assert "test_cross_repo_conformance_run_root_reuse_contract.sh" in workflow, "cross repo conformance run-root reuse regression missing"
assert "test_plain_python_compat_manifest_contract_doc.sh" in workflow, "plain python compat manifest contract doc regression missing"
assert "test_uap_automation_operations_summary_contract.sh" in workflow, "automation operations summary regression missing"
assert "test_run_contract_conformance_ci_check_contract.sh" in workflow, "contract-conformance helper contract regression missing"
assert "test_contract_conformance_helper_wiring.sh" in workflow, "contract-conformance helper wiring regression missing"
assert "test_run_platform_contracts_ci_check_contract.sh" in workflow, "platform-contracts helper contract regression missing"
assert "test_platform_contracts_helper_wiring.sh" in workflow, "platform-contracts helper wiring regression missing"
assert "test_run_federated_conformance_ci_check_contract.sh" in workflow, "federated-conformance helper contract regression missing"
assert "test_federated_conformance_helper_wiring.sh" in workflow, "federated-conformance helper wiring regression missing"
assert "test_run_federated_summary_ci_check_contract.sh" in workflow, "federated-summary helper contract regression missing"
assert "test_federated_summary_helper_wiring.sh" in workflow, "federated-summary helper wiring regression missing"
assert "test_run_federated_summary_ci_check_smoke.sh" in workflow, "federated-summary helper smoke regression missing"
assert "run_platform_contracts_ci_check.sh" in workflow, "platform-contracts helper missing"
assert platform_contracts_workflow_invocation in contract_conformance_job, "contract-conformance job missing platform-contracts helper invocation"
assert contract_conformance_job.count(platform_contracts_workflow_invocation) == 1, "contract-conformance job should invoke platform-contracts helper once"
assert "python3 -m pip install -r requirements-dev.txt" not in contract_conformance_job, "contract-conformance job should not inline requirements install"
assert "python3 scripts/validate_contracts.py --root ." not in contract_conformance_job, "contract-conformance job should not inline contract validator"
assert "python3 scripts/classify_schema_change.py --enforce-expected" not in contract_conformance_job, "contract-conformance job should not inline semver classifier"
assert "test_run_provider_profile_ci_check_contract.sh" in workflow, "provider-profile helper contract regression missing"
assert "test_provider_profile_helper_wiring.sh" in workflow, "provider-profile helper wiring regression missing"
assert "test_run_provider_gateway_ready_ci_check_contract.sh" in workflow, "provider-gateway-ready helper contract regression missing"
assert "test_provider_gateway_ready_helper_wiring.sh" in workflow, "provider-gateway-ready helper wiring regression missing"
assert "test_run_plain_python_compat_workflow_chain_contract.sh" in workflow, "plain-python compat workflow helper contract regression missing"
assert "test_run_issue_quality_ci_check_contract.sh" in workflow, "issue-quality helper contract regression missing"
assert "test_issue_quality_helper_wiring.sh" in workflow, "issue-quality helper wiring regression missing"
assert "test_run_external_artifact_residency_ci_check_contract.sh" in workflow, "external-artifact residency helper contract regression missing"
assert "test_external_artifact_residency_helper_wiring.sh" in workflow, "external-artifact residency helper wiring regression missing"
assert "test_run_control_plane_governance_ci_check_contract.sh" in workflow, "control-plane governance helper contract regression missing"
assert "test_control_plane_governance_helper_wiring.sh" in workflow, "control-plane governance helper wiring regression missing"
assert "run_provider_profile_ci_check.sh" in workflow, "provider-profile helper missing"
assert provider_profile_workflow_invocation in workflow, "provider-profile helper workflow call missing"
assert "test_run_o11y_replay_ci_check_contract.sh" in workflow, "o11y helper contract regression missing"
assert "test_o11y_replay_helper_wiring.sh" in workflow, "o11y helper wiring regression missing"
assert "test_run_runtime_operations_ready_ci_check_contract.sh" in workflow, "runtime-operations-ready helper contract regression missing"
assert "test_runtime_operations_ready_helper_wiring.sh" in workflow, "runtime-operations-ready helper wiring regression missing"
assert "run_o11y_replay_ci_check.sh" in workflow, "o11y helper missing"
assert o11y_replay_workflow_invocation in workflow, "o11y helper workflow call missing"
assert "run_runtime_handoff_ci_check.sh" in workflow, "runtime handoff ci helper missing"
assert runtime_handoff_workflow_invocation in workflow, "runtime handoff ci helper call missing"
assert "run_monday_agent_harness_projection_ci_check.sh" in workflow, "monday projection ci check helper missing"
assert workflow_invocation in workflow, "monday projection ci check call missing"
assert "monday-harness-projection:" in workflow, "monday harness projection job missing"
assert "repository: rather-not-work-on/platform-observability-gateway" in workflow, "observability checkout missing for compat smoke"
assert "repository: rather-not-work-on/platform-provider-gateway" in workflow, "provider checkout missing for runtime stack sequence smoke"
assert "repository: rather-not-work-on/monday" in workflow, "monday checkout missing for compat smoke"
assert federated_conformance.count("repository: rather-not-work-on/platform-provider-gateway") == 1, "federated-conformance should checkout provider gateway exactly once"
assert federated_conformance_workflow_invocation in federated_conformance, "federated-conformance job missing helper invocation"
assert federated_conformance.count(federated_conformance_workflow_invocation) == 1, "federated-conformance job should invoke helper once"
assert "python3 -m pip install -r platform-contracts/requirements-dev.txt" not in federated_conformance, "federated-conformance job should not inline contracts requirements install"
assert "python3 -m pip install -r platform-provider-gateway/requirements-dev.txt" not in federated_conformance, "federated-conformance job should not inline provider requirements install"
assert "python3 -m pip install -r platform-observability-gateway/requirements-dev.txt" not in federated_conformance, "federated-conformance job should not inline observability requirements install"
assert "python3 -m pip install -r monday/requirements-dev.txt" not in federated_conformance, "federated-conformance job should not inline monday requirements install"
assert "rollout_external_artifact_policy.py" not in federated_conformance, "federated-conformance job should not inline artifact policy rollout command"
assert "cross_repo_conformance_check.py" not in federated_conformance, "federated-conformance job should not inline conformance checker command"
assert "if: always()" in workflow.split("      - name: Upload federated summary artifact", 1)[1].split("        with:", 1)[0], "summary artifact upload must run on failure"
provider_profile_job = workflow.split("  provider-profile:", 1)[1].split("  o11y-replay:", 1)[0]
assert provider_profile_workflow_invocation in provider_profile_job, "provider-profile job missing helper invocation"
assert provider_profile_job.count(provider_profile_workflow_invocation) == 1, "provider-profile job should invoke helper once"
assert "litellm_stack_launcher.sh" not in provider_profile_job, "provider-profile job should not inline launcher command"
o11y_replay_job = workflow.split("  o11y-replay:", 1)[1].split("  runtime-handoff:", 1)[0]
assert o11y_replay_workflow_invocation in o11y_replay_job, "o11y-replay job missing helper invocation"
assert o11y_replay_job.count(o11y_replay_workflow_invocation) == 1, "o11y-replay job should invoke helper once"
assert "langfuse_stack_launcher.sh" not in o11y_replay_job, "o11y-replay job should not inline launcher command"

expected_plain_python_workflow_steps = [step["workflow_command"] for step in guardrails]
assert plain_python_workflow_steps == expected_plain_python_workflow_steps, "plain-python compat workflow helper steps drifted from manifest"
assert plain_python_workflow_invocation in loop_guardrails, "loop-guardrails missing plain-python compat workflow helper invocation"
assert loop_guardrails.count(plain_python_workflow_invocation) == 1, "loop-guardrails should invoke plain-python compat workflow helper once"
for snippet in expected_plain_python_workflow_steps:
    assert snippet not in loop_guardrails, f"workflow loop-guardrails should not inline plain-python compat snippet once helper exists: {snippet}"
assert issue_quality_workflow_invocation in loop_guardrails, "loop-guardrails missing issue-quality helper invocation"
assert loop_guardrails.count(issue_quality_workflow_invocation) == 1, "loop-guardrails should invoke issue-quality helper once"
for snippet in issue_quality_workflow_steps:
    assert snippet not in loop_guardrails, f"workflow loop-guardrails should not inline issue-quality helper step once helper exists: {snippet}"
assert external_artifact_residency_workflow_invocation in loop_guardrails, "loop-guardrails missing external-artifact residency helper invocation"
assert loop_guardrails.count(external_artifact_residency_workflow_invocation) == 1, "loop-guardrails should invoke external-artifact residency helper once"
for snippet in external_artifact_residency_workflow_steps:
    assert snippet not in loop_guardrails, f"workflow loop-guardrails should not inline external-artifact residency helper step once helper exists: {snippet}"
assert control_plane_governance_workflow_invocation in loop_guardrails, "loop-guardrails missing control-plane governance helper invocation"
assert loop_guardrails.count(control_plane_governance_workflow_invocation) == 1, "loop-guardrails should invoke control-plane governance helper once"
for snippet in control_plane_governance_workflow_steps:
    assert snippet not in loop_guardrails, f"workflow loop-guardrails should not inline control-plane governance helper step once helper exists: {snippet}"

summary_job = workflow.split("federated-summary:", 1)[1]
summary_job = summary_job.split("      - name: Upload federated summary artifact", 1)[0]
assert federated_summary_workflow_invocation in summary_job, "federated-summary job missing helper invocation"
assert summary_job.count(federated_summary_workflow_invocation) == 1, "federated-summary job should invoke helper once"
assert "append_job_result() {" not in summary_job, "inline append_job_result still present in federated-summary job"
assert "federated_ci_summary.py" not in summary_job, "inline summary helper path still present in federated-summary job"
assert "assess_federated_ci_summary_readiness.py" not in summary_job, "inline readiness helper path still present in federated-summary job"
assert "python3 - <<'PY'" not in summary_job, "inline python still present in federated-summary job"

for helper_test in helper_tests:
    assert helper_test not in workflow, f"workflow should call monday projection helper only, found direct suite entry: {helper_test}"

assert "test_run_monday_agent_harness_projection_ci_check_contract.sh" not in workflow, "workflow should not call monday projection ci check contract directly"
assert "run_monday_agent_harness_projection_ci_suite.sh" not in workflow, "workflow should not call monday projection suite helper directly"
PY

echo "federated ci workflow summary contract ok"
