#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import sys
from datetime import datetime, timezone

ALLOWED_STATUS = {"draft", "active", "blocked", "done"}
REQUIRED_KEYS = ["plan_item_id", "title", "target_repo", "status", "execution_order"]


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_items(items):
    errors = []
    for idx, item in enumerate(items):
        for key in REQUIRED_KEYS:
            if key not in item:
                errors.append(f"item[{idx}] missing required key: {key}")
        if "status" in item and item["status"] not in ALLOWED_STATUS:
            errors.append(
                f"item[{idx}] invalid status '{item['status']}' (allowed: {sorted(ALLOWED_STATUS)})"
            )
        if "execution_order" in item and not isinstance(item["execution_order"], int):
            errors.append(f"item[{idx}] execution_order must be integer")
    return errors


def build_desired(items):
    return sorted(items, key=lambda x: (x["execution_order"], x["plan_item_id"]))


def build_actual_index(actual_issues):
    index = {}
    for it in actual_issues:
        key = f"{it.get('plan_item_id','')}::{it.get('target_repo','')}"
        index[key] = it
    return index


def make_actions(desired_items, actual_index):
    actions = []
    for item in desired_items:
        key = f"{item['plan_item_id']}::{item['target_repo']}"
        existing = actual_index.get(key)
        if existing is None:
            actions.append({"action": "create", "key": key, "item": item})
            continue

        delta = {}
        for field in ["title", "status", "execution_order"]:
            if existing.get(field) != item.get(field):
                delta[field] = {"from": existing.get(field), "to": item.get(field)}

        if delta:
            actions.append({"action": "update", "key": key, "delta": delta, "item": item})
        else:
            actions.append({"action": "noop", "key": key, "item": item})
    return actions


def main():
    parser = argparse.ArgumentParser(description="Parser -> diff -> dry-run pipeline")
    parser.add_argument(
        "--plan-file",
        default="planningops/fixtures/plan-items/sample-plan-items-20.json",
        help="Plan items json file",
    )
    parser.add_argument(
        "--state-file",
        default="planningops/fixtures/plan-items/actual-state-empty.json",
        help="Actual issues state json file",
    )
    parser.add_argument(
        "--run-id",
        default=None,
        help="Stable run id. If omitted, UTC timestamp is used",
    )
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    args = parser.parse_args()

    plan_doc = load_json(Path(args.plan_file))
    actual_doc = load_json(Path(args.state_file))

    items = plan_doc.get("items", [])
    errors = validate_items(items)
    if errors:
        print("validation failed")
        for e in errors:
            print(f"- {e}")
        return 1

    desired = build_desired(items)
    actual_index = build_actual_index(actual_doc.get("issues", []))
    actions = make_actions(desired, actual_index)

    run_id = args.run_id or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    summary = {
        "run_id": run_id,
        "mode": args.mode,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "counts": {
            "total": len(actions),
            "create": sum(1 for a in actions if a["action"] == "create"),
            "update": sum(1 for a in actions if a["action"] == "update"),
            "noop": sum(1 for a in actions if a["action"] == "noop"),
        },
        "actions": actions,
    }

    out_path = Path(f"planningops/artifacts/sync-summary/{run_id}.json")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(summary, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"summary written: {out_path}")
    print(
        f"counts create={summary['counts']['create']} update={summary['counts']['update']} noop={summary['counts']['noop']}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
