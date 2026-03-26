#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_issue_quality_ci_check.sh"

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
workflow_invocation = subprocess.check_output(
    ["bash", str(script_path), "--print-workflow-invocation"],
    text=True,
).strip()
help_output = subprocess.check_output(
    ["bash", str(script_path), "--help"],
    text=True,
)

expected_steps = [
    "bash planningops/scripts/test_validate_issue_quality_contract.sh",
    "bash planningops/scripts/test_validate_federated_issue_quality_contract.sh",
    "python3 planningops/scripts/validate_issue_quality.py --strict",
]

assert steps == expected_steps, "issue-quality helper step inventory drifted"
assert workflow_invocation == "bash planningops/scripts/run_issue_quality_ci_check.sh --python-bin python3", "issue-quality helper workflow invocation drifted"
assert "usage: run_issue_quality_ci_check.sh [options]" in help_output, "issue-quality helper usage missing"
assert "--python-bin <path>" in help_output, "issue-quality helper help missing python-bin flag"
assert "--print-steps" in help_output, "issue-quality helper help missing steps flag"
assert "--print-workflow-invocation" in help_output, "issue-quality helper help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_issue_quality_ci_check_contract.sh"' in script, "issue-quality helper must self-run its contract test"
assert 'bash planningops/scripts/test_validate_issue_quality_contract.sh' in script, "issue-quality helper missing issue-quality contract regression"
assert 'bash planningops/scripts/test_validate_federated_issue_quality_contract.sh' in script, "issue-quality helper missing federated issue-quality contract regression"
assert '"${PYTHON_BIN}" planningops/scripts/validate_issue_quality.py --strict' in script, "issue-quality helper missing live validator wiring"
PY

echo "issue quality ci check contract ok"
