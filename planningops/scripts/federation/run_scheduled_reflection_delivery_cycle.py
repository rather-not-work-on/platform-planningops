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

from federated_python_env import (  # noqa: E402
    build_bootstrap_plan,
    build_managed_env,
    ensure_bootstrap_environment,
    resolve_bootstrap_root,
)


RUNNER_CONTRACT_REF = "planningops/contracts/scheduled-reflection-delivery-cycle-contract.md"
MONDAY_SCHEDULED_ENTRYPOINT = "monday/scripts/run_scheduled_queue_cycle.py"
REFLECTION_RUNNER = "planningops/scripts/federation/run_worker_outcome_reflection_cycle.py"
DELIVERY_RUNNER = "planningops/scripts/federation/run_reflection_delivery_cycle.py"


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
    raise FileNotFoundError(f"input not found: {raw_path}")


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


def normalize_cross_repo_path(planningops_repo: Path, monday_repo: Path, path: Path) -> str:
    try:
        return str(path.resolve().relative_to(planningops_repo.resolve()))
    except ValueError:
        try:
            return str(path.resolve().relative_to(monday_repo.resolve()))
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
    parser = argparse.ArgumentParser(
        description="Run the monday scheduled queue cycle through planningops reflection and delivery orchestration"
    )
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--monday-repo-dir", default="monday", help="monday repo directory relative to workspace root")
    parser.add_argument("--monday-python", default=None, help="Optional Python interpreter override for monday leaf scripts")
    parser.add_argument(
        "--monday-scheduled-script",
        default="scripts/run_scheduled_queue_cycle.py",
        help="monday scheduled queue script path relative to the monday repo",
    )
    parser.add_argument("--queue", required=True, help="Queue seed file for the monday scheduled queue cycle")
    parser.add_argument("--worker-outcome-json", required=True, help="Worker outcome artifact to feed into reflection")
    parser.add_argument("--queue-db", default=None)
    parser.add_argument("--idempotency", default=None)
    parser.add_argument("--transition-log", default=None)
    parser.add_argument("--goal-key", default=None)
    parser.add_argument("--delivery-target", default=None)
    parser.add_argument("--channel-kind", default=None)
    parser.add_argument("--thread-ref", default=None)
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--run-id",
        default=f"scheduled-reflection-delivery-cycle-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument("--scheduled-output", default=None)
    parser.add_argument("--packet-output", default=None)
    parser.add_argument("--evaluation-output", default=None)
    parser.add_argument("--action-output", default=None)
    parser.add_argument("--goal-transition-output", default=None)
    parser.add_argument("--reflection-output", default=None)
    parser.add_argument("--delivery-output", default=None)
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


def failure_report(
    *,
    args,
    goal_key: str,
    scheduled_cycle_report_ref: str,
    worker_outcome_ref: str,
    reflection_cycle_report_ref: str,
    reflection_action_ref: str,
    delivery_cycle_report_ref: str,
    stage_reports: list[dict],
    failure_stage: str,
    errors: list[str],
    report_path: Path,
) -> int:
    payload = {
        "generated_at_utc": now_utc(),
        "mode": args.mode,
        "goal_key": goal_key,
        "scheduled_cycle_report_ref": scheduled_cycle_report_ref,
        "worker_outcome_ref": worker_outcome_ref,
        "reflection_cycle_report_ref": reflection_cycle_report_ref,
        "reflection_action_ref": reflection_action_ref,
        "delivery_cycle_report_ref": delivery_cycle_report_ref,
        "reflection_decision": None,
        "action_kind": None,
        "delivery_required": None,
        "delivery_skipped": None,
        "goal_transition_required": None,
        "goal_transition_report_path": "-",
        "runner_contract_ref": RUNNER_CONTRACT_REF,
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

    queue_path = resolve_input_path(planningops_repo, workspace_root, monday_repo, args.queue)
    worker_outcome_path = resolve_input_path(planningops_repo, workspace_root, monday_repo, args.worker_outcome_json)

    report_dir = (
        planningops_repo / "planningops" / "artifacts" / "validation" / "scheduled-reflection-delivery-cycle" / args.run_id
    )
    scheduled_output = resolve_output_path(planningops_repo, args.scheduled_output, report_dir / "scheduled-cycle-report.json")
    packet_output = resolve_output_path(planningops_repo, args.packet_output, report_dir / "reflection-packet.json")
    evaluation_output = resolve_output_path(
        planningops_repo, args.evaluation_output, report_dir / "reflection-evaluation.json"
    )
    action_output = resolve_output_path(planningops_repo, args.action_output, report_dir / "reflection-action.json")
    reflection_output = resolve_output_path(
        planningops_repo, args.reflection_output, report_dir / "reflection-cycle-report.json"
    )
    delivery_output = resolve_output_path(planningops_repo, args.delivery_output, report_dir / "delivery-cycle-report.json")
    report_output = resolve_output_path(planningops_repo, args.output, report_dir / "cycle-report.json")
    idempotency_path = resolve_output_path(planningops_repo, args.idempotency, report_dir / "scheduled-idempotency.json")
    transition_log_path = resolve_output_path(
        planningops_repo, args.transition_log, report_dir / "scheduled-transition-log.ndjson"
    )
    goal_transition_output = resolve_output_path(
        planningops_repo, args.goal_transition_output, report_dir / "goal-transition-report.json"
    )

    stage_reports: list[dict] = []
    worker_outcome_ref = normalize_cross_repo_path(planningops_repo, monday_repo, worker_outcome_path)
    scheduled_report_ref = normalize_repo_path(planningops_repo, scheduled_output)
    reflection_report_ref = normalize_repo_path(planningops_repo, reflection_output)
    delivery_report_ref = normalize_repo_path(planningops_repo, delivery_output)
    action_ref = normalize_repo_path(planningops_repo, action_output)
    goal_key = args.goal_key or "-"

    monday_script = monday_repo / args.monday_scheduled_script
    if not monday_script.exists():
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="resolve_monday_scheduled_entrypoint",
            errors=[f"monday scheduled script not found: {args.monday_scheduled_script}"],
            report_path=report_output,
        )

    scheduled_command = [
        python_bin,
        args.monday_scheduled_script,
        "--queue",
        str(queue_path),
        "--run-id",
        f"{args.run_id}-scheduled",
        "--idempotency",
        str(idempotency_path),
        "--report",
        str(scheduled_output),
        "--transition-log",
        str(transition_log_path),
    ]
    if args.queue_db:
        scheduled_command.extend(["--queue-db", str(resolve_output_path(planningops_repo, args.queue_db, Path(args.queue_db)))])

    rc, out, err = run_cmd(scheduled_command, monday_repo, env)
    stage_reports.append(build_stage_report("scheduled_queue_cycle", scheduled_command, monday_repo, rc, out, err, scheduled_output))
    if rc != 0:
        errors = ["scheduled_queue_cycle_failed"]
        if scheduled_output.exists():
            errors.extend(load_json(scheduled_output).get("errors") or [])
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="scheduled_queue_cycle",
            errors=errors,
            report_path=report_output,
        )

    if not scheduled_output.exists():
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="scheduled_queue_cycle",
            errors=["scheduled cycle report missing"],
            report_path=report_output,
        )

    scheduled_report = load_json(scheduled_output)
    if scheduled_report.get("verdict") != "pass":
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="scheduled_queue_cycle",
            errors=["scheduled cycle report verdict must be pass"],
            report_path=report_output,
        )

    dequeued = list(scheduled_report.get("dequeued") or [])
    if len(dequeued) != 1:
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="scheduled_queue_cycle",
            errors=[f"expected exactly one dequeued queue item, got {len(dequeued)}"],
            report_path=report_output,
        )

    worker_outcome = load_json(worker_outcome_path)
    expected_queue_item_id = str(dequeued[0].get("card_id") or "")
    actual_queue_item_id = str(worker_outcome.get("queue_item_id") or "")
    if not expected_queue_item_id or actual_queue_item_id != expected_queue_item_id:
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="load_worker_outcome",
            errors=[
                "worker outcome queue_item_id must match the scheduled dequeued queue item",
                f"expected={expected_queue_item_id or '-'} actual={actual_queue_item_id or '-'}",
            ],
            report_path=report_output,
        )

    goal_key = args.goal_key or str(worker_outcome.get("goal_key") or goal_key)

    reflection_command = [
        bootstrap_info["preferred_python"],
        str(planningops_repo / "planningops" / "scripts" / "federation" / "run_worker_outcome_reflection_cycle.py"),
        "--workspace-root",
        str(workspace_root),
        "--monday-repo-dir",
        str(monday_repo),
        "--outcome-json",
        str(worker_outcome_path),
        "--source-outcome-ref",
        worker_outcome_ref,
        "--mode",
        args.mode,
        "--run-id",
        f"{args.run_id}-reflection",
        "--packet-output",
        str(packet_output),
        "--evaluation-output",
        str(evaluation_output),
        "--action-output",
        str(action_output),
        "--goal-transition-output",
        str(goal_transition_output),
        "--output",
        str(reflection_output),
    ]
    if args.goal_key:
        reflection_command.extend(["--goal-key", args.goal_key])

    rc, out, err = run_cmd(reflection_command, planningops_repo, env)
    stage_reports.append(build_stage_report("reflection_cycle", reflection_command, planningops_repo, rc, out, err, reflection_output))
    if rc != 0:
        errors = ["reflection_cycle_failed"]
        if reflection_output.exists():
            errors.extend(load_json(reflection_output).get("errors") or [])
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="reflection_cycle",
            errors=errors,
            report_path=report_output,
        )

    reflection_report = load_json(reflection_output)
    action_ref = str(reflection_report.get("reflection_action_ref") or action_ref)

    delivery_command = [
        bootstrap_info["preferred_python"],
        str(planningops_repo / "planningops" / "scripts" / "federation" / "run_reflection_delivery_cycle.py"),
        "--workspace-root",
        str(workspace_root),
        "--monday-repo-dir",
        str(monday_repo),
        "--action-file",
        str(action_output),
        "--mode",
        args.mode,
        "--run-id",
        f"{args.run_id}-delivery",
        "--output",
        str(delivery_output),
    ]
    if args.delivery_target:
        delivery_command.extend(["--delivery-target", args.delivery_target])
    if args.channel_kind:
        delivery_command.extend(["--channel-kind", args.channel_kind])
    if args.thread_ref:
        delivery_command.extend(["--thread-ref", args.thread_ref])

    rc, out, err = run_cmd(delivery_command, planningops_repo, env)
    stage_reports.append(build_stage_report("delivery_cycle", delivery_command, planningops_repo, rc, out, err, delivery_output))
    if rc != 0:
        errors = ["delivery_cycle_failed"]
        if delivery_output.exists():
            errors.extend(load_json(delivery_output).get("errors") or [])
        return failure_report(
            args=args,
            goal_key=goal_key,
            scheduled_cycle_report_ref=scheduled_report_ref,
            worker_outcome_ref=worker_outcome_ref,
            reflection_cycle_report_ref=reflection_report_ref,
            reflection_action_ref=action_ref,
            delivery_cycle_report_ref=delivery_report_ref,
            stage_reports=stage_reports,
            failure_stage="delivery_cycle",
            errors=errors,
            report_path=report_output,
        )

    delivery_report = load_json(delivery_output)
    payload = {
        "generated_at_utc": now_utc(),
        "mode": args.mode,
        "goal_key": reflection_report.get("goal_key") or goal_key,
        "scheduled_cycle_report_ref": scheduled_report_ref,
        "worker_outcome_ref": worker_outcome_ref,
        "reflection_cycle_report_ref": reflection_report_ref,
        "reflection_action_ref": reflection_report.get("reflection_action_ref") or action_ref,
        "delivery_cycle_report_ref": delivery_report_ref,
        "reflection_decision": reflection_report.get("reflection_decision"),
        "action_kind": reflection_report.get("action_kind"),
        "delivery_required": delivery_report.get("delivery_required"),
        "delivery_skipped": delivery_report.get("delivery_skipped"),
        "goal_transition_required": reflection_report.get("goal_transition_required"),
        "goal_transition_report_path": delivery_report.get("goal_transition_report_path")
        or reflection_report.get("goal_transition_report_path")
        or "-",
        "runner_contract_ref": RUNNER_CONTRACT_REF,
        "stage_reports": stage_reports,
        "error_count": 0,
        "errors": [],
        "verdict": "pass",
    }
    write_report(report_output, payload)
    print(f"report written: {report_output}")
    print(f"verdict=pass reflection_decision={payload['reflection_decision']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
