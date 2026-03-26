#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_platform_contracts_ci_check.sh"

python3 - <<'PY' "${SCRIPT_PATH}"
import subprocess
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
script = script_path.read_text(encoding="utf-8")
workflow_invocation = subprocess.check_output(
    ["bash", str(script_path), "--print-workflow-invocation"],
    text=True,
).strip()
help_output = subprocess.check_output(
    ["bash", str(script_path), "--help"],
    text=True,
)

assert workflow_invocation == "bash planningops/scripts/run_platform_contracts_ci_check.sh --contracts-root platform-contracts --python-bin python3", "platform-contracts helper invocation drifted"
assert "usage: run_platform_contracts_ci_check.sh [options]" in help_output, "platform-contracts help usage missing"
assert "--contracts-root <path>" in help_output, "platform-contracts help missing contracts-root flag"
assert "--python-bin <path>" in help_output, "platform-contracts help missing python-bin flag"
assert "--venv-root <path>" in help_output, "platform-contracts help missing venv-root flag"
assert "--print-workflow-invocation" in help_output, "platform-contracts help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_platform_contracts_ci_check_contract.sh"' in script, "platform-contracts helper must self-run its contract test"
assert '"${PYTHON_BIN}" -m venv "${VENV_ROOT}"' in script, "platform-contracts helper missing managed venv bootstrap"
assert '"${VENV_ROOT}/bin/python" -m pip install --upgrade pip' in script, "platform-contracts helper missing pip bootstrap"
assert '"${VENV_ROOT}/bin/python" -m pip install -r requirements-dev.txt' in script, "platform-contracts helper missing requirements install"
assert '"${VENV_ROOT}/bin/python" scripts/validate_contracts.py --root .' in script, "platform-contracts helper missing contract validator"
assert '"${VENV_ROOT}/bin/python" scripts/classify_schema_change.py --enforce-expected' in script, "platform-contracts helper missing semver classifier"
PY

echo "platform contracts ci check contract ok"
