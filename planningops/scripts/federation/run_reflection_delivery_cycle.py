#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
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


RUNNER_CONTRACT_REF = "planningops/contracts/reflection-delivery-cycle-contract.md"
ACTION_CONTRACT_REF = "planningops/contracts/reflection-action-handoff-contract.md"
MONDAY_DELIVERY_ENTRYPOINT = "monday/scripts/send_reflection_decision_update.py"

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


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[4]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    candidates = [
        (planningops_repo / raw_workspace_root).resolve(),
        planningops_repo,
        planningops_repo.parent,
    ]
    for candidate in candidates:
        if (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def resolve_component_repo(workspace_root: Path, repo_dir: str) -> Path:
    path = Path(repo_dir)
    if path.is_absolute():
        return path
    return (workspace_root / path).resolve()


def resolve_input_path(planningops_repo: Path, workspace_root: Path, monday_repo: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    candidates: list[Path] = []
    if path.is_absolute():
        candidates.append(path)
    else:
        candidates.extend(
            [
                (planningops_repo / path).resolve(),
                (workspace_root / path).resolve(),
                (monday_repo / path).resolve(),
                path.resolve(),
            ]
        )
    for candidate in candidates:
        if candidate.exists():
            return candidate
    raise FileNotFoundError(f"reflection action input not found: {raw_path}")


def resolve_output_path(planningops_repo: Path, raw_path: str | None, default_path: Path) -> Path:
    if raw_path is None:
        return default_path
    path = Path(raw_path)
    if path.is_absolute():
        return path
    return (planningops_repo / path).resolve()


def normalize_repo_path(repo_root: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(repo_root.resolve()))
    except ValueError:
        return str(path.resolve())


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_report(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def run_cmd(command: list[str], cwd: Path, env: dict[str, str]) -> tuple[int, str, str]:
    completed = subprocess.run(command, cwd=str(cwd), capture_output=True, text=True, env=env)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def build_stage_report(stage: str, command: list[str], cwd: Path, rc: int, out: str, err: str, artifact_path: Path) -> dict:
    return {
        "stage": stage,
        "command": command,
        "cwd": str(cwd),
        "exit_code": rc,
        "stdout_tail": out[-1000:],
        "stderr_tail": err[-1000:],
        "artifact_path": str(artifact_path),
        "artifact_exists": artifact_path.exists(),
        "verdict": "pass" if rc == 0 else "fail",
    }


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
        default="scripts/send_reflection_decision_update.py",
        help="monday delivery script path relative to the monday repo",
    )
    parser.add_argument("--action-file", required=True, help="Reflection action artifact path")
    parser.add_argument("--delivery-target", default=None)
    parser.add_argument("--channel-kind", default=None)
    parser.add_argument("--thread-ref", default=None)
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
        "delivery_target_resolution_mode": "-",
        "delivery_target_profile_ref": "-",
        "delivery_transport_kind": "-",
        "delivery_outbox_message_ref": "-",
        "goal_transition_report_path": str(action.get("goal_transition_report_path") or "-"),
        "runner_contract_ref": RUNNER_CONTRACT_REF,
    }


def extract_delivery_summary(delivery_report: dict) -> dict:
    delegate_report = delivery_report.get("delegate_report") or {}
    nested_report = (delegate_report.get("delivery_report") or delivery_report.get("delivery_report") or {})
    outbox_message_ref = (
        delegate_report.get("outbox_message_ref")
        or delivery_report.get("outbox_message_ref")
        or nested_report.get("outboxMessageRef")
        or "-"
    )
    return {
        "delivery_verdict": str(nested_report.get("deliveryVerdict") or "-"),
        "delivery_target_resolution_mode": str(nested_report.get("targetResolutionMode") or "-"),
        "delivery_target_profile_ref": str(nested_report.get("targetProfileRef") or "-"),
        "delivery_transport_kind": str(nested_report.get("transportKind") or "-"),
        "delivery_outbox_message_ref": str(outbox_message_ref or "-"),
    }


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
) -> int:
    payload = {
        "generated_at_utc": now_utc(),
        **base_report_fields(action_ref, action),
        "mode": args.mode,
        "delivery_skipped": False,
        "monday_delivery_report_ref": monday_delivery_report_ref,
        "delivery_verdict": delivery_verdict,
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
    delivery_output = resolve_output_path(planningops_repo, args.delivery_output, report_dir / "delivery-report.json")
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

    command = [
        python_bin,
        args.monday_delivery_script,
        "--action-file",
        str(action_path),
        "--mode",
        args.mode,
        "--output",
        str(delivery_output),
    ]
    if args.delivery_target:
        command.extend(["--delivery-target", args.delivery_target])
    if args.channel_kind:
        command.extend(["--channel-kind", args.channel_kind])
    if args.thread_ref:
        command.extend(["--thread-ref", args.thread_ref])
    if args.monday_profiles_config:
        command.extend(["--profiles-config", args.monday_profiles_config])

    rc, out, err = run_cmd(command, monday_repo, env)
    stage_reports.append(build_stage_report("delivery_execution", command, monday_repo, rc, out, err, delivery_output))

    delivery_report_ref = normalize_repo_path(planningops_repo, delivery_output)
    if not delivery_output.exists():
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="delivery_execution",
            errors=["monday delivery report missing"],
            report_path=report_output,
            monday_delivery_report_ref=delivery_report_ref,
        )

    delivery_report = load_json(delivery_output)
    delivery_summary = extract_delivery_summary(delivery_report)
    errors = list(delivery_report.get("errors") or [])
    if rc != 0:
        errors = errors or ["monday delivery entrypoint returned non-zero"]
        return failure_report(
            args=args,
            action_ref=action_ref,
            action=action,
            stage_reports=stage_reports,
            failure_stage="delivery_execution",
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
            failure_stage="delivery_execution",
            errors=errors or ["monday delivery report verdict must be pass"],
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
