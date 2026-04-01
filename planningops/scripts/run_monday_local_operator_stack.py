#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_VALIDATION_ROOT = Path("planningops/artifacts/validation")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return REPO_ROOT


def resolve_workspace_root(repo_root: Path, raw_workspace_root: str) -> Path:
    candidates = [
        Path(raw_workspace_root).resolve(),
        (repo_root / raw_workspace_root).resolve(),
        repo_root.parent,
    ]
    for candidate in candidates:
        if (candidate / "monday").exists():
            return candidate
    return candidates[0]


def resolve_path(base: Path, raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path.resolve()
    return (base / path).resolve()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def run_command(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def build_step_record(
    name: str,
    command: list[str],
    cwd: Path,
    report_path: Path,
    dry_run: bool,
) -> dict:
    record = {
        "name": name,
        "command": command,
        "cwd": str(cwd),
        "report_path": str(report_path),
        "report_exists": False,
        "report_summary": None,
        "status": "planned" if dry_run else "skipped",
        "exit_code": None,
        "stdout_tail": "",
        "stderr_tail": "",
    }
    if dry_run:
        return record

    rc, out, err = run_command(command, cwd)
    record["exit_code"] = rc
    record["stdout_tail"] = out[-1000:]
    record["stderr_tail"] = err[-1000:]
    record["report_exists"] = report_path.exists()
    if report_path.exists():
        record["report_summary"] = load_json(report_path)
    record["status"] = "pass" if rc == 0 else "fail"
    return record


def build_readiness_command(args, repo_root: Path, report_path: Path) -> list[str]:
    readiness_script = resolve_path(repo_root, args.readiness_script)
    return [
        args.planningops_python,
        str(readiness_script),
        "--workspace-root",
        str(args.workspace_root),
        "--planningops-runtime-profile-file",
        args.planningops_runtime_profile_file,
        "--monday-planner-runtime-file",
        args.monday_planner_runtime_file,
        "--probe-endpoints",
        args.probe_endpoints,
        "--codex-bin",
        args.codex_bin,
        "--output",
        str(report_path),
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Run the planningops-owned monday local operator wrapper.")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories.")
    parser.add_argument(
        "--planningops-runtime-profile-file",
        default="planningops/config/runtime-profiles.json",
        help="Path to planningops runtime profile catalog.",
    )
    parser.add_argument(
        "--monday-planner-runtime-file",
        default="monday/config/planner-runtime.json",
        help="Path to monday planner runtime config.",
    )
    parser.add_argument(
        "--execution-mode",
        choices=["stack", "direct", "both"],
        default="stack",
        help="Which operator lane to run after readiness.",
    )
    parser.add_argument(
        "--direct-profile",
        choices=["local_ollama", "local_lmstudio"],
        default="local_ollama",
        help="Direct monday local LLM profile used for direct or both modes.",
    )
    parser.add_argument("--probe-endpoints", choices=["on", "off"], default="on")
    parser.add_argument("--codex-bin", default="codex")
    parser.add_argument("--planningops-python", default="python3")
    parser.add_argument("--monday-python", default="python3")
    parser.add_argument(
        "--readiness-script",
        default="planningops/scripts/assess_monday_local_codex_readiness.py",
        help="Readiness script path.",
    )
    parser.add_argument(
        "--stack-smoke-script",
        default="planningops/scripts/federation/run_local_runtime_stack_smoke.py",
        help="Planningops local stack smoke script path.",
    )
    parser.add_argument(
        "--monday-smoke-script",
        default="scripts/run_local_runtime_smoke.py",
        help="Monday local smoke script path, resolved relative to monday repo when not absolute.",
    )
    parser.add_argument(
        "--run-id",
        default=f"monday-local-operator-stack-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
        help="Aggregate run id.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Render the plan and readiness without executing smoke commands.",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Aggregate output path. Defaults to planningops/runtime-artifacts/local/monday-local-operator-stack/<run-id>.json",
    )
    parser.add_argument(
        "--validation-root",
        default=str(DEFAULT_VALIDATION_ROOT),
        help="Validation artifact root for mirrored latest + stamped operator reports.",
    )
    args = parser.parse_args()

    repo_root = resolve_repo_root()
    workspace_root = resolve_workspace_root(repo_root, args.workspace_root)
    monday_repo = (workspace_root / "monday").resolve()
    stack_smoke_script = resolve_path(repo_root, args.stack_smoke_script)
    monday_smoke_script = resolve_path(monday_repo, args.monday_smoke_script)

    base_dir = repo_root / "planningops" / "runtime-artifacts" / "local" / "monday-local-operator-stack" / args.run_id
    readiness_report_path = base_dir / "readiness.json"
    stack_report_path = base_dir / "stack-smoke.json"
    direct_report_path = base_dir / f"{args.direct_profile}.json"

    readiness_command = build_readiness_command(args, repo_root, readiness_report_path)
    readiness_step = build_step_record(
        name="readiness",
        command=readiness_command,
        cwd=repo_root,
        report_path=readiness_report_path,
        dry_run=False,
    )
    readiness_report = load_json(readiness_report_path) if readiness_report_path.exists() else None
    if readiness_step["status"] == "fail" and readiness_report is not None:
        readiness_step["status"] = "report_only"

    stack_step = {
        "name": "stack_smoke",
        "command": [],
        "cwd": str(repo_root),
        "report_path": str(stack_report_path),
        "report_exists": False,
        "report_summary": None,
        "status": "skipped",
        "exit_code": None,
        "stdout_tail": "",
        "stderr_tail": "",
    }
    direct_step = {
        "name": "direct_smoke",
        "command": [],
        "cwd": str(monday_repo),
        "report_path": str(direct_report_path),
        "report_exists": False,
        "report_summary": None,
        "status": "skipped",
        "exit_code": None,
        "stdout_tail": "",
        "stderr_tail": "",
    }

    recommended_next_steps = list((readiness_report or {}).get("recommended_next_steps") or [])
    reason_code = "monday_local_operator_stack_ok"
    verdict = "pass"

    readiness_status = (readiness_report or {}).get("assessment_status")
    if readiness_step["status"] == "fail" and readiness_report is None:
        verdict = "fail"
        reason_code = "readiness_command_failed"
    elif readiness_status == "blocked":
        verdict = "fail"
        reason_code = "readiness_blocked"
    elif args.execution_mode in {"stack", "both"} and readiness_status != "ready":
        verdict = "fail"
        reason_code = "stack_requires_ready_readiness"
        recommended_next_steps.append("Rerun after the gateway-first local readiness becomes `ready`, or switch to `--execution-mode direct`.")
    else:
        if args.execution_mode in {"stack", "both"}:
            stack_command = [
                args.planningops_python,
                str(stack_smoke_script),
                "--workspace-root",
                str(args.workspace_root),
                "--profile",
                "local",
                "--run-id",
                f"{args.run_id}-stack",
                "--output",
                str(stack_report_path),
            ]
            stack_step = build_step_record(
                name="stack_smoke",
                command=stack_command,
                cwd=repo_root,
                report_path=stack_report_path,
                dry_run=args.dry_run,
            )

        if args.execution_mode in {"direct", "both"}:
            direct_command = [
                args.monday_python,
                str(monday_smoke_script),
                "--profile",
                args.direct_profile,
                "--run-id",
                f"{args.run_id}-{args.direct_profile}",
                "--output",
                str(direct_report_path),
            ]
            direct_step = build_step_record(
                name="direct_smoke",
                command=direct_command,
                cwd=monday_repo,
                report_path=direct_report_path,
                dry_run=args.dry_run,
            )

        executed_steps = [step for step in (stack_step, direct_step) if step["status"] in {"pass", "fail", "planned"}]
        failing_steps = [step["name"] for step in executed_steps if step["status"] == "fail"]
        if failing_steps:
            verdict = "fail"
            reason_code = "operator_stack_execution_failed"
            recommended_next_steps.append(f"Inspect failed steps: {', '.join(failing_steps)}")
        elif args.dry_run:
            verdict = "planned"
            reason_code = "operator_stack_dry_run_only"
        else:
            verdict = "pass"
            reason_code = "monday_local_operator_stack_ok"
            recommended_next_steps.append("Inspect the stamped reports and use the monday direct smoke output as the next handoff evidence.")

    output_path = (
        Path(args.output)
        if args.output
        else repo_root / "planningops" / "runtime-artifacts" / "local" / "monday-local-operator-stack" / f"{args.run_id}.json"
    )
    if not output_path.is_absolute():
        output_path = (repo_root / output_path).resolve()

    validation_root = resolve_path(repo_root, args.validation_root)
    validation_latest_report_path = validation_root / "monday-local-operator-stack-report.json"
    validation_stamped_report_path = validation_root / f"{args.run_id}-monday-local-operator-stack-report.json"

    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "execution_mode": args.execution_mode,
        "direct_profile": args.direct_profile if args.execution_mode in {"direct", "both"} else None,
        "dry_run": args.dry_run,
        "verdict": verdict,
        "reason_code": reason_code,
        "readiness": {
            "status": readiness_status,
            "report_path": str(readiness_report_path),
            "report": readiness_report,
            "step": readiness_step,
        },
        "stack_smoke": stack_step,
        "direct_smoke": direct_step,
        "recommended_next_steps": recommended_next_steps,
        "artifact_paths": {
            "detail_dir": str(base_dir),
            "runtime_report_path": str(output_path),
            "validation_latest_report_path": str(validation_latest_report_path),
            "validation_stamped_report_path": str(validation_stamped_report_path),
        },
    }

    for path in {output_path, validation_latest_report_path, validation_stamped_report_path}:
        write_json(path, report)

    print(f"report written: {output_path}")
    print(f"verdict={verdict} reason_code={reason_code}")
    return 0 if verdict in {"pass", "planned"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
