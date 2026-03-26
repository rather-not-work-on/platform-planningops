#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_contract_conformance_ci_check.sh"

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

assert local_invocation == "bash planningops/scripts/run_contract_conformance_ci_check.sh --run-id ${RUN_ID}-contract --workspace-root .. --bootstrap-mode auto --python-bin \\\"${PYTHON_BIN}\\\"", "local contract-conformance helper invocation drifted"
assert "usage: run_contract_conformance_ci_check.sh [options]" in help_output, "contract-conformance help usage missing"
assert "--run-id <id>" in help_output, "contract-conformance help missing run-id flag"
assert "--workspace-root <path>" in help_output, "contract-conformance help missing workspace-root flag"
assert "--bootstrap-mode <mode>" in help_output, "contract-conformance help missing bootstrap-mode flag"
assert "--python-bin <path>" in help_output, "contract-conformance help missing python-bin flag"
assert "--print-local-invocation" in help_output, "contract-conformance help missing local invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_contract_conformance_ci_check_contract.sh"' in script, "contract-conformance helper must self-run its contract test"
assert '"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/federation/cross_repo_conformance_check.py" \\' in script, "contract-conformance helper missing checker command"
assert '--workspace-root "${WORKSPACE_ROOT}" \\' in script, "contract-conformance helper missing workspace-root wiring"
assert '--bootstrap-mode "${BOOTSTRAP_MODE}" \\' in script, "contract-conformance helper missing bootstrap-mode wiring"
assert '--run-id "${RUN_ID}"' in script, "contract-conformance helper missing run-id wiring"
PY

echo "contract conformance ci check contract ok"
