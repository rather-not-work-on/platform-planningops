#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/core/loop/runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner_core", module_path)
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
        "execution_order": 1,
        "execution_kind": "inventory",
        "target_repo": "rather-not-work-on/platform-planningops",
        "content": {"type": "Issue", "number": 78, "repository": "rather-not-work-on/platform-planningops"},
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

# High-value ready-first rule must prioritize ready-* over backlog even when backlog has lower execution_order.
allowed_with_backlog = {"backlog", "ready-contract", "ready-implementation"}
candidates_with_backlog = mod.normalize_candidates(items, allowed_with_backlog)
assert [c["number"] for c in candidates_with_backlog] == [42, 77, 101], candidates_with_backlog

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
assert trace["selected"]["execution_kind"] == "executable", trace

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
assert mod.parse_execution_kind("- execution_kind: `inventory`") == "inventory"
assert mod.parse_execution_kind("execution_kind: executable") == "executable"
assert mod.parse_execution_kind("no marker") == "executable"

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

plan_item_id = mod.parse_plan_item_id("plan_item_id: `pec-350`")
assert plan_item_id == "pec-350", plan_item_id
assert mod.parse_plan_item_id("no marker") is None

with tempfile.TemporaryDirectory() as td:
    pec_path = Path(td) / "pec.json"
    pec_path.write_text(
        json.dumps(
            {
                "execution_contract": {
                    "plan_id": "pec-test",
                    "plan_revision": 1,
                    "source_of_truth": "docs/workbench/unified-personal-agent-platform/plans/2026-03-03-plan-auto-executable-plans-contract-and-runner-plan.md",
                    "items": [
                        {
                            "plan_item_id": "pec-350",
                            "execution_order": 42,
                            "title": "runner preflight",
                            "target_repo": "rather-not-work-on/monday",
                            "component": "planningops",
                            "workflow_state": "ready_contract",
                            "loop_profile": "l1_contract_clarification",
                            "depends_on": [],
                            "primary_output": "planningops/scripts/core/loop/runner.py",
                        }
                    ],
                }
            },
            ensure_ascii=True,
        ),
        encoding="utf-8",
    )

    selected_for_preflight = {
        "number": 42,
        "order": 42,
        "status": "Todo",
        "workflow_state": "ready-contract",
        "issue_repo": "rather-not-work-on/monday",
        "target_repo": "rather-not-work-on/monday",
        "component": "planningops",
        "loop_profile": "L1 Contract-Clarification",
        "initiative": "unified-personal-agent-platform",
        "plan_item_id": "pec-350",
    }

    preflight_hybrid_ok = mod.evaluate_pec_preflight(
        "hybrid",
        str(pec_path),
        selected_for_preflight,
        "unified-personal-agent-platform",
    )
    assert preflight_hybrid_ok["status"] == "pass", preflight_hybrid_ok

    selected_mismatch = dict(selected_for_preflight)
    selected_mismatch["workflow_state"] = "in-progress"
    selected_mismatch["status"] = "In Progress"
    preflight_hybrid_fail = mod.evaluate_pec_preflight(
        "hybrid",
        str(pec_path),
        selected_mismatch,
        "unified-personal-agent-platform",
    )
    assert preflight_hybrid_fail["status"] == "fail", preflight_hybrid_fail
    assert preflight_hybrid_fail["reason_code"] == "pec_projection_mismatch", preflight_hybrid_fail

    preflight_strict_missing_contract = mod.evaluate_pec_preflight(
        "strict-pec",
        None,
        selected_for_preflight,
        "unified-personal-agent-platform",
    )
    assert preflight_strict_missing_contract["status"] == "fail", preflight_strict_missing_contract
    assert preflight_strict_missing_contract["reason_code"] == "pec_contract_file_required", preflight_strict_missing_contract

    preflight_legacy = mod.evaluate_pec_preflight(
        "legacy",
        None,
        selected_for_preflight,
        "unified-personal-agent-platform",
    )
    assert preflight_legacy["status"] == "skipped", preflight_legacy
    assert preflight_legacy["reason_code"] == "pec_legacy_mode", preflight_legacy

    captured = {}

    def fake_run_worker_pack_ok(args):
        captured["args"] = args
        output_index = args.index("--output") + 1
        output_path = Path(args[output_index])
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(
            json.dumps(
                {
                    "worker_task_pack": {
                        "retry_policy": {"max_retries": 2},
                        "timeout_ms": 32000,
                    },
                    "validation_errors": [],
                },
                ensure_ascii=True,
            ),
            encoding="utf-8",
        )
        return 0, "worker-pack-ok", ""

    mod.run = fake_run_worker_pack_ok
    worker_pack_ok = mod.evaluate_worker_task_pack_preflight(
        runtime_profile_file="planningops/config/runtime-profiles.json",
        selected=selected_for_preflight,
        mode="dry-run",
        loop_profile="L1 Contract-Clarification",
    )
    assert worker_pack_ok["status"] == "pass", worker_pack_ok
    assert worker_pack_ok["reason_code"] == "worker_task_pack_ok", worker_pack_ok
    assert "--task-key" in captured["args"], captured
    assert worker_pack_ok["worker_task_pack"]["retry_policy"]["max_retries"] == 2, worker_pack_ok
    assert worker_pack_ok["worker_task_pack"]["timeout_ms"] == 32000, worker_pack_ok

    def fake_run_worker_pack_fail(args):
        return 1, "", "worker-pack-fail"

    mod.run = fake_run_worker_pack_fail
    worker_pack_fail = mod.evaluate_worker_task_pack_preflight(
        runtime_profile_file="planningops/config/runtime-profiles.json",
        selected=selected_for_preflight,
        mode="apply",
        loop_profile="L3 Implementation-TDD",
    )
    assert worker_pack_fail["status"] == "fail", worker_pack_fail
    assert worker_pack_fail["reason_code"] == "worker_task_pack_invalid", worker_pack_fail
    generated_report = Path(captured["args"][captured["args"].index("--output") + 1])
    if generated_report.exists():
        generated_report.unlink()

    reconcile_items = [
        {
            "status": "Todo",
            "workflow_state": "ready-implementation",
            "execution_order": 10,
            "target_repo": "rather-not-work-on/platform-planningops",
            "content": {"type": "Issue", "number": 301, "repository": "rather-not-work-on/platform-planningops"},
        },
        {
            "status": "Todo",
            "workflow_state": "ready-implementation",
            "execution_order": 20,
            "target_repo": "rather-not-work-on/monday",
            "content": {"type": "Issue", "number": 302, "repository": "rather-not-work-on/monday"},
        },
    ]

    def fake_run_closed_reconcile_ok(args):
        if args[:3] == ["gh", "issue", "view"]:
            issue_number = int(args[3])
            state = "CLOSED" if issue_number == 301 else "OPEN"
            return 0, json.dumps({"state": state}, ensure_ascii=True), ""
        raise AssertionError(f"unexpected run call: {args}")

    mod.run = fake_run_closed_reconcile_ok
    project_config_fixture = {
        "status": {"id": "F_STATUS", "options": {"todo": "O_TODO", "done": "O_DONE"}},
        "initiative": {"id": "F_INIT"},
        "target_repo": {"id": "F_REPO"},
        "execution_order": {"id": "F_ORDER"},
        "component": {"id": "F_COMPONENT", "options": {"planningops": "O_COMPONENT_PLANNINGOPS"}},
        "workflow_state": {"id": "F_WF", "options": {"done": "O_WF_DONE", "ready_implementation": "O_WF_READY_IMPL"}},
        "plan_lane": {"id": "F_LANE", "options": {"m3_guardrails": "O_LANE_M3"}},
        "loop_profile": {"id": "F_LOOP", "options": {"l4_integration_reconcile": "O_LOOP_L4"}},
    }
    mod.load_project_sync_config = lambda path: {
        "owner": "rather-not-work-on",
        "project_number": 2,
        "project_id": "PVT_TEST",
        "initiative": "unified-personal-agent-platform",
        "fields": project_config_fixture,
    }
    mod.build_project_sync_issue_index = lambda owner, project_number: {}
    mod.load_project_sync_issue = lambda repo, number: {
        "repo": repo,
        "number": number,
        "url": f"https://github.com/{repo}/issues/{number}",
        "title": f"issue-{number}",
        "body": "\n".join(
            [
                "## Planning Context",
                "- plan_item_id: `AK10`",
                "- target_repo: `rather-not-work-on/platform-planningops`",
                "- component: `planningops`",
                "- workflow_state: `ready-implementation`",
                "- loop_profile: `l4_integration_reconcile`",
                "- execution_order: `10`",
                "- plan_lane: `M3 Guardrails`",
            ]
        ),
        "state": "CLOSED" if number == 301 else "OPEN",
    }
    sync_calls = []
    mod.sync_project_issue_fields = lambda project, issue, apply_mode, issue_index: sync_calls.append(
        (issue["repo"], issue["number"], apply_mode)
    ) or {"issue_repo": issue["repo"], "issue_number": issue["number"], "field_updates": ["status"]}
    reconcile_apply = mod.evaluate_closed_issue_reconcile(
        requested_mode="auto",
        run_mode="apply",
        no_feedback=False,
        items=reconcile_items,
        allowed_workflow_states={"ready-implementation"},
        output_path=str(Path(td) / "closed-reconcile-apply.json"),
    )
    assert reconcile_apply["status"] == "pass", reconcile_apply
    assert reconcile_apply["effective_mode"] == "apply", reconcile_apply
    assert reconcile_apply["updated_count"] == 1, reconcile_apply
    assert reconcile_apply["issue_refs"] == ["rather-not-work-on/platform-planningops#301"], reconcile_apply
    assert sync_calls == [("rather-not-work-on/platform-planningops", 301, True)], sync_calls

    reconcile_check = mod.evaluate_closed_issue_reconcile(
        requested_mode="auto",
        run_mode="dry-run",
        no_feedback=True,
        items=reconcile_items,
        allowed_workflow_states={"ready-implementation"},
        output_path=str(Path(td) / "closed-reconcile-check.json"),
    )
    assert reconcile_check["status"] == "pass", reconcile_check
    assert reconcile_check["effective_mode"] == "check", reconcile_check
    assert sync_calls[-1] == ("rather-not-work-on/platform-planningops", 301, False), sync_calls

    reconcile_off = mod.evaluate_closed_issue_reconcile(
        requested_mode="off",
        run_mode="apply",
        no_feedback=False,
        items=reconcile_items,
        allowed_workflow_states={"ready-implementation"},
        output_path=str(Path(td) / "closed-reconcile-off.json"),
    )
    assert reconcile_off["status"] == "skipped", reconcile_off
    assert reconcile_off["reason_code"] == "closed_issue_reconcile_off", reconcile_off

    def fake_run_closed_reconcile_fail(args):
        if args[:3] == ["gh", "issue", "view"]:
            return 0, json.dumps({"state": "CLOSED"}, ensure_ascii=True), ""
        raise AssertionError(f"unexpected run call: {args}")

    mod.run = fake_run_closed_reconcile_fail
    mod.sync_project_issue_fields = lambda project, issue, apply_mode, issue_index: (_ for _ in ()).throw(
        RuntimeError("closed-reconcile-fail")
    )
    reconcile_fail = mod.evaluate_closed_issue_reconcile(
        requested_mode="apply",
        run_mode="apply",
        no_feedback=False,
        items=reconcile_items,
        allowed_workflow_states={"ready-implementation"},
        output_path=str(Path(td) / "closed-reconcile-fail.json"),
    )
    assert reconcile_fail["status"] == "fail", reconcile_fail
    assert reconcile_fail["reason_code"] == "closed_issue_reconcile_failed", reconcile_fail

    closed_only_attempts = [
        {
            "number": 301,
            "issue_repo": "rather-not-work-on/platform-planningops",
            "result": "issue_not_open",
            "state": "CLOSED",
        }
    ]
    closed_only_trace = mod.build_selection_trace(
        mod.normalize_candidates(reconcile_items, {"ready-implementation"}),
        None,
        closed_only_attempts,
        {"ready-implementation"},
    )
    closed_only_trace["closed_issue_reconcile"] = reconcile_check
    no_eligible_closed = mod.build_no_eligible_result(
        closed_only_trace,
        mod.normalize_candidates(reconcile_items, {"ready-implementation"}),
        closed_only_attempts,
        reconcile_check,
        True,
    )
    assert no_eligible_closed["result"] == "no_eligible_todo_issue", no_eligible_closed
    assert no_eligible_closed["last_verdict"] == "inconclusive", no_eligible_closed
    assert no_eligible_closed["reason_code"] == "closed_issue_project_drift", no_eligible_closed
    assert no_eligible_closed["recommended_action"] == "rerun_apply_closed_issue_reconcile", no_eligible_closed

    no_eligible_empty = mod.build_no_eligible_result(
        {"candidate_count": 0},
        [],
        [],
        {"issues_total": 0},
        True,
    )
    assert no_eligible_empty["reason_code"] == "no_candidate_project_items", no_eligible_empty
    assert no_eligible_empty["recommended_action"] == "retriage_backlog", no_eligible_empty

with tempfile.TemporaryDirectory() as td:
    snapshot_path = Path(td) / "project-items-snapshot.json"
    project_item_calls = []

    def fake_run_project_items_live(args):
        if args[:3] == ["gh", "project", "item-list"]:
            project_item_calls.append(tuple(args))
            return 0, json.dumps({"items": items}, ensure_ascii=True), ""
        raise AssertionError(f"unexpected run call: {args}")

    mod.run = fake_run_project_items_live
    live_project_items = mod.load_project_items(
        "rather-not-work-on",
        2,
        1000,
        snapshot_path=snapshot_path,
        snapshot_fallback_mode="auto",
    )
    assert live_project_items["source"] == "live", live_project_items
    assert live_project_items["rate_limit_fallback_used"] is False, live_project_items
    assert live_project_items["rate_limit_guidance"]["status"] == "not_needed", live_project_items
    assert snapshot_path.exists(), snapshot_path

    def fake_run_project_items_rate_limited(args):
        if args[:3] == ["gh", "project", "item-list"]:
            return 1, "", "GraphQL: API rate limit exceeded for user"
        raise AssertionError(f"unexpected run call: {args}")

    mod.run = fake_run_project_items_rate_limited
    snapshot_project_items = mod.load_project_items(
        "rather-not-work-on",
        2,
        1000,
        snapshot_path=snapshot_path,
        snapshot_fallback_mode="auto",
    )
    assert snapshot_project_items["source"] == "snapshot", snapshot_project_items
    assert snapshot_project_items["rate_limit_fallback_used"] is True, snapshot_project_items
    assert "rate limit exceeded" in snapshot_project_items["rate_limit_error"].lower(), snapshot_project_items
    assert snapshot_project_items["rate_limit_guidance"]["status"] == "snapshot_fallback_active", snapshot_project_items
    assert "apply" in snapshot_project_items["rate_limit_guidance"]["blocked_modes"], snapshot_project_items

    require_project_items = mod.load_project_items(
        "rather-not-work-on",
        2,
        1000,
        snapshot_path=snapshot_path,
        snapshot_fallback_mode="require",
    )
    assert require_project_items["source"] == "snapshot", require_project_items

    try:
        mod.load_project_items(
            "rather-not-work-on",
            2,
            1000,
            snapshot_path=snapshot_path,
            snapshot_fallback_mode="off",
        )
        raise AssertionError("expected rate-limit failure without snapshot fallback")
    except RuntimeError as exc:
        assert "rate limit" in str(exc).lower(), exc

guidance_live_blocked = mod.build_rate_limit_guidance(
    run_mode="apply",
    snapshot_path="planningops/artifacts/loop-runner/project-items-snapshot.json",
    fallback_used=False,
    rate_limit_error="GraphQL: API rate limit exceeded for user",
)
assert guidance_live_blocked["status"] == "live_api_blocked", guidance_live_blocked
assert guidance_live_blocked["blocked_modes"] == ["apply"], guidance_live_blocked

issue_doc_calls = []


def fake_run_issue_doc_cached(args):
    if args[:3] == ["gh", "issue", "view"]:
        issue_doc_calls.append(tuple(args))
        return 0, json.dumps({"body": "cached body", "state": "OPEN"}, ensure_ascii=True), ""
    raise AssertionError(f"unexpected run call: {args}")


mod.run = fake_run_issue_doc_cached
mod.ISSUE_DOC_CACHE.clear()
first_issue_doc = mod.load_issue_doc(77, "rather-not-work-on/platform-planningops")
second_issue_doc = mod.load_issue_doc(77, "rather-not-work-on/platform-planningops")
assert first_issue_doc["state"] == "OPEN", first_issue_doc
assert second_issue_doc["body"] == "cached body", second_issue_doc
assert len(issue_doc_calls) == 1, issue_doc_calls

ready_impl_cross_repo = {
    "workflow_state": "ready-implementation",
    "target_repo": "rather-not-work-on/monday",
    "issue_repo": "rather-not-work-on/platform-planningops",
}
l4_profile = mod.determine_loop_profile(ready_impl_cross_repo, {}, "rather-not-work-on/platform-planningops")
assert l4_profile == "L4 Integration-Reconcile", l4_profile

l5_profile = mod.determine_loop_profile(selected, {"replanning_triggered": True}, "rather-not-work-on/platform-planningops")
assert l5_profile == "L5 Recovery-Replan", l5_profile

replenishment_candidates = mod.build_replenishment_candidates(
    issue_num=77,
    payload={"last_verdict": "fail", "reason_code": "runtime_error_retries_exhausted", "replanning_triggered": True},
    selected={"target_repo": "rather-not-work-on/platform-planningops", "issue_repo": "rather-not-work-on/platform-planningops"},
    verification_path=Path("planningops/artifacts/verification/issue-77-verification.json"),
    payload_path=Path("planningops/artifacts/verification/issue-77-project-payload.json"),
    watchdog_path=Path("planningops/artifacts/loop-runner/watchdog/issue-77.json"),
    replan_decision_path=Path("planningops/artifacts/replan/issue-77.md"),
)
assert len(replenishment_candidates) == 1, replenishment_candidates
candidate = replenishment_candidates[0]
assert candidate["depends_on"] == [77], candidate
assert candidate["evidence_refs"], candidate
assert candidate["acceptance_criteria"], candidate

no_replenishment = mod.build_replenishment_candidates(
    issue_num=77,
    payload={"last_verdict": "pass", "reason_code": "ok", "replanning_triggered": False, "auto_paused": False},
    selected={"target_repo": "rather-not-work-on/platform-planningops", "issue_repo": "rather-not-work-on/platform-planningops"},
    verification_path=Path("planningops/artifacts/verification/issue-77-verification.json"),
    payload_path=Path("planningops/artifacts/verification/issue-77-project-payload.json"),
    watchdog_path=Path("planningops/artifacts/loop-runner/watchdog/issue-77.json"),
    replan_decision_path=None,
)
assert no_replenishment == [], no_replenishment

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
