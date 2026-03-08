#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
from pathlib import Path

module_path = Path("planningops/scripts/planning_context.py")
spec = importlib.util.spec_from_file_location("planning_context", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

body = "\n".join(
    [
        "## Planning Context",
        "- plan_item_id: `stock-034-9601`",
        "- target_repo: `rather-not-work-on/platform-planningops`",
        "- component: `planningops`",
        "- execution_kind: `inventory`",
        "- workflow_state: `backlog`",
        "- loop_profile: `l1_contract_clarification`",
        "- execution_order: `9601`",
        "- plan_lane: `M3 Guardrails`",
        "- depends_on: `E24 (rather-not-work-on/platform-planningops#142), stock-034-9602 (rather-not-work-on/platform-planningops#88)`",
    ]
)

meta = mod.parse_metadata(body)
assert meta["plan_item_id"] == "stock-034-9601", meta
assert meta["execution_kind"] == "inventory", meta
assert meta["plan_lane"] == "M3 Guardrails", meta
assert meta["depends_on"].startswith("E24"), meta

assert mod.parse_execution_order(meta["execution_order"]) == 9601
assert mod.parse_execution_order("not-a-number") is None

canonical_deps = mod.parse_depends_on_plan_item_keys(meta["depends_on"])
assert canonical_deps == ["E24"], canonical_deps

mixed_deps = mod.parse_depends_on_plan_item_keys(
    meta["depends_on"],
    pattern=r"(?:[A-Z][0-9]{2}|stock-\d{3}-\d{4})",
)
assert mixed_deps == ["E24", "stock-034-9602"], mixed_deps

print("planning_context contract tests ok")
PY
