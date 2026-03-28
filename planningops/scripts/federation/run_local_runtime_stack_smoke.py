#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from federated_python_env import build_bootstrap_plan, build_managed_env, ensure_bootstrap_environment, resolve_bootstrap_root


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


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def summarize_report(report_path: Path, keys: list[str]) -> dict | None:
    if not report_path.exists():
        return None
    doc = load_json(report_path)
    return {key: doc.get(key) for key in keys}


def run_cmd(cmd: list[str], cwd: Path, env: dict[str, str]) -> tuple[int, str, str]:
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, env=env)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def execute_with_retries(
    cmd: list[str],
    cwd: Path,
    env: dict[str, str],
    retries: int,
) -> tuple[int, str, str, list[dict[str, object]]]:
    attempts: list[dict[str, object]] = []
    rc = 1
    out = ""
    err = ""
    for attempt_number in range(1, retries + 2):
        rc, out, err = run_cmd(cmd, cwd, env)
        attempts.append(
            {
                "attempt": attempt_number,
                "exit_code": rc,
                "stdout_tail": out[-1000:],
                "stderr_tail": err[-1000:],
            }
        )
        if rc == 0:
            break
    return rc, out, err, attempts


def build_component_report(
    component: str,
    repo: str,
    cwd: Path,
    command: list[str],
    env: dict[str, str],
    report_path: Path,
    summary_keys: list[str],
    retries: int,
) -> dict:
    rc, out, err, attempts = execute_with_retries(command, cwd, env, retries)
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
        "attempt_count": len(attempts),
        "attempts": attempts,
        "recovered_after_retry": rc == 0 and len(attempts) > 1,
        "verdict": "pass" if rc == 0 else "fail",
    }


def build_launcher_report(
    name: str,
    cwd: Path,
    command: list[str],
    env: dict[str, str],
    retries: int = 0,
) -> dict:
    rc, out, err, attempts = execute_with_retries(command, cwd, env, retries)
    return {
        "name": name,
        "cwd": str(cwd),
        "command": command,
        "exit_code": rc,
        "stdout_tail": out[-1000:],
        "stderr_tail": err[-1000:],
        "attempt_count": len(attempts),
        "attempts": attempts,
        "recovered_after_retry": rc == 0 and len(attempts) > 1,
        "verdict": "pass" if rc == 0 else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Run repo-owned local smoke entrypoints as a planningops federated stack smoke")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repositories")
    parser.add_argument("--profile", default="local", help="Runtime profile id passed to monday/provider smoke entrypoints")
    parser.add_argument(
        "--run-id",
        default=f"local-runtime-stack-smoke-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}",
    )
    parser.add_argument(
        "--output",
        default=None,
        help="Aggregate output path. Defaults to planningops/runtime-artifacts/local/runtime-stack-smoke/<run-id>.json",
    )
    parser.add_argument(
        "--bootstrap-mode",
        choices=["auto", "off", "require"],
        default="auto",
        help="Manage a deterministic Python env for sibling-repo smoke entrypoints",
    )
    parser.add_argument(
        "--bootstrap-root",
        default="planningops/runtime-artifacts/tooling/federated-conformance",
        help="Managed virtualenv root used when local bootstrap is required",
    )
    parser.add_argument(
        "--component-retries",
        type=int,
        default=1,
        help="Number of retries for each component smoke after the initial attempt",
    )
    parser.add_argument(
        "--simulate-deepagents-task",
        action="append",
        default=[],
        help="Optional deterministic task forwarded to monday local runtime smoke to avoid live planner variability",
    )
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    bootstrap_root = resolve_bootstrap_root(planningops_repo, args.bootstrap_root)
    bootstrap_plan = build_bootstrap_plan(planningops_repo, workspace_root, bootstrap_root)
    bootstrap_info = ensure_bootstrap_environment(bootstrap_plan, args.bootstrap_mode)

    if bootstrap_info.get("reexec_required"):
        child_cmd = [bootstrap_info["managed_python"], str(Path(__file__).resolve()), *sys.argv[1:]]
        child = subprocess.run(child_cmd, env=build_managed_env(bootstrap_info))
        return int(child.returncode)

    env = build_managed_env(bootstrap_info)
    python_bin = bootstrap_info["preferred_python"]

    monday_repo = workspace_root / "monday"
    provider_repo = workspace_root / "platform-provider-gateway"
    o11y_repo = workspace_root / "platform-observability-gateway"

    monday_report = monday_repo / "runtime-artifacts" / "smoke" / f"{args.run_id}-monday.json"
    provider_report = provider_repo / "runtime-artifacts" / "live" / f"{args.run_id}-provider.json"
    o11y_report = o11y_repo / "runtime-artifacts" / "live" / f"{args.run_id}-observability.json"
    launcher_runs = [
        build_launcher_report(
            "provider_gateway",
            provider_repo,
            [
                "bash",
                "-c",
                "bash scripts/litellm_stack_launcher.sh "
                f"--mode start --runtime-profile-file '{workspace_root / 'platform-planningops' / 'planningops' / 'config' / 'runtime-profiles.json'}' "
                f"--profiles '{args.profile}' --run-id '{args.run_id}-provider-launcher' "
                "&& npm run gate:litellm-stack-ready",
            ],
            env,
            retries=1,
        ),
        build_launcher_report(
            "observability_gateway",
            o11y_repo,
            [
                "bash",
                "scripts/langfuse_stack_launcher.sh",
                "--mode",
                "start",
                "--run-id",
                f"{args.run_id}-observability-launcher",
            ],
            env,
            retries=1,
        ),
    ]

    try:
        component_runs = [
            build_component_report(
                component="monday",
                repo="rather-not-work-on/monday",
                cwd=monday_repo,
                env=env,
                command=[
                    python_bin,
                    "scripts/run_local_runtime_smoke.py",
                    "--profile",
                    args.profile,
                    "--run-id",
                    f"{args.run_id}-monday",
                    "--output",
                    str(monday_report),
                    *[
                        item
                        for task in args.simulate_deepagents_task
                        for item in ("--simulate-deepagents-task", task)
                    ],
                ],
                report_path=monday_report,
                summary_keys=["verdict", "reason_code", "runtime_run_id"],
                retries=args.component_retries,
            ),
            build_component_report(
                component="provider",
                repo="rather-not-work-on/platform-provider-gateway",
                cwd=provider_repo,
                env=env,
                command=[
                    python_bin,
                    "scripts/litellm_live_smoke.py",
                    "--profile",
                    args.profile,
                    "--launcher-mode",
                    "dry-run",
                    "--run-id",
                    f"{args.run_id}-provider",
                    "--output",
                    str(provider_report),
                ],
                report_path=provider_report,
                summary_keys=["verdict", "reason_code", "scenario"],
                retries=args.component_retries,
            ),
            build_component_report(
                component="observability",
                repo="rather-not-work-on/platform-observability-gateway",
                cwd=o11y_repo,
                env=env,
                command=[
                    python_bin,
                    "scripts/langfuse_live_smoke.py",
                    "--launcher-mode",
                    "dry-run",
                    "--run-id",
                    f"{args.run_id}-observability",
                    "--output",
                    str(o11y_report),
                ],
                report_path=o11y_report,
                summary_keys=["verdict", "reason_code", "launcher_mode_requested"],
                retries=args.component_retries,
            ),
        ]
    finally:
        launcher_runs.extend(
            [
                build_launcher_report(
                    "provider_gateway_stop",
                    provider_repo,
                    ["bash", "scripts/litellm_stack_launcher.sh", "--mode", "stop"],
                    env,
                ),
                build_launcher_report(
                    "observability_gateway_stop",
                    o11y_repo,
                    ["bash", "scripts/langfuse_stack_launcher.sh", "--mode", "stop"],
                    env,
                ),
            ]
        )

    failures = [row for row in component_runs if row["verdict"] != "pass"]
    component_verdicts = {row["component"]: row["verdict"] for row in component_runs}
    tolerated_launcher_failures: list[dict] = []
    launcher_failures: list[dict] = []
    for row in launcher_runs:
        if row["verdict"] == "pass":
            row["tolerated_failure"] = False
            continue

        component_name = None
        if row["name"] == "provider_gateway":
            component_name = "provider"
        elif row["name"] == "observability_gateway":
            component_name = "observability"

        tolerated = component_name is not None and component_verdicts.get(component_name) == "pass"
        row["tolerated_failure"] = tolerated
        if tolerated:
            tolerated_launcher_failures.append(row)
        else:
            launcher_failures.append(row)
    report = {
        "generated_at_utc": now_utc(),
        "run_id": args.run_id,
        "workspace_root": str(workspace_root),
        "requested_profile": args.profile,
        "bootstrap": {
            "mode": bootstrap_info["mode"],
            "managed_python": bootstrap_info["managed_python"],
            "bootstrap_root": bootstrap_info["bootstrap_root"],
            "requirements_hash": bootstrap_info["requirements_hash"],
            "reexec_required": bool(bootstrap_info.get("reexec_required")),
            "venv_rebuilt": bool(bootstrap_info.get("venv_rebuilt")),
        },
        "launcher_runs": launcher_runs,
        "tolerated_launcher_failures": tolerated_launcher_failures,
        "component_runs": component_runs,
        "failure_count": len(failures) + len(launcher_failures),
        "verdict": "pass" if not failures and not launcher_failures else "fail",
    }

    output_path = (
        Path(args.output)
        if args.output
        else planningops_repo / "planningops" / "runtime-artifacts" / "local" / "runtime-stack-smoke" / f"{args.run_id}.json"
    )
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"verdict={report['verdict']} failure_count={report['failure_count']}")
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
