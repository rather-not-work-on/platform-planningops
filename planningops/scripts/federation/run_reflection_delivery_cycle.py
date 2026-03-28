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

from federated_python_env import (
    build_bootstrap_plan,
    build_managed_env,
    ensure_bootstrap_environment,
    resolve_bootstrap_root,
)
from reflection_cycle_common import (
    build_stage_report,
    load_json,
    normalize_monday_runtime_ref,
    normalize_repo_path,
    normalize_workspace_path,
    now_utc,
    parse_json_doc,
    resolve_component_repo,
    resolve_input_path,
    resolve_output_path,
    resolve_repo_root,
    resolve_workspace_root,
    run_cmd,
    write_report,
)


RUNNER_CONTRACT_REF = "planningops/contracts/reflection-delivery-cycle-contract.md"
ACTION_CONTRACT_REF = "planningops/contracts/reflection-action-handoff-contract.md"
MONDAY_DELIVERY_ENTRYPOINT = "monday/scripts/enqueue_scheduled_delivery_work_item.py"
DEFAULT_SCHEDULE_KEY = "recurring-delivery"

REQUIRED_ACTION_FIELDS = [
    "active_goal_key",
    "queue_item_id",
    "worker_run_id",
    "reflection_decision",
    "action_kind",
    "message_class_hint",
    "goal_transition_report_path",
    "handoff_contract_ref",
    "verdict",
]
def parse_args():
    parser = argparse.ArgumentParser(description="Run the planningops -> monday reflection delivery cycle")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--monday-repo-dir", default="monday", help="monday repo directory relative to workspace root")
    parser.add_argument("--monday-python", default=None, help="Optional Python interpreter override for monday leaf scripts")
    parser.add_argument(
        "--monday-profiles-config",
        default=None,
        help="Optional monday local operator profile config override passed through to monday delivery CLIs",
    )
    parser.add_argument(
        "--monday-delivery-script",
        default="scripts/enqueue_scheduled_delivery_work_item.py",
        help="monday scheduled delivery queue admission script path relative to the monday repo",
    )
    parser.add_argument(
        "--monday-queue-db",
        default=None,
        help="Optional monday queue-db override passed through to monday queue admission",
    )
    parser.add_argument("--action-file", required=True, help="Reflection action artifact path")
    parser.add_argument("--delivery-target", default=None)
    parser.add_argument("--channel-kind", default=None)
    parser.add_argument("--thread-ref", default=None)
    parser.add_argument("--schedule-key", default=DEFAULT_SCHEDULE_KEY)
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--run-id",
        default=f"reflection-delivery-cycle-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument("--delivery-output", default=None)
    parser.add_argument("--output", default=None, help="Aggregate cycle report output path")
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


def base_report_fields(action_ref: str, action: dict | None) -> dict:
    action = action or {}
    return {
        "mode": None,
        "goal_key": str(action.get("active_goal_key") or "-"),
        "reflection_action_ref": action_ref,
        "reflection_decision": action.get("reflection_decision"),
        "action_kind": action.get("action_kind"),
        "message_class_hint": action.get("message_class_hint"),
        "delivery_required": action.get("delivery_required"),
        "delivery_skipped": None,
        "monday_delivery_entrypoint": "-",
        "monday_delivery_report_ref": "-",
        "delivery_verdict": "-",
        "queue_admission_verdict": "-",
        "selected_delivery_entrypoint": "-",
        "scheduled_delivery_work_item_ref": "-",
        "scheduled_queue_item_ref": "-",
        "scheduled_queue_item_id": "-",
        "delivery_idempotency_key": "-",
        "delivery_target_resolution_mode": "-",
        "delivery_target_profile_ref": "-",
        "delivery_transport_kind": "-",
        "delivery_outbox_message_ref": "-",
        "goal_transition_report_path": str(action.get("goal_transition_report_path") or "-"),
        "runner_contract_ref": RUNNER_CONTRACT_REF,
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


def resolve_monday_output(raw_path: str | None, run_id: str, monday_repo: Path) -> tuple[str, Path]:
    default_rel = Path("runtime-artifacts") / "scheduler-queue" / "admission-reports" / f"reflection-delivery-cycle-{run_id}.json"
    if raw_path is None:
        return str(default_rel), (monday_repo / default_rel).resolve()
    output_path = Path(raw_path)
    if output_path.is_absolute():
        return str(output_path), output_path.resolve()
    return str(output_path), (monday_repo / output_path).resolve()


def failure_report(
    *,
    args,
    action_ref: str,
    action: dict | None,
    stage_reports: list[dict],
    failure_stage: str,
    errors: list[str],
    report_path: Path,
    monday_delivery_report_ref: str = "-",
    delivery_verdict: str = "-",
    delivery_target_resolution_mode: str = "-",
    delivery_target_profile_ref: str = "-",
    delivery_transport_kind: str = "-",
    delivery_outbox_message_ref: str = "-",
    queue_admission_verdict: str = "-",
    selected_delivery_entrypoint: str = "-",
    scheduled_delivery_work_item_ref: str = "-",
    scheduled_queue_item_ref: str = "-",
    scheduled_queue_item_id: str = "-",
    delivery_idempotency_key: str = "-",
) -> int:
    payload = {
        "generated_at_utc": now_utc(),
        **base_report_fields(action_ref, action),
        "mode": args.mode,
        "delivery_skipped": False,
        "monday_delivery_report_ref": monday_delivery_report_ref,
        "delivery_verdict": delivery_verdict,
        "queue_admission_verdict": queue_admission_verdict,
        "selected_delivery_entrypoint": selected_delivery_entrypoint,
        "scheduled_delivery_work_item_ref": scheduled_delivery_work_item_ref,
        "scheduled_queue_item_ref": scheduled_queue_item_ref,
        "scheduled_queue_item_id": scheduled_queue_item_id,
        "delivery_idempotency_key": delivery_idempotency_key,
        "delivery_target_resolution_mode": delivery_target_resolution_mode,
        "delivery_target_profile_ref": delivery_target_profile_ref,
        "delivery_transport_kind": delivery_transport_kind,
        "delivery_outbox_message_ref": delivery_outbox_message_ref,
        "stage_reports": stage_reports,
        "failure_stage": failure_stage,
        "error_count": len(errors),
        "errors": errors,
        "verdict": "fail",
    }
    write_report(report_path, payload)
    print(f"report written: {report_path}")
    print(f"verdict=fail failure_stage={failure_stage}")
    return 1


def validate_action(action: dict) -> list[str]:
    errors: list[str] = []
    if not isinstance(action, dict):
        return ["action artifact must be a JSON object"]
    for field in REQUIRED_ACTION_FIELDS:
        if field not in action:
            errors.append(f"missing action field: {field}")
    if action.get("handoff_contract_ref") != ACTION_CONTRACT_REF:
        errors.append("handoff_contract_ref does not match reflection action handoff contract")
    if action.get("verdict") != "pass":
        errors.append("action artifact verdict must be pass")
    if not isinstance(action.get("delivery_required"), bool):
        errors.append("delivery_required must be boolean")
    return errors


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

    env = build_managed_env(bootstrap_info)
    python_bin = args.monday_python or bootstrap_info["preferred_python"]

    report_dir = planningops_repo / "planningops" / "artifacts" / "validation" / "reflection-delivery-cycle" / args.run_id
    report_output = resolve_output_path(planningops_repo, args.output, report_dir / "cycle-report.json")

    stage_reports: list[dict] = []

    try:
        action_path = resolve_input_path(planningops_repo, workspace_root, monday_repo, args.action_file)
    except FileNotFoundError as exc:
        return failure_report(
            args=args,
            action_ref=args.action_file,
            action=None,
            stage_reports=stage_reports,
            failure_stage="load_action",
            errors=[str(exc)],
            report_path=report_output,
        )

    action_ref = normalize_repo_path(planningops_repo, action_path)
    action = load_json(action_path)
    action_errors = validate_action(action)
    if action_errors:
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="validate_action",
            errors=action_errors,
            report_path=report_output,
        )

    if action.get("message_class_hint") == "goal_completed":
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="validate_queue_admission_handoff",
            errors=["goal_completed reflection actions must flow through the supervisor goal-completion handoff"],
            report_path=report_output,
        )

    if not action["delivery_required"]:
        payload = {
            "generated_at_utc": now_utc(),
            **base_report_fields(action_ref, action),
            "mode": args.mode,
            "delivery_skipped": True,
            "delivery_verdict": "skipped",
            "stage_reports": [],
            "error_count": 0,
            "errors": [],
            "verdict": "pass",
        }
        write_report(report_output, payload)
        print(f"report written: {report_output}")
        print("verdict=pass delivery_skipped=true")
        return 0

    monday_script = monday_repo / args.monday_delivery_script
    if not monday_script.exists():
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="resolve_monday_entrypoint",
            errors=[f"monday delivery script not found: {args.monday_delivery_script}"],
            report_path=report_output,
        )

    monday_output_arg, monday_output_path = resolve_monday_output(args.delivery_output, args.run_id, monday_repo)

    command = [
        python_bin,
        args.monday_delivery_script,
        "--reflection-action-file",
        str(action_path),
        "--schedule-key",
        args.schedule_key,
        "--mode",
        args.mode,
        "--output",
        monday_output_arg,
    ]
    if args.delivery_target:
        command.extend(["--delivery-target", args.delivery_target])
    if args.channel_kind:
        command.extend(["--channel-kind", args.channel_kind])
    if args.thread_ref:
        command.extend(["--thread-ref", args.thread_ref])
    if args.monday_profiles_config:
        command.extend(["--profiles-config", args.monday_profiles_config])
    if args.monday_queue_db:
        command.extend(["--queue-db", args.monday_queue_db])

    rc, out, err = run_cmd(command, monday_repo, env)
    parsed_stdout_report = parse_json_doc(out)
    delivery_output = monday_output_path
    if not delivery_output.exists() and parsed_stdout_report:
        reported_ref = str(parsed_stdout_report.get("report_ref") or "").strip()
        if reported_ref:
            delivery_output = (monday_repo / reported_ref).resolve()
    stage_reports.append(build_stage_report("queue_admission", command, monday_repo, rc, out, err, delivery_output))

    delivery_report_ref = normalize_workspace_path(workspace_root, delivery_output)
    if not delivery_output.exists():
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="queue_admission",
            errors=["monday queue admission report missing"],
            report_path=report_output,
            monday_delivery_report_ref=delivery_report_ref,
        )

    delivery_report = load_json(delivery_output)
    delivery_summary = extract_queue_admission_summary(delivery_report, workspace_root, monday_repo)
    errors = list(delivery_report.get("errors") or [])
    if rc != 0:
        errors = errors or ["monday queue admission returned non-zero"]
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="queue_admission",
            errors=errors,
            report_path=report_output,
            monday_delivery_report_ref=delivery_report_ref,
            **delivery_summary,
        )
    if delivery_report.get("verdict") != "pass":
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="queue_admission",
            errors=errors or ["monday queue admission report verdict must be pass"],
            report_path=report_output,
            monday_delivery_report_ref=delivery_report_ref,
            **delivery_summary,
        )

    payload = {
        "generated_at_utc": now_utc(),
        **base_report_fields(action_ref, action),
        "mode": args.mode,
        "delivery_skipped": False,
        "monday_delivery_entrypoint": MONDAY_DELIVERY_ENTRYPOINT,
        "monday_delivery_report_ref": delivery_report_ref,
        **delivery_summary,
        "stage_reports": stage_reports,
        "error_count": 0,
        "errors": [],
        "verdict": "pass",
    }
    write_report(report_output, payload)
    print(f"report written: {report_output}")
    print(f"verdict=pass delivery_verdict={delivery_summary['delivery_verdict']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
