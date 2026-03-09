#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


WORKFLOW_TO_STATUS = {
    "backlog": "todo",
    "ready_contract": "todo",
    "ready_implementation": "todo",
    "in_progress": "in_progress",
    "review_gate": "in_progress",
    "blocked": "blocked",
    "done": "done",
}

REQUIRED_ITEM_KEYS = [
    "plan_item_id",
    "execution_order",
    "title",
    "target_repo",
    "component",
    "workflow_state",
    "loop_profile",
    "depends_on",
    "primary_output",
]

PLAN_ITEM_ID_RE = re.compile(r"plan_item_id:\s*`([^`]+)`")
BLUEPRINT_KEYS = [
    "interface_contract_refs",
    "package_topology_ref",
    "dependency_manifest_ref",
    "file_plan_ref",
]


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_key(value):
    if value is None:
        return ""
    return str(value).strip().lower().replace(" ", "_").replace("-", "_")


def as_int(value):
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def parse_plan_item_id(issue_body: str):
    if not issue_body:
        return None
    match = PLAN_ITEM_ID_RE.search(issue_body)
    if not match:
        return None
    return match.group(1).strip()


def parse_blueprint_refs(issue_body: str):
    refs = {}
    for key in BLUEPRINT_KEYS:
        refs[key] = None
        match = re.search(rf"(?mi)^{key}:\s*(.+?)\s*$", issue_body or "")
        if match:
            value = match.group(1).strip()
            if value:
                refs[key] = value
    missing = [key for key in BLUEPRINT_KEYS if not refs.get(key)]
    return {
        "refs": refs,
        "missing": missing,
        "complete": len(missing) == 0,
    }


def validate_contract(contract_doc):
    errors = []
    ec = contract_doc.get("execution_contract")
    if not isinstance(ec, dict):
        return ["execution_contract object is required"]

    for key in ["plan_id", "plan_revision", "source_of_truth", "items"]:
        if key not in ec:
            errors.append(f"execution_contract.{key} is required")

    if errors:
        return errors

    if not isinstance(ec["plan_revision"], int) or ec["plan_revision"] <= 0:
        errors.append("execution_contract.plan_revision must be integer >= 1")

    items = ec.get("items")
    if not isinstance(items, list) or not items:
        errors.append("execution_contract.items must be non-empty list")
        return errors

    seen_ids = set()
    for idx, item in enumerate(items):
        path = f"execution_contract.items[{idx}]"
        if not isinstance(item, dict):
            errors.append(f"{path} must be object")
            continue
        for key in REQUIRED_ITEM_KEYS:
            if key not in item:
                errors.append(f"{path}.{key} is required")

        item_id = item.get("plan_item_id")
        if isinstance(item_id, str) and item_id:
            if item_id in seen_ids:
                errors.append(f"duplicate plan_item_id: {item_id}")
            seen_ids.add(item_id)

    return errors


def build_expected_projection(contract_doc, initiative):
    expected = {}
    for item in contract_doc["execution_contract"]["items"]:
        plan_item_id = item["plan_item_id"]
        workflow_state = normalize_key(item["workflow_state"])
        expected[plan_item_id] = {
            "plan_item_id": plan_item_id,
            "execution_order": as_int(item["execution_order"]),
            "target_repo": item["target_repo"],
            "component": normalize_key(item["component"]),
            "workflow_state": workflow_state,
            "loop_profile": normalize_key(item["loop_profile"]),
            "status": WORKFLOW_TO_STATUS[item["workflow_state"]],
            "initiative": initiative,
            "blueprint_required": workflow_state == "ready_implementation",
        }
    return expected


def load_project_items(owner, project_number, limit):
    rc, out, err = run(
        [
            "gh",
            "project",
            "item-list",
            str(project_number),
            "--owner",
            owner,
            "--limit",
            str(limit),
            "--format",
            "json",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to fetch project items: {err}")
    return json.loads(out).get("items", [])


def load_snapshot_items(snapshot_file: Path):
    doc = read_json(snapshot_file)
    if isinstance(doc, dict):
        return doc.get("items", [])
    if isinstance(doc, list):
        return doc
    raise ValueError("snapshot must be list or object with items[]")


def build_actual_projection(items, initiative_filter):
    by_plan_item = {}
    duplicate_plan_item_ids = []
    for item in items:
        content = item.get("content") or {}
        if content.get("type") not in {"Issue", "DraftIssue"}:
            continue

        initiative = item.get("initiative")
        if initiative_filter and initiative != initiative_filter:
            continue

        plan_item_id = parse_plan_item_id(content.get("body") or "")
        if not plan_item_id:
            continue

        row = {
            "plan_item_id": plan_item_id,
            "issue_number": content.get("number"),
            "issue_url": content.get("url"),
            "execution_order": as_int(item.get("execution_order")),
            "target_repo": item.get("target_repo"),
            "component": normalize_key(item.get("component")),
            "workflow_state": normalize_key(item.get("workflow_state")),
            "loop_profile": normalize_key(item.get("loop_profile")),
            "status": normalize_key(item.get("status")),
            "initiative": initiative,
        }
        blueprint_meta = parse_blueprint_refs(content.get("body") or "")
        row["blueprint_complete"] = blueprint_meta["complete"]
        row["blueprint_missing"] = blueprint_meta["missing"]

        if plan_item_id in by_plan_item:
            duplicate_plan_item_ids.append(plan_item_id)
            continue
        by_plan_item[plan_item_id] = row

    return by_plan_item, sorted(set(duplicate_plan_item_ids))


def compare_projection(expected, actual, fail_on_unexpected):
    missing = []
    mismatches = []
    unexpected = []

    compare_fields = [
        "execution_order",
        "target_repo",
        "component",
        "workflow_state",
        "loop_profile",
        "status",
        "initiative",
    ]

    for plan_item_id, exp in expected.items():
        act = actual.get(plan_item_id)
        if not act:
            missing.append(
                {
                    "plan_item_id": plan_item_id,
                    "execution_order": exp["execution_order"],
                    "expected_target_repo": exp["target_repo"],
                }
            )
            continue

        for field in compare_fields:
            if exp[field] != act[field]:
                mismatches.append(
                    {
                        "plan_item_id": plan_item_id,
                        "issue_number": act.get("issue_number"),
                        "field": field,
                        "expected": exp[field],
                        "actual": act[field],
                    }
                )
        if exp.get("blueprint_required") and not act.get("blueprint_complete", False):
            mismatches.append(
                {
                    "plan_item_id": plan_item_id,
                    "issue_number": act.get("issue_number"),
                    "field": "blueprint_complete",
                    "expected": True,
                    "actual": False,
                    "missing_refs": act.get("blueprint_missing", []),
                }
            )

    if fail_on_unexpected:
        for plan_item_id, act in actual.items():
            if plan_item_id not in expected:
                unexpected.append(
                    {
                        "plan_item_id": plan_item_id,
                        "issue_number": act.get("issue_number"),
                        "target_repo": act.get("target_repo"),
                    }
                )

    return missing, mismatches, unexpected


def main():
    parser = argparse.ArgumentParser(description="Verify PEC projection drift between contract items and GitHub Project fields")
    parser.add_argument("--contract-file", required=True, help="PEC v1 JSON file path")
    parser.add_argument("--snapshot-file", default=None, help="Optional project item-list json snapshot (offline mode)")
    parser.add_argument("--owner", default="rather-not-work-on", help="GitHub org/user owner for project lookup")
    parser.add_argument("--project-number", type=int, default=2, help="GitHub project number")
    parser.add_argument("--initiative", default="unified-personal-agent-platform", help="Initiative field filter")
    parser.add_argument("--limit", type=int, default=200, help="Project item-list limit")
    parser.add_argument("--fail-on-unexpected", action="store_true", help="Fail when project has plan_item_id not in contract")
    parser.add_argument("--strict", action="store_true", help="Return non-zero on drift")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/plan-projection-report.json",
        help="Output report path",
    )
    args = parser.parse_args()

    contract_doc = read_json(Path(args.contract_file))
    validation_errors = validate_contract(contract_doc)
    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "contract_file": args.contract_file,
        "snapshot_file": args.snapshot_file,
        "project": {
            "owner": args.owner,
            "project_number": args.project_number,
            "initiative": args.initiative,
            "limit": args.limit,
        },
        "validation_errors": validation_errors,
    }

    if validation_errors:
        report["verdict"] = "fail"
        report["reasons"] = ["contract_validation_failed"]
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    expected = build_expected_projection(contract_doc, args.initiative)
    report["plan_id"] = contract_doc["execution_contract"]["plan_id"]
    report["plan_revision"] = contract_doc["execution_contract"]["plan_revision"]
    report["source_of_truth"] = contract_doc["execution_contract"]["source_of_truth"]
    report["expected_items_total"] = len(expected)

    if args.snapshot_file:
        items = load_snapshot_items(Path(args.snapshot_file))
        mode = "snapshot"
    else:
        items = load_project_items(args.owner, args.project_number, args.limit)
        mode = "live"
    report["mode"] = mode
    report["project_items_scanned"] = len(items)

    actual, duplicate_ids = build_actual_projection(items, args.initiative)
    missing, mismatches, unexpected = compare_projection(expected, actual, args.fail_on_unexpected)

    reasons = []
    if duplicate_ids:
        reasons.append("duplicate_plan_item_id_in_project")
    if missing:
        reasons.append("projection_item_missing")
    if mismatches:
        reasons.append("projection_field_mismatch")
    if unexpected:
        reasons.append("unexpected_project_item")

    report.update(
        {
            "actual_items_total": len(actual),
            "duplicate_plan_item_id_count": len(duplicate_ids),
            "duplicate_plan_item_ids": duplicate_ids,
            "missing_count": len(missing),
            "mismatch_count": len(mismatches),
            "unexpected_count": len(unexpected),
            "missing": missing,
            "mismatches": mismatches,
            "unexpected": unexpected,
            "verdict": "pass" if not reasons else "fail",
            "reasons": reasons,
        }
    )

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))

    if args.strict and report["verdict"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
