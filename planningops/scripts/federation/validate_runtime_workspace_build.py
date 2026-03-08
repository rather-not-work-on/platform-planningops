#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_POLICY = Path("planningops/config/node-workspace-bootstrap-policy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/runtime-skeleton-wave3-build-review.json")
DEFAULT_REPOS = [
    "rather-not-work-on/monday",
    "rather-not-work-on/platform-provider-gateway",
    "rather-not-work-on/platform-observability-gateway",
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
        if (candidate / "monday").exists() and (candidate / "platform-provider-gateway").exists():
            return candidate
    return (planningops_repo / raw_workspace_root).resolve()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def run_cmd(cmd: list[str], cwd: Path) -> tuple[int, str, str]:
    completed = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True)
    return completed.returncode, completed.stdout.strip(), completed.stderr.strip()


def repo_dir_name(target_repo: str) -> str:
    return target_repo.split("/")[-1]


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate runtime workspace build baseline across federated repos")
    parser.add_argument("--workspace-root", default="..")
    parser.add_argument("--policy", default=str(DEFAULT_POLICY))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--repo", action="append", default=[], help="Optional target repo override")
    parser.add_argument("--skip-install", action="store_true")
    parser.add_argument("--skip-typecheck", action="store_true")
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)
    policy_path = Path(args.policy)
    if not policy_path.is_absolute():
        policy_path = planningops_repo / policy_path
    policy = load_json(policy_path)

    repos = args.repo or DEFAULT_REPOS
    rows = []
    errors = []

    root_files = policy.get("root_files") or []
    required_scripts = set(policy.get("required_root_scripts") or [])
    required_dev_deps = set(policy.get("required_root_dev_dependencies") or [])
    lockfile_path = str((policy.get("lockfile") or {}).get("path") or "pnpm-lock.yaml")
    local_install = list((policy.get("commands") or {}).get("local_install") or [])
    typecheck_cmd = list((policy.get("commands") or {}).get("typecheck") or [])

    for target_repo in repos:
        repo_root = workspace_root / repo_dir_name(target_repo)
        repo_row = {
            "target_repo": target_repo,
            "repo_root": str(repo_root),
            "root_file_checks": [],
            "manifest_checks": [],
            "command_checks": [],
        }

        for relative_path in root_files:
            path = repo_root / relative_path
            repo_row["root_file_checks"].append(
                {
                    "path": str(path),
                    "exists": path.exists(),
                    "verdict": "pass" if path.exists() else "fail",
                }
            )

        package_json_path = repo_root / "package.json"
        if package_json_path.exists():
            package_json = load_json(package_json_path)
            scripts = package_json.get("scripts") or {}
            dev_deps = package_json.get("devDependencies") or {}
            for key in sorted(required_scripts):
                present = key in scripts
                repo_row["manifest_checks"].append(
                    {
                        "kind": "script",
                        "key": key,
                        "present": present,
                        "verdict": "pass" if present else "fail",
                    }
                )
            for key in sorted(required_dev_deps):
                present = key in dev_deps
                repo_row["manifest_checks"].append(
                    {
                        "kind": "devDependency",
                        "key": key,
                        "present": present,
                        "verdict": "pass" if present else "fail",
                    }
                )
        else:
            repo_row["manifest_checks"].append(
                {
                    "kind": "package.json",
                    "key": "package.json",
                    "present": False,
                    "verdict": "fail",
                }
            )

        if not args.skip_install:
            rc, out, err = run_cmd(local_install, repo_root)
            repo_row["command_checks"].append(
                {
                    "kind": "local_install",
                    "command": local_install,
                    "exit_code": rc,
                    "stdout_tail": out[-1200:],
                    "stderr_tail": err[-1200:],
                    "verdict": "pass" if rc == 0 else "fail",
                }
            )

        if not args.skip_typecheck:
            rc, out, err = run_cmd(typecheck_cmd, repo_root)
            repo_row["command_checks"].append(
                {
                    "kind": "typecheck",
                    "command": typecheck_cmd,
                    "exit_code": rc,
                    "stdout_tail": out[-1200:],
                    "stderr_tail": err[-1200:],
                    "verdict": "pass" if rc == 0 else "fail",
                }
            )

        lockfile = repo_root / lockfile_path
        repo_row["lockfile_check"] = {
            "path": str(lockfile),
            "exists": lockfile.exists(),
            "verdict": "pass" if lockfile.exists() else "fail",
        }

        rows.append(repo_row)

    for repo_row in rows:
        for group_name in ["root_file_checks", "manifest_checks", "command_checks"]:
            for row in repo_row[group_name]:
                if row.get("verdict") != "pass":
                    errors.append({"target_repo": repo_row["target_repo"], "group": group_name, **row})
        if repo_row["lockfile_check"].get("verdict") != "pass":
            errors.append({"target_repo": repo_row["target_repo"], "group": "lockfile_check", **repo_row["lockfile_check"]})

    report = {
        "generated_at_utc": now_utc(),
        "workspace_root": str(workspace_root),
        "policy_path": str(policy_path),
        "repos_checked": len(rows),
        "skip_install": args.skip_install,
        "skip_typecheck": args.skip_typecheck,
        "rows": rows,
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(f"repos_checked={report['repos_checked']} error_count={report['error_count']} verdict={report['verdict']}")
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
