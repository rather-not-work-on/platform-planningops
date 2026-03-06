#!/usr/bin/env python3

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


DEFAULT_CONFIG = Path("planningops/config/federated-label-taxonomy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/federated-issue-quality-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def parse_label_names(raw_labels):
    names = []
    for row in raw_labels or []:
        if isinstance(row, dict):
            value = row.get("name")
            if isinstance(value, str) and value:
                names.append(value)
        elif isinstance(row, str) and row:
            names.append(row)
    return names


def list_open_issues(repo: str):
    rc, out, err = run(
        ["gh", "issue", "list", "--repo", repo, "--state", "open", "--limit", "200", "--json", "number,title,url,body,labels"]
    )
    if rc != 0:
        raise RuntimeError(err or out)
    return json.loads(out)


def has_prefix(labels: set, prefix: str):
    for label in labels:
        if label.startswith(prefix):
            return True
    return False


def main():
    parser = argparse.ArgumentParser(description="Validate federated issue label quality across execution repos")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--issues-file", default=None, help="Optional local issue JSON array for contract tests")
    parser.add_argument("--apply-default-labels", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    cfg = load_json(Path(args.config))
    required = cfg.get("required") if isinstance(cfg.get("required"), dict) else {}
    required_all = [x for x in (required.get("required_labels_all") or []) if isinstance(x, str) and x]
    required_priority_any = [x for x in (required.get("required_priority_labels_any") or []) if isinstance(x, str) and x]
    required_prefixes = [x for x in (required.get("required_label_prefixes") or []) if isinstance(x, str) and x]
    repos = [row for row in (cfg.get("repos") or []) if isinstance(row, dict) and row.get("repo")]
    default_priority = cfg.get("default_priority_label") or "p2"

    if not repos:
        print("invalid config: repos must be non-empty", file=sys.stderr)
        return 2

    repo_defaults = {row["repo"]: row for row in repos}
    issues_by_repo = {}
    errors = []

    if args.issues_file:
        raw_rows = load_json(Path(args.issues_file))
        if not isinstance(raw_rows, list):
            print("issues file must be JSON array", file=sys.stderr)
            return 2
        for row in raw_rows:
            if not isinstance(row, dict):
                continue
            repo = row.get("repo")
            if not isinstance(repo, str) or not repo:
                continue
            issues_by_repo.setdefault(repo, []).append(row)
    else:
        for repo_row in repos:
            repo = repo_row["repo"]
            try:
                issues_by_repo[repo] = list_open_issues(repo)
            except Exception as exc:  # noqa: BLE001
                message = str(exc)
                errors.append({"repo": repo, "message": message})
                issues_by_repo[repo] = []

    violations = []
    results = []
    applied_count = 0
    issues_in_scope = 0

    for repo, issues in issues_by_repo.items():
        defaults = repo_defaults.get(repo, {})
        default_area = defaults.get("default_area_label")
        default_type = defaults.get("default_type_label")

        for issue in issues:
            body = issue.get("body") or ""
            if "plan_item_id:" not in body:
                continue

            issues_in_scope += 1
            number = issue.get("number")
            title = issue.get("title")
            url = issue.get("url")

            label_names = set(parse_label_names(issue.get("labels")))
            missing = []
            to_add = []

            for name in required_all:
                if name not in label_names:
                    missing.append(name)
                    to_add.append(name)

            if required_priority_any and not label_names.intersection(required_priority_any):
                missing.append("priority")
                to_add.append(default_priority)

            for prefix in required_prefixes:
                if not has_prefix(label_names, prefix):
                    missing.append(prefix)
                    if prefix == "area/" and isinstance(default_area, str) and default_area:
                        to_add.append(default_area)
                    if prefix == "type/" and isinstance(default_type, str) and default_type:
                        to_add.append(default_type)

            to_add_unique = sorted({label for label in to_add if label and label not in label_names})

            applied_labels = []
            if to_add_unique and args.apply_default_labels:
                if args.issues_file:
                    label_names.update(to_add_unique)
                    applied_labels = list(to_add_unique)
                    applied_count += len(to_add_unique)
                else:
                    rc, out, err = run(
                        [
                            "gh",
                            "issue",
                            "edit",
                            str(number),
                            "--repo",
                            repo,
                            "--add-label",
                            ",".join(to_add_unique),
                        ]
                    )
                    if rc != 0:
                        errors.append(
                            {
                                "repo": repo,
                                "issue_number": number,
                                "message": err or out,
                            }
                        )
                    else:
                        label_names.update(to_add_unique)
                        applied_labels = list(to_add_unique)
                        applied_count += len(to_add_unique)

            remaining_missing = []
            for name in required_all:
                if name not in label_names:
                    remaining_missing.append(name)
            if required_priority_any and not label_names.intersection(required_priority_any):
                remaining_missing.append("priority")
            for prefix in required_prefixes:
                if not has_prefix(label_names, prefix):
                    remaining_missing.append(prefix)

            if remaining_missing:
                violations.append(
                    {
                        "repo": repo,
                        "issue_number": number,
                        "issue_title": title,
                        "issue_url": url,
                        "missing": remaining_missing,
                    }
                )

            results.append(
                {
                    "repo": repo,
                    "issue_number": number,
                    "issue_title": title,
                    "issue_url": url,
                    "missing_before": missing,
                    "applied_labels": applied_labels,
                    "missing_after": remaining_missing,
                }
            )

    verdict = "pass" if len(violations) == 0 and len(errors) == 0 else "fail"

    report = {
        "generated_at_utc": now_utc(),
        "mode": "apply-default-labels" if args.apply_default_labels else "check",
        "config_path": str(Path(args.config)),
        "issues_in_scope": issues_in_scope,
        "applied_label_count": applied_count,
        "violation_count": len(violations),
        "error_count": len(errors),
        "violations": violations,
        "errors": errors,
        "results": results,
        "verdict": verdict,
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out}")
    print(
        f"issues_in_scope={report['issues_in_scope']} applied_label_count={report['applied_label_count']} "
        f"violation_count={report['violation_count']} error_count={report['error_count']} verdict={report['verdict']}"
    )

    if args.strict and verdict != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
