#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_runtime_operations_ready_ci_check.sh"

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
help_output = subprocess.check_output(
    ["bash", str(script_path), "--help"],
    text=True,
)

assert local_invocation == "bash planningops/scripts/run_runtime_operations_ready_ci_check.sh --run-id ${RUN_ID}-runtime-operations-ready --provider-root ../platform-provider-gateway --monday-root ../monday --runtime-profile ${LOCAL_RUNTIME_PROFILE}", "local runtime-operations-ready helper invocation drifted"
assert "usage: run_runtime_operations_ready_ci_check.sh [options]" in help_output, "runtime-operations-ready help usage missing"
assert "--run-id <id>" in help_output, "runtime-operations-ready help missing run-id flag"
assert "--provider-root <path>" in help_output, "runtime-operations-ready help missing provider-root flag"
assert "--monday-root <path>" in help_output, "runtime-operations-ready help missing monday-root flag"
assert "--runtime-profile <name>" in help_output, "runtime-operations-ready help missing runtime-profile flag"
assert "--print-local-invocation" in help_output, "runtime-operations-ready help missing local invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_runtime_operations_ready_ci_check_contract.sh"' in script, "runtime-operations-ready helper must self-run its contract test"
assert "trap cleanup EXIT" in script, "runtime-operations-ready helper missing cleanup trap"
assert 'bash scripts/litellm_stack_launcher.sh --mode start --run-id "${RUN_ID}"' in script, "runtime-operations-ready helper missing stack start wiring"
assert 'bash scripts/litellm_stack_launcher.sh --mode stop >/dev/null 2>&1 || true' in script, "runtime-operations-ready helper missing stack stop wiring"
assert 'PLANNER_RUNTIME_PROFILE="${RUNTIME_PROFILE}" npm run gate:runtime-operations-ready' in script, "runtime-operations-ready helper missing monday gate wiring"
PY

echo "runtime operations ready ci check contract ok"
