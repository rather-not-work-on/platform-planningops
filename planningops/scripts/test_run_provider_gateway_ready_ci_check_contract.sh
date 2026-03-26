#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_provider_gateway_ready_ci_check.sh"

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

assert local_invocation == "bash planningops/scripts/run_provider_gateway_ready_ci_check.sh --run-id ${RUN_ID}-provider-gateway-ready --provider-root ../platform-provider-gateway", "local provider-gateway-ready helper invocation drifted"
assert "usage: run_provider_gateway_ready_ci_check.sh [options]" in help_output, "provider-gateway-ready help usage missing"
assert "--run-id <id>" in help_output, "provider-gateway-ready help missing run-id flag"
assert "--provider-root <path>" in help_output, "provider-gateway-ready help missing provider-root flag"
assert "--print-local-invocation" in help_output, "provider-gateway-ready help missing local invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_provider_gateway_ready_ci_check_contract.sh"' in script, "provider-gateway-ready helper must self-run its contract test"
assert "trap cleanup EXIT" in script, "provider-gateway-ready helper missing cleanup trap"
assert 'bash scripts/litellm_stack_launcher.sh --mode start --run-id "${RUN_ID}"' in script, "provider-gateway-ready helper missing stack start wiring"
assert 'bash scripts/litellm_stack_launcher.sh --mode stop >/dev/null 2>&1 || true' in script, "provider-gateway-ready helper missing stack stop wiring"
assert "npm run gate:litellm-stack-ready" in script, "provider-gateway-ready helper missing readiness gate command"
PY

echo "provider gateway ready ci check contract ok"
