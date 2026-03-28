#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOC_PATH="${ROOT_DIR}/../docs/initiatives/unified-personal-agent-platform/40-quality/uap-automation-operations-summary.quality.md"

python3 - <<'PY' "$DOC_PATH"
import sys
from pathlib import Path

doc = Path(sys.argv[1]).read_text(encoding="utf-8")

required_snippets = [
    "planningops/contracts/federated-ci-summary-contract.md",
    "planningops/contracts/supervisor-operator-handoff-contract.md",
    "planningops/scripts/autonomous_supervisor_loop.py",
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "python3 planningops/scripts/assess_federated_ci_summary_readiness.py --strict",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
    "status=degraded",
    "operator_action=inspect_federated_ci_gates",
    "litellm_fallback_only_ready",
    "remediation_commands",
    "priority_preview_ref",
    "resolve_operator_priority_preview.py",
    "resolve_supervisor_operator_handoff_bundle.py",
    "validate_supervisor_operator_handoff_bundle.py",
    "assess_supervisor_operator_handoff_bundle_readiness.py",
    "validate_supervisor_operator_handoff_bundle_readiness.py",
    "doctor_supervisor_operator_handoff_bundle.py",
    "gate_supervisor_operator_handoff_bundle.sh",
    "priority_display_packet_ref",
    "resolve_operator_priority_display_packet.py",
]

for snippet in required_snippets:
    assert snippet in doc, f"missing automation operations summary snippet: {snippet}"
PY

echo "uap automation operations summary contract ok"
