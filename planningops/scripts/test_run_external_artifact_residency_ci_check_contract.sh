#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_external_artifact_residency_ci_check.sh"

python3 - <<'PY' "${SCRIPT_PATH}"
import subprocess
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
script = script_path.read_text(encoding="utf-8")
steps = subprocess.check_output(
    ["bash", str(script_path), "--print-steps"],
    text=True,
).splitlines()
workflow_invocation = subprocess.check_output(
    ["bash", str(script_path), "--print-workflow-invocation"],
    text=True,
).strip()
help_output = subprocess.check_output(
    ["bash", str(script_path), "--help"],
    text=True,
)

expected_steps = [
    "bash planningops/scripts/test_validate_external_only_commit_guard.sh",
    "bash planningops/scripts/test_migrate_external_only_artifacts_contract.sh",
    "bash planningops/scripts/test_artifact_sink_e2e.sh",
    'BASE_REF="${{ github.event.pull_request.base.sha }}"',
    'if [[ -z "$BASE_REF" || "$BASE_REF" == "null" ]]; then BASE_REF="origin/main"; fi',
    'python3 planningops/scripts/validate_external_only_commit_guard.py --base-ref "$BASE_REF" --head-ref "${{ github.sha }}" --strict',
    "python3 planningops/scripts/validate_external_only_commit_guard.py --mode tracked --strict",
]

assert steps == expected_steps, "external-artifact residency helper step inventory drifted"
assert workflow_invocation == 'bash planningops/scripts/run_external_artifact_residency_ci_check.sh --base-ref "${{ github.event.pull_request.base.sha }}" --head-ref "${{ github.sha }}" --python-bin python3', "external-artifact residency helper workflow invocation drifted"
assert "usage: run_external_artifact_residency_ci_check.sh [options]" in help_output, "external-artifact residency helper usage missing"
assert "--base-ref <ref>" in help_output, "external-artifact residency helper help missing base-ref flag"
assert "--head-ref <ref>" in help_output, "external-artifact residency helper help missing head-ref flag"
assert "--python-bin <path>" in help_output, "external-artifact residency helper help missing python-bin flag"
assert "--print-steps" in help_output, "external-artifact residency helper help missing steps flag"
assert "--print-workflow-invocation" in help_output, "external-artifact residency helper help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_external_artifact_residency_ci_check_contract.sh"' in script, "external-artifact residency helper must self-run its contract test"
assert 'RESOLVED_BASE_REF="$(resolve_base_ref "${BASE_REF}")"' in script, "external-artifact residency helper missing base-ref normalization"
assert 'bash planningops/scripts/test_validate_external_only_commit_guard.sh' in script, "external-artifact residency helper missing commit-guard regression"
assert 'bash planningops/scripts/test_migrate_external_only_artifacts_contract.sh' in script, "external-artifact residency helper missing migration regression"
assert 'bash planningops/scripts/test_artifact_sink_e2e.sh' in script, "external-artifact residency helper missing sink regression"
assert '"${PYTHON_BIN}" planningops/scripts/validate_external_only_commit_guard.py \\' in script, "external-artifact residency helper missing live commit guard wiring"
assert '--base-ref "${RESOLVED_BASE_REF}"' in script, "external-artifact residency helper missing resolved base-ref wiring"
assert '--head-ref "${HEAD_REF}"' in script, "external-artifact residency helper missing head-ref wiring"
assert '--mode tracked \\' in script, "external-artifact residency helper missing tracked baseline wiring"
PY

echo "external artifact residency ci check contract ok"
