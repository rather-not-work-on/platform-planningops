#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_MATRIX_PATH="$ROOT_DIR/planningops/scripts/federation/federated_ci_matrix_local.sh"
HELPER_PATH="$ROOT_DIR/planningops/scripts/run_contract_conformance_ci_check.sh"

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

local_block = local_matrix.split('run_check "contract-conformance" "contract" \\', 1)[1].split('run_check "provider-profile" "infra" \\', 1)[0]

assert local_invocation in local_block, "local contract-conformance block missing helper invocation"
assert local_block.count(local_invocation) == 1, "local contract-conformance helper invocation should appear once"
assert "cross_repo_conformance_check.py" not in local_block, "local contract-conformance block should not inline conformance checker command"
PY

echo "contract conformance helper wiring ok"
