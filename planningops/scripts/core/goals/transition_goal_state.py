#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys

from resolve_active_goal import load_json, validate_registry


ALLOWED_TRANSITIONS = {
    ("draft", "active"),
    ("draft", "archived"),
    ("active", "blocked"),
    ("active", "achieved"),
    ("blocked", "active"),
    ("blocked", "archived"),
    ("achieved", "archived"),
}


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def require_goal(doc: dict, goal_key: str) -> tuple[int, dict]:
    for index, goal in enumerate(doc["goals"]):
        if str(goal.get("goal_key") or "").strip() == goal_key:
            return index, goal
    raise RuntimeError(f"goal not found: {goal_key}")


def build_report(
    *,
    args,
    before_doc: dict,
    proposed_doc: dict | None,
    errors: list[str],
    goal_key: str,
    from_status: str | None,
) -> dict:
    return {
        "generated_at_utc": now_utc(),
        "registry": args.registry,
        "mode": args.mode,
        "goal_key": goal_key,
        "from_status": from_status,
        "to_status": args.to_status,
        "activate_next_goal_key": args.activate_next_goal_key,
        "transition_reason": args.reason,
        "evidence_refs": args.evidence_ref,
        "active_goal_key_before": before_doc.get("active_goal_key"),
        "active_goal_key_after": None if proposed_doc is None else proposed_doc.get("active_goal_key"),
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "errors": errors,
        "proposed_registry": proposed_doc,
    }


def parse_args():
    parser = argparse.ArgumentParser(description="Apply deterministic active-goal registry state transitions")
    parser.add_argument("--registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--goal-key", required=True)
    parser.add_argument("--to-status", required=True, choices=["draft", "active", "blocked", "achieved", "archived"])
    parser.add_argument("--activate-next-goal-key", default=None)
    parser.add_argument("--reason", required=True)
    parser.add_argument("--evidence-ref", action="append", default=[])
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/goal-state-transition-report.json",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[4]
    registry_path = repo_root / args.registry
    before_doc = load_json(registry_path)
    errors = validate_registry(before_doc, repo_root=repo_root)
    if errors:
        report = build_report(
            args=args,
            before_doc=before_doc,
            proposed_doc=None,
            errors=[f"registry invalid before transition: {error}" for error in errors],
            goal_key=args.goal_key,
            from_status=None,
        )
    else:
        working_doc = json.loads(json.dumps(before_doc))
        index, goal = require_goal(working_doc, args.goal_key)
        from_status = str(goal.get("status") or "").strip()
        to_status = args.to_status

        if from_status == to_status:
            errors.append("transition_is_noop")
        elif (from_status, to_status) not in ALLOWED_TRANSITIONS:
            errors.append(f"transition_not_allowed: {from_status}->{to_status}")

        current_active_key = str(working_doc.get("active_goal_key") or "").strip()
        next_goal = None
        next_index = None
        if args.activate_next_goal_key:
            next_index, next_goal = require_goal(working_doc, args.activate_next_goal_key)
            next_status = str(next_goal.get("status") or "").strip()
            if next_status not in {"draft", "blocked"}:
                errors.append(f"next_goal_not_promotable: {args.activate_next_goal_key}:{next_status}")
            if args.activate_next_goal_key == args.goal_key:
                errors.append("activate_next_goal_key must differ from goal_key")
        elif from_status == "active" and to_status != "active":
            errors.append("activate_next_goal_key required when transitioning the current active goal away from active")

        if from_status != "active" and to_status in {"blocked", "achieved"}:
            errors.append(f"only_active_goal_can_transition_to_{to_status}")

        if to_status == "active" and current_active_key and current_active_key != args.goal_key:
            errors.append("cannot_activate_goal_while_another_goal_is_active")

        if not args.reason.strip():
            errors.append("transition_reason_required")

        if not errors:
            working_doc["goals"][index]["status"] = to_status
            if from_status == "active" and to_status != "active":
                working_doc["active_goal_key"] = ""
            if next_goal is not None and next_index is not None:
                working_doc["goals"][next_index]["status"] = "active"
                working_doc["active_goal_key"] = args.activate_next_goal_key
            elif to_status == "active":
                working_doc["active_goal_key"] = args.goal_key

            post_errors = validate_registry(working_doc, repo_root=repo_root)
            if post_errors:
                errors.extend([f"registry invalid after transition: {error}" for error in post_errors])

        report = build_report(
            args=args,
            before_doc=before_doc,
            proposed_doc=working_doc if not errors else None,
            errors=errors,
            goal_key=args.goal_key,
            from_status=from_status,
        )

        if not errors and args.mode == "apply":
            registry_path.write_text(json.dumps(working_doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    output_path = repo_root / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
