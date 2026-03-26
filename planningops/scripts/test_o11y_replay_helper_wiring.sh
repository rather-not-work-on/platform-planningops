#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_MATRIX_PATH="$ROOT_DIR/planningops/scripts/federation/federated_ci_matrix_local.sh"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_o11y_replay_ci_check.sh"

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

local_block = local_matrix.split('run_check "o11y-replay" "infra" \\', 1)[1].split('run_check "runtime-handoff" "runtime" \\', 1)[0]
workflow_block = workflow.split("  o11y-replay:", 1)[1].split("  runtime-handoff:", 1)[0]

assert local_invocation in local_block, "local o11y-replay block missing helper invocation"
assert workflow_invocation in workflow_block, "workflow o11y-replay job missing helper invocation"
assert local_block.count(local_invocation) == 1, "local o11y-replay helper invocation should appear once"
assert workflow_block.count(workflow_invocation) == 1, "workflow o11y-replay helper invocation should appear once"
assert "langfuse_stack_launcher.sh" not in local_block, "local o11y-replay block should not inline launcher command"
assert "langfuse_stack_launcher.sh" not in workflow_block, "workflow o11y-replay job should not inline launcher command"
PY

echo "o11y replay helper wiring ok"
