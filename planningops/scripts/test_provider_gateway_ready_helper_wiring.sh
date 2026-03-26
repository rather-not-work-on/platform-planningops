#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_MATRIX_PATH="$ROOT_DIR/planningops/scripts/federation/federated_ci_matrix_local.sh"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_provider_gateway_ready_ci_check.sh"

python3 - <<'PY' "$LOCAL_MATRIX_PATH" "$HELPER_PATH"
import subprocess
import sys
from pathlib import Path

local_matrix = Path(sys.argv[1]).read_text(encoding="utf-8")
helper_path = Path(sys.argv[2])

local_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-local-invocation"],
    text=True,
).strip()

local_block = local_matrix.split('run_check "provider-gateway-ready" "infra" \\', 1)[1].split('run_check "o11y-replay" "infra" \\', 1)[0]

assert local_invocation in local_block, "local provider-gateway-ready block missing helper invocation"
assert local_block.count(local_invocation) == 1, "local provider-gateway-ready helper invocation should appear once"
assert "run_with_litellm_stack" not in local_block, "local provider-gateway-ready block should not inline stack wrapper"
assert "litellm_stack_launcher.sh" not in local_block, "local provider-gateway-ready block should not inline launcher command"
assert "gate:litellm-stack-ready" not in local_block, "local provider-gateway-ready block should not inline readiness gate command"
PY

echo "provider gateway ready helper wiring ok"
