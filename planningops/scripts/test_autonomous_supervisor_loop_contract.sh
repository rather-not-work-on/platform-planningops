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

print("autonomous supervisor loop contract tests ok")
PY
