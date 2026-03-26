#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_control_plane_governance_ci_check.sh"

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
    "bash planningops/scripts/test_validate_artifact_storage_policy_contract.sh",
    "python3 planningops/scripts/validate_artifact_storage_policy.py --strict",
    "bash planningops/scripts/test_control_tower_ontology_contract.sh",
    "bash planningops/scripts/test_ontology_entity_map_contract.sh",
    "bash planningops/scripts/test_memory_tier_contract.sh",
    "bash planningops/scripts/test_memory_compactor_contract.sh",
    "bash planningops/scripts/test_memory_archive_contract.sh",
    "bash planningops/scripts/test_memory_rehydrate_contract.sh",
    "bash planningops/scripts/test_inventory_issue_lifecycle_contract.sh",
    "bash planningops/scripts/test_autonomous_scheduler_queue_control_plane_contract.sh",
    "python3 planningops/scripts/memory_compactor.py --mode check --root . --rules planningops/config/memory-tier-rules.json --output planningops/artifacts/validation/memory-gate-report.json --strict",
    "python3 planningops/scripts/inventory_issue_lifecycle.py audit --repo rather-not-work-on/platform-planningops --strict --output planningops/artifacts/validation/inventory-issue-lifecycle-report.json",
]

assert steps == expected_steps, "control-plane governance helper step inventory drifted"
assert workflow_invocation == "bash planningops/scripts/run_control_plane_governance_ci_check.sh --python-bin python3", "control-plane governance helper workflow invocation drifted"
assert "usage: run_control_plane_governance_ci_check.sh [options]" in help_output, "control-plane governance helper usage missing"
assert "--python-bin <path>" in help_output, "control-plane governance helper help missing python-bin flag"
assert "--root <path>" in help_output, "control-plane governance helper help missing root flag"
assert "--memory-output <path>" in help_output, "control-plane governance helper help missing memory-output flag"
assert "--inventory-output <path>" in help_output, "control-plane governance helper help missing inventory-output flag"
assert "--inventory-issues-file <path>" in help_output, "control-plane governance helper help missing inventory-issues-file flag"
assert "--print-steps" in help_output, "control-plane governance helper help missing steps flag"
assert "--print-workflow-invocation" in help_output, "control-plane governance helper help missing workflow invocation flag"
assert 'bash "${ROOT_DIR}/planningops/scripts/test_run_control_plane_governance_ci_check_contract.sh"' in script, "control-plane governance helper must self-run its contract test"
assert 'bash planningops/scripts/test_validate_artifact_storage_policy_contract.sh' in script, "control-plane governance helper missing artifact-storage regression"
assert '"${PYTHON_BIN}" planningops/scripts/validate_artifact_storage_policy.py --strict' in script, "control-plane governance helper missing artifact-storage validator wiring"
assert 'bash planningops/scripts/test_control_tower_ontology_contract.sh' in script, "control-plane governance helper missing ontology contract regression"
assert 'bash planningops/scripts/test_ontology_entity_map_contract.sh' in script, "control-plane governance helper missing ontology map regression"
assert 'bash planningops/scripts/test_memory_tier_contract.sh' in script, "control-plane governance helper missing memory-tier regression"
assert 'bash planningops/scripts/test_memory_compactor_contract.sh' in script, "control-plane governance helper missing memory-compactor regression"
assert 'bash planningops/scripts/test_memory_archive_contract.sh' in script, "control-plane governance helper missing memory-archive regression"
assert 'bash planningops/scripts/test_memory_rehydrate_contract.sh' in script, "control-plane governance helper missing memory-rehydrate regression"
assert 'bash planningops/scripts/test_inventory_issue_lifecycle_contract.sh' in script, "control-plane governance helper missing inventory lifecycle regression"
assert 'bash planningops/scripts/test_autonomous_scheduler_queue_control_plane_contract.sh' in script, "control-plane governance helper missing scheduler queue regression"
assert '"${PYTHON_BIN}" planningops/scripts/memory_compactor.py \\' in script, "control-plane governance helper missing memory gate wiring"
assert '--root "${ROOT_PATH}" \\' in script, "control-plane governance helper missing root wiring for memory gate"
assert '--output "${MEMORY_OUTPUT}" \\' in script, "control-plane governance helper missing memory output wiring"
assert 'INVENTORY_ARGS=(' in script, "control-plane governance helper missing inventory argument array"
assert '--root "${ROOT_PATH}"' in script, "control-plane governance helper missing inventory root wiring"
assert '--output "${INVENTORY_OUTPUT}"' in script, "control-plane governance helper missing inventory output wiring"
assert 'INVENTORY_ARGS+=(--issues-file "${INVENTORY_ISSUES_FILE}")' in script, "control-plane governance helper missing inventory issues-file override"
assert '"${PYTHON_BIN}" planningops/scripts/inventory_issue_lifecycle.py "${INVENTORY_ARGS[@]}"' in script, "control-plane governance helper missing inventory audit wiring"
PY

echo "control plane governance ci check contract ok"
