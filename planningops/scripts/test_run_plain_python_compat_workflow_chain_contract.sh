#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_plain_python_compat_workflow_chain.sh"
RESOLVER_PATH="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"

python3 - <<'PY' "${SCRIPT_PATH}" "${RESOLVER_PATH}"
import json
import subprocess
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
resolver_path = Path(sys.argv[2])
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
guardrails = json.loads(
    subprocess.check_output(
        ["python3", str(resolver_path), "--mode", "guardrails"],
        text=True,
    )
)
expected_steps = [step["workflow_command"] for step in guardrails]

assert steps == expected_steps, "plain-python compat workflow helper steps drifted"
assert workflow_invocation == "bash planningops/scripts/run_plain_python_compat_workflow_chain.sh", "plain-python compat workflow invocation drifted"
assert "usage: run_plain_python_compat_workflow_chain.sh [options]" in help_output, "plain-python compat helper usage missing"
assert "--manifest-file <path>" in help_output, "plain-python compat helper help missing manifest flag"
assert "--print-steps" in help_output, "plain-python compat helper help missing steps flag"
assert "--print-workflow-invocation" in help_output, "plain-python compat helper help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_plain_python_compat_workflow_chain_contract.sh"' in script, "plain-python compat workflow helper must self-run its contract test"
assert "resolve_plain_python_compat_manifest.py" in script, "plain-python compat workflow helper must use the canonical resolver"
assert "--mode\", \"guardrails\"" in script or "--mode guardrails" in script, "plain-python compat workflow helper must request canonical guardrails mode"
assert 'bash -lc "${step}"' in script, "plain-python compat workflow helper must replay each workflow command through bash -lc"
PY

echo "plain python compat workflow chain contract ok"
