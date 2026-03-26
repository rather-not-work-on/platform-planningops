#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_MATRIX_PATH="$ROOT_DIR/planningops/scripts/federation/federated_ci_matrix_local.sh"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_provider_profile_ci_check.sh"

python3 - <<'PY' "$LOCAL_MATRIX_PATH" "$WORKFLOW_PATH" "$HELPER_PATH"
import subprocess
import sys
from pathlib import Path

local_matrix = Path(sys.argv[1]).read_text(encoding="utf-8")
workflow = Path(sys.argv[2]).read_text(encoding="utf-8")
helper_path = Path(sys.argv[3])

local_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-local-invocation"],
    text=True,
).strip()
workflow_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-workflow-invocation"],
    text=True,
).strip()

local_block = local_matrix.split('run_check "provider-profile" "infra" \\', 1)[1].split('run_check "provider-gateway-ready" "infra" \\', 1)[0]
workflow_block = workflow.split("  provider-profile:", 1)[1].split("  o11y-replay:", 1)[0]

assert local_invocation in local_block, "local provider-profile block missing helper invocation"
assert workflow_invocation in workflow_block, "workflow provider-profile job missing helper invocation"
assert local_block.count(local_invocation) == 1, "local provider-profile helper invocation should appear once"
assert workflow_block.count(workflow_invocation) == 1, "workflow provider-profile helper invocation should appear once"
assert "litellm_stack_launcher.sh" not in local_block, "local provider-profile block should not inline launcher command"
assert "litellm_stack_launcher.sh" not in workflow_block, "workflow provider-profile job should not inline launcher command"
PY

echo "provider profile helper wiring ok"
