#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_RULES = Path("planningops/config/issue-quality-rules.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/issue-quality-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def has_section(body: str, section: str) -> bool:
    pattern = rf"(?m)^##\s+{re.escape(section)}\s*$"
    return re.search(pattern, body) is not None


def has_metadata_key(body: str, key: str) -> bool:
    pattern = rf"(?m)^-\s+{re.escape(key)}:\s*.+$"
    return re.search(pattern, body) is not None


def count_acceptance_checklist(body: str) -> int:
    # Count all checklist lines; contract requires minimum count.
    return len(re.findall(r"(?m)^-\s+\[\s?[xX]?\s?\]\s+.+$", body))


def extract_label_names(issue: dict):
    labels = issue.get("labels") or []
    names = []
    for label in labels:
        if isinstance(label, dict):
            name = label.get("name")
        else:
            name = str(label)
        if name:
            names.append(name)
    return names


def validate_issue(issue: dict, rules: dict):
    body = issue.get("body") or ""
    violations = []
    labels = extract_label_names(issue)
    label_set = set(labels)

    for section in rules.get("required_sections", []):
        if not has_section(body, section):
            violations.append(f"missing section: {section}")

    for key in rules.get("required_metadata_keys", []):
        if not has_metadata_key(body, key):
            violations.append(f"missing metadata key: {key}")

    min_items = int(rules.get("minimum_acceptance_checklist_items", 0) or 0)
    checklist_count = count_acceptance_checklist(body)
    if checklist_count < min_items:
        violations.append(f"acceptance checklist items < {min_items} (actual={checklist_count})")

    for marker in rules.get("forbidden_evidence_markers", []):
        if marker and marker in body:
            violations.append(f"forbidden evidence marker present: {marker}")

    for label in rules.get("required_labels_all", []):
        if label not in label_set:
            violations.append(f"missing required label: {label}")

    priority_labels = rules.get("required_priority_labels_any", [])
    if priority_labels:
        present = [label for label in priority_labels if label in label_set]
        if len(present) == 0:
            violations.append(f"missing priority label; require one of {priority_labels}")
        if len(present) > 1:
            violations.append(f"multiple priority labels present: {present}")

    for prefix in rules.get("required_label_prefixes", []):
        if not any(name.startswith(prefix) for name in labels):
            violations.append(f"missing required label prefix: {prefix}*")

    return {
        "number": issue.get("number"),
        "title": issue.get("title"),
        "url": issue.get("url"),
        "labels": labels,
        "violation_count": len(violations),
        "violations": violations,
    }


def fetch_open_issues(repo: str):
    rc, out, err = run([
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
    ])
    if rc != 0:
        raise RuntimeError(f"failed to fetch issues: {err}")
    return json.loads(out)


def fetch_issue(repo: str, issue_number: int):
    rc, out, err = run(
        [
            "gh",
            "issue",
            "view",
            str(issue_number),
            "--repo",
            repo,
            "--json",
            "number,title,body,url,labels",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to fetch issue #{issue_number}: {err}")
    return json.loads(out)


def main():
    parser = argparse.ArgumentParser(description="Validate backlog issue quality contract")
    parser.add_argument("--rules", default=str(DEFAULT_RULES))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--repo", default=None)
    parser.add_argument("--issues-file", default=None, help="Optional local issue JSON array")
    parser.add_argument("--issue-number", type=int, default=None, help="Validate only one issue by number")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero when violations exist")
    args = parser.parse_args()

    rules = load_json(Path(args.rules))
    repo = args.repo or rules.get("repo", "rather-not-work-on/platform-planningops")

    if args.issues_file:
        issues = load_json(Path(args.issues_file))
    elif args.issue_number is not None:
        issues = [fetch_issue(repo, args.issue_number)]
    else:
        issues = fetch_open_issues(repo)

    require_marker = bool(rules.get("require_plan_item_id_marker", True))
    scoped = []
    for issue in issues:
        body = issue.get("body") or ""
        if require_marker and "plan_item_id:" not in body:
            continue
        scoped.append(issue)

    rows = [validate_issue(issue, rules) for issue in scoped]
    bad = [row for row in rows if row["violation_count"] > 0]

    report = {
        "generated_at_utc": now_utc(),
        "repo": repo,
        "rules_path": str(Path(args.rules)),
        "issues_scanned": len(issues),
        "issues_in_scope": len(scoped),
        "violation_count": len(bad),
        "violations": bad,
        "verdict": "pass" if not bad else "fail",
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out}")
    print(f"issues_in_scope={report['issues_in_scope']} violation_count={report['violation_count']} verdict={report['verdict']}")

    if args.strict and bad:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
