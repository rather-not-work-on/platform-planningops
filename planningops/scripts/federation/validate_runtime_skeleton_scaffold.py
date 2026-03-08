#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from federated_python_env import build_bootstrap_plan, build_managed_env, ensure_bootstrap_environment, resolve_bootstrap_root


ROOT_FILE_EXPECTATIONS = {
    "rather-not-work-on/monday": ["package.json", "pnpm-workspace.yaml", "tsconfig.base.json"],
    "rather-not-work-on/platform-provider-gateway": ["package.json", "pnpm-workspace.yaml", "tsconfig.base.json"],
    "rather-not-work-on/platform-observability-gateway": ["package.json", "pnpm-workspace.yaml", "tsconfig.base.json"],
}

COMMAND_EXPECTATIONS = {
    "rather-not-work-on/monday": [
        ["bash", "scripts/test_module_readmes.sh"],
        ["python", "scripts/validate_handoff_mapping.py"],
        ["python", "scripts/validate_contract_pin.py"],
    ],
    "rather-not-work-on/platform-provider-gateway": [
        ["bash", "scripts/test_module_readmes.sh"],
        ["python", "scripts/validate_contract_pin.py", "--output", "runtime-artifacts/validation/provider-contract-pin-report.json"],
        ["bash", "scripts/test_provider_guardrails.sh"],
    ],
    "rather-not-work-on/platform-observability-gateway": [
        ["bash", "scripts/test_module_readmes.sh"],
        ["python", "scripts/validate_contract_pin.py", "--output", "runtime-artifacts/validation/o11y-contract-pin-report.json"],
        ["bash", "scripts/test_observability_guardrails.sh"],
    ],
}


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
        if (candidate / "platform-provider-gateway").exists() and (candidate / "monday").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def repo_dir_name(target_repo: str) -> str:
    return target_repo.split("/")[-1]


def normalize_contract_items(contract_doc: dict, selected_plan_item_ids: set[str] | None) -> list[dict]:
    items = []
    for item in ((contract_doc.get("execution_contract") or {}).get("items") or []):
        plan_item_id = str(item.get("plan_item_id") or "")
        if selected_plan_item_ids and plan_item_id not in selected_plan_item_ids:
            continue
        items.append(item)
    return items


def run_cmd(cmd: list[str], cwd: Path, env: dict[str, str]) -> tuple[int, str, str]:
    completed = subprocess.run(cmd, cwd=str(cwd), env=env, capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def check_output_exists(
    item: dict,
    planningops_repo: Path,
    workspace_root: Path,
    include_planningops_items: bool,
) -> dict | None:
    target_repo = str(item.get("target_repo") or "")
    primary_output = str(item.get("primary_output") or "")
    plan_item_id = str(item.get("plan_item_id") or "")

    if not target_repo or not primary_output:
        return {
            "check_type": "primary_output",
            "plan_item_id": plan_item_id,
            "target_repo": target_repo,
            "primary_output": primary_output,
            "verdict": "fail",
            "message": "target_repo and primary_output are required",
        }

    if target_repo.endswith("/platform-planningops") and not include_planningops_items:
        return None

    repo_root = planningops_repo if target_repo.endswith("/platform-planningops") else workspace_root / repo_dir_name(target_repo)
    output_path = repo_root / primary_output
    return {
        "check_type": "primary_output",
        "plan_item_id": plan_item_id,
        "target_repo": target_repo,
        "primary_output": primary_output,
        "path": str(output_path),
        "exists": output_path.exists(),
        "verdict": "pass" if output_path.exists() else "fail",
    }


def check_root_files(target_repo: str, workspace_root: Path) -> list[dict]:
    expected = ROOT_FILE_EXPECTATIONS.get(target_repo, [])
    repo_root = workspace_root / repo_dir_name(target_repo)
    rows = []
    for relative_path in expected:
        path = repo_root / relative_path
        rows.append(
            {
                "check_type": "root_file",
                "target_repo": target_repo,
                "path": str(path),
                "exists": path.exists(),
                "verdict": "pass" if path.exists() else "fail",
            }
        )
    return rows


def expand_command(cmd: list[str], python_bin: str) -> list[str]:
    if not cmd:
        return cmd
    if cmd[0] == "python":
        return [python_bin, *cmd[1:]]
    return cmd


def run_repo_commands(target_repo: str, workspace_root: Path, env: dict[str, str], python_bin: str) -> list[dict]:
    commands = COMMAND_EXPECTATIONS.get(target_repo, [])
    repo_root = workspace_root / repo_dir_name(target_repo)
    rows = []
    for raw_cmd in commands:
        cmd = expand_command(raw_cmd, python_bin)
        rc, out, err = run_cmd(cmd, repo_root, env)
        rows.append(
            {
                "check_type": "repo_command",
                "target_repo": target_repo,
                "cwd": str(repo_root),
                "command": cmd,
                "exit_code": rc,
                "verdict": "pass" if rc == 0 else "fail",
                "stdout_tail": out[-1200:],
                "stderr_tail": err[-1200:],
            }
        )
    return rows


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate runtime skeleton scaffold outputs across federated repos")
    parser.add_argument(
        "--contract",
        default="docs/workbench/unified-personal-agent-platform/plans/2026-03-09-runtime-skeleton-wave2.execution-contract.json",
        help="Execution contract JSON to validate",
    )
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repos")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/runtime-skeleton-wave2-scaffold-review.json",
        help="Output review report path",
    )
    parser.add_argument(
        "--plan-item-id",
        action="append",
        default=[],
        help="Optional plan_item_id filter; repeat to validate a subset",
    )
    parser.add_argument("--include-planningops-items", action="store_true", help="Also validate planningops-owned primary outputs")
    parser.add_argument("--skip-command-checks", action="store_true", help="Skip repo-local command execution")
    parser.add_argument("--bootstrap-mode", choices=["auto", "off", "require"], default="auto")
    parser.add_argument(
        "--bootstrap-root",
        default="planningops/runtime-artifacts/tooling/federated-conformance",
        help="Managed virtualenv root used when sibling repo Python deps must be bootstrapped",
    )
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    bootstrap_root = resolve_bootstrap_root(planningops_repo, args.bootstrap_root)
    bootstrap_plan = build_bootstrap_plan(planningops_repo, workspace_root, bootstrap_root)
    bootstrap_info = ensure_bootstrap_environment(bootstrap_plan, args.bootstrap_mode)
    bootstrap_info["workspace_root"] = str(workspace_root)

    if bootstrap_info.get("reexec_required"):
        child_cmd = [bootstrap_info["managed_python"], str(Path(__file__).resolve()), *sys.argv[1:]]
        child = subprocess.run(child_cmd, env=build_managed_env(bootstrap_info))
        return int(child.returncode)

    contract_path = Path(args.contract)
    if not contract_path.is_absolute():
        contract_path = planningops_repo / contract_path
    contract_doc = load_json(contract_path)
    selected_ids = {value.strip() for value in args.plan_item_id if value.strip()} or None
    items = normalize_contract_items(contract_doc, selected_ids)

    output_checks = []
    root_checks = []
    command_checks = []
    target_repos = sorted({str(item.get("target_repo") or "") for item in items if str(item.get("target_repo") or "") and not str(item.get("target_repo") or "").endswith("/platform-planningops")})

    for item in items:
        row = check_output_exists(item, planningops_repo, workspace_root, args.include_planningops_items)
        if row is not None:
            output_checks.append(row)

    for target_repo in target_repos:
        root_checks.extend(check_root_files(target_repo, workspace_root))

    env = build_managed_env(bootstrap_info)
    python_bin = sys.executable
    if not args.skip_command_checks:
        for target_repo in target_repos:
            command_checks.extend(run_repo_commands(target_repo, workspace_root, env, python_bin))

    all_rows = output_checks + root_checks + command_checks
    failures = [row for row in all_rows if row.get("verdict") != "pass"]
    report = {
        "generated_at_utc": now_utc(),
        "contract": str(contract_path),
        "workspace_root": str(workspace_root),
        "selected_plan_item_ids": sorted(selected_ids or []),
        "bootstrap": bootstrap_info,
        "skip_command_checks": args.skip_command_checks,
        "include_planningops_items": args.include_planningops_items,
        "items_checked": len(items),
        "target_repo_count": len(target_repos),
        "output_check_count": len(output_checks),
        "root_check_count": len(root_checks),
        "command_check_count": len(command_checks),
        "failure_count": len(failures),
        "output_checks": output_checks,
        "root_checks": root_checks,
        "command_checks": command_checks,
        "verdict": "pass" if not failures else "fail",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(
        " ".join(
            [
                f"items_checked={report['items_checked']}",
                f"output_check_count={report['output_check_count']}",
                f"root_check_count={report['root_check_count']}",
                f"command_check_count={report['command_check_count']}",
                f"failure_count={report['failure_count']}",
                f"verdict={report['verdict']}",
            ]
        )
    )
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
