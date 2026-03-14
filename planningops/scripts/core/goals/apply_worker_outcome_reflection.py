#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from resolve_active_goal import build_resolved_payload, load_json, resolve_active_goal, validate_registry


REQUIRED_EVALUATION_FIELDS = [
    "source_packet_ref",
    "active_goal_key",
    "packet_goal_key",
    "queue_item_id",
    "worker_run_id",
    "reflection_decision",
    "decision_reason",
    "control_plane_action",
    "verdict",
]

ACTION_MAPPING = {
    "continue": {
        "action_kind": "record_continue",
        "delivery_required": False,
        "message_class_hint": "status_update",
        "operator_channel_role": "none",
        "requested_goal_status": "-",
        "goal_transition_required": False,
    },
    "replan_required": {
        "action_kind": "trigger_replan_review",
        "delivery_required": True,
        "message_class_hint": "decision_request",
        "operator_channel_role": "primary_operator_channel",
        "requested_goal_status": "-",
        "goal_transition_required": False,
    },
    "goal_achieved": {
        "action_kind": "prepare_goal_completion",
        "delivery_required": True,
        "message_class_hint": "goal_completed",
        "operator_channel_role": "terminal_notification_channel",
        "requested_goal_status": "achieved",
        "goal_transition_required": True,
    },
    "operator_notify": {
        "action_kind": "escalate_operator_attention",
        "delivery_required": True,
        "message_class_hint": "blocked_report",
        "operator_channel_role": "primary_operator_channel",
        "requested_goal_status": "-",
        "goal_transition_required": False,
    },
}


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_args():
    parser = argparse.ArgumentParser(
        description="Apply planningops reflection evaluation outputs into deterministic action artifacts"
    )
    parser.add_argument("--evaluation-json", required=True)
    parser.add_argument("--active-goal-registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--goal-key", default=None)
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument("--goal-transition-output", default=None)
    parser.add_argument("--output", default="planningops/artifacts/validation/worker-outcome-reflection-action.json")
    return parser.parse_args()


def require_fields(doc: dict, required_fields: list[str], prefix: str, errors: list[str]) -> None:
    for field in required_fields:
        if field not in doc:
            errors.append(f"{prefix}.{field} is required")


def validate_evaluation(doc: dict, errors: list[str]) -> None:
    if not isinstance(doc, dict):
        errors.append("evaluation must be an object")
        return
    require_fields(doc, REQUIRED_EVALUATION_FIELDS, "evaluation", errors)
    if doc.get("verdict") != "pass":
        errors.append("evaluation.verdict must be pass")
    decision = str(doc.get("reflection_decision") or "").strip()
    if decision and decision not in ACTION_MAPPING:
        errors.append(f"evaluation.reflection_decision invalid: {decision}")


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


def normalize_repo_path(repo_root: Path, path: Path) -> str:
    try:
        return str(path.relative_to(repo_root))
    except ValueError:
        return str(path)


def summarize_action(queue_item_id: str, active_goal_key: str, decision: str, action_kind: str) -> str:
    if decision == "continue":
        return (
            f"Queue item {queue_item_id} remains in the supervisor flow after reflection decision "
            f"{decision} ({action_kind})."
        )
    if decision == "replan_required":
        return (
            f"Queue item {queue_item_id} exhausted runtime recovery and requires replanning review for "
            f"goal {active_goal_key}."
        )
    if decision == "goal_achieved":
        return (
            f"Queue item {queue_item_id} completed successfully and qualifies goal {active_goal_key} "
            f"for goal-completion handling."
        )
    return (
        f"Queue item {queue_item_id} requires operator attention for goal {active_goal_key} after "
        f"reflection decision {decision}."
    )


def build_channel_projection(resolved_goal: dict, role: str) -> tuple[str, str, str]:
    if role == "none":
        return "-", "-", "-"
    if role == "primary_operator_channel":
        channel = resolved_goal["primary_operator_channel"]
    elif role == "terminal_notification_channel":
        channel = resolved_goal["terminal_notification_channel"]
    else:
        raise RuntimeError(f"unsupported operator_channel_role: {role}")
    return (
        str(channel["kind"]),
        str(channel["execution_repo"]),
        str(channel["adapter_contract_ref"]),
    )


def maybe_apply_goal_transition(
    *,
    args,
    repo_root: Path,
    resolved_goal_key: str,
    evaluation_ref: str,
    should_apply: bool,
) -> tuple[str, list[str]]:
    if not should_apply:
        return "-", []

    transition_output = (
        repo_root / args.goal_transition_output
        if args.goal_transition_output
        else (repo_root / args.output).with_name((repo_root / args.output).stem + "-goal-transition.json")
    )
    script_path = SCRIPT_DIR / "transition_goal_state.py"
    command = [
        sys.executable,
        str(script_path),
        "--registry",
        args.active_goal_registry,
        "--goal-key",
        resolved_goal_key,
        "--to-status",
        "achieved",
        "--reason",
        "reflection_goal_achieved",
        "--evidence-ref",
        evaluation_ref,
        "--mode",
        "apply",
        "--output",
        str(transition_output),
    ]
    result = subprocess.run(command, capture_output=True, text=True, cwd=repo_root)
    errors: list[str] = []
    if result.returncode != 0:
        stderr = result.stderr.strip()
        stdout = result.stdout.strip()
        errors.append(
            "goal_transition_apply_failed"
            + (f": {stderr}" if stderr else "")
            + (f": {stdout}" if stdout else "")
        )
        return "-", errors
    return normalize_repo_path(repo_root, transition_output), errors


def main() -> int:
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[4]
    evaluation_path = repo_root / args.evaluation_json
    evaluation = load_json(evaluation_path)

    errors: list[str] = []
    validate_evaluation(evaluation, errors)

    resolved_goal = None
    if not errors:
        resolved_goal, goal_errors = resolve_goal_context(repo_root / args.active_goal_registry, args.goal_key)
        errors.extend(goal_errors)

    action_mapping = None
    if not errors:
        if evaluation.get("active_goal_key") != resolved_goal.get("goal_key"):
            errors.append(
                "evaluation.active_goal_key must match the resolved goal: "
                f"{evaluation.get('active_goal_key')} != {resolved_goal.get('goal_key')}"
            )
        action_mapping = ACTION_MAPPING.get(str(evaluation.get("reflection_decision")))
        if action_mapping is None:
            errors.append(f"unsupported reflection_decision: {evaluation.get('reflection_decision')}")

    goal_transition_report_path = "-"
    if not errors and action_mapping:
        goal_transition_report_path, transition_errors = maybe_apply_goal_transition(
            args=args,
            repo_root=repo_root,
            resolved_goal_key=str(resolved_goal["goal_key"]),
            evaluation_ref=args.evaluation_json,
            should_apply=args.mode == "apply" and bool(action_mapping["goal_transition_required"]),
        )
        errors.extend(transition_errors)

    operator_channel_kind = "-"
    operator_channel_execution_repo = "-"
    operator_channel_adapter_contract_ref = "-"
    if not errors and action_mapping:
        (
            operator_channel_kind,
            operator_channel_execution_repo,
            operator_channel_adapter_contract_ref,
        ) = build_channel_projection(resolved_goal, str(action_mapping["operator_channel_role"]))

    queue_item_id = str(evaluation.get("queue_item_id") or "-")
    active_goal_key = str((resolved_goal or {}).get("goal_key") or evaluation.get("active_goal_key") or "-")
    reflection_decision = str(evaluation.get("reflection_decision") or "")
    handoff_summary = (
        summarize_action(queue_item_id, active_goal_key, reflection_decision, action_mapping["action_kind"])
        if action_mapping
        else "Reflection action handoff could not be generated."
    )

    payload = {
        "generated_at_utc": now_utc(),
        "action_version": 1,
        "mode": args.mode,
        "active_goal_key": active_goal_key,
        "packet_goal_key": evaluation.get("packet_goal_key"),
        "queue_item_id": evaluation.get("queue_item_id"),
        "worker_run_id": evaluation.get("worker_run_id"),
        "source_packet_ref": evaluation.get("source_packet_ref"),
        "reflection_evaluation_ref": args.evaluation_json,
        "reflection_decision": reflection_decision or None,
        "decision_reason": evaluation.get("decision_reason"),
        "control_plane_action": evaluation.get("control_plane_action"),
        "action_kind": None if action_mapping is None else action_mapping["action_kind"],
        "delivery_required": None if action_mapping is None else action_mapping["delivery_required"],
        "message_class_hint": None if action_mapping is None else action_mapping["message_class_hint"],
        "operator_channel_role": None if action_mapping is None else action_mapping["operator_channel_role"],
        "operator_channel_kind": operator_channel_kind,
        "operator_channel_execution_repo": operator_channel_execution_repo,
        "operator_channel_adapter_contract_ref": operator_channel_adapter_contract_ref,
        "goal_transition_required": None if action_mapping is None else action_mapping["goal_transition_required"],
        "requested_goal_status": None if action_mapping is None else action_mapping["requested_goal_status"],
        "goal_transition_report_path": goal_transition_report_path,
        "handoff_summary": handoff_summary,
        "handoff_contract_ref": "planningops/contracts/reflection-action-handoff-contract.md",
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "errors": errors,
    }

    if (
        payload["delivery_required"] is True
        and payload["operator_channel_role"] == "none"
        and "delivery_required=true requires operator_channel_role" not in errors
    ):
        payload["verdict"] = "fail"
        payload["error_count"] += 1
        payload["errors"].append("delivery_required=true requires operator_channel_role")

    if (
        payload["goal_transition_required"] is True
        and payload["requested_goal_status"] != "achieved"
        and "goal_transition_required requires requested_goal_status=achieved" not in payload["errors"]
    ):
        payload["verdict"] = "fail"
        payload["error_count"] += 1
        payload["errors"].append("goal_transition_required requires requested_goal_status=achieved")

    if (
        payload["operator_channel_role"] != "none"
        and payload["operator_channel_kind"] == "-"
        and "operator_channel_role requires channel projection" not in payload["errors"]
    ):
        payload["verdict"] = "fail"
        payload["error_count"] += 1
        payload["errors"].append("operator_channel_role requires channel projection")

    output_path = repo_root / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(payload, ensure_ascii=True, indent=2))
    return 0 if payload["verdict"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
