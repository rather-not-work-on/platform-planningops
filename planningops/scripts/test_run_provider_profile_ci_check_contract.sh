#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_provider_profile_ci_check.sh"

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

assert local_invocation == "bash planningops/scripts/run_provider_profile_ci_check.sh --run-id ${RUN_ID}-provider --provider-root ../platform-provider-gateway --runtime-profile-file planningops/config/runtime-profiles.json --profiles local,oracle_cloud", "local provider-profile helper invocation drifted"
assert workflow_invocation == "bash planningops/scripts/run_provider_profile_ci_check.sh --run-id ci-provider-${{ github.run_id }} --provider-root platform-provider-gateway --runtime-profile-file planningops/config/runtime-profiles.json --profiles local,oracle_cloud", "workflow provider-profile helper invocation drifted"
assert "usage: run_provider_profile_ci_check.sh [options]" in help_output, "provider-profile help usage missing"
assert "--run-id <id>" in help_output, "provider-profile help missing run-id flag"
assert "--provider-root <path>" in help_output, "provider-profile help missing provider-root flag"
assert "--runtime-profile-file <path>" in help_output, "provider-profile help missing runtime-profile-file flag"
assert "--profiles <csv>" in help_output, "provider-profile help missing profiles flag"
assert "--print-local-invocation" in help_output, "provider-profile help missing local invocation flag"
assert "--print-workflow-invocation" in help_output, "provider-profile help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_provider_profile_ci_check_contract.sh"' in script, "provider-profile helper must self-run its contract test"
assert "bash scripts/litellm_stack_launcher.sh \\" in script, "provider-profile helper missing launcher command"
assert '--mode dry-run \\' in script, "provider-profile helper missing dry-run mode"
assert '--runtime-profile-file "${RUNTIME_PROFILE_FILE}" \\' in script, "provider-profile helper missing runtime profile file wiring"
assert '--profiles "${PROFILES}" \\' in script, "provider-profile helper missing profiles wiring"
assert '--run-id "${RUN_ID}"' in script, "provider-profile helper missing run-id wiring"
PY

echo "provider profile ci check contract ok"
