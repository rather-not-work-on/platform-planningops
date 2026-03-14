#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from resolve_active_goal import build_resolved_payload, load_json, resolve_active_goal, validate_registry


REQUIRED_PACKET_FIELDS = [
    "packet_version",
    "exported_at_utc",
    "source_repo",
    "source_contract_ref",
    "source_outcome_ref",
    "worker_outcome",
    "reflection_hints",
]
REQUIRED_OUTCOME_FIELDS = [
    "transition_id",
    "queue_item_id",
    "goal_key",
    "schedule_key",
    "lease_owner",
    "worker_run_id",
    "state_from",
    "state_to",
    "transition_reason",
    "occurred_at_utc",
    "attempt_count",
    "retry_budget_remaining",
]
REQUIRED_HINT_FIELDS = [
    "outcome_class",
    "completion_candidate",
    "retry_exhausted",
    "dead_letter",
    "operator_attention_recommended",
    "allowed_decisions",
]
ALLOWED_DECISIONS = {"continue", "replan_required", "goal_achieved", "operator_notify"}


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_args():
    parser = argparse.ArgumentParser(description="Evaluate monday worker outcome reflection packets into planningops decisions")
    parser.add_argument("--packet-json", required=True)
    parser.add_argument("--active-goal-registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--goal-key", default=None)
    parser.add_argument("--output", default="planningops/artifacts/validation/worker-outcome-reflection-evaluation.json")
    return parser.parse_args()


def require_fields(doc: dict, required_fields: list[str], prefix: str, errors: list[str]) -> None:
    for field in required_fields:
        if field not in doc:
            errors.append(f"{prefix}.{field} is required")


def validate_packet(packet: dict, errors: list[str]) -> None:
    if not isinstance(packet, dict):
        errors.append("packet must be an object")
        return
    require_fields(packet, REQUIRED_PACKET_FIELDS, "packet", errors)
    outcome = packet.get("worker_outcome")
    hints = packet.get("reflection_hints")
    if not isinstance(outcome, dict):
        errors.append("packet.worker_outcome must be an object")
    else:
        require_fields(outcome, REQUIRED_OUTCOME_FIELDS, "packet.worker_outcome", errors)
    if not isinstance(hints, dict):
        errors.append("packet.reflection_hints must be an object")
    else:
        require_fields(hints, REQUIRED_HINT_FIELDS, "packet.reflection_hints", errors)
        allowed = hints.get("allowed_decisions")
        if not isinstance(allowed, list) or not allowed:
            errors.append("packet.reflection_hints.allowed_decisions must be non-empty list")
        else:
            invalid = sorted(set(str(item) for item in allowed) - ALLOWED_DECISIONS)
            if invalid:
                errors.append(f"packet.reflection_hints.allowed_decisions invalid: {invalid}")


def resolve_goal_context(registry_path: Path, goal_key: str | None) -> tuple[dict | None, list[str]]:
    if not registry_path.exists():
        return None, [f"active goal registry not found: {registry_path}"]
    registry = load_json(registry_path)
    repo_root = Path(__file__).resolve().parents[4]
    errors = validate_registry(registry, repo_root=repo_root)
    if errors:
        return None, [f"active goal registry invalid: {error}" for error in errors]
    try:
        goal = build_resolved_payload(resolve_active_goal(registry, goal_key=goal_key))
    except RuntimeError as exc:
        return None, [str(exc)]
    return goal, []


def derive_decision(packet: dict, active_goal: dict | None, errors: list[str]) -> tuple[str | None, str | None]:
    outcome = packet["worker_outcome"]
    hints = packet["reflection_hints"]
    packet_goal_key = str(outcome["goal_key"])
    active_goal_key = str((active_goal or {}).get("goal_key") or "")
    allowed = list(hints["allowed_decisions"])

    if active_goal_key and packet_goal_key != active_goal_key:
        decision = "operator_notify"
        reason = "packet_goal_mismatch_active_goal"
    else:
        outcome_class = str(hints["outcome_class"])
        if outcome_class == "dead_letter":
            decision = "replan_required"
            reason = "dead_letter_runtime_outcome"
        elif outcome_class == "retry_wait":
            decision = "continue"
            reason = "retry_wait_runtime_outcome"
        elif outcome_class == "completion" and bool(hints["completion_candidate"]):
            decision = "goal_achieved"
            reason = "completed_runtime_outcome"
        else:
            errors.append(f"unsupported outcome_class decision mapping: {outcome_class}")
            return None, None

    if decision not in allowed:
        errors.append(f"decision_not_allowed_by_packet: {decision}")
        return None, None
    return decision, reason


def control_plane_action_for(decision: str) -> str:
    mapping = {
        "continue": "none",
        "replan_required": "replan_backlog",
        "goal_achieved": "evaluate_goal_completion",
        "operator_notify": "notify_operator",
    }
    return mapping[decision]


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[4]
    packet_path = repo_root / args.packet_json
    packet = load_json(packet_path)
    errors: list[str] = []
    validate_packet(packet, errors)

    active_goal = None
    if not errors:
        active_goal, goal_errors = resolve_goal_context(repo_root / args.active_goal_registry, args.goal_key)
        errors.extend(goal_errors)

    decision = None
    decision_reason = None
    if not errors:
        decision, decision_reason = derive_decision(packet, active_goal, errors)

    outcome = packet.get("worker_outcome") or {}
    payload = {
        "generated_at_utc": now_utc(),
        "packet_json": args.packet_json,
        "source_packet_ref": args.packet_json,
        "source_outcome_ref": packet.get("source_outcome_ref"),
        "active_goal_key": None if active_goal is None else active_goal.get("goal_key"),
        "packet_goal_key": outcome.get("goal_key"),
        "queue_item_id": outcome.get("queue_item_id"),
        "worker_run_id": outcome.get("worker_run_id"),
        "allowed_decisions": ((packet.get("reflection_hints") or {}).get("allowed_decisions") or []),
        "reflection_decision": decision,
        "decision_reason": decision_reason,
        "decision_timestamp_utc": now_utc(),
        "control_plane_action": None if decision is None else control_plane_action_for(decision),
        "reflection_contract_ref": "planningops/contracts/worker-outcome-reflection-contract.md",
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "errors": errors,
    }

    output_path = repo_root / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=True, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())
