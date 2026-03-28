#!/usr/bin/env python3

from __future__ import annotations

import argparse
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
SCRIPTS_DIR = SCRIPT_DIR.parent
if str(SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_DIR))
CORE_GOALS_DIR = SCRIPT_DIR.parent / "core" / "goals"
if str(CORE_GOALS_DIR) not in sys.path:
    sys.path.insert(0, str(CORE_GOALS_DIR))

from federated_python_env import (  # noqa: E402
    build_bootstrap_plan,
    build_managed_env,
    ensure_bootstrap_environment,
    resolve_bootstrap_root,
)
from reflection_cycle_common import (  # noqa: E402
    load_json,
    normalize_repo_path,
    now_utc,
    resolve_component_repo,
    resolve_goal_context,
    resolve_repo_path,
    resolve_repo_root,
    resolve_workspace_root,
)
from supervisor_handoff_common import (  # noqa: E402
    build_inbox_payload,
    build_operator_handoff_validation_report,
    build_operator_report,
    build_operator_summary_markdown,
    emit_operator_handoff_bundle_sidecars,
    load_federated_ci_summary_snapshot,
    run_goal_completion_delivery,
    save_json,
)


RUNNER_CONTRACT_REF = "planningops/contracts/supervisor-operator-handoff-contract.md"
ACTION_CONTRACT_REF = "planningops/contracts/reflection-action-handoff-contract.md"


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Bridge a goal-completed reflection action into supervisor handoff artifacts and monday goal-completion queue admission"
    )
    parser.add_argument("--workspace-root", default="..")
    parser.add_argument("--monday-repo-dir", default="monday")
    parser.add_argument("--monday-python", default=None)
    parser.add_argument("--monday-profiles-config", default=None)
    parser.add_argument(
        "--monday-supervisor-goal-completion-script",
        default="scripts/enqueue_scheduled_delivery_work_item.py",
    )
    parser.add_argument("--monday-supervisor-schedule-key", default="recurring-delivery")
    parser.add_argument("--monday-supervisor-queue-db", default=None)
    parser.add_argument("--active-goal-registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--goal-key", default=None)
    parser.add_argument("--reflection-action-file", required=True)
    parser.add_argument("--goal-transition-output", default=None)
    parser.add_argument(
        "--federated-ci-summary",
        default="planningops/artifacts/ci/federated-ci-summary.json",
    )
    parser.add_argument(
        "--federated-ci-summary-readiness",
        default="planningops/artifacts/validation/federated-ci-summary-readiness.json",
    )
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--run-id",
        default=f"reflection-goal-completion-handoff-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument("--summary-output", default=None)
    parser.add_argument("--output", default=None)
    parser.add_argument(
        "--bootstrap-mode",
        choices=["auto", "off", "require"],
        default="auto",
        help="Managed Python bootstrap mode for sibling-repo leaf scripts",
    )
    parser.add_argument(
        "--bootstrap-root",
        default="planningops/runtime-artifacts/tooling/federated-conformance",
        help="Managed virtualenv root used when bootstrap is required",
    )
    return parser.parse_args()

def resolve_existing_path_ref(path_ref: str, *, planningops_repo: Path, workspace_root: Path) -> str:
    text = str(path_ref or "").strip()
    if not text or text == "-":
        return "-"

    candidate = Path(text)
    candidates = [candidate] if candidate.is_absolute() else [planningops_repo / candidate, workspace_root / candidate]
    for resolved_candidate in candidates:
        if resolved_candidate.exists():
            return str(resolved_candidate.resolve())
    return text


def validate_reflection_action(action: dict) -> list[str]:
    errors: list[str] = []
    if not isinstance(action, dict):
        return ["reflection action must be a JSON object"]
    required = [
        "handoff_contract_ref",
        "verdict",
        "active_goal_key",
        "reflection_decision",
        "action_kind",
        "delivery_required",
        "message_class_hint",
        "goal_transition_required",
        "goal_transition_report_path",
    ]
    for field in required:
        if field not in action:
            errors.append(f"missing reflection action field: {field}")
    if action.get("handoff_contract_ref") != ACTION_CONTRACT_REF:
        errors.append("handoff_contract_ref must match reflection action handoff contract")
    if action.get("verdict") != "pass":
        errors.append("reflection action verdict must be pass")
    if action.get("reflection_decision") != "goal_achieved":
        errors.append("reflection action must use reflection_decision=goal_achieved")
    if action.get("action_kind") != "prepare_goal_completion":
        errors.append("reflection action must use action_kind=prepare_goal_completion")
    if action.get("message_class_hint") != "goal_completed":
        errors.append("reflection action must use message_class_hint=goal_completed")
    if action.get("delivery_required") is not True:
        errors.append("reflection action must require delivery")
    if action.get("goal_transition_required") is not True:
        errors.append("reflection action must require goal transition")
    return errors


def maybe_apply_goal_transition(
    *,
    planningops_repo: Path,
    active_goal_registry: str,
    goal_key: str,
    evidence_ref: str,
    goal_transition_output: str | None,
) -> tuple[str, list[str]]:
    output_path = (
        Path(goal_transition_output).resolve()
        if goal_transition_output
        else planningops_repo / "planningops" / "artifacts" / "validation" / f"{goal_key}-reflection-goal-transition.json"
    )
    command = [
        sys.executable,
        str(planningops_repo / "planningops" / "scripts" / "core" / "goals" / "transition_goal_state.py"),
        "--registry",
        active_goal_registry,
        "--goal-key",
        goal_key,
        "--to-status",
        "achieved",
        "--reason",
        "reflection_goal_achieved",
        "--evidence-ref",
        evidence_ref,
        "--mode",
        "apply",
        "--output",
        str(output_path),
    ]
    result = subprocess.run(command, capture_output=True, text=True, cwd=str(planningops_repo))
    if result.returncode != 0:
        stderr = result.stderr.strip()
        stdout = result.stdout.strip()
        detail = "goal transition apply failed"
        if stderr:
            detail = f"{detail}: {stderr}"
        elif stdout:
            detail = f"{detail}: {stdout}"
        return "-", [detail]
    return str(output_path.resolve()), []


def failure_report(
    *,
    mode: str,
    goal_key: str,
    action_ref: str,
    summary_ref: str,
    report_path: Path,
    failure_stage: str,
    errors: list[str],
    operator_report_ref: str = "-",
    operator_summary_ref: str = "-",
    inbox_payload_ref: str = "-",
    handoff_validation_ref: str = "-",
    goal_completion_delivery_report_ref: str = "-",
) -> int:
    payload = {
        "generated_at_utc": now_utc(),
        "mode": mode,
        "goal_key": goal_key,
        "reflection_action_ref": action_ref,
        "summary_ref": summary_ref,
        "operator_report_ref": operator_report_ref,
        "operator_summary_ref": operator_summary_ref,
        "inbox_payload_ref": inbox_payload_ref,
        "operator_handoff_validation_ref": handoff_validation_ref,
        "goal_completion_delivery_report_ref": goal_completion_delivery_report_ref,
        "reflection_decision": "goal_achieved",
        "action_kind": "prepare_goal_completion",
        "message_class_hint": "goal_completed",
        "goal_completion_delivery_enabled": None,
        "goal_completion_delivery_verdict": None,
        "queue_admission_verdict": None,
        "selected_delivery_entrypoint": None,
        "scheduled_delivery_work_item_ref": None,
        "scheduled_queue_item_ref": None,
        "scheduled_queue_item_id": None,
        "delivery_idempotency_key": None,
        "runner_contract_ref": RUNNER_CONTRACT_REF,
        "failure_stage": failure_stage,
        "error_count": len(errors),
        "errors": errors,
        "verdict": "fail",
    }
    save_json(report_path, payload)
    print(f"report written: {report_path}")
    print(f"verdict=fail failure_stage={failure_stage}")
    return 1


def main() -> int:
    args = parse_args()
    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    monday_repo = resolve_component_repo(workspace_root, args.monday_repo_dir)

    bootstrap_root = resolve_bootstrap_root(planningops_repo, args.bootstrap_root)
    bootstrap_plan = build_bootstrap_plan(planningops_repo, workspace_root, bootstrap_root)
    bootstrap_info = ensure_bootstrap_environment(bootstrap_plan, args.bootstrap_mode)
    if bootstrap_info.get("reexec_required"):
        child_cmd = [bootstrap_info["managed_python"], str(Path(__file__).resolve()), *sys.argv[1:]]
        child = subprocess.run(child_cmd, env=build_managed_env(bootstrap_info))
        return int(child.returncode)

    report_dir = (
        planningops_repo / "planningops" / "artifacts" / "validation" / "reflection-goal-completion-handoff" / args.run_id
    )
    summary_output = (
        Path(args.summary_output).resolve()
        if args.summary_output
        else report_dir / "summary.json"
    )
    report_output = (
        Path(args.output).resolve()
        if args.output
        else report_dir / "cycle-report.json"
    )
    run_dir = summary_output.parent

    action_path = resolve_repo_path(planningops_repo, args.reflection_action_file)
    action_ref = normalize_repo_path(planningops_repo, action_path)
    if not action_path.exists():
        return failure_report(
            mode=args.mode,
            goal_key=args.goal_key or "-",
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="load_reflection_action",
            errors=[f"reflection action not found: {action_path}"],
        )

    action = load_json(action_path)
    action_errors = validate_reflection_action(action)
    action_goal_key = str(action.get("active_goal_key") or "").strip()
    if args.goal_key and args.goal_key != action_goal_key:
        action_errors.append(
            f"reflection action goal_key mismatch: expected {args.goal_key}, got {action_goal_key or '-'}"
        )
    if action_errors:
        return failure_report(
            mode=args.mode,
            goal_key=args.goal_key or action_goal_key or "-",
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="validate_reflection_action",
            errors=action_errors,
        )

    resolved_goal, goal_errors = resolve_goal_context(
        resolve_repo_path(planningops_repo, args.active_goal_registry),
        planningops_repo,
        args.goal_key or action_goal_key,
    )
    if goal_errors:
        return failure_report(
            mode=args.mode,
            goal_key=args.goal_key or action_goal_key or "-",
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="resolve_goal_context",
            errors=goal_errors,
        )

    resolved_goal_key = str((resolved_goal or {}).get("goal_key") or "").strip()
    if resolved_goal_key and action_goal_key and resolved_goal_key != action_goal_key:
        return failure_report(
            mode=args.mode,
            goal_key=resolved_goal_key,
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="resolve_goal_context",
            errors=[
                "reflection action goal_key must match the resolved active goal",
                f"expected={resolved_goal_key}",
                f"actual={action_goal_key}",
            ],
        )

    federated_ci_summary = load_federated_ci_summary_snapshot(
        resolve_repo_path(planningops_repo, args.federated_ci_summary),
        resolve_repo_path(planningops_repo, args.federated_ci_summary_readiness),
    )

    output_path = report_output
    operator_report_path = run_dir / "operator-report.json"
    last_operator_report_path = output_path.with_name(f"{output_path.stem}-operator-report.json")
    operator_summary_path = run_dir / "operator-summary.md"
    last_operator_summary_path = output_path.with_name(f"{output_path.stem}-operator-summary.md")
    inbox_payload_path = run_dir / "inbox-payload.json"
    last_inbox_payload_path = output_path.with_name(f"{output_path.stem}-inbox-payload.json")
    operator_handoff_validation_path = run_dir / "operator-handoff-validation.json"
    last_operator_handoff_validation_path = output_path.with_name(f"{output_path.stem}-operator-handoff-validation.json")
    monday_priority_preview_root = monday_repo / "runtime-artifacts" / "messaging" / "operator-priority-previews"
    monday_priority_display_packet_root = monday_repo / "runtime-artifacts" / "messaging" / "operator-priority-display-packets"
    operator_priority_preview_path = monday_priority_preview_root / f"{args.run_id}-operator-priority-preview.json"
    last_operator_priority_preview_path = monday_priority_preview_root / f"{output_path.stem}-operator-priority-preview.json"
    operator_priority_display_packet_path = monday_priority_display_packet_root / f"{args.run_id}-operator-priority-display-packet.json"
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
    operator_handoff_bundle_readiness_validation_path = run_dir / "operator-handoff-bundle-readiness-validation.json"
    last_operator_handoff_bundle_readiness_validation_path = output_path.with_name(
        f"{output_path.stem}-operator-handoff-bundle-readiness-validation.json"
    )
    last_goal_completion_delivery_path = output_path.with_name(f"{output_path.stem}-goal-completion-delivery-report.json")

    goal_transition_report_path = str(action.get("goal_transition_report_path") or "").strip()
    if (
        args.mode == "apply"
        and bool(action.get("goal_transition_required")) is True
        and (not goal_transition_report_path or goal_transition_report_path == "-")
    ):
        goal_transition_report_path, transition_errors = maybe_apply_goal_transition(
            planningops_repo=planningops_repo,
            active_goal_registry=args.active_goal_registry,
            goal_key=resolved_goal_key or action_goal_key,
            evidence_ref=str(action.get("reflection_evaluation_ref") or action_ref),
            goal_transition_output=args.goal_transition_output,
        )
        if transition_errors:
            return failure_report(
                mode=args.mode,
                goal_key=resolved_goal_key or action_goal_key or "-",
                action_ref=action_ref,
                summary_ref=normalize_repo_path(planningops_repo, summary_output),
                report_path=report_output,
                failure_stage="apply_goal_transition",
                errors=transition_errors,
            )
    goal_transition_report_path = resolve_existing_path_ref(
        goal_transition_report_path,
        planningops_repo=planningops_repo,
        workspace_root=workspace_root,
    )
    summary = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "supervisor_verdict": "pass",
        "stop_reason": "goal_completed",
        "stop_details": {
            "goal_transition": {
                "output_path": goal_transition_report_path,
                "goal_key": resolved_goal_key or action_goal_key,
            },
            "source_reflection_action_ref": action_ref,
            "source_reflection_decision": str(action.get("reflection_decision") or ""),
        },
        "cycles": [],
        "resolved_active_goal": resolved_goal or {},
        "operator_report_path": str(operator_report_path),
        "operator_report_last_path": str(last_operator_report_path),
        "operator_summary_path": str(operator_summary_path),
        "operator_summary_last_path": str(last_operator_summary_path),
        "inbox_payload_path": str(inbox_payload_path),
        "inbox_payload_last_path": str(last_inbox_payload_path),
        "operator_handoff_validation_path": str(operator_handoff_validation_path),
        "operator_handoff_validation_last_path": str(last_operator_handoff_validation_path),
        "operator_priority_preview_path": str(operator_priority_preview_path),
        "operator_priority_preview_last_path": str(last_operator_priority_preview_path),
        "operator_priority_display_packet_path": str(operator_priority_display_packet_path),
        "operator_priority_display_packet_last_path": str(last_operator_priority_display_packet_path),
        "operator_handoff_bundle_path": str(operator_handoff_bundle_path),
        "operator_handoff_bundle_last_path": str(last_operator_handoff_bundle_path),
        "operator_handoff_bundle_validation_path": str(operator_handoff_bundle_validation_path),
        "operator_handoff_bundle_validation_last_path": str(last_operator_handoff_bundle_validation_path),
        "operator_handoff_bundle_readiness_path": str(operator_handoff_bundle_readiness_path),
        "operator_handoff_bundle_readiness_last_path": str(last_operator_handoff_bundle_readiness_path),
        "operator_handoff_bundle_readiness_validation_path": str(operator_handoff_bundle_readiness_validation_path),
        "operator_handoff_bundle_readiness_validation_last_path": str(
            last_operator_handoff_bundle_readiness_validation_path
        ),
    }
    if federated_ci_summary:
        summary["federated_ci_summary"] = federated_ci_summary

    save_json(summary_output, summary)

    operator_report = build_operator_report(summary, summary_output, run_dir)
    save_json(operator_report_path, operator_report)
    save_json(last_operator_report_path, operator_report)
    operator_summary = build_operator_summary_markdown(
        operator_report,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    write_text(operator_summary_path, operator_summary)
    write_text(last_operator_summary_path, operator_summary)

    goal_completion_delivery = run_goal_completion_delivery(args, run_dir, operator_report_path, operator_summary_path)
    summary["goal_completion_delivery_path"] = str(goal_completion_delivery.get("output_path") or "-")
    summary["goal_completion_delivery_last_path"] = str(last_goal_completion_delivery_path)
    summary["goal_completion_delivery"] = goal_completion_delivery
    if goal_completion_delivery.get("enabled") and isinstance(goal_completion_delivery.get("report"), dict) and goal_completion_delivery["report"]:
        save_json(last_goal_completion_delivery_path, goal_completion_delivery["report"])
    if goal_completion_delivery.get("enabled") and goal_completion_delivery.get("verdict") != "pass":
        summary["supervisor_verdict"] = "fail"
        summary["stop_reason"] = "goal_completion_delivery_failed"
        summary["stop_details"] = {
            "previous_stop_reason": "goal_completed",
            "goal_transition": summary["stop_details"].get("goal_transition") or {},
            "goal_completion_delivery": goal_completion_delivery,
            "source_reflection_action_ref": action_ref,
            "source_reflection_decision": str(action.get("reflection_decision") or ""),
        }

    save_json(summary_output, summary)
    operator_report = build_operator_report(summary, summary_output, run_dir)
    save_json(operator_report_path, operator_report)
    save_json(last_operator_report_path, operator_report)
    operator_summary = build_operator_summary_markdown(
        operator_report,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    write_text(operator_summary_path, operator_summary)
    write_text(last_operator_summary_path, operator_summary)

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
        return failure_report(
            mode=args.mode,
            goal_key=resolved_goal_key or action_goal_key or "-",
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="validate_supervisor_operator_handoff",
            errors=list(operator_handoff_validation.get("errors") or ["unknown handoff validation failure"]),
            operator_report_ref=normalize_repo_path(planningops_repo, operator_report_path),
            operator_summary_ref=normalize_repo_path(planningops_repo, last_operator_summary_path),
            inbox_payload_ref=normalize_repo_path(planningops_repo, inbox_payload_path),
            handoff_validation_ref=normalize_repo_path(planningops_repo, operator_handoff_validation_path),
            goal_completion_delivery_report_ref=str(goal_completion_delivery.get("output_path") or "-"),
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
        return failure_report(
            mode=args.mode,
            goal_key=resolved_goal_key or action_goal_key or "-",
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="assess_supervisor_operator_handoff_bundle_readiness",
            errors=list(handoff_bundle_readiness.get("blocking_reasons") or ["unknown bundle readiness failure"]),
            operator_report_ref=normalize_repo_path(planningops_repo, operator_report_path),
            operator_summary_ref=normalize_repo_path(planningops_repo, last_operator_summary_path),
            inbox_payload_ref=normalize_repo_path(planningops_repo, inbox_payload_path),
            handoff_validation_ref=normalize_repo_path(planningops_repo, operator_handoff_validation_path),
            goal_completion_delivery_report_ref=str(goal_completion_delivery.get("output_path") or "-"),
        )

    operator_summary = build_operator_summary_markdown(
        operator_report,
        handoff_validation_path=last_operator_handoff_validation_path,
    )
    write_text(operator_summary_path, operator_summary)
    write_text(last_operator_summary_path, operator_summary)
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
        return failure_report(
            mode=args.mode,
            goal_key=resolved_goal_key or action_goal_key or "-",
            action_ref=action_ref,
            summary_ref=normalize_repo_path(planningops_repo, summary_output),
            report_path=report_output,
            failure_stage="validate_supervisor_operator_handoff_after_bundle",
            errors=list(operator_handoff_validation.get("errors") or ["unknown post-bundle handoff validation failure"]),
            operator_report_ref=normalize_repo_path(planningops_repo, operator_report_path),
            operator_summary_ref=normalize_repo_path(planningops_repo, last_operator_summary_path),
            inbox_payload_ref=normalize_repo_path(planningops_repo, inbox_payload_path),
            handoff_validation_ref=normalize_repo_path(planningops_repo, operator_handoff_validation_path),
            goal_completion_delivery_report_ref=str(goal_completion_delivery.get("output_path") or "-"),
        )

    save_json(summary_output, summary)

    delivery_enabled = bool(goal_completion_delivery.get("enabled"))
    delivery_verdict = str(goal_completion_delivery.get("delivery_verdict") or "-")
    queue_admission_verdict = str(goal_completion_delivery.get("queue_admission_verdict") or "-")
    payload = {
        "generated_at_utc": now_utc(),
        "mode": args.mode,
        "goal_key": resolved_goal_key or action_goal_key or "-",
        "reflection_action_ref": action_ref,
        "summary_ref": normalize_repo_path(planningops_repo, summary_output),
        "operator_report_ref": normalize_repo_path(planningops_repo, operator_report_path),
        "operator_summary_ref": normalize_repo_path(planningops_repo, last_operator_summary_path),
        "inbox_payload_ref": normalize_repo_path(planningops_repo, inbox_payload_path),
        "operator_handoff_validation_ref": normalize_repo_path(planningops_repo, operator_handoff_validation_path),
        "operator_handoff_bundle_ref": normalize_repo_path(planningops_repo, last_operator_handoff_bundle_path),
        "operator_handoff_bundle_validation_ref": normalize_repo_path(
            planningops_repo, last_operator_handoff_bundle_validation_path
        ),
        "operator_handoff_bundle_readiness_ref": normalize_repo_path(
            planningops_repo, last_operator_handoff_bundle_readiness_path
        ),
        "operator_handoff_bundle_readiness_validation_ref": normalize_repo_path(
            planningops_repo, last_operator_handoff_bundle_readiness_validation_path
        ),
        "goal_completion_delivery_report_ref": str(goal_completion_delivery.get("output_path") or "-"),
        "reflection_decision": str(action.get("reflection_decision") or ""),
        "action_kind": str(action.get("action_kind") or ""),
        "message_class_hint": str(action.get("message_class_hint") or ""),
        "goal_completion_delivery_enabled": delivery_enabled,
        "goal_completion_delivery_verdict": delivery_verdict,
        "queue_admission_verdict": queue_admission_verdict,
        "selected_delivery_entrypoint": goal_completion_delivery.get("selected_delivery_entrypoint"),
        "scheduled_delivery_work_item_ref": goal_completion_delivery.get("scheduled_delivery_work_item_ref"),
        "scheduled_queue_item_ref": goal_completion_delivery.get("scheduled_queue_item_ref"),
        "scheduled_queue_item_id": goal_completion_delivery.get("scheduled_queue_item_id"),
        "delivery_idempotency_key": goal_completion_delivery.get("delivery_idempotency_key"),
        "runner_contract_ref": RUNNER_CONTRACT_REF,
        "error_count": 0,
        "errors": [],
        "verdict": "pass",
    }
    if delivery_enabled and goal_completion_delivery.get("verdict") != "pass":
        payload["verdict"] = "fail"
        payload["error_count"] = len(goal_completion_delivery.get("errors") or [])
        payload["errors"] = list(goal_completion_delivery.get("errors") or ["goal completion delivery failed"])
    save_json(report_output, payload)
    print(f"report written: {report_output}")
    print(f"verdict={payload['verdict']} delivery_verdict={delivery_verdict}")
    return 0 if payload["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
