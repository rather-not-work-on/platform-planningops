#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
from pathlib import Path


module_path = Path("planningops/scripts/sync_project_fields_after_issue_create.py")
spec = importlib.util.spec_from_file_location("sync_project_fields_after_issue_create", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

body = "\n".join(
    [
        "## Planning Context",
        "- plan_item_id: `B21`",
        "- target_repo: `rather-not-work-on/platform-provider-gateway`",
        "- component: `provider-gateway`",
        "- workflow_state: `ready-implementation`",
        "- loop_profile: `l4_integration_reconcile`",
        "- execution_order: `2210`",
        "- plan_lane: `M2 Sync Core`",
    ]
)
meta = mod.parse_metadata(body)
assert meta["plan_item_id"] == "B21", meta
assert meta["component"] == "provider-gateway", meta
assert meta["workflow_state"] == "ready-implementation", meta
assert meta["plan_lane"] == "M2 Sync Core", meta

assert mod.normalize_option_key("ready-implementation") == "ready_implementation"
assert mod.normalize_option_key("provider-gateway") == "provider_gateway"
assert mod.normalize_option_key("M3 Guardrails") == "m3_guardrails"

project = {
    "owner": "rather-not-work-on",
    "project_number": 2,
    "project_id": "PVT_TEST",
    "initiative": "unified-personal-agent-platform",
    "fields": {
        "status": {"id": "F_STATUS", "options": {"todo": "O_TODO", "in_progress": "O_IP", "blocked": "O_BLOCK", "done": "O_DONE"}},
        "initiative": {"id": "F_INIT"},
        "target_repo": {"id": "F_REPO"},
        "execution_order": {"id": "F_ORDER"},
        "component": {"id": "F_COMPONENT", "options": {"provider_gateway": "O_COMPONENT_PROVIDER"}},
        "workflow_state": {"id": "F_WF", "options": {"ready_implementation": "O_WF_READY_IMPL"}},
        "plan_lane": {"id": "F_LANE", "options": {"m2_sync_core": "O_LANE_M2"}},
        "loop_profile": {"id": "F_LOOP", "options": {"l4_integration_reconcile": "O_LOOP_L4"}},
    },
}
issue = {
    "repo": "rather-not-work-on/platform-provider-gateway",
    "number": 3,
    "url": "https://github.com/rather-not-work-on/platform-provider-gateway/issues/3",
    "body": body,
    "state": "OPEN",
    "metadata": meta,
}

# Dry-run should normalize and plan all requested fields.
dry = mod.sync_one_issue(project, issue, apply_mode=False, issue_index={})
assert dry["component"] == "provider_gateway", dry
assert dry["workflow_state"] == "ready_implementation", dry
assert dry["plan_lane"] == "m2_sync_core", dry
assert "component(provider_gateway)" in dry["field_updates"], dry
assert "workflow_state(ready_implementation)" in dry["field_updates"], dry
assert "plan_lane(m2_sync_core)" in dry["field_updates"], dry

closed_project = {
    **project,
    "fields": {
        **project["fields"],
        "workflow_state": {
            "id": "F_WF",
            "options": {
                "ready_implementation": "O_WF_READY_IMPL",
                "done": "O_WF_DONE",
            },
        },
    },
}
closed_issue = {**issue, "state": "CLOSED"}
closed_dry = mod.sync_one_issue(closed_project, closed_issue, apply_mode=False, issue_index={})
assert closed_dry["issue_state"] == "closed", closed_dry
assert closed_dry["workflow_state"] == "done", closed_dry
assert "workflow_state(done)" in closed_dry["field_updates"], closed_dry

calls = []
mod.ensure_project_item = lambda owner, project_number, issue_url: "PVTI_TEST_1"
mod.find_project_item_id = lambda owner, project_number, issue_number, issue_repo, issue_index: "PVTI_TEST_1"
mod.set_text_field = lambda project_id, item_id, field_id, text: calls.append(("text", field_id, text))
mod.set_number_field = lambda project_id, item_id, field_id, number_value: calls.append(("number", field_id, number_value))
mod.set_select_field = lambda project_id, item_id, field_id, option_id: calls.append(("select", field_id, option_id))

apply_row = mod.sync_one_issue(project, issue, apply_mode=True, issue_index={})
updated = set(apply_row["field_updates"])
assert {"component", "workflow_state", "plan_lane"}.issubset(updated), apply_row
assert {"status", "initiative", "target_repo", "execution_order", "loop_profile"}.issubset(updated), apply_row

# Ensure we touched the expected select options.
select_calls = [c for c in calls if c[0] == "select"]
select_option_ids = {c[2] for c in select_calls}
assert "O_COMPONENT_PROVIDER" in select_option_ids, select_calls
assert "O_WF_READY_IMPL" in select_option_ids, select_calls
assert "O_LANE_M2" in select_option_ids, select_calls

print("sync_project_fields_after_issue_create contract tests ok")
PY
