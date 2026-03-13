#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

CORE_GOALS_DIR = Path(__file__).resolve().parent / "core" / "goals"
if str(CORE_GOALS_DIR) not in sys.path:
    sys.path.insert(0, str(CORE_GOALS_DIR))

from resolve_active_goal import build_resolved_payload, load_json, resolve_active_goal, validate_registry


DEFAULT_OUTPUT = Path("planningops/artifacts/validation/active-goal-registry-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def parse_args():
    parser = argparse.ArgumentParser(description="Validate active goal registry contract")
    parser.add_argument("--registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main():
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[2]
    registry_path = repo_root / args.registry
    doc = load_json(registry_path)
    errors = validate_registry(doc, repo_root=repo_root)
    resolved = None
    if not errors:
        resolved = build_resolved_payload(resolve_active_goal(doc))

    report = {
        "generated_at_utc": now_utc(),
        "registry": args.registry,
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "errors": errors,
        "active_goal_key": doc.get("active_goal_key"),
        "resolved_goal": resolved,
    }

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    if args.strict and errors:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
