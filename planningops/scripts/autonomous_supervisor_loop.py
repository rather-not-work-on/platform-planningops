#!/usr/bin/env python3

from __future__ import annotations

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
import supervisor_handoff_common as shared_handoff_common
import validate_supervisor_operator_handoff as handoff_validator


ARTIFACT_SINK = ArtifactSink(local_cache_external=True)
GOAL_EXHAUSTION_REASON_CODES = {
    "no_eligible_todo_issue",
    "no_candidate_project_items",
    "closed_issue_project_drift",
    "inventory_only_candidates_only",
}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(args, cwd: Path | None = None):
    cp = subprocess.run(args, capture_output=True, text=True, cwd=str(cwd) if cwd else None)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def resolve_repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidate = (planningops_repo / raw_workspace_root).resolve()
    if (candidate / "monday").exists():
        return candidate
    if (planningops_repo.parent / "monday").exists():
        return planningops_repo.parent
    return candidate


def resolve_component_repo(workspace_root: Path, repo_dir: str) -> Path:
    path = Path(repo_dir)
    if path.is_absolute():
        return path
    return (workspace_root / path).resolve()


def resolve_repo_path(repo_root: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path
    return (repo_root / path).resolve()


def normalize_workspace_path(workspace_root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(workspace_root.resolve()))
    except ValueError:
        return str(path.resolve())


def normalize_monday_runtime_ref(workspace_root: Path, monday_repo: Path, raw_ref: str | None) -> str:
    text = str(raw_ref or "").strip()
    if not text or text == "-":
        return "-"
    path_text, separator, suffix = text.partition("#")
    path = Path(path_text)
    if not path.is_absolute():
        path = (monday_repo / path).resolve()
    normalized = normalize_workspace_path(workspace_root, path)
    return f"{normalized}{separator}{suffix}" if separator else normalized


def build_federated_ci_remediation_commands(next_step: str | None, ready: bool) -> list[str]:
    if ready:
        return []

    commands: list[str] = [
        "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    ]
    normalized_next_step = str(next_step or "").strip()
    if normalized_next_step and normalized_next_step.lower() != "none" and normalized_next_step not in commands:
        commands.append(normalized_next_step)
    gate_command = "bash planningops/scripts/gate_federated_ci_summary.sh"
    if gate_command not in commands:
        commands.append(gate_command)
    return commands


def first_remediation_command(commands: list[str]) -> str | None:
    for command in commands:
        normalized = str(command or "").strip()
        if normalized:
            return normalized
    return None


def render_priority_summary_markdown(
    *,
    headline: str | None = None,
    first_action_command: str | None = None,
    remediation_commands: list[str] | None = None,
) -> str | None:
    resolved_headline = str(headline or "").strip()
    resolved_first_action = str(first_action_command or "").strip()
    resolved_commands = [str(item).strip() for item in (remediation_commands or []) if str(item).strip()]
    if not (resolved_headline or resolved_first_action or resolved_commands):
        return None

    lines = ["## Priority"]
    if resolved_headline:
        lines.append(f"- headline: {resolved_headline}")
    if resolved_first_action:
        lines.append(f"- first action: `{resolved_first_action}`")
    if resolved_commands:
        rendered_commands = "; ".join(f"`{command}`" for command in resolved_commands)
        lines.append(f"- remediation commands: {rendered_commands}")
    return "\n".join(lines)


def apply_priority_surface_fields(
    doc: dict,
    *,
    headline: str | None = None,
    first_action_command: str | None = None,
    remediation_commands: list[str] | None = None,
) -> None:
    resolved_headline = str(headline or "").strip()
    resolved_first_action = str(first_action_command or "").strip()
    if resolved_headline:
        doc["priority_headline"] = resolved_headline
    if resolved_first_action:
        doc["priority_cta_command"] = resolved_first_action
    if summary_markdown := render_priority_summary_markdown(
        headline=resolved_headline,
        first_action_command=resolved_first_action,
        remediation_commands=remediation_commands,
    ):
        doc["priority_summary_markdown"] = summary_markdown


def load_federated_ci_summary_snapshot(summary_path: Path, readiness_path: Path) -> dict | None:
    readiness_doc = load_json(readiness_path, {})
    if not isinstance(readiness_doc, dict) or not readiness_doc:
        return None

    ready = bool(readiness_doc.get("ready") is True)
    next_step = str(readiness_doc.get("next_step") or "").strip() or None

    remediation_commands = build_federated_ci_remediation_commands(next_step, ready)
    return {
        "summary_path": str(readiness_doc.get("summary_path") or summary_path),
        "readiness_path": str(readiness_path),
        "validation_report_path": str(readiness_doc.get("validation_report_path") or "").strip() or None,
        "summary_run_id": str(readiness_doc.get("summary_run_id") or "").strip() or None,
        "summary_generated_at_utc": str(readiness_doc.get("summary_generated_at_utc") or "").strip() or None,
        "summary_verdict": str(readiness_doc.get("summary_verdict") or "").strip() or None,
        "overall_status": str(readiness_doc.get("overall_status") or "").strip() or None,
        "check_count": int(readiness_doc.get("check_count") or 0),
        "validation_verdict": str(readiness_doc.get("validation_verdict") or "").strip() or None,
        "validation_state": str(readiness_doc.get("validation_state") or "").strip() or None,
        "readiness_status": str(readiness_doc.get("readiness_status") or "").strip() or None,
        "ready": ready,
        "blocking_reasons": list(readiness_doc.get("blocking_reasons") or []),
        "next_step": next_step,
        "remediation_commands": remediation_commands,
        "first_action_command": first_remediation_command(remediation_commands),
    }


def extract_queue_admission_summary(queue_admission_report: dict, workspace_root: Path, monday_repo: Path) -> dict:
    mode = str(queue_admission_report.get("mode") or "").strip()
    admitted_count = int(queue_admission_report.get("admitted_count") or 0)
    projected_delivery_verdict = "queued" if mode == "apply" and admitted_count > 0 else "dry_run"
    return {
        "delivery_verdict": projected_delivery_verdict,
        "queue_admission_verdict": str(queue_admission_report.get("verdict") or "-"),
        "selected_delivery_entrypoint": str(queue_admission_report.get("selected_delivery_entrypoint") or "-"),
        "scheduled_delivery_work_item_ref": normalize_monday_runtime_ref(
            workspace_root, monday_repo, queue_admission_report.get("scheduled_delivery_work_item_ref")
        ),
        "scheduled_queue_item_ref": normalize_monday_runtime_ref(
            workspace_root, monday_repo, queue_admission_report.get("scheduled_queue_item_ref")
        ),
        "scheduled_queue_item_id": str(queue_admission_report.get("queue_item_id") or "-"),
        "delivery_idempotency_key": str(queue_admission_report.get("delivery_idempotency_key") or "-"),
        "delivery_target_resolution_mode": "-",
        "delivery_target_profile_ref": "-",
        "delivery_transport_kind": "-",
        "delivery_outbox_message_ref": "-",
    }


def run_goal_completion_delivery(args, run_dir: Path, operator_report_path: Path, operator_summary_path: Path):
    operator_report = load_json(operator_report_path, {})
    if str(operator_report.get("message_class_hint") or "") != "goal_completed":
        return {"enabled": False}

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    monday_repo = resolve_component_repo(workspace_root, args.monday_repo_dir)
    monday_script = monday_repo / args.monday_supervisor_goal_completion_script
    monday_output_rel = (
        Path("runtime-artifacts") / "scheduler-queue" / "admission-reports" / f"supervisor-goal-completion-{run_dir.name}.json"
    )
    delivery_output = (monday_repo / monday_output_rel).resolve()

    if not monday_script.exists():
        return {
            "enabled": False,
            "skip_reason": "monday_repo_unavailable",
            "output_path": str(delivery_output),
            "verdict": "skipped",
        }

    command = [
        args.monday_python or sys.executable,
        args.monday_supervisor_goal_completion_script,
        "--operator-report-file",
        str(operator_report_path),
        "--operator-summary-file",
        str(operator_summary_path),
        "--schedule-key",
        args.monday_supervisor_schedule_key,
        "--mode",
        args.mode,
        "--output",
        str(monday_output_rel),
    ]
    if args.monday_profiles_config:
        command.extend(["--profiles-config", args.monday_profiles_config])
    if args.monday_supervisor_queue_db:
        command.extend(["--queue-db", args.monday_supervisor_queue_db])

    rc, out, err = run(command, cwd=monday_repo)
    parsed_stdout_report = parse_json_doc(out)
    if not delivery_output.exists() and isinstance(parsed_stdout_report, dict):
        reported_ref = str(parsed_stdout_report.get("report_ref") or "").strip()
        if reported_ref:
            delivery_output = (monday_repo / reported_ref).resolve()
    report = load_json(delivery_output, {})
    summary = extract_queue_admission_summary(report if isinstance(report, dict) else {}, workspace_root, monday_repo)
    errors = list(report.get("errors") or []) if isinstance(report, dict) else []
    verdict = "pass" if rc == 0 and isinstance(report, dict) and report.get("verdict") == "pass" else "fail"
    if verdict == "fail" and not errors:
        errors = ["monday supervisor goal completion queue admission failed"]

    return {
        "enabled": True,
        "rc": rc,
        "command": command,
        "cwd": str(monday_repo),
        "stdout": out[-2000:],
        "stderr": err[-2000:],
        "output_path": normalize_workspace_path(workspace_root, delivery_output),
        "report": report if isinstance(report, dict) else {},
        "errors": errors,
        "verdict": verdict,
        **summary,
    }


def load_json(path: Path, default):
    read_path = ARTIFACT_SINK.resolve_read_path(path)
    if not read_path.exists():
        return default
    return json.loads(read_path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    ARTIFACT_SINK.write_json(path, data)


def load_items_rows(path: Path):
    if not path.exists():
        return None
    doc = load_json(path, None)
    if isinstance(doc, list):
        return doc
    if isinstance(doc, dict):
        items = doc.get("items")
        if isinstance(items, list):
            return items
    return None


def seed_issue_runner_snapshot(snapshot_path: Path, items_file: str | None = None):
    if snapshot_path.exists():
        return {"status": "existing", "snapshot_path": str(snapshot_path), "seed_source": None, "row_count": None}

    candidate_paths = []
    if items_file:
        candidate_paths.append(Path(items_file))
    candidate_paths.append(Path("planningops/artifacts/program/program-manifest.json"))

    for candidate_path in candidate_paths:
        rows = load_items_rows(candidate_path)
        if rows is None:
            continue
        save_json(
            snapshot_path,
            {
                "generated_at_utc": now_utc(),
                "seed_source": str(candidate_path),
                "items": rows,
            },
        )
        return {
            "status": "seeded",
            "snapshot_path": str(snapshot_path),
            "seed_source": str(candidate_path),
            "row_count": len(rows),
        }

    return {"status": "missing_seed_source", "snapshot_path": str(snapshot_path), "seed_source": None, "row_count": 0}


def copy_json_sidecar(source: Path, target: Path) -> None:
    save_json(target, load_json(source, {}))


def apply_operator_handoff_sidecar_fields(doc: dict, summary: dict) -> None:
    for doc_key, summary_key in (
        ("operator_handoff_validation_path", "operator_handoff_validation_last_path"),
        ("priority_preview_ref", "operator_priority_preview_last_path"),
        ("priority_display_packet_ref", "operator_priority_display_packet_last_path"),
        ("operator_handoff_bundle_path", "operator_handoff_bundle_last_path"),
        ("operator_handoff_bundle_validation_path", "operator_handoff_bundle_validation_last_path"),
        ("operator_handoff_bundle_readiness_path", "operator_handoff_bundle_readiness_last_path"),
        (
            "operator_handoff_bundle_readiness_validation_path",
            "operator_handoff_bundle_readiness_validation_last_path",
        ),
    ):
        value = str(summary.get(summary_key) or "").strip()
        if value:
            doc[doc_key] = value


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
    selection_trace = loop_result.get("selection_trace")
    if isinstance(selection_trace, dict):
        selection_guidance = selection_trace.get("rate_limit_guidance")
        if isinstance(selection_guidance, dict):
            return selection_guidance

    if fallback_used:
        error_text = str(rate_limit_error or "").lower()
        reason = "Supervisor observed snapshot-backed issue intake from live GitHub load failure."
        fallback_cause = "other"
        if "rate limit exceeded" in error_text:
            reason = "Supervisor observed snapshot-backed issue intake due to GitHub API pressure."
            fallback_cause = "rate_limit"
        elif "unknown owner type" in error_text:
            reason = "Supervisor observed snapshot fallback due to owner/project resolution failure."
            fallback_cause = "owner_resolution"
        elif any(token in error_text for token in ("could not resolve host", "error connecting to api.github.com")):
            reason = "Supervisor observed snapshot fallback due to GitHub network connectivity failure."
            fallback_cause = "network"
        elif any(token in error_text for token in ("failed to log in", "authentication", "bad credentials", "token")):
            reason = "Supervisor observed snapshot fallback due to GitHub authentication failure."
            fallback_cause = "auth"
        return {
            "status": "snapshot_fallback_active",
            "recommended_wait_minutes": 15,
            "retry_mode": "retry_live_after_cooldown",
            "allowed_modes": ["dry-run", "no-feedback"],
            "blocked_modes": ["apply"],
            "reason": reason,
            "raw_error": rate_limit_error,
            "fallback_cause": fallback_cause,
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
            "fallback_cause": "rate_limit",
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


def finalize_operator_report(report: dict, summary: dict, stop_reason: str):
    federated_ci_summary = report.get("federated_ci_summary")
    remediation_commands = []
    if isinstance(federated_ci_summary, dict) and federated_ci_summary and not federated_ci_summary.get("ready", False):
        remediation_commands = list(federated_ci_summary.get("remediation_commands") or [])
        first_action_command = first_remediation_command(remediation_commands)
        guidance = report.get("guidance") or {}
        report["guidance"] = {
            **guidance,
            "federated_ci_summary_run_id": federated_ci_summary.get("summary_run_id"),
            "federated_ci_readiness_status": federated_ci_summary.get("readiness_status"),
            "federated_ci_next_step": federated_ci_summary.get("next_step"),
            "federated_ci_remediation_commands": remediation_commands,
        }
        if first_action_command:
            report["guidance"]["first_action_command"] = first_action_command
        if str(report.get("status") or "") == "ok":
            report.update(
                {
                    "status": "degraded",
                    "headline": "Supervisor converged, but the latest federated runtime gate is blocked.",
                    "operator_action": "inspect_federated_ci_gates",
                    "needs_human_attention": False,
                    "reason": (
                        "Supervisor converged locally, but the latest federated CI readiness is "
                        f"{federated_ci_summary.get('readiness_status') or 'blocked'}; "
                        f"next step: {federated_ci_summary.get('next_step') or 'inspect the canonical federated CI doctor output.'}"
                    ),
                }
            )
        if first_action_command:
            report["first_action_command"] = first_action_command
    apply_priority_surface_fields(
        report,
        headline=str(report.get("headline") or "").strip(),
        first_action_command=str(report.get("first_action_command") or "").strip(),
        remediation_commands=remediation_commands,
    )
    if not str(report.get("priority_cta_command") or "").strip():
        fallback_priority_cta = str(report.get("operator_action") or "").strip()
        if fallback_priority_cta:
            report["priority_cta_command"] = fallback_priority_cta
    return decorate_operator_handoff(report, summary, stop_reason)


def build_operator_report(summary: dict, summary_path: Path, run_dir: Path):
    cycles = summary.get("cycles") or []
    last_cycle = cycles[-1] if cycles else {}
    stop_reason = str(summary.get("stop_reason") or "")
    stop_details = summary.get("stop_details") or {}
    goal_completion_delivery = summary.get("goal_completion_delivery") or {}
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
    federated_ci_summary = summary.get("federated_ci_summary")
    if isinstance(federated_ci_summary, dict) and federated_ci_summary:
        report["federated_ci_summary"] = federated_ci_summary
    apply_operator_handoff_sidecar_fields(report, summary)

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
        return finalize_operator_report(report, summary, stop_reason)

    if stop_reason == "converged_with_snapshot_fallback":
        report.update(
            {
                "status": "degraded",
                "headline": "Supervisor converged with snapshot-backed GitHub intake.",
                "operator_action": "retry_live_after_cooldown",
                "needs_human_attention": False,
            }
        )
        return finalize_operator_report(report, summary, stop_reason)

    if stop_reason == "github_rate_limited":
        report.update(
            {
                "status": "blocked",
                "headline": "Live GitHub intake is blocked by API rate limiting.",
                "operator_action": "wait_for_cooldown_then_retry_live",
                "needs_human_attention": False,
            }
        )
        return finalize_operator_report(report, summary, stop_reason)

    if stop_reason == "experiment_triggered":
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor paused on experiment trigger.",
                "operator_action": "review_experiment_trigger",
            }
        )
        return finalize_operator_report(report, summary, stop_reason)

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
            return finalize_operator_report(report, summary, stop_reason)
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor stopped because backlog selection requires replanning.",
                "operator_action": "regenerate_backlog_or_reconcile_project",
            }
        )
        return finalize_operator_report(report, summary, stop_reason)

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
        return finalize_operator_report(report, summary, stop_reason)

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
        return finalize_operator_report(report, summary, stop_reason)

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
                    "goal_completion_delivery_report_path": goal_completion_delivery.get("output_path"),
                    "goal_completion_delivery_verdict": goal_completion_delivery.get("delivery_verdict"),
                    "goal_completion_queue_admission_verdict": goal_completion_delivery.get("queue_admission_verdict"),
                    "goal_completion_selected_delivery_entrypoint": goal_completion_delivery.get("selected_delivery_entrypoint"),
                    "goal_completion_scheduled_delivery_work_item_ref": goal_completion_delivery.get("scheduled_delivery_work_item_ref"),
                    "goal_completion_scheduled_queue_item_ref": goal_completion_delivery.get("scheduled_queue_item_ref"),
                    "goal_completion_scheduled_queue_item_id": goal_completion_delivery.get("scheduled_queue_item_id"),
                    "goal_completion_delivery_idempotency_key": goal_completion_delivery.get("delivery_idempotency_key"),
                    "goal_completion_delivery_target_resolution_mode": goal_completion_delivery.get("delivery_target_resolution_mode"),
                    "goal_completion_delivery_target_profile_ref": goal_completion_delivery.get("delivery_target_profile_ref"),
                    "goal_completion_delivery_outbox_message_ref": goal_completion_delivery.get("delivery_outbox_message_ref"),
                },
            }
        )
        if goal_completion_delivery.get("output_path"):
            report["goal_completion_delivery_report_path"] = goal_completion_delivery.get("output_path")
        return finalize_operator_report(report, summary, stop_reason)

    if stop_reason == "goal_completion_delivery_failed":
        transition = stop_details.get("goal_transition") or {}
        report.update(
            {
                "status": "blocked",
                "headline": "Supervisor completed the active goal but terminal delivery failed.",
                "operator_action": "inspect_goal_completion_delivery",
                "needs_human_attention": True,
                "reason": (goal_completion_delivery.get("errors") or ["Goal completion delivery failed."])[0],
                "guidance": {
                    **(report.get("guidance") or {}),
                    "goal_transition_report_path": transition.get("output_path"),
                    "completed_goal_key": transition.get("goal_key"),
                    "goal_completion_delivery_report_path": goal_completion_delivery.get("output_path"),
                    "goal_completion_delivery_verdict": goal_completion_delivery.get("delivery_verdict"),
                    "goal_completion_queue_admission_verdict": goal_completion_delivery.get("queue_admission_verdict"),
                    "goal_completion_selected_delivery_entrypoint": goal_completion_delivery.get("selected_delivery_entrypoint"),
                    "goal_completion_scheduled_delivery_work_item_ref": goal_completion_delivery.get("scheduled_delivery_work_item_ref"),
                    "goal_completion_scheduled_queue_item_ref": goal_completion_delivery.get("scheduled_queue_item_ref"),
                    "goal_completion_scheduled_queue_item_id": goal_completion_delivery.get("scheduled_queue_item_id"),
                    "goal_completion_delivery_idempotency_key": goal_completion_delivery.get("delivery_idempotency_key"),
                    "goal_completion_delivery_target_resolution_mode": goal_completion_delivery.get("delivery_target_resolution_mode"),
                    "goal_completion_delivery_target_profile_ref": goal_completion_delivery.get("delivery_target_profile_ref"),
                    "goal_completion_delivery_outbox_message_ref": goal_completion_delivery.get("delivery_outbox_message_ref"),
                },
            }
        )
        if goal_completion_delivery.get("output_path"):
            report["goal_completion_delivery_report_path"] = goal_completion_delivery.get("output_path")
        return finalize_operator_report(report, summary, stop_reason)

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
        return finalize_operator_report(report, summary, stop_reason)

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
        return finalize_operator_report(report, summary, stop_reason)

    if stop_reason in {"quality_gate_fail", "backlog_gate_fail", "escalation_auto_pause", "experiment_auto_executor_failed"}:
        report.update(
            {
                "status": "review_required",
                "headline": "Supervisor stopped on a blocking gate failure.",
                "operator_action": "inspect_failure_and_replan",
            }
        )
        return finalize_operator_report(report, summary, stop_reason)

    return finalize_operator_report(report, summary, stop_reason)


def build_operator_summary_markdown(operator_report: dict, handoff_validation_path: Path | None = None):
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
    if handoff_validation_path is not None:
        lines.append(f"- Handoff Validation Path: {handoff_validation_path}")
    for label, field in (
        ("Handoff Bundle Path", "operator_handoff_bundle_path"),
        ("Handoff Bundle Validation Path", "operator_handoff_bundle_validation_path"),
        ("Handoff Bundle Readiness Path", "operator_handoff_bundle_readiness_path"),
        (
            "Handoff Bundle Readiness Validation Path",
            "operator_handoff_bundle_readiness_validation_path",
        ),
    ):
        value = str(operator_report.get(field) or "").strip()
        if value:
            lines.append(f"- {label}: {value}")
    reason = operator_report.get("reason")
    if reason:
        lines.extend(["", "## Reason", "", reason])
    first_action_command = str(operator_report.get("first_action_command") or "").strip()
    priority_cta_command = str(operator_report.get("priority_cta_command") or "").strip()
    priority_summary_markdown = str(operator_report.get("priority_summary_markdown") or "").strip()
    if priority_summary_markdown:
        lines.extend(["", priority_summary_markdown])
    if first_action_command:
        lines.extend(["", "## First Action", "", f"`{first_action_command}`"])
    federated_ci_summary = operator_report.get("federated_ci_summary")
    if isinstance(federated_ci_summary, dict) and federated_ci_summary:
        lines.extend(
            [
                "",
                "## Federated CI",
                "",
                f"- Run ID: {federated_ci_summary.get('summary_run_id') or 'unknown'}",
                f"- Summary Verdict: {federated_ci_summary.get('summary_verdict') or 'unknown'}",
                f"- Readiness Status: {federated_ci_summary.get('readiness_status') or 'unknown'}",
                f"- Ready: {'yes' if federated_ci_summary.get('ready') else 'no'}",
                f"- Summary Path: {federated_ci_summary.get('summary_path') or '-'}",
                f"- Readiness Path: {federated_ci_summary.get('readiness_path') or '-'}",
            ]
        )
        next_step = federated_ci_summary.get("next_step")
        if next_step:
            lines.append(f"- Next Step: {next_step}")
        remediation_commands = list(federated_ci_summary.get("remediation_commands") or [])
        if remediation_commands:
            lines.extend(["- Remediation Commands:"])
            lines.extend([f"  - {command}" for command in remediation_commands])
    return "\n".join(lines) + "\n"


def build_inbox_payload(operator_report: dict, operator_summary_path: Path, handoff_validation_path: Path | None = None):
    attachments = [str(operator_summary_path), str(operator_report.get("summary_path"))]
    cycle_report_path = operator_report.get("cycle_report_path")
    if cycle_report_path:
        attachments.append(str(cycle_report_path))
    goal_completion_delivery_report_path = operator_report.get("goal_completion_delivery_report_path")
    if goal_completion_delivery_report_path:
        attachments.append(str(goal_completion_delivery_report_path))
    if handoff_validation_path is not None:
        attachments.append(str(handoff_validation_path))
    for field in (
        "operator_handoff_bundle_path",
        "operator_handoff_bundle_validation_path",
        "operator_handoff_bundle_readiness_path",
        "operator_handoff_bundle_readiness_validation_path",
    ):
        value = str(operator_report.get(field) or "").strip()
        if value:
            attachments.append(value)
    federated_ci_summary = operator_report.get("federated_ci_summary")
    if isinstance(federated_ci_summary, dict):
        federated_summary_path = str(federated_ci_summary.get("summary_path") or "").strip()
        federated_readiness_path = str(federated_ci_summary.get("readiness_path") or "").strip()
        federated_validation_report_path = str(federated_ci_summary.get("validation_report_path") or "").strip()
        if federated_summary_path:
            attachments.append(federated_summary_path)
        if federated_readiness_path:
            attachments.append(federated_readiness_path)
        if federated_validation_report_path:
            attachments.append(federated_validation_report_path)

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
    first_action_command = str(operator_report.get("first_action_command") or "").strip()
    priority_headline = str(operator_report.get("priority_headline") or operator_report.get("headline") or "").strip()
    priority_cta_command = str(operator_report.get("priority_cta_command") or first_action_command or "").strip()
    priority_summary_markdown = str(operator_report.get("priority_summary_markdown") or "").strip()
    if priority_summary_markdown:
        lines.extend(["", priority_summary_markdown])
    if first_action_command:
        lines.extend(["", "First Action:", f"`{first_action_command}`"])
    if isinstance(federated_ci_summary, dict) and federated_ci_summary:
        lines.extend(
            [
                "",
                "Federated CI:",
                f"- Run ID: {federated_ci_summary.get('summary_run_id') or 'unknown'}",
                f"- Readiness Status: {federated_ci_summary.get('readiness_status') or 'unknown'}",
                f"- Ready: {'yes' if federated_ci_summary.get('ready') else 'no'}",
                f"- Summary Verdict: {federated_ci_summary.get('summary_verdict') or 'unknown'}",
                f"- Next Step: {federated_ci_summary.get('next_step') or 'none'}",
            ]
        )
        remediation_commands = list(federated_ci_summary.get("remediation_commands") or [])
        if remediation_commands:
            lines.append("- Remediation Commands:")
            lines.extend([f"  - {command}" for command in remediation_commands])

    payload = {
        "generated_at_utc": now_utc(),
        "title": f"[{str(operator_report.get('status') or 'unknown').upper()}] {priority_headline or operator_report.get('headline')}",
        "status": operator_report.get("status"),
        "headline": operator_report.get("headline"),
        "priority_headline": priority_headline or None,
        "operator_action": operator_report.get("operator_action"),
        "recommended_wait_minutes": operator_report.get("recommended_wait_minutes"),
        "retry_mode": operator_report.get("retry_mode"),
        "needs_human_attention": operator_report.get("needs_human_attention"),
        "attachments": attachments,
        "body_markdown": "\n".join(lines) + "\n",
    }
    if handoff_validation_path is not None:
        payload["operator_handoff_validation_path"] = str(handoff_validation_path)
    for field in (
        "priority_preview_ref",
        "priority_display_packet_ref",
        "operator_handoff_bundle_path",
        "operator_handoff_bundle_validation_path",
        "operator_handoff_bundle_readiness_path",
        "operator_handoff_bundle_readiness_validation_path",
    ):
        value = str(operator_report.get(field) or "").strip()
        if value:
            payload[field] = value
    if first_action_command:
        payload["first_action_command"] = first_action_command
    if priority_cta_command:
        payload["priority_cta_command"] = priority_cta_command
    if priority_summary_markdown:
        payload["priority_summary_markdown"] = priority_summary_markdown
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


def build_operator_handoff_validation_report(
    *,
    operator_report_path: Path,
    inbox_payload_path: Path,
    operator_summary_path: Path,
) -> dict:
    report_schema_path = Path(handoff_validator.DEFAULT_REPORT_SCHEMA)
    payload_schema_path = Path(handoff_validator.DEFAULT_PAYLOAD_SCHEMA)
    report_schema_doc = handoff_validator.load_json(report_schema_path)
    payload_schema_doc = handoff_validator.load_json(payload_schema_path)
    operator_report_doc = handoff_validator.load_json(operator_report_path)
    inbox_payload_doc = handoff_validator.load_json(inbox_payload_path)
    return handoff_validator.build_report(
        operator_report_path=operator_report_path,
        inbox_payload_path=inbox_payload_path,
        operator_summary_path=operator_summary_path,
        operator_report_doc=operator_report_doc,
        inbox_payload_doc=inbox_payload_doc,
        report_schema_path=report_schema_path,
        payload_schema_path=payload_schema_path,
        report_schema_doc=report_schema_doc,
        payload_schema_doc=payload_schema_doc,
    )


def emit_operator_handoff_bundle_sidecars(
    *,
    operator_report_path: Path,
    monday_repo: Path,
    preview_path: Path,
    display_packet_path: Path,
    bundle_path: Path,
    bundle_validation_path: Path,
    readiness_path: Path,
    readiness_validation_path: Path,
) -> tuple[dict, dict, dict]:
    monday_repo = monday_repo.resolve()
    monday_scripts_dir = monday_repo / "scripts"
    if str(monday_scripts_dir) not in sys.path:
        sys.path.insert(0, str(monday_scripts_dir))

    from render_operator_priority_preview import render_priority_preview
    from export_operator_priority_display_packet import export_display_packet
    from resolve_supervisor_operator_handoff_bundle import resolve_handoff_bundle
    from assess_supervisor_operator_handoff_bundle_readiness import assess_handoff_bundle_readiness

    preview_output_path, preview_doc = render_priority_preview(
        str(operator_report_path),
        output=str(preview_path),
        root=monday_repo,
    )
    preview_ref_for_display = str(preview_output_path.resolve())
    try:
        preview_ref_for_display = preview_output_path.resolve().relative_to(monday_repo.resolve()).as_posix()
    except ValueError:
        # Fallback to absolute path when preview output is outside the monday repo root.
        preview_ref_for_display = str(preview_output_path.resolve())
    display_output_path, display_packet = export_display_packet(
        artifact_file=None,
        preview_ref=preview_ref_for_display,
        output=str(display_packet_path),
        root=monday_repo,
    )
    if preview_output_path.resolve() != preview_path.resolve():
        raise RuntimeError(
            f"operator priority preview path drifted: expected {preview_path.resolve()} got {preview_output_path.resolve()}"
        )
    if display_output_path.resolve() != display_packet_path.resolve():
        raise RuntimeError(
            f"operator priority display packet path drifted: expected {display_packet_path.resolve()} got {display_output_path.resolve()}"
        )
    preview_ref = str(display_packet.get("priority_preview_ref") or "").strip()
    resolved_preview_ref = Path(preview_ref)
    if not resolved_preview_ref.is_absolute():
        resolved_preview_ref = (monday_repo / resolved_preview_ref).resolve()
    else:
        resolved_preview_ref = resolved_preview_ref.resolve()
    if resolved_preview_ref != preview_output_path.resolve():
        raise RuntimeError(
            f"operator priority display packet preview ref drifted: expected {preview_output_path.resolve()} got {preview_ref or 'missing'}"
        )

    _bundle_output_path, bundle_doc = resolve_handoff_bundle(
        artifact_file=str(operator_report_path),
        schema_path=None,
        output=str(bundle_path),
    )
    readiness_doc, _readiness_validation_doc = assess_handoff_bundle_readiness(
        bundle_file=str(bundle_path),
        artifact_file=None,
        bundle_schema_path=None,
        validation_schema_path=None,
        bundle_validation_output=str(bundle_validation_path),
        output=str(readiness_path),
        readiness_validation_output=str(readiness_validation_path),
    )
    return preview_doc, display_packet, readiness_doc


# Canonical supervisor handoff/report helpers are sourced from supervisor_handoff_common.py.
now_utc = shared_handoff_common.now_utc
resolve_repo_root = shared_handoff_common.resolve_repo_root
resolve_workspace_root = shared_handoff_common.resolve_workspace_root
resolve_component_repo = shared_handoff_common.resolve_component_repo
resolve_repo_path = shared_handoff_common.resolve_repo_path
normalize_workspace_path = shared_handoff_common.normalize_workspace_path
normalize_monday_runtime_ref = shared_handoff_common.normalize_monday_runtime_ref
apply_priority_surface_fields = shared_handoff_common.apply_priority_surface_fields
load_federated_ci_summary_snapshot = shared_handoff_common.load_federated_ci_summary_snapshot
extract_queue_admission_summary = shared_handoff_common.extract_queue_admission_summary
run_goal_completion_delivery = shared_handoff_common.run_goal_completion_delivery
load_json = shared_handoff_common.load_json
save_json = shared_handoff_common.save_json
copy_json_sidecar = shared_handoff_common.copy_json_sidecar
parse_json_doc = shared_handoff_common.parse_json_doc
apply_operator_handoff_sidecar_fields = shared_handoff_common.apply_operator_handoff_sidecar_fields
derive_message_class_hint = shared_handoff_common.derive_message_class_hint
decorate_operator_handoff = shared_handoff_common.decorate_operator_handoff
finalize_operator_report = shared_handoff_common.finalize_operator_report
build_operator_report = shared_handoff_common.build_operator_report
build_operator_summary_markdown = shared_handoff_common.build_operator_summary_markdown
build_inbox_payload = shared_handoff_common.build_inbox_payload
build_operator_handoff_validation_report = shared_handoff_common.build_operator_handoff_validation_report
emit_operator_handoff_bundle_sidecars = shared_handoff_common.emit_operator_handoff_bundle_sidecars


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
    if args.mode == "dry-run" or args.offline:
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


def run_backlog_gate(args, cycle_dir: Path, candidate_file: str | None, items_file: str | None = None):
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
    effective_items_file = args.items_file or items_file
    if effective_items_file:
        cmd.extend(["--items-file", effective_items_file])
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
    parser.add_argument("--workspace-root", default="..")
    parser.add_argument("--monday-repo-dir", default="monday")
    parser.add_argument("--monday-python", default=None)
    parser.add_argument("--monday-profiles-config", default=None)
    parser.add_argument("--federated-ci-summary", default="planningops/artifacts/ci/federated-ci-summary.json")
    parser.add_argument(
        "--federated-ci-summary-readiness",
        default="planningops/artifacts/validation/federated-ci-summary-readiness.json",
    )
    parser.add_argument(
        "--monday-supervisor-goal-completion-script",
        default="scripts/enqueue_scheduled_delivery_work_item.py",
    )
    parser.add_argument("--monday-supervisor-schedule-key", default="recurring-delivery")
    parser.add_argument("--monday-supervisor-queue-db", default=None)
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
    if args.offline:
        args.issue_runner_project_items_snapshot_fallback = "require"
        seed_issue_runner_snapshot(Path(args.issue_runner_project_items_snapshot), args.items_file)

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
    run_dir = (Path(args.artifacts_root) / run_id).resolve()
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
        selection_trace = loop_result.get("selection_trace") if isinstance(loop_result.get("selection_trace"), dict) else {}
        snapshot_items_file = None
        if selection_trace:
            snapshot_path = selection_trace.get("project_items_snapshot_path")
            if isinstance(snapshot_path, str) and snapshot_path.strip():
                snapshot_candidate = Path(snapshot_path.strip())
                if snapshot_candidate.exists():
                    snapshot_items_file = str(snapshot_candidate)
                    # Program manifests omit project status fields; prefer projected issues when present.
                    if "program-manifest" in snapshot_candidate.name:
                        projected_issues_fallback = Path("planningops/artifacts/backlog/projected-issues.json")
                        if projected_issues_fallback.exists():
                            snapshot_items_file = str(projected_issues_fallback)

        # In offline mode, avoid live gh item-list dependency for backlog gate.
        if snapshot_items_file is None and args.offline:
            manifest_fallback = Path("planningops/artifacts/program/program-manifest.json")
            if manifest_fallback.exists():
                snapshot_items_file = str(manifest_fallback)

        backlog_gate = run_backlog_gate(args, cycle_dir, candidate_file, snapshot_items_file)
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
    planningops_repo = resolve_repo_root()
    federated_ci_summary = load_federated_ci_summary_snapshot(
        resolve_repo_path(planningops_repo, args.federated_ci_summary),
        resolve_repo_path(planningops_repo, args.federated_ci_summary_readiness),
    )
    if federated_ci_summary:
        summary["federated_ci_summary"] = federated_ci_summary

    output_path = Path(args.output).resolve()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    monday_repo = resolve_component_repo(workspace_root, args.monday_repo_dir)
    operator_report_path = run_dir / "operator-report.json"
    last_operator_report_path = output_path.with_name(f"{output_path.stem}-operator-report.json")
    operator_summary_path = run_dir / "operator-summary.md"
    last_operator_summary_path = output_path.with_name(f"{output_path.stem}-operator-summary.md")
    inbox_payload_path = run_dir / "inbox-payload.json"
    last_inbox_payload_path = output_path.with_name(f"{output_path.stem}-inbox-payload.json")
    operator_handoff_validation_path = run_dir / "operator-handoff-validation.json"
    last_operator_handoff_validation_path = output_path.with_name(f"{output_path.stem}-operator-handoff-validation.json")
    monday_priority_preview_root = monday_repo / "runtime-artifacts" / "messaging" / "operator-priority-previews"
    monday_priority_display_packet_root = (
        monday_repo / "runtime-artifacts" / "messaging" / "operator-priority-display-packets"
    )
    operator_priority_preview_path = monday_priority_preview_root / f"{run_id}-operator-priority-preview.json"
    last_operator_priority_preview_path = monday_priority_preview_root / f"{output_path.stem}-operator-priority-preview.json"
    operator_priority_display_packet_path = (
        monday_priority_display_packet_root / f"{run_id}-operator-priority-display-packet.json"
    )
    last_operator_priority_display_packet_path = (
        monday_priority_display_packet_root / f"{output_path.stem}-operator-priority-display-packet.json"
    )
    operator_handoff_bundle_path = run_dir / "operator-handoff-bundle.json"
    last_operator_handoff_bundle_path = output_path.with_name(f"{output_path.stem}-operator-handoff-bundle.json")
    operator_handoff_bundle_validation_path = run_dir / "operator-handoff-bundle-validation.json"
    last_operator_handoff_bundle_validation_path = output_path.with_name(
        f"{output_path.stem}-operator-handoff-bundle-validation.json"
    )
    operator_handoff_bundle_readiness_path = run_dir / "operator-handoff-bundle-readiness.json"
    last_operator_handoff_bundle_readiness_path = output_path.with_name(
        f"{output_path.stem}-operator-handoff-bundle-readiness.json"
    )
    operator_handoff_bundle_readiness_validation_path = (
        run_dir / "operator-handoff-bundle-readiness-validation.json"
    )
    last_operator_handoff_bundle_readiness_validation_path = output_path.with_name(
        f"{output_path.stem}-operator-handoff-bundle-readiness-validation.json"
    )
    summary["operator_report_path"] = str(operator_report_path)
    summary["operator_report_last_path"] = str(last_operator_report_path)
    summary["operator_summary_path"] = str(operator_summary_path)
    summary["operator_summary_last_path"] = str(last_operator_summary_path)
    summary["inbox_payload_path"] = str(inbox_payload_path)
    summary["inbox_payload_last_path"] = str(last_inbox_payload_path)
    summary["operator_handoff_validation_path"] = str(operator_handoff_validation_path)
    summary["operator_handoff_validation_last_path"] = str(last_operator_handoff_validation_path)
    summary["operator_priority_preview_path"] = str(operator_priority_preview_path)
    summary["operator_priority_preview_last_path"] = str(last_operator_priority_preview_path)
    summary["operator_priority_display_packet_path"] = str(operator_priority_display_packet_path)
    summary["operator_priority_display_packet_last_path"] = str(last_operator_priority_display_packet_path)
    summary["operator_handoff_bundle_path"] = str(operator_handoff_bundle_path)
    summary["operator_handoff_bundle_last_path"] = str(last_operator_handoff_bundle_path)
    summary["operator_handoff_bundle_validation_path"] = str(operator_handoff_bundle_validation_path)
    summary["operator_handoff_bundle_validation_last_path"] = str(last_operator_handoff_bundle_validation_path)
    summary["operator_handoff_bundle_readiness_path"] = str(operator_handoff_bundle_readiness_path)
    summary["operator_handoff_bundle_readiness_last_path"] = str(last_operator_handoff_bundle_readiness_path)
    summary["operator_handoff_bundle_readiness_validation_path"] = str(
        operator_handoff_bundle_readiness_validation_path
    )
    summary["operator_handoff_bundle_readiness_validation_last_path"] = str(
        last_operator_handoff_bundle_readiness_validation_path
    )
    operator_report = build_operator_report(summary, output_path, run_dir)
    save_json(operator_report_path, operator_report)
    save_json(last_operator_report_path, operator_report)
    operator_summary = build_operator_summary_markdown(
        operator_report,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    operator_summary_path.write_text(operator_summary, encoding="utf-8")
    last_operator_summary_path.write_text(operator_summary, encoding="utf-8")
    if stop_reason == "goal_completed":
        last_goal_completion_delivery_path = output_path.with_name(f"{output_path.stem}-goal-completion-delivery-report.json")
        goal_completion_delivery = run_goal_completion_delivery(args, run_dir, operator_report_path, operator_summary_path)
        summary["goal_completion_delivery_path"] = str(goal_completion_delivery.get("output_path") or "-")
        summary["goal_completion_delivery_last_path"] = str(last_goal_completion_delivery_path)
        summary["goal_completion_delivery"] = goal_completion_delivery
        if goal_completion_delivery.get("enabled") and isinstance(goal_completion_delivery.get("report"), dict) and goal_completion_delivery["report"]:
            save_json(last_goal_completion_delivery_path, goal_completion_delivery["report"])
        if goal_completion_delivery.get("enabled") and goal_completion_delivery.get("verdict") != "pass":
            stop_reason = "goal_completion_delivery_failed"
            supervisor_verdict = "fail"
            stop_details = {
                "previous_stop_reason": "goal_completed",
                "goal_transition": stop_details.get("goal_transition") or {},
                "goal_completion_delivery": goal_completion_delivery,
            }
            summary["supervisor_verdict"] = supervisor_verdict
            summary["stop_reason"] = stop_reason
            summary["stop_details"] = stop_details
        operator_report = build_operator_report(summary, output_path, run_dir)
        save_json(operator_report_path, operator_report)
        save_json(last_operator_report_path, operator_report)
        operator_summary = build_operator_summary_markdown(
            operator_report,
            handoff_validation_path=last_operator_handoff_validation_path,
        )
        operator_summary_path.write_text(operator_summary, encoding="utf-8")
        last_operator_summary_path.write_text(operator_summary, encoding="utf-8")
    inbox_payload = build_inbox_payload(
        operator_report,
        last_operator_summary_path,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    save_json(inbox_payload_path, inbox_payload)
    save_json(last_inbox_payload_path, inbox_payload)
    operator_handoff_validation = build_operator_handoff_validation_report(
        operator_report_path=operator_report_path,
        inbox_payload_path=inbox_payload_path,
        operator_summary_path=last_operator_summary_path,
    )
    save_json(operator_handoff_validation_path, operator_handoff_validation)
    save_json(last_operator_handoff_validation_path, operator_handoff_validation)
    if operator_handoff_validation.get("verdict") != "pass":
        raise RuntimeError(
            "supervisor operator handoff validation failed: "
            f"{operator_handoff_validation.get('errors') or ['unknown validation failure']}"
        )
    _preview_doc, _display_packet_doc, handoff_bundle_readiness = emit_operator_handoff_bundle_sidecars(
        operator_report_path=operator_report_path,
        monday_repo=monday_repo,
        preview_path=last_operator_priority_preview_path,
        display_packet_path=last_operator_priority_display_packet_path,
        bundle_path=last_operator_handoff_bundle_path,
        bundle_validation_path=last_operator_handoff_bundle_validation_path,
        readiness_path=last_operator_handoff_bundle_readiness_path,
        readiness_validation_path=last_operator_handoff_bundle_readiness_validation_path,
    )
    if handoff_bundle_readiness.get("ready") is not True:
        raise RuntimeError(
            "supervisor operator handoff bundle readiness failed: "
            f"{handoff_bundle_readiness.get('blocking_reasons') or ['unknown readiness failure']}"
        )
    copy_json_sidecar(last_operator_priority_preview_path, operator_priority_preview_path)
    copy_json_sidecar(last_operator_priority_display_packet_path, operator_priority_display_packet_path)
    copy_json_sidecar(last_operator_handoff_bundle_path, operator_handoff_bundle_path)
    copy_json_sidecar(last_operator_handoff_bundle_validation_path, operator_handoff_bundle_validation_path)
    copy_json_sidecar(last_operator_handoff_bundle_readiness_path, operator_handoff_bundle_readiness_path)
    copy_json_sidecar(
        last_operator_handoff_bundle_readiness_validation_path,
        operator_handoff_bundle_readiness_validation_path,
    )
    operator_summary = build_operator_summary_markdown(
        operator_report,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    operator_summary_path.write_text(operator_summary, encoding="utf-8")
    last_operator_summary_path.write_text(operator_summary, encoding="utf-8")
    inbox_payload = build_inbox_payload(
        operator_report,
        last_operator_summary_path,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    save_json(inbox_payload_path, inbox_payload)
    save_json(last_inbox_payload_path, inbox_payload)
    operator_handoff_validation = build_operator_handoff_validation_report(
        operator_report_path=operator_report_path,
        inbox_payload_path=inbox_payload_path,
        operator_summary_path=last_operator_summary_path,
    )
    save_json(operator_handoff_validation_path, operator_handoff_validation)
    save_json(last_operator_handoff_validation_path, operator_handoff_validation)
    if operator_handoff_validation.get("verdict") != "pass":
        raise RuntimeError(
            "supervisor operator handoff validation failed after bundle emission: "
            f"{operator_handoff_validation.get('errors') or ['unknown validation failure']}"
        )
    save_json(output_path, summary)
    save_json(run_dir / "summary.json", summary)
    print(json.dumps(summary, ensure_ascii=True, indent=2))
    return 0 if supervisor_verdict == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
