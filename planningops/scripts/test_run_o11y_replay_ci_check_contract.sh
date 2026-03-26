#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_o11y_replay_ci_check.sh"

python3 - <<'PY' "${SCRIPT_PATH}"
import subprocess
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
script = script_path.read_text(encoding="utf-8")
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

assert local_invocation == "bash planningops/scripts/run_o11y_replay_ci_check.sh --run-id ${RUN_ID}-o11y --o11y-root ../platform-observability-gateway", "local o11y helper invocation drifted"
assert workflow_invocation == "bash planningops/scripts/run_o11y_replay_ci_check.sh --run-id ci-o11y-${{ github.run_id }} --o11y-root platform-observability-gateway", "workflow o11y helper invocation drifted"
assert "usage: run_o11y_replay_ci_check.sh [options]" in help_output, "o11y helper help usage missing"
assert "--run-id <id>" in help_output, "o11y helper help missing run-id flag"
assert "--o11y-root <path>" in help_output, "o11y helper help missing o11y-root flag"
assert "--print-local-invocation" in help_output, "o11y helper help missing local invocation flag"
assert "--print-workflow-invocation" in help_output, "o11y helper help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_o11y_replay_ci_check_contract.sh"' in script, "o11y helper must self-run its contract test"
assert "bash scripts/langfuse_stack_launcher.sh --mode dry-run --run-id \"${RUN_ID}\"" in script, "o11y helper missing dry-run launcher command"
PY

echo "o11y replay ci check contract ok"
