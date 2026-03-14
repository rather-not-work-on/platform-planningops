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


RUNNER_CONTRACT_REF = "planningops/contracts/reflection-cycle-orchestration-contract.md"


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
    raise FileNotFoundError(f"worker outcome input not found: {raw_path}")


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


def run_cmd(command: list[str], cwd: Path, env: dict[str, str]) -> tuple[int, str, str]:
    completed = subprocess.run(command, cwd=str(cwd), capture_output=True, text=True, env=env)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def write_report(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def parse_args():
    parser = argparse.ArgumentParser(description="Run the monday -> planningops worker outcome reflection cycle")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--monday-repo-dir", default="monday", help="monday repo directory relative to workspace root")
    parser.add_argument("--monday-python", default=None, help="Optional Python interpreter override for monday leaf scripts")
    parser.add_argument(
        "--monday-exporter-script",
        default="scripts/export_worker_outcome_reflection_packet.py",
        help="monday exporter script path relative to the monday repo",
    )
    parser.add_argument("--outcome-json", required=True, help="Worker outcome artifact path")
    parser.add_argument("--source-outcome-ref", default=None, help="Explicit source outcome reference to preserve in packet output")
    parser.add_argument("--active-goal-registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--goal-key", default=None)
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--run-id",
        default=f"worker-outcome-reflection-cycle-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument("--packet-output", default=None)
    parser.add_argument("--evaluation-output", default=None)
    parser.add_argument("--action-output", default=None)
    parser.add_argument("--goal-transition-output", default=None)
    parser.add_argument("--output", default=None, help="Cycle report output path")
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


def failure_report(
    *,
    args,
    goal_key: str,
    outcome_ref: str,
    packet_ref: str,
    evaluation_ref: str,
    action_ref: str,
    stage_reports: list[dict],
    failure_stage: str,
    errors: list[str],
    report_path: Path,
) -> int:
    payload = {
        "generated_at_utc": now_utc(),
        "mode": args.mode,
        "goal_key": goal_key,
        "source_outcome_ref": outcome_ref,
        "reflection_packet_ref": packet_ref,
        "reflection_evaluation_ref": evaluation_ref,
        "reflection_action_ref": action_ref,
        "reflection_decision": None,
        "action_kind": None,
        "delivery_required": None,
        "goal_transition_required": None,
        "goal_transition_report_path": "-",
        "runner_contract_ref": RUNNER_CONTRACT_REF,
        "failure_stage": failure_stage,
        "error_count": len(errors),
        "errors": errors,
        "stage_reports": stage_reports,
        "verdict": "fail",
    }
    write_report(report_path, payload)
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

    env = build_managed_env(bootstrap_info)
    python_bin = args.monday_python or bootstrap_info["preferred_python"]
    if not args.monday_python:
        python_bin = bootstrap_info["preferred_python"]

    outcome_path = resolve_input_path(planningops_repo, workspace_root, monday_repo, args.outcome_json)
    report_dir = planningops_repo / "planningops" / "artifacts" / "validation" / "worker-outcome-reflection-cycle" / args.run_id
    packet_output = resolve_output_path(planningops_repo, args.packet_output, report_dir / "packet.json")
    evaluation_output = resolve_output_path(planningops_repo, args.evaluation_output, report_dir / "evaluation.json")
    action_output = resolve_output_path(planningops_repo, args.action_output, report_dir / "action.json")
    report_output = resolve_output_path(planningops_repo, args.output, report_dir / "cycle-report.json")

    source_outcome_ref = args.source_outcome_ref or normalize_repo_path(monday_repo, outcome_path)
    goal_key = args.goal_key or "-"

    stage_reports: list[dict] = []

    exporter_command = [
        python_bin,
        args.monday_exporter_script,
        "--outcome-json",
        str(outcome_path),
        "--source-outcome-ref",
        source_outcome_ref,
        "--output",
        str(packet_output),
    ]
    rc, out, err = run_cmd(exporter_command, monday_repo, env)
    stage_reports.append(build_stage_report("packet_export", exporter_command, monday_repo, rc, out, err, packet_output))
    if rc != 0:
        return failure_report(
            args=args,
            goal_key=goal_key,
            outcome_ref=source_outcome_ref,
            packet_ref=normalize_repo_path(planningops_repo, packet_output),
            evaluation_ref=normalize_repo_path(planningops_repo, evaluation_output),
            action_ref=normalize_repo_path(planningops_repo, action_output),
            stage_reports=stage_reports,
            failure_stage="packet_export",
            errors=["packet_export_failed"],
            report_path=report_output,
        )

    evaluator_command = [
        bootstrap_info["preferred_python"],
        str(planningops_repo / "planningops" / "scripts" / "core" / "goals" / "evaluate_worker_outcome_reflection.py"),
        "--packet-json",
        str(packet_output),
        "--active-goal-registry",
        args.active_goal_registry,
        "--output",
        str(evaluation_output),
    ]
    if args.goal_key:
        evaluator_command.extend(["--goal-key", args.goal_key])
    rc, out, err = run_cmd(evaluator_command, planningops_repo, env)
    stage_reports.append(
        build_stage_report("reflection_evaluation", evaluator_command, planningops_repo, rc, out, err, evaluation_output)
    )
    if rc != 0:
        errors = ["reflection_evaluation_failed"]
        if evaluation_output.exists():
            errors.extend(load_json(evaluation_output).get("errors") or [])
        return failure_report(
            args=args,
            goal_key=goal_key,
            outcome_ref=source_outcome_ref,
            packet_ref=normalize_repo_path(planningops_repo, packet_output),
            evaluation_ref=normalize_repo_path(planningops_repo, evaluation_output),
            action_ref=normalize_repo_path(planningops_repo, action_output),
            stage_reports=stage_reports,
            failure_stage="reflection_evaluation",
            errors=errors,
            report_path=report_output,
        )

    applier_command = [
        bootstrap_info["preferred_python"],
        str(planningops_repo / "planningops" / "scripts" / "core" / "goals" / "apply_worker_outcome_reflection.py"),
        "--evaluation-json",
        str(evaluation_output),
        "--active-goal-registry",
        args.active_goal_registry,
        "--mode",
        args.mode,
        "--output",
        str(action_output),
    ]
    if args.goal_key:
        applier_command.extend(["--goal-key", args.goal_key])
    if args.goal_transition_output:
        applier_command.extend(["--goal-transition-output", args.goal_transition_output])
    rc, out, err = run_cmd(applier_command, planningops_repo, env)
    stage_reports.append(
        build_stage_report("reflection_action_application", applier_command, planningops_repo, rc, out, err, action_output)
    )
    if rc != 0:
        errors = ["reflection_action_application_failed"]
        if action_output.exists():
            errors.extend(load_json(action_output).get("errors") or [])
        return failure_report(
            args=args,
            goal_key=goal_key,
            outcome_ref=source_outcome_ref,
            packet_ref=normalize_repo_path(planningops_repo, packet_output),
            evaluation_ref=normalize_repo_path(planningops_repo, evaluation_output),
            action_ref=normalize_repo_path(planningops_repo, action_output),
            stage_reports=stage_reports,
            failure_stage="reflection_action_application",
            errors=errors,
            report_path=report_output,
        )

    evaluation = load_json(evaluation_output)
    action = load_json(action_output)
    payload = {
        "generated_at_utc": now_utc(),
        "mode": args.mode,
        "goal_key": action.get("active_goal_key") or evaluation.get("active_goal_key") or goal_key,
        "source_outcome_ref": source_outcome_ref,
        "reflection_packet_ref": normalize_repo_path(planningops_repo, packet_output),
        "reflection_evaluation_ref": normalize_repo_path(planningops_repo, evaluation_output),
        "reflection_action_ref": normalize_repo_path(planningops_repo, action_output),
        "queue_item_id": action.get("queue_item_id") or evaluation.get("queue_item_id"),
        "worker_run_id": action.get("worker_run_id") or evaluation.get("worker_run_id"),
        "reflection_decision": action.get("reflection_decision") or evaluation.get("reflection_decision"),
        "decision_reason": action.get("decision_reason") or evaluation.get("decision_reason"),
        "control_plane_action": action.get("control_plane_action") or evaluation.get("control_plane_action"),
        "action_kind": action.get("action_kind"),
        "delivery_required": action.get("delivery_required"),
        "goal_transition_required": action.get("goal_transition_required"),
        "goal_transition_report_path": action.get("goal_transition_report_path", "-"),
        "operator_channel_role": action.get("operator_channel_role"),
        "operator_channel_kind": action.get("operator_channel_kind"),
        "operator_channel_execution_repo": action.get("operator_channel_execution_repo"),
        "runner_contract_ref": RUNNER_CONTRACT_REF,
        "stage_reports": stage_reports,
        "verdict": "pass",
        "error_count": 0,
        "errors": [],
    }
    write_report(report_output, payload)
    print(f"report written: {report_output}")
    print(f"verdict=pass action_kind={payload['action_kind']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
