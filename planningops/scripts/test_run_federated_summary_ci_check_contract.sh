#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_federated_summary_ci_check.sh"

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

expected = "bash planningops/scripts/run_federated_summary_ci_check.sh --run-id ci-${{ github.run_id }} --contract-conformance-result ${{ needs.contract-conformance.result }} --runtime-handoff-result ${{ needs.runtime-handoff.result }} --monday-harness-projection-result ${{ needs.monday-harness-projection.result }} --o11y-replay-result ${{ needs.o11y-replay.result }} --provider-profile-result ${{ needs.provider-profile.result }} --federated-conformance-result ${{ needs.federated-conformance.result }} --loop-guardrails-result ${{ needs.loop-guardrails.result }}"
assert workflow_invocation == expected, "federated-summary helper invocation drifted"
assert "usage: run_federated_summary_ci_check.sh [options]" in help_output, "federated-summary help usage missing"
assert "--run-id <id>" in help_output, "federated-summary help missing run-id flag"
assert "--contract-conformance-result <result>" in help_output, "federated-summary help missing contract result flag"
assert "--loop-guardrails-result <result>" in help_output, "federated-summary help missing loop-guardrails result flag"
assert "--stamped-readiness-validation-path <path>" in help_output, "federated-summary help missing readiness validation path flag"
assert "--print-workflow-invocation" in help_output, "federated-summary help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_federated_summary_ci_check_contract.sh"' in script, "federated-summary helper must self-run its contract test"
assert 'python3 "${SUMMARY_HELPER}" init \\' in script, "federated-summary helper missing init command"
assert 'python3 "${SUMMARY_HELPER}" append-check \\' in script, "federated-summary helper missing append-check command"
assert 'python3 "${SUMMARY_HELPER}" finalize \\' in script, "federated-summary helper missing finalize command"
assert 'append_job_result "federated-conformance" "federation" "${FEDERATED_CONFORMANCE_RESULT}"' in script, "federated-summary helper missing federated-conformance mapping"
assert 'append_job_result "monday-harness-projection" "runtime" "${MONDAY_HARNESS_PROJECTION_RESULT}"' in script, "federated-summary helper missing monday projection mapping"
assert 'python3 "${READINESS_HELPER}" \\' in script, "federated-summary helper missing readiness helper call"
PY

echo "federated summary ci check contract ok"
