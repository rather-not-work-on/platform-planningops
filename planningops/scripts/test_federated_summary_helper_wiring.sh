#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_federated_summary_ci_check.sh"

python3 - <<'PY' "$WORKFLOW_PATH" "$HELPER_PATH"
import subprocess
import sys
from pathlib import Path

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
helper_path = Path(sys.argv[2])

workflow_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-workflow-invocation"],
    text=True,
).strip()

workflow_block = workflow.split("  federated-summary:", 1)[1].split("      - name: Upload federated summary artifact", 1)[0]

assert workflow_invocation in workflow_block, "workflow federated-summary job missing helper invocation"
assert workflow_block.count(workflow_invocation) == 1, "workflow federated-summary helper invocation should appear once"
assert "append_job_result()" not in workflow_block, "workflow federated-summary job should not inline append_job_result shell function"
assert "federated_ci_summary.py" not in workflow_block, "workflow federated-summary job should not inline summary helper path"
assert "assess_federated_ci_summary_readiness.py" not in workflow_block, "workflow federated-summary job should not inline readiness helper path"
PY

echo "federated summary helper wiring ok"
