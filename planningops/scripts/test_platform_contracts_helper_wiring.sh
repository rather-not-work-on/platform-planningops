#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/.github/workflows/federated-ci-matrix.yml"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_platform_contracts_ci_check.sh"

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

workflow_block = workflow.split("  contract-conformance:", 1)[1].split("  provider-profile:", 1)[0]

assert workflow_invocation in workflow_block, "workflow contract-conformance job missing platform-contracts helper invocation"
assert workflow_block.count(workflow_invocation) == 1, "workflow contract-conformance helper invocation should appear once"
assert "python3 -m pip install -r requirements-dev.txt" not in workflow_block, "workflow contract-conformance job should not inline requirements install"
assert "python3 scripts/validate_contracts.py --root ." not in workflow_block, "workflow contract-conformance job should not inline contract validator"
assert "python3 scripts/classify_schema_change.py --enforce-expected" not in workflow_block, "workflow contract-conformance job should not inline semver classifier"
PY

echo "platform contracts helper wiring ok"
