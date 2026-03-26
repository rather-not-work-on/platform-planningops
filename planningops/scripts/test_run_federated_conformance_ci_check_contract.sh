#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_federated_conformance_ci_check.sh"

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

assert workflow_invocation == "bash planningops/scripts/run_federated_conformance_ci_check.sh --run-id ci-federated-${{ github.run_id }} --workspace-root . --python-bin python3 --policy-output planningops/artifacts/validation/federated-artifact-policy-rollout-report.json --bootstrap-mode require --output planningops/artifacts/conformance/ci-federated-${{ github.run_id }}.json", "workflow federated-conformance helper invocation drifted"
assert "usage: run_federated_conformance_ci_check.sh [options]" in help_output, "federated-conformance help usage missing"
assert "--run-id <id>" in help_output, "federated-conformance help missing run-id flag"
assert "--workspace-root <path>" in help_output, "federated-conformance help missing workspace-root flag"
assert "--python-bin <path>" in help_output, "federated-conformance help missing python-bin flag"
assert "--policy-output <path>" in help_output, "federated-conformance help missing policy-output flag"
assert "--bootstrap-mode <mode>" in help_output, "federated-conformance help missing bootstrap-mode flag"
assert "--output <path>" in help_output, "federated-conformance help missing output flag"
assert "--print-workflow-invocation" in help_output, "federated-conformance help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_federated_conformance_ci_check_contract.sh"' in script, "federated-conformance helper must self-run its contract test"
assert '"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/rollout_external_artifact_policy.py" \\' in script, "federated-conformance helper missing artifact policy rollout command"
assert '"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/federation/cross_repo_conformance_check.py" \\' in script, "federated-conformance helper missing conformance checker command"
assert '--workspace-root "${WORKSPACE_ROOT}" \\' in script, "federated-conformance helper missing workspace-root wiring"
assert '--output "${POLICY_OUTPUT}"' in script, "federated-conformance helper missing policy output wiring"
assert '--bootstrap-mode "${BOOTSTRAP_MODE}" \\' in script, "federated-conformance helper missing bootstrap-mode wiring"
assert '--run-id "${RUN_ID}" \\' in script, "federated-conformance helper missing run-id wiring"
assert '--output "${OUTPUT}"' in script, "federated-conformance helper missing conformance output wiring"
PY

echo "federated conformance ci check contract ok"
