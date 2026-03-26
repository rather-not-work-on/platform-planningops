#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_federated_conformance_ci_check.sh"

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

workflow_block = workflow.split("  federated-conformance:", 1)[1].split("  loop-guardrails:", 1)[0]

assert workflow_invocation in workflow_block, "workflow federated-conformance job missing helper invocation"
assert workflow_block.count(workflow_invocation) == 1, "workflow federated-conformance helper invocation should appear once"
assert "python3 -m pip install -r platform-contracts/requirements-dev.txt" not in workflow_block, "workflow federated-conformance job should not inline requirements install"
assert "python3 -m pip install -r platform-provider-gateway/requirements-dev.txt" not in workflow_block, "workflow federated-conformance job should not inline provider requirements install"
assert "python3 -m pip install -r platform-observability-gateway/requirements-dev.txt" not in workflow_block, "workflow federated-conformance job should not inline observability requirements install"
assert "python3 -m pip install -r monday/requirements-dev.txt" not in workflow_block, "workflow federated-conformance job should not inline monday requirements install"
assert "rollout_external_artifact_policy.py" not in workflow_block, "workflow federated-conformance job should not inline artifact policy rollout command"
assert "cross_repo_conformance_check.py" not in workflow_block, "workflow federated-conformance job should not inline conformance checker command"
PY

echo "federated conformance helper wiring ok"
