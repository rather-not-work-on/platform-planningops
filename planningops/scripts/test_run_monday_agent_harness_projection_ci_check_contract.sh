#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_monday_agent_harness_projection_ci_check.sh"

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
    "planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh",
    "planningops/scripts/test_monday_agent_harness_projection_helper_wiring.sh",
    "planningops/scripts/test_run_monday_agent_harness_projection_ci_suite_contract.sh",
    "planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh",
]

assert steps == expected, "printed step inventory drifted from canonical monday projection ci check chain"
assert "--print-steps" in script, "print-steps switch missing"
assert 'printf \'%s\\n\' "${STEPS[@]}"' in script, "print-steps output missing"
assert "--print-local-invocation" in script, "print-local-invocation switch missing"
assert "--print-workflow-invocation" in script, "print-workflow-invocation switch missing"
assert "usage: run_monday_agent_harness_projection_ci_check.sh [options] [suite-options]" in help_output, "ci check help usage missing"
assert "--print-steps" in help_output, "ci check help missing print-steps flag"
assert "--print-local-invocation" in help_output, "ci check help missing print-local-invocation flag"
assert "--print-workflow-invocation" in help_output, "ci check help missing print-workflow-invocation flag"
assert "passed through to run_monday_agent_harness_projection_ci_suite.sh" in help_output, "ci check help missing suite passthrough note"
assert local_invocation == "bash planningops/scripts/run_monday_agent_harness_projection_ci_check.sh --summary-run-id ${RUN_ID} --monday-root ../monday --mission-id monday-harness-projection", "local invocation drifted"
assert workflow_invocation == "bash planningops/scripts/run_monday_agent_harness_projection_ci_check.sh --summary-run-id ci-${{ github.run_id }} --monday-root monday --mission-id monday-harness-projection", "workflow invocation drifted"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh"' in script, "ci check self-contract invocation missing"
assert 'bash "${ROOT_DIR}/planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh" "$@"' in script, "suite helper invocation missing"
PY

echo "monday agent harness projection ci check contract ok"
