#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HELPER_PATH="${ROOT_DIR}/planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh"
CHECK_PATH="${ROOT_DIR}/planningops/scripts/run_monday_agent_harness_projection_ci_check.sh"
LOCAL_MATRIX_PATH="${ROOT_DIR}/planningops/scripts/federation/federated_ci_matrix_local.sh"
WORKFLOW_PATH="${ROOT_DIR}/.github/workflows/federated-ci-matrix.yml"

python3 - <<'PY' "${HELPER_PATH}" "${CHECK_PATH}" "${LOCAL_MATRIX_PATH}" "${WORKFLOW_PATH}"
import subprocess
import sys
from pathlib import Path

helper_path = Path(sys.argv[1])
check_path = Path(sys.argv[2])
local_matrix = Path(sys.argv[3]).read_text(encoding="utf-8")
workflow = Path(sys.argv[4]).read_text(encoding="utf-8")

helper_tests = subprocess.check_output(
    ["bash", str(helper_path), "--print-tests"],
    text=True,
).splitlines()
assert helper_tests, "monday projection helper TESTS array empty"

check_steps = subprocess.check_output(
    ["bash", str(check_path), "--print-steps"],
    text=True,
).splitlines()
local_invocation = subprocess.check_output(
    ["bash", str(check_path), "--print-local-invocation"],
    text=True,
).strip()
workflow_invocation = subprocess.check_output(
    ["bash", str(check_path), "--print-workflow-invocation"],
    text=True,
).strip()
assert check_steps == [
    "planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh",
    "planningops/scripts/test_monday_agent_harness_projection_helper_wiring.sh",
    "planningops/scripts/test_run_monday_agent_harness_projection_ci_suite_contract.sh",
    "planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh",
], "monday projection ci check wrapper step inventory drifted"
local_required = [
    local_invocation,
]
workflow_required = [
    workflow_invocation,
]

for snippet in local_required:
    assert snippet in local_matrix, f"missing local matrix helper wiring snippet: {snippet}"
    assert local_matrix.count(snippet) == 1, f"local matrix helper wiring snippet should appear once: {snippet}"

for snippet in workflow_required:
    assert snippet in workflow, f"missing workflow helper wiring snippet: {snippet}"
    assert workflow.count(snippet) == 1, f"workflow helper wiring snippet should appear once: {snippet}"

for helper_test in helper_tests:
    assert helper_test not in local_matrix, f"local matrix should not inline helper suite entry: {helper_test}"
    assert helper_test not in workflow, f"workflow should not inline helper suite entry: {helper_test}"

assert "test_monday_agent_harness_projection_helper_wiring.sh" not in local_matrix, "local matrix should not call helper wiring test directly"
assert "test_monday_agent_harness_projection_helper_wiring.sh" not in workflow, "workflow should not call helper wiring test directly"
assert "test_run_monday_agent_harness_projection_ci_check_contract.sh" not in local_matrix, "local matrix should not call monday check contract directly"
assert "test_run_monday_agent_harness_projection_ci_check_contract.sh" not in workflow, "workflow should not call monday check contract directly"
assert "test_run_monday_agent_harness_projection_ci_suite_contract.sh" not in local_matrix, "local matrix should not call monday suite contract directly"
assert "test_run_monday_agent_harness_projection_ci_suite_contract.sh" not in workflow, "workflow should not call monday suite contract directly"
assert "run_monday_agent_harness_projection_ci_suite.sh" not in local_matrix, "local matrix should not call monday suite helper directly"
assert "run_monday_agent_harness_projection_ci_suite.sh" not in workflow, "workflow should not call monday suite helper directly"
assert "sync_monday_agent_harness_projection_latest.sh" not in local_matrix, "local matrix should not call monday sync helper directly"
assert "sync_monday_agent_harness_projection_latest.sh" not in workflow, "workflow should not call monday sync helper directly"
PY

echo "monday agent harness projection helper wiring ok"
