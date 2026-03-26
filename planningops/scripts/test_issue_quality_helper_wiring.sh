#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_PATH="${ROOT_DIR}/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="${ROOT_DIR}/planningops/scripts/run_issue_quality_ci_check.sh"

python3 - <<'PY' "${WORKFLOW_PATH}" "${HELPER_PATH}"
import subprocess
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
helper_path = Path(sys.argv[2])
loop_guardrails = workflow.split("  loop-guardrails:", 1)[1].split("  federated-summary:", 1)[0]
workflow_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
steps = subprocess.check_output(
    ["bash", str(helper_path), "--print-steps"],
    text=True,
).splitlines()

assert "test_run_issue_quality_ci_check_contract.sh" in loop_guardrails, "loop-guardrails missing issue-quality helper contract regression"
assert "test_issue_quality_helper_wiring.sh" in loop_guardrails, "loop-guardrails missing issue-quality helper wiring regression"
assert workflow_invocation in loop_guardrails, "loop-guardrails missing issue-quality helper invocation"
assert loop_guardrails.count(workflow_invocation) == 1, "loop-guardrails should invoke issue-quality helper once"
for step in steps:
    assert step not in loop_guardrails, f"loop-guardrails should not inline issue-quality helper step once helper exists: {step}"
PY

echo "issue quality helper wiring ok"
