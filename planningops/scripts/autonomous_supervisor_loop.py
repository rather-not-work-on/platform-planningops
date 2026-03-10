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

from artifact_sink import ArtifactSink


ARTIFACT_SINK = ArtifactSink(local_cache_external=True)


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
        return report

    if stop_reason == "converged_with_snapshot_fallback":
        report.update(
            {
                "status": "degraded",
                "headline": "Supervisor converged with snapshot-backed GitHub intake.",
                "operator_action": "retry_live_after_cooldown",
                "needs_human_attention": False,
            }
        )
        return report

    if stop_reason == "github_rate_limited":
        report.update(
            {
                "status": "blocked",
                "headline": "Live GitHub intake is blocked by API rate limiting.",
                "operator_action": "wait_for_cooldown_then_retry_live",
                "needs_human_attention": False,
            }
        )
        return report

    if stop_reason == "experiment_triggered":
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor paused on experiment trigger.",
                "operator_action": "review_experiment_trigger",
            }
        )
        return report

    if stop_reason in {"quality_gate_fail", "backlog_gate_fail", "escalation_auto_pause", "experiment_auto_executor_failed"}:
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor stopped on a blocking gate failure.",
                "operator_action": "inspect_failure_and_replan",
            }
        )
        return report

    return report


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
    return parser.parse_args()


def main():
    args = parse_args()
    if args.max_cycles <= 0:
        print("max-cycles must be positive")
        return 1

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
    }:
        supervisor_verdict = "fail"
    elif stop_reason in {"experiment_triggered", "sequence_exhausted"}:
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
        },
    }

    output_path = Path(args.output)
    operator_report_path = run_dir / "operator-report.json"
    last_operator_report_path = output_path.with_name(f"{output_path.stem}-operator-report.json")
    summary["operator_report_path"] = str(operator_report_path)
    summary["operator_report_last_path"] = str(last_operator_report_path)
    save_json(output_path, summary)
    save_json(run_dir / "summary.json", summary)
    operator_report = build_operator_report(summary, output_path, run_dir)
    save_json(operator_report_path, operator_report)
    save_json(last_operator_report_path, operator_report)
    print(json.dumps(summary, ensure_ascii=True, indent=2))
    return 0 if supervisor_verdict == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
