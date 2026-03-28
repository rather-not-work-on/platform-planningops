#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from artifact_sink import ArtifactSink
import validate_supervisor_operator_handoff as handoff_validator


ARTIFACT_SINK = ArtifactSink(local_cache_external=True)


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def _run(args, cwd: Path | None = None):
    cp = subprocess.run(args, capture_output=True, text=True, cwd=str(cwd) if cwd else None)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path, default):
    read_path = ARTIFACT_SINK.resolve_read_path(path)
    if not read_path.exists():
        return default
    return json.loads(read_path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    ARTIFACT_SINK.write_json(path, data)


def copy_json_sidecar(source: Path, target: Path) -> None:
    save_json(target, load_json(source, {}))


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


def parse_json_doc(raw: str):
    text = (raw or "").strip()
    if not text:
        return None
    try:
        return json.loads(text)
    except Exception:  # noqa: BLE001
        return None


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

    rc, out, err = _run(command, cwd=monday_repo)
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
