#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


VALID_STATUSES = {"draft", "active", "blocked", "achieved", "archived"}
VALID_CHANNEL_KINDS = {"slack_skill_cli", "slack_skill_mcp", "email_cli", "email_mcp"}
PRIMARY_OPERATOR_CHANNEL_KINDS = {"slack_skill_cli", "slack_skill_mcp"}
TERMINAL_NOTIFICATION_CHANNEL_KINDS = {"email_cli", "email_mcp"}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate_registry(doc, repo_root: Path):
    errors = []
    if not isinstance(doc, dict):
        return ["registry must be an object"]
    if doc.get("registry_version") != 1:
        errors.append("registry_version must be 1")
    goals = doc.get("goals")
    if not isinstance(goals, list) or not goals:
        errors.append("goals must be non-empty list")
        return errors
    active_goal_key = str(doc.get("active_goal_key") or "").strip()
    goal_keys = set()
    active_goals = []
    goal_statuses = {}
    deferred_successors = []
    for index, goal in enumerate(goals):
        path = f"goals[{index}]"
        if not isinstance(goal, dict):
            errors.append(f"{path} must be object")
            continue
        for key in [
            "goal_key",
            "title",
            "status",
            "owner_repo",
            "goal_brief_ref",
            "execution_contract_file",
            "completion_contract_refs",
            "operator_channels",
        ]:
            if key not in goal:
                errors.append(f"{path}.{key} is required")
        goal_key = str(goal.get("goal_key") or "").strip()
        if not goal_key:
            errors.append(f"{path}.goal_key must be non-empty")
        elif goal_key in goal_keys:
            errors.append(f"duplicate goal_key: {goal_key}")
        else:
            goal_keys.add(goal_key)
        status = str(goal.get("status") or "").strip()
        if status not in VALID_STATUSES:
            errors.append(f"{path}.status invalid: {status}")
        if status == "active":
            active_goals.append(goal_key)
        if goal_key:
            goal_statuses[goal_key] = status
        next_goal_key = str(goal.get("next_goal_key") or "").strip()
        if next_goal_key:
            deferred_successors.append((path, goal_key, next_goal_key))
        for ref_key in ["goal_brief_ref", "execution_contract_file"]:
            ref = str(goal.get(ref_key) or "").strip()
            if ref and not (repo_root / ref).exists():
                errors.append(f"{path}.{ref_key} does not exist: {ref}")
        completion_refs = goal.get("completion_contract_refs")
        if not isinstance(completion_refs, list) or not completion_refs:
            errors.append(f"{path}.completion_contract_refs must be non-empty list")
        else:
            for ref in completion_refs:
                ref_value = str(ref or "").strip()
                if not ref_value or not (repo_root / ref_value).exists():
                    errors.append(f"{path}.completion_contract_refs invalid ref: {ref}")
        channels = goal.get("operator_channels")
        if not isinstance(channels, dict):
            errors.append(f"{path}.operator_channels must be object")
            continue
        for channel_key in ["primary_operator_channel", "terminal_notification_channel"]:
            channel = channels.get(channel_key)
            if not isinstance(channel, dict):
                errors.append(f"{path}.operator_channels.{channel_key} must be object")
                continue
            kind = str(channel.get("kind") or "").strip()
            if kind not in VALID_CHANNEL_KINDS:
                errors.append(f"{path}.operator_channels.{channel_key}.kind invalid: {kind}")
            if channel_key == "primary_operator_channel" and kind and kind not in PRIMARY_OPERATOR_CHANNEL_KINDS:
                errors.append(f"{path}.operator_channels.{channel_key}.kind must be slack_skill_*")
            if channel_key == "terminal_notification_channel" and kind and kind not in TERMINAL_NOTIFICATION_CHANNEL_KINDS:
                errors.append(f"{path}.operator_channels.{channel_key}.kind must be email_*")
            execution_repo = str(channel.get("execution_repo") or "").strip()
            if not execution_repo:
                errors.append(f"{path}.operator_channels.{channel_key}.execution_repo is required")
            adapter_contract_ref = str(channel.get("adapter_contract_ref") or "").strip()
            if not adapter_contract_ref or not (repo_root / adapter_contract_ref).exists():
                errors.append(
                    f"{path}.operator_channels.{channel_key}.adapter_contract_ref invalid: {adapter_contract_ref}"
                )

    if len(active_goals) > 1:
        errors.append("at most one active goal is allowed")
    if active_goal_key and active_goal_key not in goal_keys:
        errors.append(f"active_goal_key not found: {active_goal_key}")
    if len(active_goals) == 1 and active_goal_key != active_goals[0]:
        errors.append("active_goal_key must match the unique active goal")
    if len(active_goals) == 0 and active_goal_key:
        errors.append("active_goal_key must be empty when no goal is active")
    for path, goal_key, next_goal_key in deferred_successors:
        if next_goal_key not in goal_keys:
            errors.append(f"{path}.next_goal_key not found: {next_goal_key}")
            continue
        if goal_key == next_goal_key:
            errors.append(f"{path}.next_goal_key must differ from goal_key")
            continue
        next_status = goal_statuses.get(next_goal_key)
        if next_status in {"achieved", "archived"}:
            errors.append(f"{path}.next_goal_key not promotable: {next_goal_key}:{next_status}")
    return errors


def resolve_active_goal(doc, goal_key: str | None = None):
    goals = doc["goals"]
    desired_key = str(goal_key or doc["active_goal_key"]).strip()
    if not desired_key:
        raise RuntimeError("no active goal configured")
    for goal in goals:
        if str(goal.get("goal_key") or "").strip() == desired_key:
            return goal
    raise RuntimeError(f"goal not found: {desired_key}")


def build_resolved_payload(goal: dict):
    payload = dict(goal)
    payload["primary_operator_channel"] = goal["operator_channels"]["primary_operator_channel"]
    payload["terminal_notification_channel"] = goal["operator_channels"]["terminal_notification_channel"]
    return payload


def parse_args():
    parser = argparse.ArgumentParser(description="Resolve the active goal registry into a single goal payload")
    parser.add_argument("--registry", default="planningops/config/active-goal-registry.json")
    parser.add_argument("--goal-key", default=None)
    parser.add_argument("--field", default=None, help="Optional field name to print only one resolved value")
    return parser.parse_args()


def main():
    args = parse_args()
    repo_root = Path(__file__).resolve().parents[4]
    registry_path = repo_root / args.registry
    doc = load_json(registry_path)
    errors = validate_registry(doc, repo_root=repo_root)
    if errors:
        print(json.dumps({"registry": args.registry, "verdict": "fail", "errors": errors}, ensure_ascii=True, indent=2))
        return 1
    goal = resolve_active_goal(doc, goal_key=args.goal_key)
    payload = build_resolved_payload(goal)
    if args.field:
        value = payload.get(args.field)
        if value is None:
            print("")
            return 1
        if isinstance(value, (dict, list)):
            print(json.dumps(value, ensure_ascii=True))
        else:
            print(str(value))
        return 0
    print(json.dumps(payload, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
