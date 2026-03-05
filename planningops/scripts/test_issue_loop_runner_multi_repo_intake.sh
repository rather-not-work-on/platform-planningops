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
                            "primary_output": "planningops/scripts/issue_loop_runner.py",
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
