#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPTS_ROOT = Path(__file__).resolve().parents[2]
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from compile_plan_to_backlog import issue_body


DEFAULT_REPO = "rather-not-work-on/platform-planningops"
DEFAULT_INITIATIVE = "unified-personal-agent-platform"
DEFAULT_MANIFEST_REPOS = ",".join(
    [
        "rather-not-work-on/platform-planningops",
        "rather-not-work-on/platform-contracts",
        "rather-not-work-on/platform-provider-gateway",
        "rather-not-work-on/platform-observability-gateway",
        "rather-not-work-on/monday",
    ]
)
DEFAULT_OUTPUT = Path("planningops/artifacts/backlog/materialize-report.json")
DEFAULT_PROJECTED_ISSUES = Path("planningops/artifacts/backlog/projected-issues.json")
DEFAULT_COMPILE_OUTPUT = Path("planningops/artifacts/validation/plan-compile-report.json")
DEFAULT_LABEL_OUTPUT = Path("planningops/artifacts/validation/issue-label-backfill-report.json")
DEFAULT_MANIFEST_OUTPUT = Path("planningops/artifacts/program/program-manifest.json")
DEFAULT_MANIFEST_REPORT = Path("planningops/artifacts/validation/program-manifest-report.json")
DEFAULT_QUALITY_OUTPUT = Path("planningops/artifacts/validation/issue-quality-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_execution_contract(path: Path):
    doc = json.loads(path.read_text(encoding="utf-8"))
    execution_contract = doc.get("execution_contract")
    if not isinstance(execution_contract, dict):
        raise RuntimeError("execution_contract object is required")
    for key in ["plan_id", "plan_revision", "source_of_truth", "items"]:
        if key not in execution_contract:
            raise RuntimeError(f"execution_contract.{key} is required")
    if not isinstance(execution_contract.get("items"), list) or not execution_contract["items"]:
        raise RuntimeError("execution_contract.items must be non-empty list")
    return execution_contract


def build_projected_issues(execution_contract, repo: str, source_plan_override: str | None = None):
    source_plan = str(source_plan_override or execution_contract.get("source_of_truth") or "").strip()
    if not source_plan:
        raise RuntimeError("source_of_truth is required for projected backlog issues")

    plan_id = execution_contract["plan_id"]
    plan_revision = execution_contract["plan_revision"]
    items = sorted(
        execution_contract["items"],
        key=lambda item: (int(item.get("execution_order", 0) or 0), str(item.get("plan_item_id") or "")),
    )
    order_to_plan_item_id = {
        int(item["execution_order"]): str(item["plan_item_id"])
        for item in items
        if isinstance(item.get("execution_order"), int) and item.get("plan_item_id")
    }

    projected_issues = []
    generated_at = now_utc()
    for item in items:
        synthetic_number = int(item["execution_order"])
        projected_item = dict(item)
        projected_item["depends_on"] = [
            order_to_plan_item_id.get(dep, str(dep)) for dep in (item.get("depends_on") or [])
        ]
        projected_issues.append(
            {
                "repo": repo,
                "number": synthetic_number,
                "state": "open",
                "updated_at": generated_at,
                "title": f"plan: [{item['execution_order']}] {item['title']}",
                "url": f"https://github.com/{repo}/issues/{synthetic_number}",
                "body": issue_body(source_plan, plan_id, plan_revision, projected_item),
                "labels": [],
            }
        )
    return projected_issues


def build_plan_item_regex(execution_contract):
    plan_item_ids = sorted(
        {
            str(item.get("plan_item_id")).strip()
            for item in execution_contract.get("items", [])
            if str(item.get("plan_item_id") or "").strip()
        }
    )
    if not plan_item_ids:
        raise RuntimeError("execution_contract.items must provide non-empty plan_item_id values")
    return "^(?:" + "|".join(re.escape(plan_item_id) for plan_item_id in plan_item_ids) + ")$"


def build_steps(args, execution_contract, projected_issues_file: str | None = None):
    source_plan = str(args.source_plan or execution_contract.get("source_of_truth") or "").strip()
    if not source_plan:
        raise RuntimeError("source_of_truth is required for backlog materialization")

    compile_cmd = [
        "python3",
        "planningops/scripts/compile_plan_to_backlog.py",
        "--contract-file",
        args.contract_file,
        "--config",
        args.compile_config,
        "--blueprint-defaults-config",
        args.blueprint_defaults_config,
        "--output",
        args.compile_output,
    ]
    if args.apply:
        compile_cmd.append("--apply")
    if args.allow_reopen_closed:
        compile_cmd.append("--allow-reopen-closed")

    label_cmd = [
        "python3",
        "planningops/scripts/backfill_issue_labels.py",
        "--output",
        args.label_output,
    ]
    if projected_issues_file:
        label_cmd.extend(
            [
                "--repo",
                args.repo,
                "--issues-file",
                projected_issues_file,
                "--write-updated-issues-file",
                projected_issues_file,
                "--apply",
            ]
        )
    else:
        label_cmd.extend(["--repo", args.repo])
    if args.apply and not projected_issues_file:
        label_cmd.append("--apply")

    manifest_cmd = [
        "python3",
        "planningops/scripts/build_program_manifest.py",
        "--plan-item-regex",
        build_plan_item_regex(execution_contract),
        "--initiative",
        args.initiative,
        "--source-plan",
        source_plan,
        "--scope-source-plan",
        "--output",
        args.manifest_output,
        "--report-output",
        args.manifest_report,
        "--strict",
    ]
    if projected_issues_file:
        manifest_cmd.extend(["--issues-file", projected_issues_file])
    else:
        manifest_cmd.extend(["--repos", args.manifest_repos])

    quality_cmd = [
        "python3",
        "planningops/scripts/validate_issue_quality.py",
        "--output",
        args.quality_output,
        "--strict",
    ]
    if projected_issues_file:
        quality_cmd.extend(["--issues-file", projected_issues_file, "--repo", args.repo])
    else:
        quality_cmd.extend(["--repo", args.repo])

    return [
        {"name": "compile_plan_to_backlog", "command": compile_cmd, "output_path": args.compile_output},
        {"name": "backfill_issue_labels", "command": label_cmd, "output_path": args.label_output},
        {"name": "build_program_manifest", "command": manifest_cmd, "output_path": args.manifest_report},
        {"name": "validate_issue_quality", "command": quality_cmd, "output_path": args.quality_output},
    ]


def execute_steps(steps, run_fn=run):
    results = []
    verdict = "pass"
    for step in steps:
        rc, out, err = run_fn(step["command"])
        result = {
            "name": step["name"],
            "command": step["command"],
            "output_path": step["output_path"],
            "rc": rc,
            "stdout": out[-2000:],
            "stderr": err[-2000:],
            "verdict": "pass" if rc == 0 else "fail",
        }
        results.append(result)
        if rc != 0:
            verdict = "fail"
            break
    return results, verdict


def parse_args():
    parser = argparse.ArgumentParser(description="Materialize planningops backlog from an execution contract")
    parser.add_argument("--contract-file", required=True, help="Execution contract JSON file path")
    parser.add_argument("--repo", default=DEFAULT_REPO)
    parser.add_argument("--initiative", default=DEFAULT_INITIATIVE)
    parser.add_argument("--manifest-repos", default=DEFAULT_MANIFEST_REPOS)
    parser.add_argument("--source-plan", default=None, help="Optional manifest source-plan override")
    parser.add_argument("--compile-config", default="planningops/config/project-field-ids.json")
    parser.add_argument(
        "--blueprint-defaults-config",
        default="planningops/config/ready-implementation-blueprint-defaults.json",
    )
    parser.add_argument("--compile-output", default=str(DEFAULT_COMPILE_OUTPUT))
    parser.add_argument("--label-output", default=str(DEFAULT_LABEL_OUTPUT))
    parser.add_argument("--manifest-output", default=str(DEFAULT_MANIFEST_OUTPUT))
    parser.add_argument("--manifest-report", default=str(DEFAULT_MANIFEST_REPORT))
    parser.add_argument("--quality-output", default=str(DEFAULT_QUALITY_OUTPUT))
    parser.add_argument("--projected-issues-output", default=str(DEFAULT_PROJECTED_ISSUES))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--apply", action="store_true", help="Apply GitHub mutations during materialization")
    parser.add_argument("--allow-reopen-closed", action="store_true")
    return parser.parse_args()


def main():
    args = parse_args()
    report = {
        "generated_at_utc": now_utc(),
        "mode": "apply" if args.apply else "dry-run",
        "contract_file": args.contract_file,
        "repo": args.repo,
        "initiative": args.initiative,
        "steps": [],
    }

    try:
        execution_contract = load_execution_contract(Path(args.contract_file))
        report["plan_id"] = execution_contract["plan_id"]
        report["plan_revision"] = execution_contract["plan_revision"]
        report["source_of_truth"] = execution_contract["source_of_truth"]
        report["items_total"] = len(execution_contract["items"])
        projected_issues_file = None
        if not args.apply:
            projected_issues_path = Path(args.projected_issues_output)
            projected_issues_path.parent.mkdir(parents=True, exist_ok=True)
            projected_issues = build_projected_issues(
                execution_contract,
                repo=args.repo,
                source_plan_override=args.source_plan,
            )
            projected_issues_path.write_text(
                json.dumps(projected_issues, ensure_ascii=True, indent=2),
                encoding="utf-8",
            )
            projected_issues_file = str(projected_issues_path)
            report["projected_issues_output"] = projected_issues_file
            report["projected_issue_count"] = len(projected_issues)
        steps = build_steps(args, execution_contract, projected_issues_file=projected_issues_file)
        report["step_count"] = len(steps)
        report["steps"], report["verdict"] = execute_steps(steps)
    except Exception as exc:  # noqa: BLE001
        report["verdict"] = "fail"
        report["error"] = str(exc)

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
