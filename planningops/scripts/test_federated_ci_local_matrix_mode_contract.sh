#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_PATH="$ROOT_DIR/scripts/federation/federated_ci_matrix_local.sh"
RESOLVER_PATH="$ROOT_DIR/scripts/resolve_plain_python_compat_manifest.py"
CONTRACT_CONFORMANCE_HELPER_PATH="$ROOT_DIR/scripts/run_contract_conformance_ci_check.sh"
HELPER_PATH="$ROOT_DIR/scripts/run_monday_agent_harness_projection_ci_suite.sh"
CHECK_PATH="$ROOT_DIR/scripts/run_monday_agent_harness_projection_ci_check.sh"
RUNTIME_HANDOFF_HELPER_PATH="$ROOT_DIR/scripts/run_runtime_handoff_ci_check.sh"
RUNTIME_OPERATIONS_READY_HELPER_PATH="$ROOT_DIR/scripts/run_runtime_operations_ready_ci_check.sh"
PROVIDER_PROFILE_HELPER_PATH="$ROOT_DIR/scripts/run_provider_profile_ci_check.sh"
PROVIDER_GATEWAY_READY_HELPER_PATH="$ROOT_DIR/scripts/run_provider_gateway_ready_ci_check.sh"
O11Y_REPLAY_HELPER_PATH="$ROOT_DIR/scripts/run_o11y_replay_ci_check.sh"

python3 - <<'PY' "$SCRIPT_PATH" "$RESOLVER_PATH" "$CONTRACT_CONFORMANCE_HELPER_PATH" "$HELPER_PATH" "$CHECK_PATH" "$RUNTIME_HANDOFF_HELPER_PATH" "$RUNTIME_OPERATIONS_READY_HELPER_PATH" "$PROVIDER_PROFILE_HELPER_PATH" "$PROVIDER_GATEWAY_READY_HELPER_PATH" "$O11Y_REPLAY_HELPER_PATH"
import json
import subprocess
import sys
from pathlib import Path

script = Path(sys.argv[1]).read_text(encoding="utf-8")
resolver_path = Path(sys.argv[2])
contract_conformance_helper_path = Path(sys.argv[3])
helper_path = Path(sys.argv[4])
check_path = Path(sys.argv[5])
runtime_handoff_helper_path = Path(sys.argv[6])
runtime_operations_ready_helper_path = Path(sys.argv[7])
provider_profile_helper_path = Path(sys.argv[8])
provider_gateway_ready_helper_path = Path(sys.argv[9])
o11y_replay_helper_path = Path(sys.argv[10])
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
contract_conformance_local_invocation = subprocess.check_output(
    ["bash", str(contract_conformance_helper_path), "--print-local-invocation"],
    text=True,
).strip()
local_invocation = subprocess.check_output(
    ["bash", str(check_path), "--print-local-invocation"],
    text=True,
).strip()
runtime_handoff_local_invocation = subprocess.check_output(
    ["bash", str(runtime_handoff_helper_path), "--print-local-invocation"],
    text=True,
).strip()
runtime_operations_ready_local_invocation = subprocess.check_output(
    ["bash", str(runtime_operations_ready_helper_path), "--print-local-invocation"],
    text=True,
).strip()
provider_profile_local_invocation = subprocess.check_output(
    ["bash", str(provider_profile_helper_path), "--print-local-invocation"],
    text=True,
).strip()
provider_gateway_ready_local_invocation = subprocess.check_output(
    ["bash", str(provider_gateway_ready_helper_path), "--print-local-invocation"],
    text=True,
).strip()
o11y_replay_local_invocation = subprocess.check_output(
    ["bash", str(o11y_replay_helper_path), "--print-local-invocation"],
    text=True,
).strip()

required_snippets = [
    'SYSTEM_PYTHON_BIN="$(command -v python3)"',
    'LOCAL_RUNTIME_PROFILE="local"',
    'SUMMARY_RECONCILE_HELPER="${ROOT_DIR}/planningops/scripts/federation/reconcile_federated_ci_summary_tmp.py"',
    'SUMMARY_CHECKPOINT_PATH="${OUT_DIR}/${RUN_ID}.checkpoint.json"',
    'LATEST_RECONCILE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile.json"',
    'STAMPED_RECONCILE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile.json"',
    'LATEST_RECONCILE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-validation.json"',
    'STAMPED_RECONCILE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-validation.json"',
    'LATEST_RECONCILE_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"',
    'LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    'STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"',
    '"provider-gateway-ready"',
    '"monday-harness-projection"',
    'run_check "provider-gateway-ready" "infra"',
    'run_check "monday-harness-projection" "runtime"',
    'cp "${SUMMARY_TMP_PATH}" "${SUMMARY_CHECKPOINT_PATH}"',
    'restore_summary_from_checkpoint_if_needed "${check_name}"',
    'local readiness_rc=0',
    'local restore_errexit=0',
    'case "$-" in',
    '*e*) restore_errexit=1 ;;',
    'python3 "${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py" write-readiness \\',
    'local stamped_readiness_rc=$?',
    'local latest_readiness_rc=$?',
    'if [[ "${restore_errexit}" -eq 1 ]]; then',
    'set -e',
    'set +e',
    'if [[ "${summary_rc}" -ne 0 ]]; then',
    'return "${summary_rc}"',
    'return "${readiness_rc}"',
    "run_check \"runtime-handoff\" \"runtime\"",
    "run_runtime_handoff_ci_check.sh",
    'bash planningops/scripts/run_monday_agent_harness_projection_ci_check.sh --summary-run-id ${RUN_ID} --monday-root ../monday --mission-id monday-harness-projection',
    'bash planningops/scripts/test_reconcile_federated_ci_summary_tmp.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_contract.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh',
    'bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh',
    'bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh',
    'bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile.sh',
    'bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile.sh',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \\',
    'python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \\',
    'bash planningops/scripts/test_plain_python_compat_manifest_contract_doc.sh',
    'bash planningops/scripts/test_cross_repo_conformance_run_root_reuse_contract.sh',
    '\\"${PYTHON_BIN}\\" planningops/scripts/verify_plan_projection.py --contract-file planningops/fixtures/plan-execution-contract-sample.json --snapshot-file planningops/fixtures/plan-projection-snapshot-sample.json --strict --output planningops/artifacts/validation/plan-projection-report.json',
    'bash planningops/scripts/test_inventory_issue_lifecycle_audit_snapshot.sh',
    'for required_check in "${REQUIRED_CHECKS[@]}"; do',
    'finalize_rc=$?',
    'SUMMARY_FINALIZED=1',
    'exit "${finalize_rc}"',
]

for snippet in required_snippets:
    assert snippet in script, f"missing local matrix mode snippet: {snippet}"

assert "assess_federated_ci_summary_readiness.py" not in script, "local matrix should route readiness writes through federated summary helper"

for step in guardrails:
    snippet = step["local_matrix_command"]
    assert snippet in script, f"missing local loop-guardrails manifest snippet: {snippet}"
    assert script.count(snippet) == 1, f"local loop-guardrails manifest snippet should appear exactly once: {snippet}"

assert script.count('PLANNINGOPS_ALLOW_SCHEMA_FETCH_FAILURE=1 \\"${PYTHON_BIN}\\" planningops/scripts/run_track1_gate_dryrun.py --kpi-path planningops/fixtures/track1-kpi-baseline-ci.json --strict') == 1, "loop-guardrails command should appear exactly once"
assert script.count('run_check "loop-guardrails" "policy"') == 1, "loop-guardrails block should appear exactly once"
assert '# duplicate loop-guardrails block removed' not in script, "loop-guardrails placeholder comments should not remain"
contract_conformance_block = script.split('run_check "contract-conformance" "contract" \\', 1)[1].split('run_check "provider-profile" "infra" \\', 1)[0]
assert contract_conformance_local_invocation in contract_conformance_block, "local matrix missing contract-conformance helper call"
assert contract_conformance_block.count(contract_conformance_local_invocation) == 1, "contract-conformance helper local invocation should appear once"
assert "cross_repo_conformance_check.py" not in contract_conformance_block, "contract-conformance block should not inline conformance checker command"
assert local_invocation in script, "local matrix missing monday projection ci check wrapper call"
assert runtime_handoff_local_invocation in script, "local matrix missing runtime handoff helper call"
provider_profile_block = script.split('run_check "provider-profile" "infra" \\', 1)[1].split('run_check "provider-gateway-ready" "infra" \\', 1)[0]
assert provider_profile_local_invocation in provider_profile_block, "local matrix missing provider-profile helper call"
assert provider_profile_block.count(provider_profile_local_invocation) == 1, "provider-profile helper local invocation should appear once"
assert "litellm_stack_launcher.sh" not in provider_profile_block, "provider-profile block should not inline launcher command"
provider_gateway_ready_block = script.split('run_check "provider-gateway-ready" "infra" \\', 1)[1].split('run_check "o11y-replay" "infra" \\', 1)[0]
assert provider_gateway_ready_local_invocation in provider_gateway_ready_block, "local matrix missing provider-gateway-ready helper call"
assert provider_gateway_ready_block.count(provider_gateway_ready_local_invocation) == 1, "provider-gateway-ready helper local invocation should appear once"
assert "run_with_litellm_stack" not in provider_gateway_ready_block, "provider-gateway-ready block should not inline stack wrapper"
assert "litellm_stack_launcher.sh" not in provider_gateway_ready_block, "provider-gateway-ready block should not inline launcher command"
assert "gate:litellm-stack-ready" not in provider_gateway_ready_block, "provider-gateway-ready block should not inline readiness gate command"
o11y_replay_block = script.split('run_check "o11y-replay" "infra" \\', 1)[1].split('run_check "runtime-handoff" "runtime" \\', 1)[0]
assert o11y_replay_local_invocation in o11y_replay_block, "local matrix missing o11y-replay helper call"
assert o11y_replay_block.count(o11y_replay_local_invocation) == 1, "o11y-replay helper local invocation should appear once"
assert "langfuse_stack_launcher.sh" not in o11y_replay_block, "o11y-replay block should not inline launcher command"
runtime_operations_ready_block = script.split('run_check "runtime-operations-ready" "runtime" \\', 1)[1].split('run_check "monday-harness-projection" "runtime" \\', 1)[0]
assert runtime_operations_ready_local_invocation in runtime_operations_ready_block, "local matrix missing runtime-operations-ready helper call"
assert runtime_operations_ready_block.count(runtime_operations_ready_local_invocation) == 1, "runtime-operations-ready helper local invocation should appear once"
assert "run_with_litellm_stack" not in runtime_operations_ready_block, "runtime-operations-ready block should not inline stack wrapper"
assert "litellm_stack_launcher.sh" not in runtime_operations_ready_block, "runtime-operations-ready block should not inline launcher command"
assert "gate:runtime-operations-ready" not in runtime_operations_ready_block, "runtime-operations-ready block should not inline monday gate command"
assert 'bash planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh' not in script, "local matrix should not call monday projection ci check contract directly"

forbidden_snippets = [
    '\\"${PYTHON_BIN}\\" planningops/scripts/verify_plan_projection.py --contract-file planningops/fixtures/plan-projection-snapshot-sample.json --snapshot-file planningops/fixtures/plan-projection-snapshot-sample.json --strict --output planningops/artifacts/validation/plan-projection-report.json',
    "--idempotency artifacts/integration/${RUN_ID}-idempotency.json",
    "--transition-log artifacts/integration/${RUN_ID}-scheduler.ndjson",
]

for snippet in forbidden_snippets:
    assert snippet not in script, f"forbidden local matrix mode snippet: {snippet}"

for helper_test in helper_tests:
    assert helper_test not in script, f"local matrix should call monday projection helper only, found direct suite entry: {helper_test}"

assert "run_monday_agent_harness_projection_ci_suite.sh" not in script, "local matrix should not call monday projection suite helper directly"
PY

echo "federated ci local matrix mode contract ok"
