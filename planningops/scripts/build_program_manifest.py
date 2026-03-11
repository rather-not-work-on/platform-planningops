#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from planning_context import normalize_value, parse_depends_on_plan_item_keys, parse_execution_order, parse_metadata


DEFAULT_OUTPUT = Path("planningops/artifacts/program/program-manifest.json")
DEFAULT_REPORT = Path("planningops/artifacts/validation/program-manifest-report.json")
DEFAULT_SOURCE_PLAN = (
    "docs/workbench/unified-personal-agent-platform/plans/"
    "2026-03-05-plan-meta-backlog-atomic-decomposition-and-federated-delivery-plan.md"
)
DEFAULT_INITIATIVE = "unified-personal-agent-platform"
DEFAULT_REPOS = [
    "rather-not-work-on/platform-planningops",
    "rather-not-work-on/platform-contracts",
    "rather-not-work-on/platform-provider-gateway",
    "rather-not-work-on/platform-observability-gateway",
    "rather-not-work-on/monday",
]
DEFAULT_PLAN_ITEM_REGEX = r"^[ABC][0-9]{2}$"


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def classify_track(plan_item_id: str):
    if plan_item_id.startswith("A"):
        return "control_plane"
    if plan_item_id.startswith("B"):
        return "federated_runtime"
    if plan_item_id.startswith("C"):
        return "reconciliation"
    return "unknown"


def list_issues_all_states(repo: str):
    page = 1
    rows = []
    while True:
        rc, out, err = run(["gh", "api", f"repos/{repo}/issues?state=all&per_page=100&page={page}"])
        if rc != 0:
            raise RuntimeError(f"failed to list issues for {repo}: {err}")
        batch = json.loads(out)
        if not batch:
            break
        for issue in batch:
            if issue.get("pull_request"):
                continue
            rows.append(
                {
                    "repo": repo,
                    "number": int(issue.get("number")),
                    "state": str(issue.get("state", "")).lower(),
                    "updated_at": normalize_value(issue.get("updated_at")),
                    "title": issue.get("title") or "",
                    "url": issue.get("html_url") or "",
                    "body": issue.get("body") or "",
                }
            )
        if len(batch) < 100:
            break
        page += 1
    return rows


def load_source_issues(args):
    if args.issues_file:
        doc = json.loads(Path(args.issues_file).read_text(encoding="utf-8"))
        if not isinstance(doc, list):
            raise RuntimeError("issues-file must contain JSON array")
        rows = []
        for raw in doc:
            rows.append(
                {
                    "repo": normalize_value(raw.get("repo")),
                    "number": int(raw.get("number")),
                    "state": normalize_value(raw.get("state")).lower() or "open",
                    "updated_at": normalize_value(raw.get("updated_at")),
                    "title": normalize_value(raw.get("title")),
                    "url": normalize_value(raw.get("url")),
                    "body": normalize_value(raw.get("body")),
                }
            )
        return rows

    repos = [x.strip() for x in args.repos.split(",") if x.strip()]
    rows = []
    for repo in repos:
        rows.extend(list_issues_all_states(repo))
    return rows


def parse_iso8601_epoch(value: str) -> int:
    if not value:
        return 0
    text = value.strip()
    if not text:
        return 0
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        return int(datetime.fromisoformat(text).timestamp())
    except ValueError:
        return 0


def state_priority(state: str) -> int:
    normalized = normalize_value(state).lower()
    if normalized == "open":
        return 0
    if normalized == "closed":
        return 1
    return 9


def choose_manifest_issue_winner(candidates):
    ranked = sorted(
        candidates,
        key=lambda row: (
            state_priority(row.get("issue_state")),
            -parse_iso8601_epoch(row.get("issue_updated_at", "")),
            -int(row.get("issue_number", 0)),
        ),
    )
    winner = ranked[0]
    losers = ranked[1:]
    return winner, losers


def dedupe_manifest_items(candidates):
    grouped = {}
    for item in candidates:
        key = (item["plan_item_id"], item["target_repo"])
        grouped.setdefault(key, []).append(item)

    deduped = []
    duplicate_groups = []
    for key in sorted(grouped.keys()):
        rows = grouped[key]
        winner, losers = choose_manifest_issue_winner(rows)
        deduped.append(winner)
        if losers:
            duplicate_groups.append(
                {
                    "plan_item_id": key[0],
                    "target_repo": key[1],
                    "candidate_count": len(rows),
                    "winner": {
                        "issue_repo": winner["issue_repo"],
                        "issue_number": winner["issue_number"],
                        "issue_state": winner["issue_state"],
                        "issue_updated_at": winner["issue_updated_at"],
                    },
                    "losers": [
                        {
                            "issue_repo": row["issue_repo"],
                            "issue_number": row["issue_number"],
                            "issue_state": row["issue_state"],
                            "issue_updated_at": row["issue_updated_at"],
                        }
                        for row in losers
                    ],
                }
            )

    return deduped, duplicate_groups


def build_manifest(source_rows, args):
    plan_item_re = re.compile(args.plan_item_regex)
    items = []
    for row in source_rows:
        metadata = parse_metadata(row["body"])
        plan_item_id = normalize_value(metadata.get("plan_item_id"))
        if not plan_item_id or not plan_item_re.search(plan_item_id):
            continue

        execution_order = parse_execution_order(metadata.get("execution_order"))
        item = {
            "plan_item_id": plan_item_id,
            "track": classify_track(plan_item_id),
            "execution_order": execution_order,
            "target_repo": normalize_value(metadata.get("target_repo")) or row["repo"],
            "issue_repo": row["repo"],
            "issue_number": int(row["number"]),
            "issue_url": row["url"],
            "issue_state": row["state"],
            "issue_updated_at": normalize_value(row.get("updated_at")),
            "component": normalize_value(metadata.get("component")),
            "workflow_state": normalize_value(metadata.get("workflow_state")),
            "loop_profile": normalize_value(metadata.get("loop_profile")),
            "plan_lane": normalize_value(metadata.get("plan_lane")),
            "depends_on": parse_depends_on_plan_item_keys(metadata.get("depends_on", "")),
        }
        items.append(item)

    items, duplicate_groups = dedupe_manifest_items(items)
    items.sort(key=lambda x: (x["execution_order"] or 10**9, x["plan_item_id"]))
    manifest = {
        "manifest_version": 1,
        "program_id": args.program_id,
        "initiative": args.initiative,
        "source_plan": args.source_plan,
        "generated_at_utc": now_utc(),
        "selection_policy": "dedupe_by_plan_item_id_and_target_repo_open_first_then_latest_update",
        "item_count": len(items),
        "items": items,
    }
    return manifest, duplicate_groups


def validate_manifest(manifest):
    errors = []
    items = manifest.get("items") or []
    if not items:
        errors.append("manifest.items must be non-empty")
        return errors

    seen_keys = {}
    seen_orders = {}
    key_set = set()
    for idx, item in enumerate(items):
        path = f"items[{idx}]"
        key = item.get("plan_item_id")
        if not key:
            errors.append(f"{path}.plan_item_id is required")
            continue
        if key in seen_keys:
            errors.append(f"duplicate plan_item_id: {key} ({seen_keys[key]} and {path})")
        seen_keys[key] = path
        key_set.add(key)

        order = item.get("execution_order")
        if not isinstance(order, int) or order <= 0:
            errors.append(f"{path}.execution_order must be integer > 0")
        elif order in seen_orders:
            errors.append(f"duplicate execution_order: {order} ({seen_orders[order]} and {path})")
        else:
            seen_orders[order] = path

        for req in ["target_repo", "component", "workflow_state", "plan_lane"]:
            if not item.get(req):
                errors.append(f"{path}.{req} is required")

    for idx, item in enumerate(items):
        path = f"items[{idx}]"
        for dep in item.get("depends_on") or []:
            if dep not in key_set:
                errors.append(f"{path}.depends_on references unknown key: {dep}")

    # Topology check: dependency execution_order must be lower than dependent item.
    order_by_key = {item["plan_item_id"]: item["execution_order"] for item in items if isinstance(item.get("execution_order"), int)}
    for idx, item in enumerate(items):
        path = f"items[{idx}]"
        this_order = item.get("execution_order")
        if not isinstance(this_order, int):
            continue
        for dep in item.get("depends_on") or []:
            dep_order = order_by_key.get(dep)
            if isinstance(dep_order, int) and dep_order >= this_order:
                errors.append(
                    f"{path}.depends_on order violation: {dep}({dep_order}) must be < {item['plan_item_id']}({this_order})"
                )

    return errors


def summarize_tracks(items):
    summary = {
        "control_plane": 0,
        "federated_runtime": 0,
        "reconciliation": 0,
        "unknown": 0,
    }
    for item in items:
        track = item.get("track", "unknown")
        summary[track] = summary.get(track, 0) + 1
    return summary


def main():
    parser = argparse.ArgumentParser(description="Build and validate program manifest from issue metadata")
    parser.add_argument("--issues-file", default=None, help="Optional local issues JSON array for offline test")
    parser.add_argument("--repos", default=",".join(DEFAULT_REPOS), help="Comma-separated repos to scan")
    parser.add_argument("--plan-item-regex", default=DEFAULT_PLAN_ITEM_REGEX, help="Regex filter for plan_item_id")
    parser.add_argument("--program-id", default="uap-po-ct-program", help="Program identifier")
    parser.add_argument("--initiative", default=DEFAULT_INITIATIVE, help="Initiative id")
    parser.add_argument("--source-plan", default=DEFAULT_SOURCE_PLAN, help="Primary source plan path")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Manifest output path")
    parser.add_argument("--report-output", default=str(DEFAULT_REPORT), help="Validation report output path")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero on validation failure")
    args = parser.parse_args()

    report = {
        "generated_at_utc": now_utc(),
        "program_id": args.program_id,
        "initiative": args.initiative,
        "source_plan": args.source_plan,
        "repos": [x.strip() for x in args.repos.split(",") if x.strip()],
        "issues_file": args.issues_file,
        "verdict": "fail",
        "errors": [],
    }

    try:
        source_rows = load_source_issues(args)
        manifest, duplicate_groups = build_manifest(source_rows, args)
        errors = validate_manifest(manifest)
        report["issues_scanned"] = len(source_rows)
        report["item_count"] = manifest["item_count"]
        report["duplicate_group_count"] = len(duplicate_groups)
        report["duplicate_groups"] = duplicate_groups
        report["track_summary"] = summarize_tracks(manifest.get("items", []))
        report["errors"] = errors
        report["verdict"] = "pass" if not errors else "fail"

        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(manifest, ensure_ascii=True, indent=2), encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        report["errors"].append(str(exc))
        report["verdict"] = "fail"

    report_path = Path(args.report_output)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))

    if args.strict and report["verdict"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
