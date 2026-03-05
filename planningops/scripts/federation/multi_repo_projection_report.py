#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description="Generate repo-level projection/drift report from sync summary")
    parser.add_argument("--summary", required=True, help="sync summary path from parser_diff_dry_run")
    parser.add_argument("--output", default=None, help="drift report output path")
    args = parser.parse_args()

    summary = load_json(Path(args.summary))
    actions = summary.get("actions", [])
    run_id = summary.get("run_id", "unknown")

    by_repo = {}
    seen_keys = set()
    duplicate_keys = []

    for act in actions:
        key = act.get("key")
        if key in seen_keys:
            duplicate_keys.append(key)
        else:
            seen_keys.add(key)

        item = act.get("item", {})
        repo = item.get("target_repo", "unknown")
        bucket = by_repo.setdefault(
            repo,
            {
                "create": 0,
                "update": 0,
                "noop": 0,
                "drift": {
                    "MISSING_ENTITY": 0,
                    "FIELD_MISMATCH": 0,
                    "IN_SYNC": 0,
                },
            },
        )

        action_type = act.get("action")
        if action_type in {"create", "update", "noop"}:
            bucket[action_type] += 1

        if action_type == "create":
            bucket["drift"]["MISSING_ENTITY"] += 1
        elif action_type == "update":
            bucket["drift"]["FIELD_MISMATCH"] += 1
        else:
            bucket["drift"]["IN_SYNC"] += 1

    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "run_id": run_id,
        "summary_path": args.summary,
        "repo_count": len(by_repo),
        "projection_key_collision_count": len(duplicate_keys),
        "duplicate_projection_keys": duplicate_keys,
        "by_repo": by_repo,
    }

    out = args.output or f"planningops/artifacts/drift/{run_id}-multi-repo-drift-report.json"
    out_path = Path(out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out_path}")
    print(
        f"repo_count={report['repo_count']} key_collisions={report['projection_key_collision_count']}"
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
