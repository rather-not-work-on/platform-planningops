#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


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
        if (candidate / "platform-provider-gateway").exists() and (candidate / "platform-observability-gateway").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def resolve_component_repo(workspace_root: Path, repo_dir: str) -> Path:
    path = Path(repo_dir)
    if path.is_absolute():
        return path
    return (workspace_root / path).resolve()


def run(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def summarize_report(report_path: Path, keys: list[str]) -> dict | None:
    if not report_path.exists():
        return None
    doc = load_json(report_path)
    return {key: doc.get(key) for key in keys}


def build_issue_args(issue_number: int | None, issue_file: str | None) -> list[str]:
    if bool(issue_number) == bool(issue_file):
        raise ValueError("exactly one of --issue-number or --issue-file is required")
    if issue_number:
        return ["--issue-number", str(issue_number)]
    return ["--issue-file", str(issue_file)]


def build_component_report(
    component: str,
    repo: str,
    cwd: Path,
    command: list[str],
    report_path: Path,
    summary_keys: list[str],
) -> dict:
    rc, out, err = run(command, cwd)
    return {
        "component": component,
        "repo": repo,
        "cwd": str(cwd),
        "command": command,
        "exit_code": rc,
        "stdout_tail": out[-1000:],
        "stderr_tail": err[-1000:],
        "report_path": str(report_path),
        "report_exists": report_path.exists(),
        "report_summary": summarize_report(report_path, summary_keys),
        "verdict": "pass" if rc == 0 else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run an issue-driven federated runtime stack smoke")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--issue-number", type=int, default=None, help="Planningops issue number to use as input")
    parser.add_argument("--issue-file", default=None, help="Offline issue fixture JSON path")
    parser.add_argument("--profile", default="local", help="Runtime profile forwarded to component smoke entrypoints")
    parser.add_argument(
        "--run-id",
        default=f"issue-driven-runtime-stack-smoke-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
        help="Aggregate execution id",
    )
    parser.add_argument(
        "--issue-mission-runner",
        default="planningops/scripts/federation/run_issue_driven_mission_smoke.py",
        help="Issue-driven mission runner path relative to planningops repo root",
    )
    parser.add_argument("--monday-repo-dir", default="monday", help="monday repo directory relative to workspace root")
    parser.add_argument("--monday-python", default="python3", help="Python interpreter for monday mission runner")
    parser.add_argument("--monday-script", default="scripts/run_local_runtime_smoke.py", help="monday smoke script path")
    parser.add_argument("--provider-repo-dir", default="platform-provider-gateway", help="provider repo directory")
    parser.add_argument("--provider-python", default="python3", help="Python interpreter for provider smoke")
    parser.add_argument("--provider-script", default="scripts/litellm_live_smoke.py", help="provider smoke script path")
    parser.add_argument(
        "--provider-launcher-mode",
        choices=["dry-run", "start"],
        default="start",
        help="Launcher mode passed to provider live smoke",
    )
    parser.add_argument("--observability-repo-dir", default="platform-observability-gateway", help="o11y repo directory")
    parser.add_argument("--observability-python", default="python3", help="Python interpreter for o11y smoke")
    parser.add_argument("--observability-script", default="scripts/langfuse_live_smoke.py", help="o11y smoke script path")
    parser.add_argument(
        "--observability-launcher-mode",
        choices=["dry-run", "start"],
        default="start",
        help="Launcher mode passed to observability live smoke",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Aggregate output path. Defaults to planningops/runtime-artifacts/local/issue-runtime-stack-smoke/<run_id>.json",
    )
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    issue_args = build_issue_args(args.issue_number, args.issue_file)

    monday_report = planningops_repo / "planningops" / "runtime-artifacts" / "local" / "issue-runtime-stack-smoke" / args.run_id / "issue-mission.json"
    issue_runner_path = Path(args.issue_mission_runner)
    if not issue_runner_path.is_absolute():
        issue_runner_path = (planningops_repo / issue_runner_path).resolve()

    component_runs = [
        build_component_report(
            component="monday_issue_mission",
            repo="rather-not-work-on/platform-planningops",
            cwd=planningops_repo,
            command=[
                sys.executable,
                str(issue_runner_path),
                "--workspace-root",
                str(workspace_root),
                *issue_args,
                "--profile",
                args.profile,
                "--monday-repo-dir",
                args.monday_repo_dir,
                "--monday-python",
                args.monday_python,
                "--monday-script",
                args.monday_script,
                "--run-id",
                f"{args.run_id}-monday",
                "--output",
                str(monday_report),
            ],
            report_path=monday_report,
            summary_keys=["verdict", "reason_code", "source_issue", "mission"],
        ),
        build_component_report(
            component="provider",
            repo="rather-not-work-on/platform-provider-gateway",
            cwd=resolve_component_repo(workspace_root, args.provider_repo_dir),
            command=[
                args.provider_python,
                args.provider_script,
                "--profile",
                args.profile,
                "--launcher-mode",
                args.provider_launcher_mode,
                "--run-id",
                f"{args.run_id}-provider",
                "--output",
                str(resolve_component_repo(workspace_root, args.provider_repo_dir) / "runtime-artifacts" / "live" / f"{args.run_id}-provider.json"),
            ],
            report_path=resolve_component_repo(workspace_root, args.provider_repo_dir) / "runtime-artifacts" / "live" / f"{args.run_id}-provider.json",
            summary_keys=["verdict", "reason_code", "scenario", "profile"],
        ),
        build_component_report(
            component="observability",
            repo="rather-not-work-on/platform-observability-gateway",
            cwd=resolve_component_repo(workspace_root, args.observability_repo_dir),
            command=[
                args.observability_python,
                args.observability_script,
                "--launcher-mode",
                args.observability_launcher_mode,
                "--run-id",
                f"{args.run_id}-observability",
                "--output",
                str(resolve_component_repo(workspace_root, args.observability_repo_dir) / "runtime-artifacts" / "live" / f"{args.run_id}-observability.json"),
            ],
            report_path=resolve_component_repo(workspace_root, args.observability_repo_dir) / "runtime-artifacts" / "live" / f"{args.run_id}-observability.json",
            summary_keys=["verdict", "reason_code", "launcher_mode_requested"],
        ),
    ]

    failures = [row for row in component_runs if row["verdict"] != "pass"]
    monday_summary = component_runs[0].get("report_summary") or {}
    monday_verdict = monday_summary.get("verdict")
    if failures:
        verdict = "fail"
        reason_code = "issue_runtime_stack_smoke_failed"
    elif monday_verdict == "skip":
        verdict = "skip"
        reason_code = "issue_runtime_stack_smoke_degraded"
    else:
        verdict = "pass"
        reason_code = "issue_runtime_stack_smoke_ok"

    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "issue_source": monday_summary.get("issue_source"),
        "source_issue": monday_summary.get("source_issue"),
        "mission": monday_summary.get("mission"),
        "component_runs": component_runs,
        "failure_count": len(failures),
        "verdict": verdict,
        "reason_code": reason_code,
    }

    output_path = (
        Path(args.output)
        if args.output
        else planningops_repo / "planningops" / "runtime-artifacts" / "local" / "issue-runtime-stack-smoke" / f"{args.run_id}.json"
    )
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"verdict={verdict} failure_count={len(failures)}")
    return 0 if verdict in {"pass", "skip"} else 1


if __name__ == "__main__":
    raise SystemExit(main())
