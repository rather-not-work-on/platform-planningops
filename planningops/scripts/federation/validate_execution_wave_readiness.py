#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPTS_ROOT = Path(__file__).resolve().parents[1]
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from compile_plan_to_backlog import validate_contract


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_repo_root() -> Path:
    current = Path(__file__).resolve()
    for candidate in [current] + list(current.parents):
        if (candidate / ".git").exists():
            return candidate
    return Path(__file__).resolve().parents[4]


def resolve_workspace_root(planningops_repo: Path, raw_workspace_root: str) -> Path:
    base = (planningops_repo / raw_workspace_root).resolve()
    if base.exists():
        return base
    if (planningops_repo.parent / "monday").exists() and (planningops_repo.parent / "platform-provider-gateway").exists():
        return planningops_repo.parent
    return base


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def repo_dir_name(target_repo: str) -> str:
    return target_repo.split("/")[-1]


def run(cmd: list[str]) -> tuple[int, str, str]:
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def fetch_open_issues(repo: str) -> list[dict]:
    rc, out, err = run(
        [
            "gh",
            "issue",
            "list",
            "--repo",
            repo,
            "--state",
            "open",
            "--limit",
            "200",
            "--json",
            "number,title,body,url",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to fetch open issues: {err or out}")
    return json.loads(out)


def parse_plan_issue(issue: dict) -> dict[str, str]:
    body = issue.get("body") or ""
    metadata = {}
    for key in ["plan_id", "plan_item_id", "workflow_state", "target_repo"]:
        match = re.search(rf"(?m)^-\s+{re.escape(key)}:\s+`?([^`\n]+)`?\s*$", body)
        if match:
            metadata[key] = match.group(1).strip()
    return metadata


def load_report(path: Path) -> dict:
    if not path.exists():
        return {"path": str(path), "exists": False, "verdict": "fail", "message": "report missing"}
    doc = load_json(path)
    return {
        "path": str(path),
        "exists": True,
        "verdict": str(doc.get("verdict") or "fail"),
        "message": "",
    }


def resolve_output_path(planningops_repo: Path, workspace_root: Path, item: dict) -> Path:
    target_repo = str(item.get("target_repo") or "")
    primary_output = str(item.get("primary_output") or "")
    planningops_path = planningops_repo / primary_output
    if planningops_path.exists() or target_repo.endswith("/platform-planningops"):
        return planningops_path
    return workspace_root / repo_dir_name(target_repo) / primary_output


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate readiness for an execution wave before projecting the next issue pack")
    parser.add_argument("--contract", required=True, help="Execution contract JSON")
    parser.add_argument("--ready-order", type=int, required=True, help="Execution order of the readiness item")
    parser.add_argument("--output", required=True, help="Output report path")
    parser.add_argument("--repo", default="rather-not-work-on/platform-planningops", help="Planning repo for issue checks")
    parser.add_argument("--workspace-root", default="..", help="Workspace root containing sibling repos")
    parser.add_argument("--blueprint-report", action="append", default=[], help="Existing validation report JSON that must have verdict=pass")
    parser.add_argument("--open-issues-file", default=None, help="Optional local JSON array used instead of gh issue list")
    args = parser.parse_args()

    planningops_repo = resolve_repo_root()
    workspace_root = resolve_workspace_root(planningops_repo, args.workspace_root)

    contract_path = Path(args.contract)
    if not contract_path.is_absolute():
        contract_path = planningops_repo / contract_path
    contract_doc = load_json(contract_path)
    contract_errors = validate_contract(contract_doc)

    ec = contract_doc.get("execution_contract") or {}
    plan_id = str(ec.get("plan_id") or "")
    items = sorted(ec.get("items") or [], key=lambda item: int(item.get("execution_order", 0)))
    ready_item = next((item for item in items if int(item.get("execution_order", 0)) == args.ready_order), None)
    prerequisite_items = [item for item in items if int(item.get("execution_order", 0)) < args.ready_order]

    output_checks = []
    for item in prerequisite_items:
        output_path = resolve_output_path(planningops_repo, workspace_root, item)
        output_checks.append(
            {
                "plan_item_id": str(item.get("plan_item_id") or ""),
                "execution_order": int(item.get("execution_order", 0) or 0),
                "target_repo": str(item.get("target_repo") or ""),
                "primary_output": str(item.get("primary_output") or ""),
                "path": str(output_path),
                "exists": output_path.exists(),
                "verdict": "pass" if output_path.exists() else "fail",
            }
        )

    report_checks = []
    for raw in args.blueprint_report:
        path = Path(raw)
        if not path.is_absolute():
            path = planningops_repo / path
        report_checks.append(load_report(path))

    if args.open_issues_file:
        open_issues = load_json(Path(args.open_issues_file))
    else:
        open_issues = fetch_open_issues(args.repo)

    prerequisite_ids = {str(item.get("plan_item_id") or "") for item in prerequisite_items}
    open_issue_checks = []
    for issue in open_issues:
        meta = parse_plan_issue(issue)
        if meta.get("plan_id") != plan_id:
            continue
        plan_item_id = meta.get("plan_item_id", "")
        if plan_item_id not in prerequisite_ids:
            continue
        open_issue_checks.append(
            {
                "number": issue.get("number"),
                "title": issue.get("title"),
                "plan_item_id": plan_item_id,
                "url": issue.get("url"),
                "verdict": "fail",
            }
        )

    errors = []
    if contract_errors:
        errors.extend(contract_errors)
    if not ready_item:
        errors.append(f"ready-order {args.ready_order} not found in execution contract")

    failures = [row for row in output_checks if row["verdict"] != "pass"]
    failures.extend(row for row in report_checks if row["verdict"] != "pass")
    failures.extend(open_issue_checks)

    report = {
        "generated_at_utc": now_utc(),
        "contract": str(contract_path),
        "plan_id": plan_id,
        "ready_order": args.ready_order,
        "ready_plan_item_id": str((ready_item or {}).get("plan_item_id") or ""),
        "workspace_root": str(workspace_root),
        "prerequisite_item_count": len(prerequisite_items),
        "contract_error_count": len(contract_errors),
        "errors": errors,
        "output_checks": output_checks,
        "report_checks": report_checks,
        "open_issue_checks": open_issue_checks,
        "failure_count": len(failures) + len(errors),
        "verdict": "pass" if not failures and not errors else "fail",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = planningops_repo / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
