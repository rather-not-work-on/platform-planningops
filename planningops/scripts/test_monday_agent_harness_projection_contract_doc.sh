#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONTRACT="${ROOT_DIR}/planningops/contracts/monday-agent-harness-projection-contract.md"
CONTRACTS_README="${ROOT_DIR}/planningops/contracts/README.md"
SCRIPTS_README="${ROOT_DIR}/planningops/scripts/README.md"
SCHEMAS_README="${ROOT_DIR}/planningops/schemas/README.md"

python3 - <<'PY' "${CONTRACT}" "${CONTRACTS_README}" "${SCRIPTS_README}" "${SCHEMAS_README}"
import sys
from pathlib import Path

contract = Path(sys.argv[1]).read_text(encoding="utf-8")
contracts_readme = Path(sys.argv[2]).read_text(encoding="utf-8")
scripts_readme = Path(sys.argv[3]).read_text(encoding="utf-8")
schemas_readme = Path(sys.argv[4]).read_text(encoding="utf-8")

required_contract_snippets = [
    "runtime-artifacts/agent-harness/completion-summary.json",
    "runtime-artifacts/agent-harness/readiness-projection.json",
    "runtime-artifacts/agent-harness/verification-projection.json",
    "runtime-artifacts/agent-harness/operator-handoff-summary.json",
    "planningops/schemas/monday-agent-harness-projection-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json",
    "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json",
    "planningops/scripts/resolve_monday_agent_harness_projection.py",
    "planningops/scripts/validate_monday_agent_harness_projection.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status.py",
    "planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh",
    "planningops/scripts/run_monday_agent_harness_projection_ci_check.sh",
    "planningops/scripts/test_monday_agent_harness_projection_helper_wiring.sh",
    "planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh",
    "planningops/scripts/resolve_monday_agent_harness_projection_status.py",
    "planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status.py",
    "planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py",
    "planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py",
    "planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle.py",
    "planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status.py",
    "planningops/scripts/doctor_monday_agent_harness_projection.py",
    "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py",
    "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py",
    "planningops/scripts/gate_monday_agent_harness_projection.sh",
    "planningops/scripts/gate_monday_agent_harness_projection_status_bundle.sh",
    "planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection.sh",
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
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh",
    "planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle.sh",
    "planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle.sh",
    "planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle.sh",
    "planningops/scripts/test_monday_agent_harness_projection_bridge.sh",
]

for snippet in required_contract_snippets:
    assert snippet in contract, f"missing contract snippet: {snippet}"

assert "monday-agent-harness-projection-contract.md" in contracts_readme, "contracts README missing monday projection contract"
assert "resolve_monday_agent_harness_projection.py" in scripts_readme, "scripts README missing monday projection resolver"
assert "validate_monday_agent_harness_projection.py" in scripts_readme, "scripts README missing monday projection validator"
assert "validate_monday_agent_harness_projection_status.py" in scripts_readme, "scripts README missing monday projection status validator"
assert "run_monday_agent_harness_projection_ci_suite.sh" in scripts_readme, "scripts README missing monday projection ci suite helper"
assert "run_monday_agent_harness_projection_ci_check.sh" in scripts_readme, "scripts README missing monday projection ci check helper"
assert "test_monday_agent_harness_projection_helper_wiring.sh" in scripts_readme, "scripts README missing monday projection helper wiring regression"
assert "test_run_monday_agent_harness_projection_ci_check_contract.sh" in scripts_readme, "scripts README missing monday projection ci check contract regression"
assert "resolve_monday_agent_harness_projection_status.py" in scripts_readme, "scripts README missing monday projection status resolver"
assert "resolve_monday_agent_harness_projection_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status resolver"
assert "resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status resolver"
assert "resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status resolver"
assert "resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status resolver"
assert "resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle status resolver"
assert "resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle resolver"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle validator"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle status validator"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle validator"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle validator"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle validator"
assert "doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle doctor"
assert "doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle doctor"
assert "gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle gate"
assert "gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle gate"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status bundle status validator"
assert "validate_monday_agent_harness_projection_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle validator"
assert "validate_monday_agent_harness_projection_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status validator"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle validator"
assert "validate_monday_agent_harness_projection_status_bundle_status_bundle_status.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle status validator"
assert "doctor_monday_agent_harness_projection.py" in scripts_readme, "scripts README missing monday projection doctor"
assert "doctor_monday_agent_harness_projection_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle doctor"
assert "doctor_monday_agent_harness_projection_status_bundle_status_bundle.py" in scripts_readme, "scripts README missing monday projection status bundle status bundle doctor"
assert "gate_monday_agent_harness_projection.sh" in scripts_readme, "scripts README missing monday projection gate"
assert "gate_monday_agent_harness_projection_status_bundle.sh" in scripts_readme, "scripts README missing monday projection status bundle gate"
assert "gate_monday_agent_harness_projection_status_bundle_status_bundle.sh" in scripts_readme, "scripts README missing monday projection status bundle status bundle gate"
assert "test_monday_agent_harness_projection_bridge.sh" in scripts_readme, "scripts README missing monday projection bridge regression"
assert "monday-agent-harness-projection-bundle.schema.json" in schemas_readme, "schemas README missing monday projection bundle schema"
assert "monday-agent-harness-projection-validation.schema.json" in schemas_readme, "schemas README missing monday projection validation schema"
assert "monday-agent-harness-projection-status.schema.json" in schemas_readme, "schemas README missing monday projection status schema"
assert "monday-agent-harness-projection-status-validation.schema.json" in schemas_readme, "schemas README missing monday projection status validation schema"
assert "monday-agent-harness-projection-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle schema"
assert "monday-agent-harness-projection-status-bundle-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle validation schema"
assert "monday-agent-harness-projection-status-bundle-status.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status schema"
assert "monday-agent-harness-projection-status-bundle-status-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle status schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle status validation schema"
assert "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json" in schemas_readme, "schemas README missing monday projection status bundle status bundle status bundle status bundle status bundle status bundle status bundle schema"
PY

echo "monday agent harness projection contract doc ok"
