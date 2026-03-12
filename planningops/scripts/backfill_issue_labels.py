#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_RULES = Path("planningops/config/issue-quality-rules.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/issue-label-backfill-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")


def fetch_open_issues(repo: str):
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
            "number,title,body,url,labels",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to fetch issues: {err}")
    return json.loads(out)


def label_names(issue: dict):
    names = []
    for row in issue.get("labels", []):
        if isinstance(row, dict) and row.get("name"):
            names.append(row["name"])
        elif isinstance(row, str) and row:
            names.append(row)
    return names


def parse_component(issue: dict):
    body = issue.get("body") or ""
    match = re.search(r"(?m)^-\s+component:\s+`?([^`\n]+)`?\s*$", body)
    if not match:
        return ""
    return match.group(1).strip().lower()


def parse_target_repo(issue: dict):
    body = issue.get("body") or ""
    match = re.search(r"(?m)^-\s+target_repo:\s+`?([^`\n]+)`?\s*$", body)
    if not match:
        return ""
    return match.group(1).strip().lower()


def parse_workflow_state(issue: dict):
    body = issue.get("body") or ""
    match = re.search(r"(?m)^-\s+workflow_state:\s+`?([^`\n]+)`?\s*$", body)
    if not match:
        return ""
    return match.group(1).strip().lower()


def parse_loop_profile(issue: dict):
    body = issue.get("body") or ""
    match = re.search(r"(?m)^-\s+loop_profile:\s+`?([^`\n]+)`?\s*$", body)
    if not match:
        return ""
    return match.group(1).strip().lower()


def infer_area_label(issue: dict):
    target_repo = parse_target_repo(issue)
    if target_repo.endswith("/platform-contracts"):
        return "area/contracts"
    if target_repo.endswith("/platform-provider-gateway"):
        return "area/provider"
    if target_repo.endswith("/platform-observability-gateway"):
        return "area/observability"
    if target_repo.endswith("/monday"):
        return "area/runtime"
    if target_repo.endswith("/platform-planningops"):
        return "area/planningops"

    component = parse_component(issue)
    if "contract" in component:
        return "area/contracts"
    if "artifact" in component:
        return "area/artifacts"
    if "quality" in component:
        return "area/quality"
    if "ci" in component:
        return "area/ci"
    return "area/planningops"


def infer_type_label(issue: dict):
    workflow_state = parse_workflow_state(issue)
    loop_profile = parse_loop_profile(issue)
    if workflow_state == "ready_implementation" or "implementation" in loop_profile:
        return "type/hardening"

    text = f"{issue.get('title', '')}\n{issue.get('body', '')}".lower()
    governance_markers = ["policy", "contract", "taxonomy", "governance", "schema"]
    if any(marker in text for marker in governance_markers):
        return "type/governance"
    return "type/hardening"


def load_issues(path: Path):
    doc = load_json(path)
    if not isinstance(doc, list):
        raise RuntimeError("issues-file must contain JSON array")
    return doc


def set_issue_labels(issue: dict, labels):
    issue["labels"] = [{"name": label} for label in sorted(set(labels))]


def main():
    parser = argparse.ArgumentParser(description="Backfill required label taxonomy on open planning issues")
    parser.add_argument("--repo", default="rather-not-work-on/platform-planningops")
    parser.add_argument("--rules", default=str(DEFAULT_RULES))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--issues-file", default=None, help="Optional local issues JSON array")
    parser.add_argument(
        "--write-updated-issues-file",
        default=None,
        help="Optional output path for local issues JSON after label application",
    )
    parser.add_argument("--apply", action="store_true", help="Apply missing labels via gh issue edit")
    args = parser.parse_args()

    rules = load_json(Path(args.rules))
    required_all = rules.get("required_labels_all", [])
    priority_labels = rules.get("required_priority_labels_any", [])
    required_prefixes = rules.get("required_label_prefixes", [])
    default_priority = "p2"

    issues = load_issues(Path(args.issues_file)) if args.issues_file else fetch_open_issues(args.repo)
    rows = []
    applied_count = 0

    for issue in issues:
        body = issue.get("body") or ""
        if "plan_item_id:" not in body:
            continue

        names = label_names(issue)
        name_set = set(names)
        to_add = []

        for label in required_all:
            if label not in name_set:
                to_add.append(label)

        if priority_labels and not any(label in name_set for label in priority_labels):
            to_add.append(default_priority)

        for prefix in required_prefixes:
            if not any(label.startswith(prefix) for label in names):
                if prefix == "area/":
                    to_add.append(infer_area_label(issue))
                elif prefix == "type/":
                    to_add.append(infer_type_label(issue))

        to_add = sorted(set(to_add))
        apply_status = "skipped"
        error = ""

        if args.apply and to_add:
            if args.issues_file:
                set_issue_labels(issue, names + to_add)
                apply_status = "applied_local"
                applied_count += 1
            else:
                rc, out, err = run(
                    [
                        "gh",
                        "issue",
                        "edit",
                        str(issue.get("number")),
                        "--repo",
                        args.repo,
                        "--add-label",
                        ",".join(to_add),
                    ]
                )
                if rc == 0:
                    apply_status = "applied"
                    applied_count += 1
                else:
                    apply_status = "error"
                    error = err or out

        rows.append(
            {
                "number": issue.get("number"),
                "title": issue.get("title"),
                "url": issue.get("url"),
                "existing_labels": sorted(names),
                "planned_labels": to_add,
                "apply_status": apply_status,
                "error": error,
            }
        )

    report = {
        "generated_at_utc": now_utc(),
        "repo": args.repo,
        "rules_path": str(Path(args.rules)),
        "issues_file": args.issues_file,
        "write_updated_issues_file": args.write_updated_issues_file,
        "mode": "apply" if args.apply else "dry-run",
        "issues_in_scope": len(rows),
        "issues_with_missing_labels": len([r for r in rows if r["planned_labels"]]),
        "issues_applied": applied_count,
        "rows": rows,
    }

    out = Path(args.output)
    write_json(out, report)
    if args.issues_file and args.write_updated_issues_file:
        write_json(Path(args.write_updated_issues_file), issues)

    print(f"report written: {out}")
    print(
        f"mode={report['mode']} issues_in_scope={report['issues_in_scope']} "
        f"missing={report['issues_with_missing_labels']} applied={report['issues_applied']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
