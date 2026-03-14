#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import json
import subprocess
import tempfile
from pathlib import Path


def run_supervisor(args):
    cp = subprocess.run(args, check=False, capture_output=True, text=True)
    return cp.returncode, cp.stdout, cp.stderr


with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    artifacts_root = td_path / "supervisor-artifacts"

    # 1) continue-on-experiment should allow multi-cycle run and converge.
    out_converged = td_path / "supervisor-converged.json"
    rc_converged, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--convergence-pass-streak",
            "2",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            "planningops/fixtures/supervisor-loop-sequence-sample.json",
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--active-goal-registry",
            "",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_converged),
        ]
    )
    assert rc_converged == 0, rc_converged
    converged = json.loads(out_converged.read_text(encoding="utf-8"))
    assert converged["supervisor_verdict"] == "pass", converged
    assert converged["stop_reason"] == "converged", converged
    assert converged["executed_cycles"] == 2, converged
    assert converged["cycles"][0]["experiment_trigger"]["triggered"] is True, converged
    assert converged["cycles"][1]["replenishment_candidates_count"] == 0, converged
    assert converged["cycles"][0]["project_items_rate_limit_fallback_used"] is False, converged
    converged_operator = json.loads(Path(converged["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert converged_operator["status"] == "ok", converged_operator
    assert converged_operator["operator_action"] == "none", converged_operator
    converged_summary = Path(converged["operator_summary_last_path"]).read_text(encoding="utf-8")
    assert "# Supervisor Operator Summary" in converged_summary, converged_summary
    assert "Action: none" in converged_summary, converged_summary
    converged_inbox = json.loads(Path(converged["inbox_payload_last_path"]).read_text(encoding="utf-8"))
    assert converged_inbox["status"] == "ok", converged_inbox
    assert converged_inbox["title"].startswith("[OK]"), converged_inbox

    # 2) default behavior should stop when experiment trigger is detected.
    out_exp_stop = td_path / "supervisor-experiment-stop.json"
    rc_exp_stop, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--loop-result-sequence-file",
            "planningops/fixtures/supervisor-loop-sequence-sample.json",
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--active-goal-registry",
            "",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_exp_stop),
        ]
    )
    assert rc_exp_stop == 1, rc_exp_stop
    exp_stop = json.loads(out_exp_stop.read_text(encoding="utf-8"))
    assert exp_stop["supervisor_verdict"] == "inconclusive", exp_stop
    assert exp_stop["stop_reason"] == "experiment_triggered", exp_stop
    assert exp_stop["executed_cycles"] == 1, exp_stop

    # 3) explicit fail verdict must stop as quality gate failure.
    fail_sequence = td_path / "fail-sequence.json"
    fail_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 1,
                        "loop_result": {
                            "selected_issue": 303,
                            "last_verdict": "fail",
                            "reason_code": "verdict_consistency_error",
                            "auto_paused": False,
                            "replenishment_candidates_count": 1,
                            "replenishment_candidates_path": "planningops/fixtures/backlog-replenishment-candidates-sample.json",
                            "selection_trace": {"selected": {"uncertainty_level": "low", "simulation_required": False}},
                            "final_loop_profile": "L3 Implementation-TDD",
                        },
                    }
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_fail = td_path / "supervisor-fail.json"
    rc_fail, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(fail_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_fail),
        ]
    )
    assert rc_fail == 1, rc_fail
    fail_doc = json.loads(out_fail.read_text(encoding="utf-8"))
    assert fail_doc["supervisor_verdict"] == "fail", fail_doc
    assert fail_doc["stop_reason"] == "quality_gate_fail", fail_doc
    assert fail_doc["cycles"][0]["reason_code"] == "verdict_consistency_error", fail_doc

    # 4) snapshot-backed convergence must remain explicit in the stop reason.
    snapshot_sequence = td_path / "snapshot-sequence.json"
    snapshot_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 0,
                        "loop_result": {
                            "selected_issue": 401,
                            "last_verdict": "pass",
                            "reason_code": "ok",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {
                                "selected": {"uncertainty_level": "low", "simulation_required": False},
                                "project_items_source": "snapshot",
                                "project_items_rate_limit_fallback_used": True,
                                "project_items_rate_limit_error": "GraphQL: API rate limit exceeded for user",
                            },
                            "final_loop_profile": "L3 Implementation-TDD",
                        },
                    },
                    {
                        "rc": 0,
                        "loop_result": {
                            "selected_issue": 402,
                            "last_verdict": "pass",
                            "reason_code": "ok",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {
                                "selected": {"uncertainty_level": "low", "simulation_required": False},
                                "project_items_source": "snapshot",
                                "project_items_rate_limit_fallback_used": True,
                                "project_items_rate_limit_error": "GraphQL: API rate limit exceeded for user",
                            },
                            "final_loop_profile": "L3 Implementation-TDD",
                        },
                    }
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_snapshot = td_path / "supervisor-snapshot.json"
    rc_snapshot, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "3",
            "--convergence-pass-streak",
            "2",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(snapshot_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_snapshot),
        ]
    )
    assert rc_snapshot == 0, rc_snapshot
    snapshot_doc = json.loads(out_snapshot.read_text(encoding="utf-8"))
    assert snapshot_doc["supervisor_verdict"] == "pass", snapshot_doc
    assert snapshot_doc["stop_reason"] == "converged_with_snapshot_fallback", snapshot_doc
    assert snapshot_doc["cycles"][0]["project_items_source"] == "snapshot", snapshot_doc
    assert snapshot_doc["cycles"][0]["project_items_rate_limit_fallback_used"] is True, snapshot_doc
    assert snapshot_doc["cycles"][0]["rate_limit_guidance"]["status"] == "snapshot_fallback_active", snapshot_doc
    assert snapshot_doc["stop_details"]["rate_limit_guidance"]["status"] == "snapshot_fallback_active", snapshot_doc
    snapshot_operator = json.loads(Path(snapshot_doc["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert snapshot_operator["status"] == "degraded", snapshot_operator
    assert snapshot_operator["operator_action"] == "retry_live_after_cooldown", snapshot_operator
    assert "dry-run" in snapshot_operator["allowed_modes"], snapshot_operator
    snapshot_summary = Path(snapshot_doc["operator_summary_last_path"]).read_text(encoding="utf-8")
    assert "Status: degraded" in snapshot_summary, snapshot_summary
    assert "Action: retry_live_after_cooldown" in snapshot_summary, snapshot_summary
    snapshot_inbox = json.loads(Path(snapshot_doc["inbox_payload_last_path"]).read_text(encoding="utf-8"))
    assert snapshot_inbox["status"] == "degraded", snapshot_inbox
    assert "retry_live_after_cooldown" in snapshot_inbox["body_markdown"], snapshot_inbox

    # 5) explicit github rate-limit failure must stop with dedicated reason and guidance.
    rate_limit_sequence = td_path / "rate-limit-sequence.json"
    rate_limit_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 1,
                        "loop_result": {
                            "result": "github_rate_limited",
                            "reason_code": "github_rate_limited",
                            "rate_limit_guidance": {
                                "status": "live_api_blocked",
                                "recommended_wait_minutes": 15,
                                "retry_mode": "retry_live_after_cooldown",
                                "allowed_modes": [],
                                "blocked_modes": ["apply"],
                            },
                            "selection_trace": {"selected": {"uncertainty_level": "low", "simulation_required": False}},
                        },
                    }
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_rate_limit = td_path / "supervisor-rate-limit.json"
    rc_rate_limit, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "apply",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(rate_limit_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_rate_limit),
        ]
    )
    assert rc_rate_limit == 1, rc_rate_limit
    rate_limit_doc = json.loads(out_rate_limit.read_text(encoding="utf-8"))
    assert rate_limit_doc["supervisor_verdict"] == "fail", rate_limit_doc
    assert rate_limit_doc["stop_reason"] == "github_rate_limited", rate_limit_doc
    assert rate_limit_doc["stop_details"]["rate_limit_guidance"]["status"] == "live_api_blocked", rate_limit_doc
    rate_limit_operator = json.loads(Path(rate_limit_doc["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert rate_limit_operator["status"] == "blocked", rate_limit_operator
    assert rate_limit_operator["operator_action"] == "wait_for_cooldown_then_retry_live", rate_limit_operator
    assert rate_limit_operator["blocked_modes"] == ["apply"], rate_limit_operator
    rate_limit_summary = Path(rate_limit_doc["operator_summary_last_path"]).read_text(encoding="utf-8")
    assert "Status: blocked" in rate_limit_summary, rate_limit_summary
    assert "Action: wait_for_cooldown_then_retry_live" in rate_limit_summary, rate_limit_summary
    rate_limit_inbox = json.loads(Path(rate_limit_doc["inbox_payload_last_path"]).read_text(encoding="utf-8"))
    assert rate_limit_inbox["status"] == "blocked", rate_limit_inbox
    assert rate_limit_inbox["attachments"][0].endswith("-operator-summary.md"), rate_limit_inbox

    # 6) no-eligible issue results must become replanning signals, not quality failures.
    no_eligible_sequence = td_path / "no-eligible-sequence.json"
    no_eligible_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 2,
                        "loop_result": {
                            "result": "no_eligible_todo_issue",
                            "reason_code": "closed_issue_project_drift",
                            "recommended_action": "rerun_apply_closed_issue_reconcile",
                            "last_verdict": "inconclusive",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {
                                "selected": None,
                                "project_items_source": "live",
                                "closed_issue_reconcile": {
                                    "status": "pass",
                                    "effective_mode": "check",
                                    "issues_total": 3,
                                },
                            },
                        },
                    }
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_no_eligible = td_path / "supervisor-no-eligible.json"
    rc_no_eligible, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(no_eligible_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--active-goal-registry",
            "",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_no_eligible),
        ]
    )
    assert rc_no_eligible == 1, rc_no_eligible
    no_eligible_doc = json.loads(out_no_eligible.read_text(encoding="utf-8"))
    assert no_eligible_doc["supervisor_verdict"] == "inconclusive", no_eligible_doc
    assert no_eligible_doc["stop_reason"] == "replan_required", no_eligible_doc
    assert no_eligible_doc["stop_details"]["reason_code"] == "closed_issue_project_drift", no_eligible_doc
    no_eligible_operator = json.loads(Path(no_eligible_doc["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert no_eligible_operator["status"] == "review_required", no_eligible_operator
    assert no_eligible_operator["operator_action"] == "regenerate_backlog_or_reconcile_project", no_eligible_operator

    materialize_success = td_path / "materialize-success.py"
    materialize_success.write_text(
        "\n".join(
            [
                "#!/usr/bin/env python3",
                "import argparse",
                "import json",
                "from pathlib import Path",
                "parser = argparse.ArgumentParser()",
                "parser.add_argument('--contract-file', required=True)",
                "parser.add_argument('--output', required=True)",
                "parser.add_argument('--projected-issues-output', default=None)",
                "parser.add_argument('--apply', action='store_true')",
                "args = parser.parse_args()",
                "report = {'verdict': 'pass', 'contract_file': args.contract_file, 'mode': 'apply' if args.apply else 'dry-run'}",
                "Path(args.output).write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding='utf-8')",
                "if args.projected_issues_output:",
                "    Path(args.projected_issues_output).write_text('[]', encoding='utf-8')",
                "print(json.dumps(report, ensure_ascii=True))",
                "raise SystemExit(0)",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    materialize_fail = td_path / "materialize-fail.py"
    materialize_fail.write_text(
        "\n".join(
            [
                "#!/usr/bin/env python3",
                "import argparse",
                "import json",
                "from pathlib import Path",
                "parser = argparse.ArgumentParser()",
                "parser.add_argument('--contract-file', required=True)",
                "parser.add_argument('--output', required=True)",
                "parser.add_argument('--projected-issues-output', default=None)",
                "parser.add_argument('--apply', action='store_true')",
                "args = parser.parse_args()",
                "report = {'verdict': 'fail', 'contract_file': args.contract_file, 'mode': 'apply' if args.apply else 'dry-run'}",
                "Path(args.output).write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding='utf-8')",
                "if args.projected_issues_output:",
                "    Path(args.projected_issues_output).write_text('[]', encoding='utf-8')",
                "print(json.dumps(report, ensure_ascii=True))",
                "raise SystemExit(1)",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    materialize_expect_contract = td_path / "materialize-expect-contract.py"
    default_active_contract = json.loads(Path("planningops/config/active-goal-registry.json").read_text(encoding="utf-8"))
    active_goal_key = str(default_active_contract.get("active_goal_key") or "").strip()
    active_goal_contract = next(
        goal["execution_contract_file"]
        for goal in default_active_contract["goals"]
        if str(goal.get("goal_key") or "").strip() == active_goal_key
    )

    materialize_expect_contract.write_text(
        "\n".join(
            [
                "#!/usr/bin/env python3",
                "import argparse",
                "import json",
                "from pathlib import Path",
                "parser = argparse.ArgumentParser()",
                "parser.add_argument('--contract-file', required=True)",
                "parser.add_argument('--output', required=True)",
                "parser.add_argument('--projected-issues-output', default=None)",
                "parser.add_argument('--apply', action='store_true')",
                "args = parser.parse_args()",
                f"expected = {active_goal_contract!r}",
                "report = {'verdict': 'pass' if args.contract_file == expected else 'fail', 'contract_file': args.contract_file}",
                "Path(args.output).write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding='utf-8')",
                "if report['verdict'] != 'pass':",
                "    raise SystemExit(1)",
                "raise SystemExit(0)",
            ]
        )
        + "\n",
        encoding="utf-8",
    )

    # 7) dry-run replanning can auto-materialize backlog and surface the materialized output for review.
    out_replan_materialized = td_path / "supervisor-replan-materialized.json"
    rc_replan_materialized, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(no_eligible_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_replan_materialized),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_success),
            "--active-goal-registry",
            "",
            "--backlog-materialization-contract-file",
            "planningops/fixtures/plan-execution-contract-sample.json",
        ]
    )
    assert rc_replan_materialized == 1, rc_replan_materialized
    replan_materialized_doc = json.loads(out_replan_materialized.read_text(encoding="utf-8"))
    assert replan_materialized_doc["supervisor_verdict"] == "inconclusive", replan_materialized_doc
    assert replan_materialized_doc["stop_reason"] == "replan_required", replan_materialized_doc
    materialization = replan_materialized_doc["cycles"][0]["backlog_materialization"]
    assert materialization["enabled"] is True, replan_materialized_doc
    assert materialization["rc"] == 0, materialization
    assert materialization["verdict"] == "pass", materialization
    assert materialization["projected_issues_output"].endswith("backlog-projected-issues.json"), materialization
    replan_materialized_operator = json.loads(
        Path(replan_materialized_doc["operator_report_last_path"]).read_text(encoding="utf-8")
    )
    assert replan_materialized_operator["operator_action"] == "review_materialized_backlog", replan_materialized_operator

    # 8) apply-mode replanning can materialize backlog and continue into the next cycle.
    apply_replan_sequence = td_path / "apply-replan-sequence.json"
    apply_replan_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 2,
                        "loop_result": {
                            "result": "no_eligible_todo_issue",
                            "reason_code": "no_eligible_todo_issue",
                            "recommended_action": "retriage_backlog",
                            "last_verdict": "inconclusive",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {
                                "selected": None,
                                "project_items_source": "live",
                            },
                        },
                    },
                    {
                        "rc": 0,
                        "loop_result": {
                            "selected_issue": 501,
                            "last_verdict": "pass",
                            "reason_code": "ok",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {"selected": {"uncertainty_level": "low", "simulation_required": False}},
                            "final_loop_profile": "L3 Implementation-TDD",
                        },
                    },
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_apply_materialized = td_path / "supervisor-apply-materialized.json"
    rc_apply_materialized, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "apply",
            "--max-cycles",
            "2",
            "--convergence-pass-streak",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(apply_replan_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_apply_materialized),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_success),
            "--active-goal-registry",
            "",
            "--backlog-materialization-contract-file",
            "planningops/fixtures/plan-execution-contract-sample.json",
        ]
    )
    assert rc_apply_materialized == 0, rc_apply_materialized
    apply_materialized_doc = json.loads(out_apply_materialized.read_text(encoding="utf-8"))
    assert apply_materialized_doc["supervisor_verdict"] == "pass", apply_materialized_doc
    assert apply_materialized_doc["stop_reason"] == "converged", apply_materialized_doc
    assert apply_materialized_doc["executed_cycles"] == 2, apply_materialized_doc
    assert apply_materialized_doc["cycles"][0]["backlog_materialization"]["enabled"] is True, apply_materialized_doc
    assert apply_materialized_doc["cycles"][1]["last_verdict"] == "pass", apply_materialized_doc

    # 9) materialization failure must become a dedicated supervisor failure.
    out_materialize_fail = td_path / "supervisor-materialize-fail.json"
    rc_materialize_fail, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(no_eligible_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_materialize_fail),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_fail),
            "--active-goal-registry",
            "",
            "--backlog-materialization-contract-file",
            "planningops/fixtures/plan-execution-contract-sample.json",
        ]
    )
    assert rc_materialize_fail == 1, rc_materialize_fail
    materialize_fail_doc = json.loads(out_materialize_fail.read_text(encoding="utf-8"))
    assert materialize_fail_doc["supervisor_verdict"] == "fail", materialize_fail_doc
    assert materialize_fail_doc["stop_reason"] == "replan_materialization_failed", materialize_fail_doc
    materialize_fail_operator = json.loads(Path(materialize_fail_doc["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert materialize_fail_operator["status"] == "blocked", materialize_fail_operator
    assert materialize_fail_operator["operator_action"] == "inspect_materialization_failure", materialize_fail_operator

    # 10) active goal registry can supply backlog materialization contract automatically.
    out_registry_resolved = td_path / "supervisor-registry-resolved.json"
    rc_registry_resolved, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(no_eligible_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_registry_resolved),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_expect_contract),
            "--active-goal-registry",
            "planningops/config/active-goal-registry.json",
        ]
    )
    assert rc_registry_resolved == 1, rc_registry_resolved
    registry_resolved_doc = json.loads(out_registry_resolved.read_text(encoding="utf-8"))
    assert registry_resolved_doc["resolved_active_goal"]["goal_key"] == active_goal_key, registry_resolved_doc
    assert registry_resolved_doc["resolved_active_goal"]["execution_contract_file"] == active_goal_contract, registry_resolved_doc

    goal_registry = td_path / "goal-registry.json"
    goal_registry.write_text(
        json.dumps(
            {
                "registry_version": 1,
                "active_goal_key": "goal-a",
                "goals": [
                    {
                        "goal_key": "goal-a",
                        "title": "Goal A",
                        "status": "active",
                        "owner_repo": "rather-not-work-on/platform-planningops",
                        "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1-goal-brief.md",
                        "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1.execution-contract.json",
                        "completion_contract_refs": ["planningops/contracts/goal-completion-contract.md"],
                        "next_goal_key": "goal-b",
                        "operator_channels": {
                            "primary_operator_channel": {
                                "kind": "slack_skill_cli",
                                "execution_repo": "rather-not-work-on/monday",
                                "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
                            },
                            "terminal_notification_channel": {
                                "kind": "email_cli",
                                "execution_repo": "rather-not-work-on/monday",
                                "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
                            },
                        },
                    },
                    {
                        "goal_key": "goal-b",
                        "title": "Goal B",
                        "status": "draft",
                        "owner_repo": "rather-not-work-on/platform-planningops",
                        "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2-goal-brief.md",
                        "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2.execution-contract.json",
                        "completion_contract_refs": ["planningops/contracts/goal-completion-contract.md"],
                        "operator_channels": {
                            "primary_operator_channel": {
                                "kind": "slack_skill_cli",
                                "execution_repo": "rather-not-work-on/monday",
                                "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
                            },
                            "terminal_notification_channel": {
                                "kind": "email_cli",
                                "execution_repo": "rather-not-work-on/monday",
                                "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
                            },
                        },
                    },
                ],
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )

    # 11) exhausted active goal should surface promotion readiness before replanning in dry-run mode.
    out_goal_promotion_ready = td_path / "supervisor-goal-promotion-ready.json"
    rc_goal_promotion_ready, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "dry-run",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(no_eligible_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_goal_promotion_ready),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_expect_contract),
            "--active-goal-registry",
            str(goal_registry),
        ]
    )
    assert rc_goal_promotion_ready == 1, rc_goal_promotion_ready
    goal_promotion_ready_doc = json.loads(out_goal_promotion_ready.read_text(encoding="utf-8"))
    assert goal_promotion_ready_doc["supervisor_verdict"] == "inconclusive", goal_promotion_ready_doc
    assert goal_promotion_ready_doc["stop_reason"] == "goal_promotion_ready", goal_promotion_ready_doc
    assert goal_promotion_ready_doc["cycles"][0]["goal_transition"]["enabled"] is True, goal_promotion_ready_doc
    assert goal_promotion_ready_doc["cycles"][0]["goal_transition"]["next_goal_key"] == "goal-b", goal_promotion_ready_doc
    goal_promotion_operator = json.loads(Path(goal_promotion_ready_doc["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert goal_promotion_operator["operator_action"] == "review_goal_promotion", goal_promotion_operator

    # 12) apply-mode promotion should activate the successor and continue with its contract.
    apply_goal_promotion_sequence = td_path / "apply-goal-promotion-sequence.json"
    apply_goal_promotion_sequence.write_text(
        json.dumps(
            {
                "cycles": [
                    {
                        "rc": 2,
                        "loop_result": {
                            "result": "no_eligible_todo_issue",
                            "reason_code": "no_eligible_todo_issue",
                            "last_verdict": "inconclusive",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {"selected": None, "project_items_source": "live"},
                        },
                    },
                    {
                        "rc": 0,
                        "loop_result": {
                            "selected_issue": 777,
                            "last_verdict": "pass",
                            "reason_code": "ok",
                            "auto_paused": False,
                            "replenishment_candidates_count": 0,
                            "selection_trace": {"selected": {"uncertainty_level": "low", "simulation_required": False}},
                            "final_loop_profile": "L3 Implementation-TDD",
                        },
                    },
                ]
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )
    out_apply_goal_promotion = td_path / "supervisor-apply-goal-promotion.json"
    rc_apply_goal_promotion, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "apply",
            "--max-cycles",
            "2",
            "--convergence-pass-streak",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(apply_goal_promotion_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_apply_goal_promotion),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_success),
            "--active-goal-registry",
            str(goal_registry),
        ]
    )
    assert rc_apply_goal_promotion == 0, rc_apply_goal_promotion
    apply_goal_promotion_doc = json.loads(out_apply_goal_promotion.read_text(encoding="utf-8"))
    assert apply_goal_promotion_doc["supervisor_verdict"] == "pass", apply_goal_promotion_doc
    assert apply_goal_promotion_doc["stop_reason"] == "converged", apply_goal_promotion_doc
    assert apply_goal_promotion_doc["resolved_active_goal"]["goal_key"] == "goal-b", apply_goal_promotion_doc
    assert apply_goal_promotion_doc["cycles"][0]["backlog_materialization"]["verdict"] == "pass", apply_goal_promotion_doc
    mutated_registry = json.loads(goal_registry.read_text(encoding="utf-8"))
    goal_lookup = {item["goal_key"]: item for item in mutated_registry["goals"]}
    assert mutated_registry["active_goal_key"] == "goal-b", mutated_registry
    assert goal_lookup["goal-a"]["status"] == "achieved", mutated_registry
    assert goal_lookup["goal-b"]["status"] == "active", mutated_registry

    terminal_registry = td_path / "terminal-goal-registry.json"
    terminal_registry.write_text(
        json.dumps(
            {
                "registry_version": 1,
                "active_goal_key": "goal-terminal",
                "goals": [
                    {
                        "goal_key": "goal-terminal",
                        "title": "Terminal Goal",
                        "status": "active",
                        "owner_repo": "rather-not-work-on/platform-planningops",
                        "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2-goal-brief.md",
                        "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2.execution-contract.json",
                        "completion_contract_refs": ["planningops/contracts/goal-completion-contract.md"],
                        "operator_channels": {
                            "primary_operator_channel": {
                                "kind": "slack_skill_cli",
                                "execution_repo": "rather-not-work-on/monday",
                                "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
                            },
                            "terminal_notification_channel": {
                                "kind": "email_cli",
                                "execution_repo": "rather-not-work-on/monday",
                                "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md",
                            },
                        },
                    }
                ],
            },
            ensure_ascii=True,
            indent=2,
        ),
        encoding="utf-8",
    )

    # 13) apply-mode completion without successor should stop cleanly and leave no active goal.
    out_goal_completed = td_path / "supervisor-goal-completed.json"
    rc_goal_completed, _, _ = run_supervisor(
        [
            "python3",
            "planningops/scripts/autonomous_supervisor_loop.py",
            "--mode",
            "apply",
            "--max-cycles",
            "1",
            "--continue-on-experiment",
            "--loop-result-sequence-file",
            str(no_eligible_sequence),
            "--items-file",
            "planningops/fixtures/backlog-stock-items-sample.json",
            "--offline",
            "--artifacts-root",
            str(artifacts_root),
            "--output",
            str(out_goal_completed),
            "--auto-materialize-backlog",
            "--backlog-materializer-script",
            str(materialize_expect_contract),
            "--active-goal-registry",
            str(terminal_registry),
        ]
    )
    assert rc_goal_completed == 0, rc_goal_completed
    goal_completed_doc = json.loads(out_goal_completed.read_text(encoding="utf-8"))
    assert goal_completed_doc["supervisor_verdict"] == "pass", goal_completed_doc
    assert goal_completed_doc["stop_reason"] == "goal_completed", goal_completed_doc
    goal_completed_operator = json.loads(Path(goal_completed_doc["operator_report_last_path"]).read_text(encoding="utf-8"))
    assert goal_completed_operator["status"] == "ok", goal_completed_operator
    assert goal_completed_operator["operator_action"] == "notify_goal_completion", goal_completed_operator
    terminal_registry_doc = json.loads(terminal_registry.read_text(encoding="utf-8"))
    assert terminal_registry_doc["active_goal_key"] == "", terminal_registry_doc
    assert terminal_registry_doc["goals"][0]["status"] == "achieved", terminal_registry_doc

print("autonomous supervisor loop contract tests ok")
PY
