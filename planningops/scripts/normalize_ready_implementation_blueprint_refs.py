#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import tempfile
from datetime import datetime, timezone
from pathlib import Path


BLUEPRINT_KEYS = [
    "interface_contract_refs",
    "package_topology_ref",
    "dependency_manifest_ref",
    "file_plan_ref",
]
KEY_REGEX = re.compile(
    r"^\s*(" + "|".join(re.escape(k) for k in BLUEPRINT_KEYS) + r")\s*:\s*(.*)\s*$",
    re.IGNORECASE,
)
HEADER_REGEX = re.compile(r"^\s*##\s+Implementation Blueprint Refs\s*$", re.IGNORECASE)


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_defaults(config_path: Path):
    doc = load_json(config_path)
    global_defaults = doc.get("global_defaults") or {}
    target_repo_defaults = doc.get("target_repo_defaults") or {}
    return {
        "global_defaults": {k: str(global_defaults.get(k, "")).strip() for k in BLUEPRINT_KEYS},
        "target_repo_defaults": {
            repo: {k: str(values.get(k, "")).strip() for k in BLUEPRINT_KEYS}
            for repo, values in target_repo_defaults.items()
        },
    }


def parse_blueprint_values(issue_body: str):
    values = {k: None for k in BLUEPRINT_KEYS}
    for line in issue_body.splitlines():
        match = KEY_REGEX.match(line)
        if not match:
            continue
        key = match.group(1).lower()
        if values.get(key):
            continue
        value = match.group(2).strip()
        if value:
            values[key] = value
    return values


def strip_existing_blueprint_block(issue_body: str):
    filtered = []
    for line in issue_body.splitlines():
        if HEADER_REGEX.match(line):
            continue
        if KEY_REGEX.match(line):
            continue
        filtered.append(line.rstrip())
    while filtered and filtered[-1] == "":
        filtered.pop()
    return "\n".join(filtered)


def resolve_default_refs(target_repo: str, defaults_doc):
    merged = dict(defaults_doc.get("global_defaults") or {})
    repo_defaults = (defaults_doc.get("target_repo_defaults") or {}).get(target_repo or "", {})
    for key in BLUEPRINT_KEYS:
        repo_value = str(repo_defaults.get(key, "")).strip()
        if repo_value:
            merged[key] = repo_value
    return {k: str(merged.get(k, "")).strip() for k in BLUEPRINT_KEYS}


def build_blueprint_block(refs):
    lines = ["## Implementation Blueprint Refs"]
    for key in BLUEPRINT_KEYS:
        value = str(refs.get(key, "")).strip()
        if value:
            lines.append(f"{key}: {value}")
        else:
            lines.append(f"{key}:")
    return "\n".join(lines)


def normalize_issue_body(issue_body: str, target_repo: str, defaults_doc):
    existing = parse_blueprint_values(issue_body)
    defaults = resolve_default_refs(target_repo, defaults_doc)

    refs = {}
    source = {}
    missing_keys = []
    for key in BLUEPRINT_KEYS:
        existing_value = str(existing.get(key) or "").strip()
        if existing_value:
            refs[key] = existing_value
            source[key] = "existing"
            continue

        default_value = str(defaults.get(key) or "").strip()
        if default_value:
            refs[key] = default_value
            source[key] = "default"
            continue

        refs[key] = ""
        source[key] = "missing"
        missing_keys.append(key)

    cleaned = strip_existing_blueprint_block(issue_body).strip()
    block = build_blueprint_block(refs)
    if cleaned:
        normalized_body = f"{cleaned}\n\n{block}\n"
    else:
        normalized_body = f"{block}\n"

    changed = issue_body.strip() != normalized_body.strip()
    return {
        "changed": changed,
        "normalized_body": normalized_body,
        "existing_refs": existing,
        "resolved_refs": refs,
        "source": source,
        "missing_keys": missing_keys,
    }


def list_project_items(owner: str, project_num: int, limit: int):
    rc, out, err = run(
        [
            "gh",
            "project",
            "item-list",
            str(project_num),
            "--owner",
            owner,
            "--limit",
            str(limit),
            "--format",
            "json",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed project item-list: {err}")
    doc = json.loads(out)
    return doc.get("items", [])


def list_candidates(items, initiative: str, workflow_states):
    workflow_set = {x.strip().lower() for x in workflow_states if x.strip()}
    candidates = []
    for item in items:
        content = item.get("content", {})
        if content.get("type") != "Issue":
            continue

        item_initiative = str(item.get("initiative") or "").strip()
        if initiative and item_initiative and item_initiative != initiative:
            continue
        if initiative and not item_initiative:
            continue

        item_workflow = str(item.get("workflow_state") or "").strip().lower()
        if item_workflow not in workflow_set:
            continue

        issue_number = content.get("number")
        issue_repo = content.get("repository")
        if not issue_number or not issue_repo:
            continue

        candidates.append(
            {
                "item_id": item.get("id"),
                "issue_number": issue_number,
                "issue_repo": issue_repo,
                "target_repo": item.get("target_repo") or issue_repo,
                "workflow_state": item.get("workflow_state"),
                "status": item.get("status"),
            }
        )
    return sorted(candidates, key=lambda x: int(x["issue_number"]))


def fetch_issue(issue_repo: str, issue_number: int):
    rc, out, err = run(
        [
            "gh",
            "issue",
            "view",
            str(issue_number),
            "--repo",
            issue_repo,
            "--json",
            "number,title,body,state,url",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed issue view {issue_repo}#{issue_number}: {err}")
    return json.loads(out)


def update_issue_body(issue_repo: str, issue_number: int, body: str):
    with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".md", delete=False) as tf:
        tf.write(body)
        temp_path = tf.name
    try:
        rc, out, err = run(
            [
                "gh",
                "issue",
                "edit",
                str(issue_number),
                "--repo",
                issue_repo,
                "--body-file",
                temp_path,
            ]
        )
        return rc, out, err
    finally:
        Path(temp_path).unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description="Normalize blueprint refs for ready-implementation issues")
    parser.add_argument("--owner", default="rather-not-work-on")
    parser.add_argument("--project-num", type=int, default=2)
    parser.add_argument("--initiative", default="unified-personal-agent-platform")
    parser.add_argument(
        "--workflow-states",
        default="ready-implementation,ready_implementation",
        help="comma-separated workflow states to include",
    )
    parser.add_argument("--limit", type=int, default=500)
    parser.add_argument(
        "--config",
        default="planningops/config/ready-implementation-blueprint-defaults.json",
        help="default blueprint refs config path",
    )
    parser.add_argument("--apply", action="store_true", help="apply updates to issues")
    parser.add_argument(
        "--fail-on-missing",
        action="store_true",
        help="return non-zero when any issue still has missing blueprint refs after normalization",
    )
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/ready-implementation-blueprint-normalize-report.json",
    )
    args = parser.parse_args()

    defaults_doc = load_defaults(Path(args.config))
    workflow_states = [x for x in args.workflow_states.split(",") if x.strip()]
    items = list_project_items(args.owner, args.project_num, args.limit)
    candidates = list_candidates(items, args.initiative, workflow_states)

    report_rows = []
    changed_count = 0
    applied_count = 0
    missing_count = 0

    for candidate in candidates:
        issue = fetch_issue(candidate["issue_repo"], candidate["issue_number"])
        if str(issue.get("state", "")).upper() != "OPEN":
            continue

        normalized = normalize_issue_body(
            issue_body=issue.get("body") or "",
            target_repo=candidate["target_repo"],
            defaults_doc=defaults_doc,
        )
        changed = bool(normalized["changed"])
        if changed:
            changed_count += 1
        if normalized["missing_keys"]:
            missing_count += 1

        applied = False
        apply_error = None
        if args.apply and changed:
            rc_edit, out_edit, err_edit = update_issue_body(
                candidate["issue_repo"],
                candidate["issue_number"],
                normalized["normalized_body"],
            )
            if rc_edit == 0:
                applied = True
                applied_count += 1
            else:
                apply_error = err_edit or out_edit or "issue edit failed"

        row = {
            "issue_number": candidate["issue_number"],
            "issue_repo": candidate["issue_repo"],
            "target_repo": candidate["target_repo"],
            "workflow_state": candidate["workflow_state"],
            "status": candidate["status"],
            "changed": changed,
            "applied": applied,
            "apply_error": apply_error,
            "missing_keys": normalized["missing_keys"],
            "source": normalized["source"],
            "resolved_refs": normalized["resolved_refs"],
            "url": issue.get("url"),
        }
        report_rows.append(row)

    report = {
        "generated_at_utc": now_utc(),
        "mode": "apply" if args.apply else "dry-run",
        "owner": args.owner,
        "project_num": args.project_num,
        "initiative": args.initiative,
        "workflow_states": workflow_states,
        "candidates_count": len(candidates),
        "changed_count": changed_count,
        "applied_count": applied_count,
        "missing_count": missing_count,
        "rows": report_rows,
        "verdict": "pass" if missing_count == 0 else "fail",
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))

    if args.apply and any(row.get("apply_error") for row in report_rows):
        return 1
    if args.fail_on_missing and missing_count > 0:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
