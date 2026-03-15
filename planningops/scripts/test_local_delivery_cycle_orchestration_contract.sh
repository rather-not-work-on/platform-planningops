#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

python3 - <<'PY'
from pathlib import Path

contract = Path("planningops/contracts/local-delivery-cycle-orchestration-contract.md")
text = contract.read_text(encoding="utf-8")

required_paths = [
    "planningops/scripts/federation/run_reflection_delivery_cycle.py",
    "planningops/scripts/autonomous_supervisor_loop.py",
    "monday/scripts/run_operator_message_delivery_cycle.py",
    "monday/scripts/run_goal_completion_delivery_cycle.py",
]

required_markers = [
    "must invoke only monday-owned local delivery-cycle entrypoints on the primary local path",
    "must not invoke these lower-level monday scripts directly on the primary local path",
    "reflection actions requiring operator delivery must flow through `monday/scripts/run_operator_message_delivery_cycle.py`",
    "goal completion delivery must flow through `monday/scripts/run_goal_completion_delivery_cycle.py`",
]

for path in required_paths:
    if path not in text:
        raise SystemExit(f"missing canonical path: {path}")

for marker in required_markers:
    if marker not in text:
        raise SystemExit(f"missing contract marker: {marker}")

print("local delivery cycle orchestration contract ok")
PY
