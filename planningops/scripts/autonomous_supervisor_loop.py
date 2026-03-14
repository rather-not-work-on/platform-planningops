#!/usr/bin/env python3

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
GOALS_CORE_DIR = SCRIPT_DIR / "core" / "goals"
if str(GOALS_CORE_DIR) not in sys.path:
    sys.path.insert(0, str(GOALS_CORE_DIR))

from artifact_sink import ArtifactSink
from resolve_active_goal import build_resolved_payload, load_json as load_goal_json, resolve_active_goal, validate_registry


ARTIFACT_SINK = ArtifactSink(local_cache_external=True)
GOAL_EXHAUSTION_REASON_CODES = {
    "no_eligible_todo_issue",
    "no_candidate_project_items",
    "closed_issue_project_drift",
    "inventory_only_candidates_only",
}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(args):
    cp = subprocess.run(args, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path, default):
    read_path = ARTIFACT_SINK.resolve_read_path(path)
    if not read_path.exists():
        return default
    return json.loads(read_path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    ARTIFACT_SINK.write_json(path, data)


def resolve_materialization_contract_from_goal(args):
    if not args.active_goal_registry:
        if args.backlog_materialization_contract_file:
            return args.backlog_materialization_contract_file, None
        return None, None

    repo_root = Path(__file__).resolve().parents[2]
    registry_path = repo_root / args.active_goal_registry
    doc = load_goal_json(registry_path)
    errors = validate_registry(doc, repo_root=repo_root)
    if errors:
        raise RuntimeError(f"active goal registry invalid: {errors}")
    try:
        goal = build_resolved_payload(resolve_active_goal(doc, goal_key=args.active_goal_key))
    except RuntimeError as exc:
        if "no active goal configured" in str(exc):
            if args.backlog_materialization_contract_file:
                return args.backlog_materialization_contract_file, None
            return None, None
        raise
    return str(goal["execution_contract_file"]), goal


def run_goal_transition(args, cycle_dir: Path, active_goal: dict, evidence_refs: list[str]):
    report_path = cycle_dir / "goal-transition-report.json"
    next_goal_key = str(active_goal.get("next_goal_key") or "").strip() or None
    cmd = [
        sys.executable,
        "planningops/scripts/core/goals/transition_goal_state.py",
        "--registry",
        args.active_goal_registry,
        "--goal-key",
        str(active_goal.get("goal_key")),
        "--to-status",
        "achieved",
        "--reason",
        "supervisor_detected_goal_exhaustion",
        "--mode",
        args.mode,
        "--output",
        str(report_path),
    ]
    if next_goal_key:
        cmd.extend(["--activate-next-goal-key", next_goal_key])
    for evidence_ref in evidence_refs:
        if evidence_ref:
            cmd.extend(["--evidence-ref", evidence_ref])

    rc, out, err = run(cmd)
    report = load_json(report_path, {})
    return {
        "enabled": True,
        "rc": rc,
        "command": cmd,
        "stdout": out[-2000:],
        "stderr": err[-2000:],
        "output_path": str(report_path),
        "report": report if isinstance(report, dict) else {},
        "next_goal_key": next_goal_key,
    }


def parse_json_doc(raw: str):
    text = (raw or "").strip()
    if not text:
        return None
    try:
        return json.loads(text)
    except Exception:  # noqa: BLE001
        return None


def extract_verdict_reason(loop_result: dict, rc: int):
    verdict = str(loop_result.get("last_verdict", "")).strip().lower()
    reason_code = str(loop_result.get("reason_code", "")).strip()
    result_name = str(loop_result.get("result", "")).strip().lower()
    if verdict not in {"pass", "fail", "inconclusive"} and result_name == "no_eligible_todo_issue":
        verdict = "inconclusive"
        if not reason_code:
            reason_code = "no_eligible_todo_issue"
    if verdict not in {"pass", "fail", "inconclusive"}:
        verdict = "pass" if rc == 0 else "fail"
    if not reason_code:
        reason_code = "ok" if verdict == "pass" else "runner_failed"
    return verdict, reason_code


def detect_experiment_trigger(loop_result: dict):
    selected = (loop_result.get("selection_trace") or {}).get("selected") or {}
    uncertainty_level = str(selected.get("uncertainty_level", "")).lower()
    simulation_required = bool(selected.get("simulation_required"))
    final_loop_profile = str(loop_result.get("final_loop_profile") or loop_result.get("selected_loop_profile") or "")

    reasons = []
    if uncertainty_level in {"high", "critical"}:
        reasons.append(f"uncertainty_level={uncertainty_level}")
    if simulation_required:
        reasons.append("simulation_required=true")
    if final_loop_profile == "L2 Simulation":
        reasons.append("loop_profile=L2 Simulation")

    return {
        "triggered": bool(reasons),
        "reasons": reasons,
        "uncertainty_level": uncertainty_level or None,
        "simulation_required": simulation_required,
        "loop_profile": final_loop_profile or None,
    }


def derive_rate_limit_guidance(loop_result: dict, project_items_source, fallback_used, rate_limit_error):
    guidance = loop_result.get("rate_limit_guidance")
    if isinstance(guidance, dict):
        return guidance

    if fallback_used:
        return {
            "status": "snapshot_fallback_active",
            "recommended_wait_minutes": 15,
            "retry_mode": "retry_live_after_cooldown",
            "allowed_modes": ["dry-run", "no-feedback"],
            "blocked_modes": ["apply"],
            "reason": "Supervisor observed snapshot-backed issue intake due to GitHub API pressure.",
            "raw_error": rate_limit_error,
        }

    if str(loop_result.get("reason_code") or "").strip() == "github_rate_limited":
        return {
            "status": "live_api_blocked",
            "recommended_wait_minutes": 15,
            "retry_mode": "retry_live_after_cooldown",
            "allowed_modes": [],
            "blocked_modes": ["apply"],
            "reason": "Supervisor observed live GitHub rate limiting without safe fallback.",
            "raw_error": rate_limit_error,
        }

    return None


def derive_message_class_hint(stop_reason: str, status: str, needs_human_attention: bool):
    if stop_reason == "goal_completed":
        return "goal_completed"
    if status == "blocked":
        return "blocked_report"
    if needs_human_attention:
        return "decision_request"
    return "status_update"


def decorate_operator_handoff(report: dict, summary: dict, stop_reason: str):
    resolved_active_goal = summary.get("resolved_active_goal") or {}
    goal_key = str(resolved_active_goal.get("goal_key") or "").strip()
    primary_operator_channel = resolved_active_goal.get("primary_operator_channel")
    terminal_notification_channel = resolved_active_goal.get("terminal_notification_channel")
    guidance = report.get("guidance") or {}

    if goal_key:
        report["goal_key"] = goal_key
    if primary_operator_channel:
        report["primary_operator_channel"] = primary_operator_channel
    if terminal_notification_channel:
        report["terminal_notification_channel"] = terminal_notification_channel
    report["message_class_hint"] = derive_message_class_hint(
        stop_reason,
        str(report.get("status") or ""),
        bool(report.get("needs_human_attention")),
    )
    report["handoff_contract_ref"] = "planningops/contracts/supervisor-operator-handoff-contract.md"

    goal_transition_report_path = guidance.get("goal_transition_report_path")
    if goal_transition_report_path:
        report["goal_transition_report_path"] = goal_transition_report_path

    return report


def build_operator_report(summary: dict, summary_path: Path, run_dir: Path):
    cycles = summary.get("cycles") or []
    last_cycle = cycles[-1] if cycles else {}
    stop_reason = str(summary.get("stop_reason") or "")
    stop_details = summary.get("stop_details") or {}
    guidance = stop_details.get("rate_limit_guidance") or last_cycle.get("rate_limit_guidance") or {}
    cycle_number = stop_details.get("cycle") or last_cycle.get("cycle")
    cycle_report_path = None
    if cycle_number:
        cycle_report_path = str(run_dir / f"cycle-{int(cycle_number):02d}" / "cycle-report.json")

    report = {
        "generated_at_utc": now_utc(),
        "run_id": summary.get("run_id"),
        "summary_path": str(summary_path),
        "cycle_report_path": cycle_report_path,
        "supervisor_verdict": summary.get("supervisor_verdict"),
        "stop_reason": stop_reason,
        "status": "review_required",
        "headline": "Supervisor run requires review.",
        "operator_action": "inspect_supervisor_summary",
        "recommended_wait_minutes": int(guidance.get("recommended_wait_minutes") or 0),
        "retry_mode": guidance.get("retry_mode") or "none",
        "allowed_modes": list(guidance.get("allowed_modes") or []),
        "blocked_modes": list(guidance.get("blocked_modes") or []),
        "needs_human_attention": True,
        "reason": guidance.get("reason") or stop_reason,
        "guidance": guidance if isinstance(guidance, dict) else {},
    }

    if stop_reason == "converged":
        report.update(
            {
                "status": "ok",
                "headline": "Supervisor run converged with live project data.",
                "operator_action": "none",
                "needs_human_attention": False,
                "reason": "No cooldown or retry guidance required.",
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "converged_with_snapshot_fallback":
        report.update(
            {
                "status": "degraded",
                "headline": "Supervisor converged with snapshot-backed GitHub intake.",
                "operator_action": "retry_live_after_cooldown",
                "needs_human_attention": False,
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "github_rate_limited":
        report.update(
            {
                "status": "blocked",
                "headline": "Live GitHub intake is blocked by API rate limiting.",
                "operator_action": "wait_for_cooldown_then_retry_live",
                "needs_human_attention": False,
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "experiment_triggered":
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor paused on experiment trigger.",
                "operator_action": "review_experiment_trigger",
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "replan_required":
        materialization = stop_details.get("backlog_materialization") or {}
        if materialization.get("enabled") and int(materialization.get("rc", 1)) == 0:
            report.update(
                {
                    "status": "review_required",
                    "headline": "Supervisor stopped after backlog materialization dry-run.",
                    "operator_action": "review_materialized_backlog",
                    "reason": "Backlog materialization succeeded, but no new live queue was consumed in this run.",
                    "guidance": {
                        **(report.get("guidance") or {}),
                        "materialize_report_path": materialization.get("output_path"),
                        "projected_issues_output": materialization.get("projected_issues_output"),
                    },
                }
            )
            return decorate_operator_handoff(report, summary, stop_reason)
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor stopped because backlog selection requires replanning.",
                "operator_action": "regenerate_backlog_or_reconcile_project",
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "goal_promotion_ready":
        transition = stop_details.get("goal_transition") or {}
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor found a promotable successor goal.",
                "operator_action": "review_goal_promotion",
                "reason": "Active goal is exhausted and the next goal can be promoted deterministically.",
                "guidance": {
                    **(report.get("guidance") or {}),
                    "goal_transition_report_path": transition.get("output_path"),
                    "next_goal_key": transition.get("next_goal_key"),
                },
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "goal_completion_ready":
        transition = stop_details.get("goal_transition") or {}
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor found an active goal ready for terminal completion.",
                "operator_action": "review_goal_completion",
                "reason": "Active goal is exhausted and no successor goal is currently registered.",
                "guidance": {
                    **(report.get("guidance") or {}),
                    "goal_transition_report_path": transition.get("output_path"),
                    "completed_goal_key": transition.get("goal_key"),
                },
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "goal_completed":
        transition = stop_details.get("goal_transition") or {}
        report.update(
            {
                "status": "ok",
                "headline": "Supervisor completed the active goal and stopped cleanly.",
                "operator_action": "notify_goal_completion",
                "needs_human_attention": False,
                "reason": "No successor goal is registered; emit terminal notification and wait for the next goal brief.",
                "guidance": {
                    **(report.get("guidance") or {}),
                    "goal_transition_report_path": transition.get("output_path"),
                    "completed_goal_key": transition.get("goal_key"),
                },
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "goal_transition_failed":
        transition = stop_details.get("goal_transition") or {}
        report.update(
            {
                "status": "blocked",
                "headline": "Supervisor failed while transitioning the active goal.",
                "operator_action": "inspect_goal_transition_failure",
                "reason": transition.get("stderr") or "Goal transition failed.",
                "guidance": {
                    **(report.get("guidance") or {}),
                    "goal_transition_report_path": transition.get("output_path"),
                },
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason == "replan_materialization_failed":
        materialization = stop_details.get("backlog_materialization") or {}
        report.update(
            {
                "status": "blocked",
                "headline": "Supervisor failed while materializing backlog on replanning.",
                "operator_action": "inspect_materialization_failure",
                "reason": materialization.get("stderr") or "Backlog materialization failed.",
                "guidance": {
                    **(report.get("guidance") or {}),
                    "materialize_report_path": materialization.get("output_path"),
                    "projected_issues_output": materialization.get("projected_issues_output"),
                },
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    if stop_reason in {"quality_gate_fail", "backlog_gate_fail", "escalation_auto_pause", "experiment_auto_executor_failed"}:
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor stopped on a blocking gate failure.",
                "operator_action": "inspect_failure_and_replan",
            }
        )
        return decorate_operator_handoff(report, summary, stop_reason)

    return decorate_operator_handoff(report, summary, stop_reason)


def build_operator_summary_markdown(operator_report: dict):
    allowed_modes = operator_report.get("allowed_modes") or []
    blocked_modes = operator_report.get("blocked_modes") or []
    lines = [
        "# Supervisor Operator Summary",
        "",
        f"- Status: {operator_report.get('status')}",
        f"- Headline: {operator_report.get('headline')}",
        f"- Action: {operator_report.get('operator_action')}",
        f"- Wait Minutes: {operator_report.get('recommended_wait_minutes')}",
        f"- Retry Mode: {operator_report.get('retry_mode')}",
        f"- Allowed Modes: {', '.join(allowed_modes) if allowed_modes else 'none'}",
        f"- Blocked Modes: {', '.join(blocked_modes) if blocked_modes else 'none'}",
        f"- Needs Human Attention: {'yes' if operator_report.get('needs_human_attention') else 'no'}",
        f"- Summary Path: {operator_report.get('summary_path')}",
    ]
    cycle_report_path = operator_report.get("cycle_report_path")
    if cycle_report_path:
        lines.append(f"- Cycle Report Path: {cycle_report_path}")
    reason = operator_report.get("reason")
    if reason:
        lines.extend(["", "## Reason", "", reason])
    return "\n".join(lines) + "\n"


def build_inbox_payload(operator_report: dict, operator_summary_path: Path):
    attachments = [str(operator_summary_path), str(operator_report.get("summary_path"))]
    cycle_report_path = operator_report.get("cycle_report_path")
    if cycle_report_path:
        attachments.append(str(cycle_report_path))

    lines = [
        f"Status: {operator_report.get('status')}",
        f"Headline: {operator_report.get('headline')}",
        f"Action: {operator_report.get('operator_action')}",
        f"Wait Minutes: {operator_report.get('recommended_wait_minutes')}",
        f"Retry Mode: {operator_report.get('retry_mode')}",
        f"Allowed Modes: {', '.join(operator_report.get('allowed_modes') or []) or 'none'}",
        f"Blocked Modes: {', '.join(operator_report.get('blocked_modes') or []) or 'none'}",
        f"Needs Human Attention: {'yes' if operator_report.get('needs_human_attention') else 'no'}",
    ]
    reason = operator_report.get("reason")
    if reason:
        lines.extend(["", "Reason:", reason])

    payload = {
        "generated_at_utc": now_utc(),
        "title": f"[{str(operator_report.get('status') or 'unknown').upper()}] {operator_report.get('headline')}",
        "status": operator_report.get("status"),
        "headline": operator_report.get("headline"),
        "operator_action": operator_report.get("operator_action"),
        "recommended_wait_minutes": operator_report.get("recommended_wait_minutes"),
        "retry_mode": operator_report.get("retry_mode"),
        "needs_human_attention": operator_report.get("needs_human_attention"),
        "attachments": attachments,
        "body_markdown": "\n".join(lines) + "\n",
    }
    goal_key = operator_report.get("goal_key")
    if goal_key:
        payload["goal_key"] = goal_key
    message_class_hint = operator_report.get("message_class_hint")
    if message_class_hint:
        payload["message_class_hint"] = message_class_hint
    payload["handoff_contract_ref"] = operator_report.get(
        "handoff_contract_ref",
        "planningops/contracts/supervisor-operator-handoff-contract.md",
    )
    if operator_report.get("primary_operator_channel"):
        payload["primary_operator_channel"] = operator_report.get("primary_operator_channel")
    if operator_report.get("terminal_notification_channel"):
        payload["terminal_notification_channel"] = operator_report.get("terminal_notification_channel")
    if operator_report.get("goal_transition_report_path"):
        payload["goal_transition_report_path"] = operator_report.get("goal_transition_report_path")
    return payload


def build_issue_runner_command(args):
    cmd = [
        "python3",
        args.issue_runner_script,
        "--mode",
        args.mode,
        "--owner",
        args.owner,
        "--project-num",
        str(args.project_num),
        "--initiative",
        args.initiative,
        "--project-items-snapshot",
        args.issue_runner_project_items_snapshot,
        "--project-items-snapshot-fallback",
        args.issue_runner_project_items_snapshot_fallback,
    ]
    if args.mode == "dry-run":
        cmd.append("--no-feedback")
    return cmd


def run_issue_cycle(args, cycle_index: int, sequence_rows):
    if sequence_rows is not None:
        if cycle_index - 1 >= len(sequence_rows):
            return {
                "status": "sequence_exhausted",
                "rc": 2,
                "stdout": "",
                "stderr": "loop_result_sequence exhausted",
                "result": {},
            }
        row = sequence_rows[cycle_index - 1]
        result = row.get("loop_result", row) if isinstance(row, dict) else {}
        rc = int(row.get("rc", 0)) if isinstance(row, dict) and row.get("rc") is not None else 0
        return {
            "status": "ok",
            "rc": rc,
            "stdout": json.dumps(result, ensure_ascii=True),
            "stderr": "",
            "result": result if isinstance(result, dict) else {},
        }

    cmd = build_issue_runner_command(args)
    rc, out, err = run(cmd)
    parsed = parse_json_doc(out)
    if not isinstance(parsed, dict):
        parsed = load_json(Path("planningops/artifacts/loop-runner/last-run.json"), {})
    return {
        "status": "ok",
        "rc": rc,
        "stdout": out,
        "stderr": err,
        "result": parsed if isinstance(parsed, dict) else {},
        "command": cmd,
    }


def run_backlog_gate(args, cycle_dir: Path, candidate_file: str | None):
    report_path = cycle_dir / "backlog-stock-report.json"
    cmd = [
        "python3",
        "planningops/scripts/backlog_stock_replenishment_guard.py",
        "--owner",
        args.owner,
        "--project-num",
        str(args.project_num),
        "--initiative",
        args.initiative,
        "--stock-policy-file",
        args.stock_policy_file,
        "--output",
        str(report_path),
    ]
    if args.items_file:
        cmd.extend(["--items-file", args.items_file])
    if args.offline:
        cmd.append("--offline")
    if candidate_file:
        cmd.extend(["--candidate-file", candidate_file])
    if args.report_only_gates:
        cmd.append("--report-only")

    rc, out, err = run(cmd)
    report = load_json(report_path, {})
    return {
        "rc": rc,
        "stdout": out,
        "stderr": err,
        "report_path": str(report_path),
        "report": report if isinstance(report, dict) else {},
        "command": cmd,
    }


def run_experiment_auto_executor(args, run_id: str, cycle_index: int, loop_result: dict):
    selected_issue = loop_result.get("selected_issue") or "unknown"
    experiment_id = f"{run_id}-cycle-{cycle_index:02d}-issue-{selected_issue}"
    output_path = Path(args.experiment_artifacts_root) / experiment_id / "supervisor-auto-executor-report.json"
    cmd = [
        "python3",
        "planningops/scripts/supervisor_experiment_auto_executor.py",
        "--repo-root",
        ".",
        "--experiment-id",
        experiment_id,
        "--topic",
        f"supervisor-cycle-{cycle_index:02d}-issue-{selected_issue}",
        "--options",
        args.experiment_options,
        "--validation-pack-file",
        args.experiment_validation_pack_file,
        "--artifacts-root",
        args.experiment_artifacts_root,
        "--worktree-root",
        args.experiment_worktree_root,
        "--output",
        str(output_path),
    ]
    if args.keep_experiment_worktrees:
        cmd.append("--keep-worktrees")

    rc, out, err = run(cmd)
    report = load_json(output_path, {})
    return {
        "enabled": True,
        "rc": rc,
        "command": cmd,
        "stdout": out[-2000:],
        "stderr": err[-2000:],
        "output_path": str(output_path),
        "report": report if isinstance(report, dict) else {},
    }


def run_backlog_materializer(args, cycle_dir: Path):
    if not args.auto_materialize_backlog or not args.backlog_materialization_contract_file:
        return {"enabled": False}

    report_path = cycle_dir / "backlog-materialize-report.json"
    projected_issues_path = cycle_dir / "backlog-projected-issues.json"
    cmd = [
        sys.executable,
        args.backlog_materializer_script,
        "--contract-file",
        args.backlog_materialization_contract_file,
        "--output",
        str(report_path),
    ]
    if args.mode == "apply":
        cmd.append("--apply")
    else:
        cmd.extend(["--projected-issues-output", str(projected_issues_path)])

    rc, out, err = run(cmd)
    report = load_json(report_path, {})
    return {
        "enabled": True,
        "rc": rc,
        "command": cmd,
        "stdout": out[-2000:],
        "stderr": err[-2000:],
        "output_path": str(report_path),
        "projected_issues_output": str(projected_issues_path) if args.mode != "apply" else None,
        "report": report if isinstance(report, dict) else {},
    }


def parse_args():
    parser = argparse.ArgumentParser(description="Autonomous plan-work-review-replan supervisor loop")
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument("--max-cycles", type=int, default=3)
    parser.add_argument("--convergence-pass-streak", type=int, default=2)
    parser.add_argument("--continue-on-experiment", action="store_true")
    parser.add_argument("--report-only-gates", action="store_true")
    parser.add_argument("--owner", default="rather-not-work-on")
    parser.add_argument("--project-num", type=int, default=2)
    parser.add_argument("--initiative", default="unified-personal-agent-platform")
    parser.add_argument("--stock-policy-file", default="planningops/config/backlog-stock-policy.json")
    parser.add_argument("--items-file", default=None, help="Optional normalized items snapshot for offline gate runs")
    parser.add_argument("--offline", action="store_true")
    parser.add_argument("--issue-runner-script", default="planningops/scripts/issue_loop_runner.py")
    parser.add_argument(
        "--issue-runner-project-items-snapshot",
        default="planningops/artifacts/loop-runner/project-items-snapshot.json",
    )
    parser.add_argument(
        "--issue-runner-project-items-snapshot-fallback",
        choices=["off", "auto", "require"],
        default="auto",
    )
    parser.add_argument(
        "--loop-result-sequence-file",
        default=None,
        help="Optional simulation sequence file with loop_result rows for deterministic contract tests",
    )
    parser.add_argument("--artifacts-root", default="planningops/artifacts/supervisor")
    parser.add_argument("--output", default="planningops/artifacts/supervisor/last-run.json")
    parser.add_argument("--run-id", default=None, help="Optional deterministic run id")
    parser.add_argument("--experiment-auto-execute", action="store_true")
    parser.add_argument("--experiment-options", default="option-a,option-b")
    parser.add_argument(
        "--experiment-validation-pack-file",
        default="planningops/config/supervisor-experiment-validation-pack.json",
    )
    parser.add_argument("--experiment-artifacts-root", default="planningops/artifacts/experiments")
    parser.add_argument("--experiment-worktree-root", default="/tmp/planningops-supervisor-experiments")
    parser.add_argument("--keep-experiment-worktrees", action="store_true")
    parser.add_argument("--auto-materialize-backlog", action="store_true")
    parser.add_argument(
        "--backlog-materializer-script",
        default="planningops/scripts/core/backlog/materialize.py",
    )
    parser.add_argument("--backlog-materialization-contract-file", default=None)
    parser.add_argument("--active-goal-registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--active-goal-key", default=None)
    return parser.parse_args()


def main():
    args = parse_args()
    if args.max_cycles <= 0:
        print("max-cycles must be positive")
        return 1
    resolved_active_goal = None
    resolved_contract_file = args.backlog_materialization_contract_file
    if args.active_goal_registry:
        try:
            goal_contract_file, goal_payload = resolve_materialization_contract_from_goal(args)
            if goal_payload is not None:
                resolved_active_goal = goal_payload
            if goal_contract_file:
                resolved_contract_file = goal_contract_file
        except Exception as exc:  # noqa: BLE001
            if args.auto_materialize_backlog:
                print(str(exc))
                return 1
    if args.auto_materialize_backlog:
        if not resolved_contract_file and resolved_active_goal is not None:
            print("backlog-materialization-contract-file or active-goal-registry is required when auto-materialize-backlog is enabled")
            return 1
        args.backlog_materialization_contract_file = resolved_contract_file

    sequence_rows = None
    if args.loop_result_sequence_file:
        loaded = load_json(Path(args.loop_result_sequence_file), {})
        if isinstance(loaded, dict) and isinstance(loaded.get("cycles"), list):
            sequence_rows = loaded.get("cycles")
        elif isinstance(loaded, list):
            sequence_rows = loaded
        else:
            sequence_rows = []

    run_id = args.run_id or f"supervisor-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}"
    run_dir = Path(args.artifacts_root) / run_id
    run_dir.mkdir(parents=True, exist_ok=True)

    cycles = []
    pass_streak = 0
    stop_reason = None
    stop_details = {}
    stop_on_experiment_trigger = not args.continue_on_experiment

    for cycle_index in range(1, args.max_cycles + 1):
        cycle_dir = run_dir / f"cycle-{cycle_index:02d}"
        cycle_dir.mkdir(parents=True, exist_ok=True)

        issue_cycle = run_issue_cycle(args, cycle_index, sequence_rows)
        if issue_cycle.get("status") == "sequence_exhausted":
            stop_reason = "sequence_exhausted"
            stop_details = {"cycle": cycle_index}
            break

        loop_result = issue_cycle.get("result", {})
        loop_rc = int(issue_cycle.get("rc", 1))
        verdict, reason_code = extract_verdict_reason(loop_result, loop_rc)
        auto_paused = bool(loop_result.get("auto_paused"))
        replan_required = auto_paused or verdict in {"fail", "inconclusive"}

        experiment = detect_experiment_trigger(loop_result)
        experiment_trigger_artifact = None
        experiment_executor = {"enabled": False}
        backlog_materialization = {"enabled": False}
        goal_transition = {"enabled": False}
        if experiment["triggered"]:
            experiment_trigger_artifact = cycle_dir / "experiment-trigger.json"
            save_json(
                experiment_trigger_artifact,
                {
                    "generated_at_utc": now_utc(),
                    "cycle": cycle_index,
                    "triggered": True,
                    "reasons": experiment["reasons"],
                    "protocol_ref": "planningops/contracts/worktree-comparative-experiment-protocol.md",
                    "selected_issue": loop_result.get("selected_issue"),
                },
            )
            if args.experiment_auto_execute:
                experiment_executor = run_experiment_auto_executor(args, run_id, cycle_index, loop_result)

        candidate_file = str(loop_result.get("replenishment_candidates_path") or "") or None
        backlog_gate = run_backlog_gate(args, cycle_dir, candidate_file)
        backlog_verdict = str((backlog_gate.get("report") or {}).get("verdict", "")).lower()
        backlog_failed = backlog_gate.get("rc", 1) != 0 or backlog_verdict == "fail"
        selection_trace = loop_result.get("selection_trace") or {}
        project_items_source = selection_trace.get("project_items_source")
        project_items_rate_limit_fallback_used = bool(selection_trace.get("project_items_rate_limit_fallback_used"))
        project_items_rate_limit_error = selection_trace.get("project_items_rate_limit_error")
        rate_limit_guidance = derive_rate_limit_guidance(
            loop_result,
            project_items_source,
            project_items_rate_limit_fallback_used,
            project_items_rate_limit_error,
        ) or selection_trace.get("rate_limit_guidance")

        cycle_record = {
            "cycle": cycle_index,
            "started_at_utc": now_utc(),
            "loop_result_rc": loop_rc,
            "loop_result": loop_result,
            "last_verdict": verdict,
            "reason_code": reason_code,
            "auto_paused": auto_paused,
            "replan_required": replan_required,
            "replan_decision_path": loop_result.get("replan_decision_path"),
            "replenishment_candidates_path": loop_result.get("replenishment_candidates_path"),
            "replenishment_candidates_count": int(loop_result.get("replenishment_candidates_count") or 0),
            "experiment_trigger": experiment,
            "experiment_trigger_artifact": str(experiment_trigger_artifact) if experiment_trigger_artifact else None,
            "experiment_auto_executor": {
                "enabled": bool(experiment_executor.get("enabled")),
                "rc": experiment_executor.get("rc"),
                "output_path": experiment_executor.get("output_path"),
                "verdict": (experiment_executor.get("report") or {}).get("verdict"),
                "selected_option": (experiment_executor.get("report") or {}).get("selected_option"),
            },
            "backlog_materialization": {
                "enabled": False,
                "rc": None,
                "output_path": None,
                "projected_issues_output": None,
                "verdict": None,
            },
            "goal_transition": {
                "enabled": False,
                "rc": None,
                "output_path": None,
                "verdict": None,
                "goal_key": None,
                "next_goal_key": None,
            },
            "project_items_source": project_items_source,
            "project_items_rate_limit_fallback_used": project_items_rate_limit_fallback_used,
            "project_items_rate_limit_error": project_items_rate_limit_error,
            "rate_limit_guidance": rate_limit_guidance,
            "backlog_gate": {
                "rc": backlog_gate.get("rc"),
                "report_path": backlog_gate.get("report_path"),
                "verdict": backlog_verdict or None,
                "breach_count": int(((backlog_gate.get("report") or {}).get("stock") or {}).get("breach_count") or 0),
                "candidate_violation_count": int(
                    ((backlog_gate.get("report") or {}).get("candidate_validation") or {}).get("violation_count") or 0
                ),
            },
            "ended_at_utc": now_utc(),
        }
        save_json(cycle_dir / "cycle-report.json", cycle_record)
        cycles.append(cycle_record)

        if verdict == "pass" and not replan_required:
            pass_streak += 1
        else:
            pass_streak = 0

        if verdict == "fail":
            if reason_code == "github_rate_limited":
                stop_reason = "github_rate_limited"
                stop_details = {"cycle": cycle_index, "rate_limit_guidance": rate_limit_guidance}
                break
            stop_reason = "quality_gate_fail"
            stop_details = {"cycle": cycle_index, "reason_code": reason_code}
            break
        if auto_paused:
            stop_reason = "escalation_auto_pause"
            stop_details = {"cycle": cycle_index, "reason_code": reason_code}
            break
        if (
            verdict == "inconclusive"
            and reason_code in GOAL_EXHAUSTION_REASON_CODES
            and resolved_active_goal
            and int(cycle_record["replenishment_candidates_count"]) == 0
        ):
            goal_transition = run_goal_transition(
                args,
                cycle_dir,
                resolved_active_goal,
                [
                    "planningops/artifacts/loop-runner/last-run.json",
                    cycle_record["backlog_gate"]["report_path"],
                ],
            )
            cycle_record["goal_transition"] = {
                "enabled": True,
                "rc": goal_transition.get("rc"),
                "output_path": goal_transition.get("output_path"),
                "verdict": (goal_transition.get("report") or {}).get("verdict"),
                "goal_key": (goal_transition.get("report") or {}).get("goal_key"),
                "next_goal_key": goal_transition.get("next_goal_key"),
            }
            save_json(cycle_dir / "cycle-report.json", cycle_record)
            if int(goal_transition.get("rc", 1)) != 0:
                stop_reason = "goal_transition_failed"
                stop_details = {
                    "cycle": cycle_index,
                    "reason_code": reason_code,
                    "goal_transition": cycle_record["goal_transition"],
                }
                break
            if goal_transition.get("next_goal_key"):
                if args.mode == "apply":
                    args.active_goal_key = goal_transition.get("next_goal_key")
                    if args.auto_materialize_backlog:
                        resolved_contract_file, resolved_active_goal = resolve_materialization_contract_from_goal(args)
                        args.backlog_materialization_contract_file = resolved_contract_file
                        backlog_materialization = run_backlog_materializer(args, cycle_dir)
                        cycle_record["backlog_materialization"] = {
                            "enabled": bool(backlog_materialization.get("enabled")),
                            "rc": backlog_materialization.get("rc"),
                            "output_path": backlog_materialization.get("output_path"),
                            "projected_issues_output": backlog_materialization.get("projected_issues_output"),
                            "verdict": (backlog_materialization.get("report") or {}).get("verdict"),
                        }
                        save_json(cycle_dir / "cycle-report.json", cycle_record)
                        if backlog_materialization.get("enabled") and int(backlog_materialization.get("rc", 1)) != 0:
                            stop_reason = "replan_materialization_failed"
                            stop_details = {
                                "cycle": cycle_index,
                                "reason_code": reason_code,
                                "backlog_materialization": cycle_record["backlog_materialization"],
                                "goal_transition": cycle_record["goal_transition"],
                            }
                            break
                    pass_streak = 0
                    continue
                stop_reason = "goal_promotion_ready"
                stop_details = {
                    "cycle": cycle_index,
                    "reason_code": reason_code,
                    "goal_transition": cycle_record["goal_transition"],
                }
                break
            if args.mode == "apply":
                resolved_active_goal = None
                args.active_goal_key = None
                stop_reason = "goal_completed"
                stop_details = {
                    "cycle": cycle_index,
                    "reason_code": reason_code,
                    "goal_transition": cycle_record["goal_transition"],
                }
                break
            stop_reason = "goal_completion_ready"
            stop_details = {
                "cycle": cycle_index,
                "reason_code": reason_code,
                "goal_transition": cycle_record["goal_transition"],
            }
            break
        if verdict == "inconclusive" and reason_code in {
            "no_eligible_todo_issue",
            "no_candidate_project_items",
            "closed_issue_project_drift",
            "dependency_blocked",
            "inventory_only_candidates_only",
        }:
            backlog_materialization = run_backlog_materializer(args, cycle_dir)
            cycle_record["backlog_materialization"] = {
                "enabled": bool(backlog_materialization.get("enabled")),
                "rc": backlog_materialization.get("rc"),
                "output_path": backlog_materialization.get("output_path"),
                "projected_issues_output": backlog_materialization.get("projected_issues_output"),
                "verdict": (backlog_materialization.get("report") or {}).get("verdict"),
            }
            save_json(cycle_dir / "cycle-report.json", cycle_record)
            if backlog_materialization.get("enabled") and int(backlog_materialization.get("rc", 1)) != 0:
                stop_reason = "replan_materialization_failed"
                stop_details = {
                    "cycle": cycle_index,
                    "reason_code": reason_code,
                    "backlog_materialization": cycle_record["backlog_materialization"],
                }
                break
            if backlog_materialization.get("enabled") and args.mode == "apply":
                pass_streak = 0
                continue
            stop_reason = "replan_required"
            stop_details = {
                "cycle": cycle_index,
                "reason_code": reason_code,
                "backlog_materialization": cycle_record["backlog_materialization"],
            }
            break
        if backlog_failed and not args.report_only_gates:
            stop_reason = "backlog_gate_fail"
            stop_details = {"cycle": cycle_index}
            break
        if experiment_executor.get("enabled") and int(experiment_executor.get("rc", 1)) != 0:
            stop_reason = "experiment_auto_executor_failed"
            stop_details = {
                "cycle": cycle_index,
                "output_path": experiment_executor.get("output_path"),
            }
            break
        if experiment["triggered"] and stop_on_experiment_trigger:
            stop_reason = "experiment_triggered"
            stop_details = {"cycle": cycle_index, "reasons": experiment["reasons"]}
            break
        if pass_streak >= args.convergence_pass_streak and int(cycle_record["replenishment_candidates_count"]) == 0:
            if project_items_rate_limit_fallback_used:
                stop_reason = "converged_with_snapshot_fallback"
                stop_details = {
                    "cycle": cycle_index,
                    "pass_streak": pass_streak,
                    "rate_limit_guidance": rate_limit_guidance,
                }
            else:
                stop_reason = "converged"
                stop_details = {"cycle": cycle_index, "pass_streak": pass_streak}
            break

    if stop_reason is None:
        stop_reason = "max_cycles_reached"
        stop_details = {"cycle_count": len(cycles)}

    supervisor_verdict = "pass"
    if stop_reason in {
        "quality_gate_fail",
        "escalation_auto_pause",
        "backlog_gate_fail",
        "experiment_auto_executor_failed",
        "github_rate_limited",
        "replan_materialization_failed",
        "goal_transition_failed",
    }:
        supervisor_verdict = "fail"
    elif stop_reason in {
        "experiment_triggered",
        "sequence_exhausted",
        "replan_required",
        "max_cycles_reached",
        "goal_promotion_ready",
        "goal_completion_ready",
    }:
        supervisor_verdict = "inconclusive"

    summary = {
        "generated_at_utc": now_utc(),
        "run_id": run_id,
        "mode": args.mode,
        "max_cycles": args.max_cycles,
        "executed_cycles": len(cycles),
        "convergence_pass_streak": args.convergence_pass_streak,
        "stop_on_experiment_trigger": stop_on_experiment_trigger,
        "report_only_gates": args.report_only_gates,
        "supervisor_verdict": supervisor_verdict,
        "stop_reason": stop_reason,
        "stop_details": stop_details,
        "cycles": cycles,
        "contracts": {
            "autonomous_run_policy": "planningops/contracts/autonomous-run-policy-contract.md",
            "worktree_experiment_protocol": "planningops/contracts/worktree-comparative-experiment-protocol.md",
            "backlog_replenishment": "planningops/contracts/backlog-stock-replenishment-contract.md",
            "backlog_materialization": "planningops/contracts/backlog-materialization-contract.md",
            "active_goal_registry": "planningops/contracts/active-goal-registry-contract.md",
            "goal_lifecycle_transition": "planningops/contracts/goal-lifecycle-transition-contract.md",
            "goal_completion": "planningops/contracts/goal-completion-contract.md",
            "operator_channel_adapter": "planningops/contracts/operator-channel-adapter-contract.md",
        },
    }
    if resolved_active_goal:
        summary["resolved_active_goal"] = {
            "goal_key": resolved_active_goal.get("goal_key"),
            "title": resolved_active_goal.get("title"),
            "execution_contract_file": resolved_active_goal.get("execution_contract_file"),
            "primary_operator_channel": resolved_active_goal.get("primary_operator_channel"),
            "terminal_notification_channel": resolved_active_goal.get("terminal_notification_channel"),
        }

    output_path = Path(args.output)
    operator_report_path = run_dir / "operator-report.json"
    last_operator_report_path = output_path.with_name(f"{output_path.stem}-operator-report.json")
    operator_summary_path = run_dir / "operator-summary.md"
    last_operator_summary_path = output_path.with_name(f"{output_path.stem}-operator-summary.md")
    inbox_payload_path = run_dir / "inbox-payload.json"
    last_inbox_payload_path = output_path.with_name(f"{output_path.stem}-inbox-payload.json")
    summary["operator_report_path"] = str(operator_report_path)
    summary["operator_report_last_path"] = str(last_operator_report_path)
    summary["operator_summary_path"] = str(operator_summary_path)
    summary["operator_summary_last_path"] = str(last_operator_summary_path)
    summary["inbox_payload_path"] = str(inbox_payload_path)
    summary["inbox_payload_last_path"] = str(last_inbox_payload_path)
    save_json(output_path, summary)
    save_json(run_dir / "summary.json", summary)
    operator_report = build_operator_report(summary, output_path, run_dir)
    save_json(operator_report_path, operator_report)
    save_json(last_operator_report_path, operator_report)
    operator_summary = build_operator_summary_markdown(operator_report)
    operator_summary_path.write_text(operator_summary, encoding="utf-8")
    last_operator_summary_path.write_text(operator_summary, encoding="utf-8")
    inbox_payload = build_inbox_payload(operator_report, last_operator_summary_path)
    save_json(inbox_payload_path, inbox_payload)
    save_json(last_inbox_payload_path, inbox_payload)
    print(json.dumps(summary, ensure_ascii=True, indent=2))
    return 0 if supervisor_verdict == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
