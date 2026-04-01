#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_VALIDATION_ROOT = WORKSPACE_ROOT / "planningops/artifacts/validation"
DEFAULT_DAY_PACKET = DEFAULT_VALIDATION_ROOT / "monday-local-operator-day-packet.json"
CONTRACT_REF = "planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def utc_timestamp_slug() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def resolve_path(raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path.resolve()
    return (WORKSPACE_ROOT / path).resolve()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def require_dict(doc: object, label: str) -> dict:
    if not isinstance(doc, dict):
        raise SystemExit(f"{label} must be a JSON object")
    return doc


def require_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"{label} must be a non-empty string")
    return value.strip()


def normalize_string_list(raw_values: object) -> list[str]:
    return [str(value) for value in list(raw_values or []) if str(value).strip()]


def dedupe_preserve_order(values: list[str]) -> list[str]:
    deduped: list[str] = []
    seen: set[str] = set()
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        deduped.append(value)
    return deduped


def require_existing_path(raw_path: object, label: str) -> Path:
    path = require_string(raw_path, label)
    resolved = resolve_path(path)
    if not resolved.exists():
        raise SystemExit(f"{label} missing: {resolved}")
    return resolved


def derive_status(*, local_runtime_summary: str, local_validation_action_lines: list[str]) -> tuple[str, bool, str, int, str]:
    lowered_summary = local_runtime_summary.lower()
    blocked = bool(local_validation_action_lines) or "verdict=fail" in lowered_summary or "readiness=blocked" in lowered_summary
    if blocked:
        return "blocked", True, "decision_request", 5, "manual_recheck"
    return "ready", False, "status_update", 0, "none"


def main() -> int:
    parser = argparse.ArgumentParser(description="Write a monday-friendly inbox payload bridge from a promoted local operator day packet.")
    parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    parser.add_argument("--day-packet", default=str(DEFAULT_DAY_PACKET))
    parser.add_argument("--bridge-id", default=f"monday-local-inbox-{utc_timestamp_slug()}")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    validation_root = resolve_path(args.validation_root)
    day_packet_path = resolve_path(args.day_packet)
    output_path = None if args.output is None else resolve_path(args.output)

    if not day_packet_path.exists():
        raise SystemExit(f"day packet missing: {day_packet_path}")
    if not (WORKSPACE_ROOT / CONTRACT_REF).exists():
        raise SystemExit(f"inbox payload bridge contract missing: {CONTRACT_REF}")

    day_packet_doc = require_dict(load_json(day_packet_path), "day packet")
    day_packet = require_dict(day_packet_doc.get("day_packet"), "day packet payload")
    source_artifacts = require_dict(day_packet.get("source_artifacts"), "day packet source artifacts")

    mission_packet_path = require_existing_path(source_artifacts.get("mission_packet_path"), "mission packet path")
    handoff_report_path = require_existing_path(source_artifacts.get("handoff_report_path"), "handoff report path")
    local_operator_report_path = require_existing_path(source_artifacts.get("local_operator_report_path"), "local operator report path")

    bridge_id = args.bridge_id
    latest_payload_path = validation_root / "monday-local-operator-inbox-payload.json"
    stamped_payload_path = validation_root / f"{bridge_id}-monday-local-operator-inbox-payload.json"

    headline = require_string(day_packet.get("headline"), "headline")
    first_action_command = require_string(day_packet.get("first_action_command"), "first action command")
    monday_runtime_entrypoint_command = require_string(
        day_packet.get("monday_runtime_entrypoint_command"),
        "monday runtime entrypoint command",
    )
    rollback_command = require_string(day_packet.get("rollback_command"), "rollback command")
    body_markdown = require_string(day_packet.get("body_markdown"), "body markdown")
    planner_profile = require_string(day_packet.get("planner_profile"), "planner profile")
    launch_mode = require_string(day_packet.get("launch_mode"), "launch mode")
    local_model_route = require_string(day_packet.get("local_model_route"), "local model route")
    local_validation_snapshot_status = require_string(
        day_packet.get("local_validation_snapshot_status"),
        "local validation snapshot status",
    )

    local_validation_summary_lines = normalize_string_list(day_packet.get("local_validation_summary_lines"))
    local_validation_action_lines = normalize_string_list(day_packet.get("local_validation_action_lines"))
    queue_lines = normalize_string_list(day_packet.get("queue_lines"))
    target_lines = normalize_string_list(day_packet.get("target_lines"))
    immediate_actions = normalize_string_list(day_packet.get("immediate_actions"))
    local_runtime_summary = str(day_packet.get("local_runtime_summary") or "").strip()

    status, needs_human_attention, message_class_hint, recommended_wait_minutes, retry_mode = derive_status(
        local_runtime_summary=local_runtime_summary,
        local_validation_action_lines=local_validation_action_lines,
    )

    attachments = dedupe_preserve_order(
        [
            str(latest_payload_path.resolve()),
            str(stamped_payload_path.resolve()),
            str(day_packet_path.resolve()),
            str(mission_packet_path.resolve()),
            str(handoff_report_path.resolve()),
            str(local_operator_report_path.resolve()),
            *normalize_string_list(day_packet.get("attachments")),
        ]
    )
    if not attachments:
        raise SystemExit("attachments must not be empty")

    payload = {
        "title": headline,
        "status": status,
        "headline": headline,
        "priority_headline": headline,
        "operator_action": "launch_monday_local_runtime",
        "recommended_wait_minutes": recommended_wait_minutes,
        "retry_mode": retry_mode,
        "needs_human_attention": needs_human_attention,
        "message_class_hint": message_class_hint,
        "planner_profile": planner_profile,
        "launch_mode": launch_mode,
        "local_model_route": local_model_route,
        "day_packet_id": str(day_packet.get("day_packet_id") or ""),
        "mission_packet_id": str(day_packet.get("mission_packet_id") or ""),
        "mission_objective": str(day_packet.get("mission_objective") or ""),
        "first_action_command": first_action_command,
        "monday_runtime_entrypoint_command": monday_runtime_entrypoint_command,
        "rollback_command": rollback_command,
        "local_validation_snapshot_status": local_validation_snapshot_status,
        "local_validation_summary_lines": local_validation_summary_lines,
        "local_validation_action_lines": local_validation_action_lines,
        "queue_lines": queue_lines,
        "target_lines": target_lines,
        "immediate_actions": immediate_actions,
        "attachments": attachments,
        "body_markdown": body_markdown,
        "bridge_contract_ref": CONTRACT_REF,
        "source_artifacts": {
            "day_packet_path": str(day_packet_path.resolve()),
            "mission_packet_path": str(mission_packet_path.resolve()),
            "handoff_report_path": str(handoff_report_path.resolve()),
            "local_operator_report_path": str(local_operator_report_path.resolve()),
        },
    }

    bridge_doc = {
        "generated_at_utc": now_utc(),
        "bridge_id": bridge_id,
        "contract_ref": CONTRACT_REF,
        "artifact_paths": {
            "latest_payload_path": str(latest_payload_path.resolve()),
            "stamped_payload_path": str(stamped_payload_path.resolve()),
            "output_path": None if output_path is None else str(output_path.resolve()),
        },
        "payload": payload,
    }

    write_json(latest_payload_path, bridge_doc)
    write_json(stamped_payload_path, bridge_doc)
    if output_path is not None:
        write_json(output_path, bridge_doc)

    print(json.dumps(bridge_doc, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
