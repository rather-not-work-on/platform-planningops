#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_VALIDATION_ROOT = WORKSPACE_ROOT / "planningops/artifacts/validation"
DEFAULT_MISSION_PACKET = DEFAULT_VALIDATION_ROOT / "monday-local-mission-packet.json"
DEFAULT_HANDOFF_REPORT = DEFAULT_VALIDATION_ROOT / "operator-handoff-report.json"
DEFAULT_LOCAL_OPERATOR_REPORT = DEFAULT_VALIDATION_ROOT / "monday-local-operator-stack-report.json"
CONTRACT_REF = "planningops/contracts/monday-local-operator-day-packet-contract.md"


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


def normalize_local_validation_records(raw_values: object) -> list[dict]:
    records: list[dict] = []
    for value in list(raw_values or []):
        if isinstance(value, dict):
            records.append(value)
    return records


def normalize_optional_string(raw_value: object) -> str | None:
    if isinstance(raw_value, str):
        value = raw_value.strip()
        if value:
            return value
    return None


def normalize_bool(raw_value: object) -> bool | None:
    if isinstance(raw_value, bool):
        return raw_value
    return None


def dedupe_preserve_order(values: list[str]) -> list[str]:
    deduped: list[str] = []
    seen: set[str] = set()
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        deduped.append(value)
    return deduped


def build_local_validation_snapshot(*, mission_packet: dict, handoff_record: dict) -> tuple[str, list[dict], list[str], list[str]]:
    snapshot_status = str(mission_packet.get("local_validation_snapshot_status") or "").strip()
    records = normalize_local_validation_records(mission_packet.get("local_validation_records"))
    summary_lines = normalize_string_list(mission_packet.get("local_validation_summary_lines"))
    action_lines = normalize_string_list(mission_packet.get("local_validation_action_lines"))
    if snapshot_status:
        return snapshot_status, records, summary_lines, action_lines

    fallback_records = normalize_local_validation_records(handoff_record.get("local_validation_records"))
    fallback_summary_lines = normalize_string_list(handoff_record.get("local_validation_summary_lines"))
    fallback_action_lines = normalize_string_list(handoff_record.get("local_validation_action_lines"))
    if fallback_records or fallback_summary_lines or fallback_action_lines:
        return "carried_from_handoff", fallback_records, fallback_summary_lines, fallback_action_lines
    return "missing", [], [], []


def build_cross_repo_validation_snapshot(
    *,
    mission_packet: dict,
    handoff_record: dict,
) -> tuple[str, str, str | None, list[str], list[str], list[str]]:
    snapshot_status = normalize_optional_string(mission_packet.get("cross_repo_validation_snapshot_status"))
    snapshot_summary = normalize_optional_string(mission_packet.get("cross_repo_validation_snapshot_summary"))
    action_line = normalize_optional_string(mission_packet.get("cross_repo_validation_action_line"))
    detail_lines = normalize_string_list(mission_packet.get("cross_repo_validation_detail_lines"))
    monday_source_validation_report_lines = normalize_string_list(mission_packet.get("monday_source_validation_report_lines"))
    action_lines = normalize_string_list(mission_packet.get("cross_repo_validation_action_lines"))
    if (
        snapshot_status is not None
        or snapshot_summary is not None
        or action_line is not None
        or detail_lines
        or monday_source_validation_report_lines
        or action_lines
    ):
        return (
            snapshot_status or "missing",
            snapshot_summary or "total=0 promotable=0 blocked=0 stale=0",
            action_line,
            detail_lines,
            monday_source_validation_report_lines,
            action_lines,
        )

    fallback_status = normalize_optional_string(handoff_record.get("cross_repo_validation_snapshot_status"))
    fallback_summary = normalize_optional_string(handoff_record.get("cross_repo_validation_snapshot_summary"))
    fallback_action_line = normalize_optional_string(handoff_record.get("cross_repo_validation_action_line"))
    fallback_detail_lines = normalize_string_list(handoff_record.get("cross_repo_validation_detail_lines"))
    fallback_monday_source_validation_report_lines = normalize_string_list(
        handoff_record.get("monday_source_validation_report_lines")
    )
    fallback_action_lines = normalize_string_list(handoff_record.get("cross_repo_validation_action_lines"))
    if (
        fallback_status is not None
        or fallback_summary is not None
        or fallback_action_line is not None
        or fallback_detail_lines
        or fallback_monday_source_validation_report_lines
        or fallback_action_lines
    ):
        return (
            fallback_status or "carried_from_handoff",
            fallback_summary or "total=0 promotable=0 blocked=0 stale=0",
            fallback_action_line,
            fallback_detail_lines,
            fallback_monday_source_validation_report_lines,
            fallback_action_lines,
        )

    return "missing", "total=0 promotable=0 blocked=0 stale=0", None, [], [], []


def build_cross_repo_validation_steering(
    *,
    mission_packet: dict,
    primary_action: str,
    cross_repo_validation_action_line: str | None,
    cross_repo_validation_packet_report_id: str | None,
    cross_repo_validation_packet_path: str | None,
) -> tuple[str, bool]:
    scope = normalize_optional_string(mission_packet.get("cross_repo_validation_steering_scope"))
    promoted = normalize_bool(mission_packet.get("cross_repo_validation_primary_action_promoted"))
    if scope is not None:
        return scope, promoted if promoted is not None else scope == "primary_action_only"

    derived_promoted = (
        cross_repo_validation_action_line is not None
        and primary_action == cross_repo_validation_action_line
        and cross_repo_validation_packet_report_id is not None
        and cross_repo_validation_packet_path is not None
    )
    return ("primary_action_only" if derived_promoted else "none"), derived_promoted


def build_body_markdown(
    *,
    headline: str,
    mission_objective: str,
    primary_action: str,
    planner_profile: str,
    launch_mode: str,
    local_model_route: str,
    first_action_command: str,
    monday_runtime_entrypoint_command: str,
    rollback_command: str,
    local_runtime_summary: str | None,
    local_runtime_next_step: str | None,
    local_validation_summary_lines: list[str],
    local_validation_action_lines: list[str],
    cross_repo_validation_snapshot_status: str,
    cross_repo_validation_snapshot_summary: str,
    cross_repo_validation_steering_scope: str,
    cross_repo_validation_primary_action_promoted: bool,
    cross_repo_validation_action_line: str | None,
    cross_repo_validation_detail_lines: list[str],
    monday_source_validation_report_lines: list[str],
    cross_repo_validation_action_lines: list[str],
    queue_lines: list[str],
    target_lines: list[str],
    immediate_actions: list[str],
    attachments: list[str],
    cross_repo_validation_packet_report_id: str | None,
    cross_repo_validation_packet_path: str | None,
) -> str:
    lines = [
        "## Monday Local Operator Day Packet",
        "",
        "### Snapshot",
        f"- headline: {headline}",
        f"- mission objective: {mission_objective}",
        f"- primary action: {primary_action}",
        f"- planner profile: `{planner_profile}`",
        f"- launch mode: `{launch_mode}`",
        f"- local model route: `{local_model_route}`",
        "",
        "### Commands",
        f"1. preflight: `{first_action_command}`",
        f"2. monday runtime: `{monday_runtime_entrypoint_command}`",
        f"3. rollback: `{rollback_command}`",
    ]
    lines.extend(["", "### Local Runtime"])
    lines.append(f"- local runtime summary: {local_runtime_summary or 'unavailable'}")
    if local_runtime_next_step:
        lines.append(f"- local runtime next step: {local_runtime_next_step}")
    lines.extend(["", "### Local Validation", *[f"- {line}" for line in local_validation_summary_lines]])
    if local_validation_action_lines:
        lines.extend(["", "### Local Validation Actions", *[f"{index}. {line}" for index, line in enumerate(local_validation_action_lines, start=1)]])
    lines.extend(
        [
            "",
            "### Cross-Repo Validation",
            f"- snapshot status: `{cross_repo_validation_snapshot_status}`",
            f"- snapshot summary: `{cross_repo_validation_snapshot_summary}`",
            f"- steering scope: `{cross_repo_validation_steering_scope}`",
            f"- primary action promoted: `{str(cross_repo_validation_primary_action_promoted).lower()}`",
        ]
    )
    if cross_repo_validation_action_line is not None:
        lines.append(f"- next action: {cross_repo_validation_action_line}")
    if cross_repo_validation_packet_report_id is not None or cross_repo_validation_packet_path is not None:
        lines.extend(["", "### Cross-Repo Validation Packet"])
        if cross_repo_validation_packet_report_id is not None:
            lines.append(f"- detail packet report id: `{cross_repo_validation_packet_report_id}`")
        if cross_repo_validation_packet_path is not None:
            lines.append(f"- detail packet path: `{cross_repo_validation_packet_path}`")
    if cross_repo_validation_detail_lines or monday_source_validation_report_lines:
        lines.extend(
            [
                "",
                "### Cross-Repo Validation Details",
                *[f"- {line}" for line in cross_repo_validation_detail_lines],
                *[f"- {line}" for line in monday_source_validation_report_lines],
            ]
        )
    if cross_repo_validation_action_lines:
        lines.extend(
            [
                "",
                "### Cross-Repo Validation Actions",
                *[
                    f"{index}. {line}"
                    for index, line in enumerate(cross_repo_validation_action_lines, start=1)
                ],
            ]
        )
    lines.extend(["", "### Queue", *[f"- {line}" for line in queue_lines]])
    lines.extend(["", "### Top Targets", *[f"{index}. {line}" for index, line in enumerate(target_lines, start=1)]])
    lines.extend(["", "### Immediate Actions", *[f"{index}. {line}" for index, line in enumerate(immediate_actions, start=1)]])
    lines.extend(["", "### Attachments", *[f"- {path}" for path in attachments]])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Write an inbox-ready monday local operator day packet from promoted mission and handoff artifacts.")
    parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    parser.add_argument("--mission-packet", default=str(DEFAULT_MISSION_PACKET))
    parser.add_argument("--handoff-report", default=str(DEFAULT_HANDOFF_REPORT))
    parser.add_argument("--local-operator-report", default=str(DEFAULT_LOCAL_OPERATOR_REPORT))
    parser.add_argument("--day-packet-id", default=f"monday-local-day-{utc_timestamp_slug()}")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    validation_root = resolve_path(args.validation_root)
    mission_packet_path = resolve_path(args.mission_packet)
    handoff_report_path = resolve_path(args.handoff_report)
    local_operator_report_path = resolve_path(args.local_operator_report)
    output_path = None if args.output is None else resolve_path(args.output)

    if not mission_packet_path.exists():
        raise SystemExit(f"mission packet missing: {mission_packet_path}")
    if not handoff_report_path.exists():
        raise SystemExit(f"handoff report missing: {handoff_report_path}")
    if not local_operator_report_path.exists():
        raise SystemExit(f"local operator report missing: {local_operator_report_path}")
    if not (WORKSPACE_ROOT / CONTRACT_REF).exists():
        raise SystemExit(f"day packet contract missing: {CONTRACT_REF}")

    mission_doc = require_dict(load_json(mission_packet_path), "mission packet")
    handoff_doc = require_dict(load_json(handoff_report_path), "handoff report")
    local_operator_doc = require_dict(load_json(local_operator_report_path), "local operator report")
    mission_packet = require_dict(mission_doc.get("mission_packet"), "mission packet payload")
    handoff_record = require_dict(handoff_doc.get("record"), "handoff report record")

    day_packet_id = args.day_packet_id
    latest_packet_path = validation_root / "monday-local-operator-day-packet.json"
    stamped_packet_path = validation_root / f"{day_packet_id}-monday-local-operator-day-packet.json"

    mission_packet_id = require_string(mission_doc.get("packet_id"), "mission packet id")
    mission_objective = require_string(mission_packet.get("mission_objective"), "mission objective")
    primary_action = require_string(mission_packet.get("primary_action"), "primary action")
    mission_prompt = require_string(mission_packet.get("mission_prompt"), "mission prompt")
    planner_profile = require_string(mission_packet.get("planner_profile"), "planner profile")
    launch_mode = require_string(mission_packet.get("launch_mode"), "launch mode")
    local_model_route = require_string(mission_packet.get("local_model_route"), "local model route")
    first_action_command = require_string(mission_packet.get("preflight_command"), "first action command")
    monday_runtime_entrypoint_command = require_string(
        mission_packet.get("monday_runtime_entrypoint_command"),
        "monday runtime entrypoint command",
    )
    rollback_command = require_string(mission_packet.get("rollback_command"), "rollback command")
    headline = f"Monday local operator day packet: {mission_objective}"

    queue_lines = normalize_string_list(handoff_record.get("queue_lines"))
    target_lines = normalize_string_list(handoff_record.get("target_lines"))
    immediate_actions = dedupe_preserve_order(
        normalize_string_list(mission_packet.get("immediate_actions"))
        + normalize_string_list(handoff_record.get("immediate_action_lines"))
    )
    cross_repo_validation_packet_report_id = normalize_optional_string(
        mission_packet.get("cross_repo_validation_packet_report_id")
    ) or normalize_optional_string(handoff_record.get("cross_repo_validation_packet_report_id"))
    cross_repo_validation_packet_path = normalize_optional_string(
        mission_packet.get("cross_repo_validation_packet_path")
    ) or normalize_optional_string(handoff_record.get("cross_repo_validation_packet_path"))
    (
        cross_repo_validation_snapshot_status,
        cross_repo_validation_snapshot_summary,
        cross_repo_validation_action_line,
        cross_repo_validation_detail_lines,
        monday_source_validation_report_lines,
        cross_repo_validation_action_lines,
    ) = build_cross_repo_validation_snapshot(mission_packet=mission_packet, handoff_record=handoff_record)
    cross_repo_validation_steering_scope, cross_repo_validation_primary_action_promoted = build_cross_repo_validation_steering(
        mission_packet=mission_packet,
        primary_action=primary_action,
        cross_repo_validation_action_line=cross_repo_validation_action_line,
        cross_repo_validation_packet_report_id=cross_repo_validation_packet_report_id,
        cross_repo_validation_packet_path=cross_repo_validation_packet_path,
    )
    if cross_repo_validation_primary_action_promoted:
        headline = f"{headline} | next action: {primary_action}"
    local_validation_snapshot_status, local_validation_records, local_validation_summary_lines, local_validation_action_lines = (
        build_local_validation_snapshot(mission_packet=mission_packet, handoff_record=handoff_record)
    )

    attachment_candidates = [
        str(latest_packet_path.resolve()),
        str(stamped_packet_path.resolve()),
        str(mission_packet_path.resolve()),
        str(handoff_report_path.resolve()),
        str(local_operator_report_path.resolve()),
        str((validation_root / f"{mission_packet_id}-monday-local-mission-packet.json").resolve()),
    ]
    handoff_artifacts = require_dict(handoff_doc.get("artifact_paths"), "handoff artifact paths")
    for key in ("latest_report_path", "stamped_report_path"):
        raw_value = handoff_artifacts.get(key)
        if isinstance(raw_value, str) and raw_value.strip():
            attachment_candidates.append(str(resolve_path(raw_value).resolve()))
    local_operator_artifacts = require_dict(local_operator_doc.get("artifact_paths"), "local operator artifact paths")
    for key in ("runtime_report_path", "detail_dir", "validation_latest_report_path", "validation_stamped_report_path"):
        raw_value = local_operator_artifacts.get(key)
        if isinstance(raw_value, str) and raw_value.strip():
            attachment_candidates.append(str(resolve_path(raw_value).resolve()))
    if cross_repo_validation_packet_path is not None:
        attachment_candidates.append(str(resolve_path(cross_repo_validation_packet_path).resolve()))
    attachments = dedupe_preserve_order(attachment_candidates)
    if not attachments:
        raise SystemExit("attachments must not be empty")

    local_runtime_summary = str(mission_packet.get("local_runtime_summary") or handoff_record.get("local_operator_summary") or "").strip()
    local_runtime_next_step = str(mission_packet.get("local_runtime_next_step") or handoff_record.get("local_operator_next_step") or "").strip()

    day_packet = {
        "version": "v1",
        "day_packet_id": day_packet_id,
        "mission_packet_id": mission_packet_id,
        "headline": headline,
        "mission_objective": mission_objective,
        "primary_action": primary_action,
        "cross_repo_validation_steering_scope": cross_repo_validation_steering_scope,
        "cross_repo_validation_primary_action_promoted": cross_repo_validation_primary_action_promoted,
        "mission_prompt": mission_prompt,
        "attention_summary": str(mission_packet.get("attention_summary") or handoff_record.get("attention_summary") or ""),
        "newest_failing_summary": str(mission_packet.get("newest_failing_summary") or handoff_record.get("newest_failing_summary") or ""),
        "planner_profile": planner_profile,
        "launch_mode": launch_mode,
        "local_model_route": local_model_route,
        "first_action_command": first_action_command,
        "monday_runtime_entrypoint_command": monday_runtime_entrypoint_command,
        "rollback_command": rollback_command,
        "local_runtime_summary": local_runtime_summary,
        "local_runtime_next_step": local_runtime_next_step,
        "local_validation_snapshot_status": local_validation_snapshot_status,
        "local_validation_records": local_validation_records,
        "local_validation_summary_lines": local_validation_summary_lines,
        "local_validation_action_lines": local_validation_action_lines,
        "cross_repo_validation_snapshot_status": cross_repo_validation_snapshot_status,
        "cross_repo_validation_snapshot_summary": cross_repo_validation_snapshot_summary,
        "cross_repo_validation_action_line": cross_repo_validation_action_line,
        "cross_repo_validation_detail_lines": cross_repo_validation_detail_lines,
        "monday_source_validation_report_lines": monday_source_validation_report_lines,
        "cross_repo_validation_action_lines": cross_repo_validation_action_lines,
        "cross_repo_validation_packet_report_id": cross_repo_validation_packet_report_id,
        "cross_repo_validation_packet_path": cross_repo_validation_packet_path,
        "queue_lines": queue_lines,
        "target_lines": target_lines,
        "immediate_actions": immediate_actions,
        "attachments": attachments,
        "body_markdown": build_body_markdown(
            headline=headline,
            mission_objective=mission_objective,
            primary_action=primary_action,
            planner_profile=planner_profile,
            launch_mode=launch_mode,
            local_model_route=local_model_route,
            first_action_command=first_action_command,
            monday_runtime_entrypoint_command=monday_runtime_entrypoint_command,
            rollback_command=rollback_command,
            local_runtime_summary=local_runtime_summary or None,
            local_runtime_next_step=local_runtime_next_step or None,
            local_validation_summary_lines=local_validation_summary_lines,
            local_validation_action_lines=local_validation_action_lines,
            cross_repo_validation_snapshot_status=cross_repo_validation_snapshot_status,
            cross_repo_validation_snapshot_summary=cross_repo_validation_snapshot_summary,
            cross_repo_validation_steering_scope=cross_repo_validation_steering_scope,
            cross_repo_validation_primary_action_promoted=cross_repo_validation_primary_action_promoted,
            cross_repo_validation_action_line=cross_repo_validation_action_line,
            cross_repo_validation_detail_lines=cross_repo_validation_detail_lines,
            monday_source_validation_report_lines=monday_source_validation_report_lines,
            cross_repo_validation_action_lines=cross_repo_validation_action_lines,
            queue_lines=queue_lines,
            target_lines=target_lines,
            immediate_actions=immediate_actions,
            attachments=attachments,
            cross_repo_validation_packet_report_id=cross_repo_validation_packet_report_id,
            cross_repo_validation_packet_path=cross_repo_validation_packet_path,
        ),
        "source_artifacts": {
            "mission_packet_path": str(mission_packet_path.resolve()),
            "handoff_report_path": str(handoff_report_path.resolve()),
            "local_operator_report_path": str(local_operator_report_path.resolve()),
        },
    }

    packet_doc = {
        "generated_at_utc": now_utc(),
        "day_packet_id": day_packet_id,
        "contract_ref": CONTRACT_REF,
        "artifact_paths": {
            "latest_packet_path": str(latest_packet_path.resolve()),
            "stamped_packet_path": str(stamped_packet_path.resolve()),
            "output_path": None if output_path is None else str(output_path.resolve()),
        },
        "day_packet": day_packet,
    }

    write_json(latest_packet_path, packet_doc)
    write_json(stamped_packet_path, packet_doc)
    if output_path is not None:
        write_json(output_path, packet_doc)

    print(json.dumps(packet_doc, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
