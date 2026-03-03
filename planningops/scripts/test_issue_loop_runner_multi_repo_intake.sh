#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/issue_loop_runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

items = [
    {
        "status": "Todo",
        "workflow_state": "ready-contract",
        "execution_order": 20,
        "target_repo": "rather-not-work-on/platform-planningops",
        "content": {"type": "Issue", "number": 77, "repository": "rather-not-work-on/platform-planningops"},
    },
    {
        "status": "Todo",
        "workflow_state": "ready-contract",
        "execution_order": 10,
        "target_repo": "rather-not-work-on/monday",
        "content": {"type": "Issue", "number": 42, "repository": "rather-not-work-on/monday"},
    },
    {
        "status": "In Progress",
        "workflow_state": "in-progress",
        "execution_order": 30,
        "content": {"type": "Issue", "number": 100, "repository": "rather-not-work-on/platform-contracts"},
    },
    {
        "status": "Todo",
        "workflow_state": "backlog",
        "execution_order": 5,
        "content": {"type": "Issue", "number": 101, "repository": "rather-not-work-on/platform-provider-gateway"},
    },
]

allowed = {"ready-contract", "ready-implementation"}
candidates = mod.normalize_candidates(items, allowed)

assert [c["number"] for c in candidates] == [42, 77], candidates
assert candidates[0]["issue_repo"] == "rather-not-work-on/monday", candidates[0]
assert candidates[1]["issue_repo"] == "rather-not-work-on/platform-planningops", candidates[1]

selected = dict(candidates[1])
selected["deps"] = [41]
attempts = [
    {"number": 42, "issue_repo": "rather-not-work-on/monday", "result": "dependency_blocked"},
    {"number": 77, "issue_repo": "rather-not-work-on/platform-planningops", "result": "selected"},
]
trace = mod.build_selection_trace(candidates, selected, attempts, allowed)

assert trace["candidate_count"] == 2, trace
assert trace["selected"]["number"] == 77, trace
assert trace["selected"]["target_repo"] == "rather-not-work-on/platform-planningops", trace

l1_profile = mod.determine_loop_profile(selected, {}, "rather-not-work-on/platform-planningops")
assert l1_profile == "L1 Contract-Clarification", l1_profile

l2_profile_sim = mod.determine_loop_profile(
    {"workflow_state": "ready-contract", "simulation_required": True},
    {},
    "rather-not-work-on/platform-planningops",
)
assert l2_profile_sim == "L2 Simulation", l2_profile_sim

l2_profile_uncertainty = mod.determine_loop_profile(
    {"workflow_state": "ready-contract", "uncertainty_level": "high"},
    {},
    "rather-not-work-on/platform-planningops",
)
assert l2_profile_uncertainty == "L2 Simulation", l2_profile_uncertainty

selector_hints = mod.parse_selector_hints("simulation_required: true\nuncertainty_level: critical\n")
assert selector_hints["simulation_required"] is True, selector_hints
assert selector_hints["uncertainty_level"] == "critical", selector_hints

blueprint_ok = mod.parse_blueprint_refs(
    "\n".join(
        [
            "interface_contract_refs: planningops/contracts/requirements-contract.md",
            "package_topology_ref: docs/initiatives/unified-personal-agent-platform/20-architecture/2026-02-27-uap-contract-boundaries.architecture.md",
            "dependency_manifest_ref: planningops/config/runtime-profiles.json",
            "file_plan_ref: docs/workbench/unified-personal-agent-platform/plans/2026-03-03-fix-gate-bootstrap-review-findings-plan.md",
        ]
    )
)
assert blueprint_ok["complete"] is True, blueprint_ok
assert blueprint_ok["missing"] == [], blueprint_ok

blueprint_missing = mod.parse_blueprint_refs("interface_contract_refs: planningops/contracts/problem-contract.md\n")
assert blueprint_missing["complete"] is False, blueprint_missing
assert sorted(blueprint_missing["missing"]) == [
    "dependency_manifest_ref",
    "file_plan_ref",
    "package_topology_ref",
], blueprint_missing

ready_impl_cross_repo = {
    "workflow_state": "ready-implementation",
    "target_repo": "rather-not-work-on/monday",
    "issue_repo": "rather-not-work-on/platform-planningops",
}
l4_profile = mod.determine_loop_profile(ready_impl_cross_repo, {}, "rather-not-work-on/platform-planningops")
assert l4_profile == "L4 Integration-Reconcile", l4_profile

l5_profile = mod.determine_loop_profile(selected, {"replanning_triggered": True}, "rather-not-work-on/platform-planningops")
assert l5_profile == "L5 Recovery-Replan", l5_profile

budget_default, budget_errors_default = mod.parse_attempt_budget("no budget fields")
assert budget_default["max_attempts"] == 3, budget_default
assert budget_default["max_duration_minutes"] == 30, budget_default
assert budget_default["max_token_budget"] == 120000, budget_default
assert budget_errors_default == [], budget_errors_default

budget_custom, budget_errors_custom = mod.parse_attempt_budget(
    "max_attempts: 5\nmax_duration_minutes: 15\nmax_token_budget: 90000\n"
)
assert budget_custom["max_attempts"] == 5, budget_custom
assert budget_custom["max_duration_minutes"] == 15, budget_custom
assert budget_custom["max_token_budget"] == 90000, budget_custom
assert budget_errors_custom == [], budget_errors_custom

_, budget_errors_invalid = mod.parse_attempt_budget("max_attempts: -2\nmax_duration_minutes: foo\n")
assert budget_errors_invalid, budget_errors_invalid

adapter = mod.resolve_execution_adapter("rather-not-work-on/platform-provider-gateway")
adapter_pre = mod.invoke_adapter_hook(
    adapter,
    "before_loop",
    {
        "issue_number": 88,
        "issue_repo": "rather-not-work-on/platform-planningops",
        "target_repo": "rather-not-work-on/platform-provider-gateway",
        "workflow_state": "ready-implementation",
        "loop_profile": "L3 Implementation-TDD",
        "mode": "dry-run",
        "selection_transition_id": "loop-test-intake",
    },
)
assert adapter_pre["status"] == "ok", adapter_pre
assert adapter_pre["reason_code"] in {"contract", "permission", "context", "runtime", "feedback_failed"}, adapter_pre

event = {
    "transition_id": "loop-test-issue-77-intake-selection",
    "run_id": "loop-test-issue-77",
    "card_id": 77,
    "from_state": "Todo",
    "to_state": "ready-contract",
    "transition_reason": "intake.selection.target_repo",
    "actor_type": "agent",
    "actor_id": "issue-loop-runner",
    "decided_at_utc": "2026-02-28T00:00:00+00:00",
    "replanning_flag": False,
    "loop_profile": l1_profile,
    "selection_trace": trace,
}

with tempfile.TemporaryDirectory() as td:
    log_path = Path(td) / "trace.ndjson"
    mod.append_ndjson(log_path, event)
    rows = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    assert len(rows) == 1, rows
    row = rows[0]
    for key in [
        "transition_id",
        "run_id",
        "card_id",
        "from_state",
        "to_state",
        "transition_reason",
        "actor_type",
        "actor_id",
        "decided_at_utc",
        "replanning_flag",
    ]:
        assert key in row, key
    assert row["selection_trace"]["selected"]["number"] == 77, row
    assert row["loop_profile"] == "L1 Contract-Clarification", row

print("issue_loop_runner multi-repo intake trace ok")
PY
