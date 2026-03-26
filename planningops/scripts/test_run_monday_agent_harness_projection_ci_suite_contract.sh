#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh"

python3 - <<'PY' "${SCRIPT_PATH}"
import subprocess
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
script = script_path.read_text(encoding="utf-8")
tests = subprocess.check_output(
    ["bash", str(script_path), "--print-tests"],
    text=True,
).splitlines()
help_output = subprocess.check_output(
    ["bash", str(script_path), "--help"],
    text=True,
)

expected = [
    "planningops/scripts/test_validate_monday_agent_harness_projection.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle.sh",
    "planningops/scripts/test_monday_agent_harness_projection_bridge.sh",
    "planningops/scripts/test_monday_agent_harness_projection_contract_doc.sh",
    "planningops/scripts/test_materialize_monday_agent_harness_projection_surfaces.sh",
    "planningops/scripts/test_sync_monday_agent_harness_projection_latest.sh",
]

assert tests == expected, "printed test inventory drifted from canonical monday projection suite"
assert "--print-tests" in script, "print-tests switch missing"
assert 'printf \'%s\\n\' "${TESTS[@]}"' in script, "print-tests output missing"
assert "usage: run_monday_agent_harness_projection_ci_suite.sh [options]" in help_output, "suite help usage missing"
assert "--summary-run-id <id>" in help_output, "suite help missing summary-run-id flag"
assert "--monday-root <path>" in help_output, "suite help missing monday-root flag"
assert "--mission-id <id>" in help_output, "suite help missing mission-id flag"
assert "--print-tests" in help_output, "suite help missing print-tests flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/sync_monday_agent_harness_projection_latest.sh" "${SYNC_ARGS[@]}"' in script, "sync helper invocation missing"
assert '--summary-run-id' in script, "summary run id passthrough missing"
assert '--monday-root' in script, "monday root passthrough missing"
assert '--mission-id' in script, "mission id passthrough missing"
PY

echo "monday agent harness projection ci suite contract ok"
