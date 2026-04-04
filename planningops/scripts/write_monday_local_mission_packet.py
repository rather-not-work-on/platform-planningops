#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_VALIDATION_ROOT = WORKSPACE_ROOT / "planningops/artifacts/validation"
DEFAULT_HANDOFF_REPORT = DEFAULT_VALIDATION_ROOT / "operator-handoff-report.json"
DEFAULT_LOCAL_OPERATOR_REPORT = DEFAULT_VALIDATION_ROOT / "monday-local-operator-stack-report.json"
CONTRACT_REF = "planningops/contracts/monday-local-mission-packet-contract.md"

PLANNER_PROFILE_CHOICES = ("auto", "local", "local_ollama", "local_lmstudio")
LAUNCH_MODE_CHOICES = ("auto", "stack", "direct")
MODEL_ROUTE_CHOICES = ("auto", "gateway_first_local", "direct_local_ollama", "direct_local_lmstudio")


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


def normalize_string_list(raw_values: object) -> list[str]:
    return [str(value) for value in list(raw_values or []) if str(value).strip()]


def normalize_local_validation_records(raw_values: object) -> list[dict]:
    records: list[dict] = []
    for value in list(raw_values or []):
        if isinstance(value, dict):
            records.append(value)
    return records


def build_local_validation_snapshot(handoff_record: dict) -> tuple[str, list[dict], list[str], list[str]]:
    records = normalize_local_validation_records(handoff_record.get("local_validation_records"))
    summary_lines = normalize_string_list(handoff_record.get("local_validation_summary_lines"))
    action_lines = normalize_string_list(handoff_record.get("local_validation_action_lines"))
    snapshot_status = "present" if records or summary_lines or action_lines else "missing"
    return snapshot_status, records, summary_lines, action_lines


def normalize_optional_string(raw_value: object) -> str | None:
    if isinstance(raw_value, str):
        value = raw_value.strip()
        if value:
            return value
    return None


def build_cross_repo_validation_snapshot(
    handoff_record: dict,
) -> tuple[str, str, str | None, list[str], list[str], list[str]]:
    snapshot_status = normalize_optional_string(handoff_record.get("cross_repo_validation_snapshot_status")) or "missing"
    snapshot_summary = (
        normalize_optional_string(handoff_record.get("cross_repo_validation_snapshot_summary"))
        or "total=0 promotable=0 blocked=0 stale=0"
    )
    action_line = normalize_optional_string(handoff_record.get("cross_repo_validation_action_line"))
    detail_lines = normalize_string_list(handoff_record.get("cross_repo_validation_detail_lines"))
    monday_source_validation_report_lines = normalize_string_list(handoff_record.get("monday_source_validation_report_lines"))
    action_lines = normalize_string_list(handoff_record.get("cross_repo_validation_action_lines"))
    return (
        snapshot_status,
        snapshot_summary,
        action_line,
        detail_lines,
        monday_source_validation_report_lines,
        action_lines,
    )


def should_promote_cross_repo_primary_action(
    *,
    immediate_actions: list[str],
    cross_repo_validation_action_line: str | None,
    cross_repo_validation_packet_report_id: str | None,
    cross_repo_validation_packet_path: str | None,
) -> bool:
    if cross_repo_validation_action_line is None:
        return False
    if cross_repo_validation_packet_report_id is None or cross_repo_validation_packet_path is None:
        return False
    if any(action.startswith("local-runtime:") for action in immediate_actions):
        return False
    if any(action.startswith("local-validation:") for action in immediate_actions):
        return False
    return True


def prepend_once(values: list[str], item: str) -> list[str]:
    return [item, *[value for value in values if value != item]]


def build_cross_repo_validation_steering(
    *,
    primary_action: str,
    cross_repo_validation_action_line: str | None,
    cross_repo_validation_packet_report_id: str | None,
    cross_repo_validation_packet_path: str | None,
) -> tuple[str, bool]:
    promoted = (
        cross_repo_validation_action_line is not None
        and primary_action == cross_repo_validation_action_line
        and cross_repo_validation_packet_report_id is not None
        and cross_repo_validation_packet_path is not None
    )
    return ("primary_action_only" if promoted else "none"), promoted


def build_mission_objective(handoff_record: dict) -> str:
    target_lines = [str(line) for line in list(handoff_record.get("target_lines") or []) if str(line).strip()]
    if target_lines:
        return f"Resolve {target_lines[0]}"
    newest_failing = str(handoff_record.get("newest_failing_summary") or "").strip()
    if newest_failing:
        return f"Investigate {newest_failing}"
    headline = str(handoff_record.get("headline") or "").strip()
    if headline:
        return headline
    return "Inspect the latest promoted local handoff state."


def choose_launch_parameters(
    *,
    local_operator_doc: dict,
    planner_profile_arg: str,
    launch_mode_arg: str,
    local_model_route_arg: str,
) -> tuple[str, str, str]:
    readiness_status = str(require_dict(local_operator_doc.get("readiness"), "local operator readiness").get("status") or "unknown")
    direct_profile = str(local_operator_doc.get("direct_profile") or "").strip() or "local_ollama"

    if launch_mode_arg != "auto":
        launch_mode = launch_mode_arg
    elif readiness_status == "ready":
        launch_mode = "stack"
    else:
        launch_mode = "direct"

    if planner_profile_arg != "auto":
        planner_profile = planner_profile_arg
    elif launch_mode == "stack":
        planner_profile = "local"
    else:
        planner_profile = direct_profile if direct_profile in {"local_ollama", "local_lmstudio"} else "local_ollama"

    if local_model_route_arg != "auto":
        local_model_route = local_model_route_arg
    elif launch_mode == "stack":
        local_model_route = "gateway_first_local"
    elif planner_profile == "local_lmstudio":
        local_model_route = "direct_local_lmstudio"
    else:
        local_model_route = "direct_local_ollama"

    return launch_mode, planner_profile, local_model_route


def build_commands(*, packet_id: str, launch_mode: str, planner_profile: str) -> tuple[str, str, str | None]:
    if launch_mode == "stack":
        preflight_command = (
            "python3 planningops/scripts/run_monday_local_operator_stack.py "
            f"--execution-mode stack --probe-endpoints on --run-id {packet_id}"
        )
        rollback_command = (
            "python3 planningops/scripts/run_monday_local_operator_stack.py "
            f"--execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id {packet_id}-rollback"
        )
        monday_runtime_entrypoint_command = (
            f"cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local --run-id {packet_id}"
        )
        return preflight_command, rollback_command, monday_runtime_entrypoint_command

    preflight_command = (
        "python3 planningops/scripts/run_monday_local_operator_stack.py "
        f"--execution-mode direct --direct-profile {planner_profile} --probe-endpoints on --run-id {packet_id}"
    )
    rollback_command = "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start"
    monday_runtime_entrypoint_command = (
        f"cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile {planner_profile} --run-id {packet_id}"
    )
    return preflight_command, rollback_command, monday_runtime_entrypoint_command


def main() -> int:
    parser = argparse.ArgumentParser(description="Write a deterministic monday local mission packet from promoted handoff artifacts.")
    parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    parser.add_argument("--handoff-report", default=str(DEFAULT_HANDOFF_REPORT))
    parser.add_argument("--local-operator-report", default=str(DEFAULT_LOCAL_OPERATOR_REPORT))
    parser.add_argument("--packet-id", default=f"monday-local-mission-{utc_timestamp_slug()}")
    parser.add_argument("--planner-profile", choices=PLANNER_PROFILE_CHOICES, default="auto")
    parser.add_argument("--launch-mode", choices=LAUNCH_MODE_CHOICES, default="auto")
    parser.add_argument("--local-model-route", choices=MODEL_ROUTE_CHOICES, default="auto")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    validation_root = resolve_path(args.validation_root)
    handoff_report_path = resolve_path(args.handoff_report)
    local_operator_report_path = resolve_path(args.local_operator_report)
    output_path = None if args.output is None else resolve_path(args.output)

    if not handoff_report_path.exists():
        raise SystemExit(f"handoff report missing: {handoff_report_path}")
    if not local_operator_report_path.exists():
        raise SystemExit(f"local operator report missing: {local_operator_report_path}")
    if not (WORKSPACE_ROOT / CONTRACT_REF).exists():
        raise SystemExit(f"mission packet contract missing: {CONTRACT_REF}")

    handoff_doc = require_dict(load_json(handoff_report_path), "handoff report")
    local_operator_doc = require_dict(load_json(local_operator_report_path), "local operator report")
    handoff_record = require_dict(handoff_doc.get("record"), "handoff report record")

    packet_id = args.packet_id
    latest_packet_path = validation_root / "monday-local-mission-packet.json"
    stamped_packet_path = validation_root / f"{packet_id}-monday-local-mission-packet.json"

    launch_mode, planner_profile, local_model_route = choose_launch_parameters(
        local_operator_doc=local_operator_doc,
        planner_profile_arg=args.planner_profile,
        launch_mode_arg=args.launch_mode,
        local_model_route_arg=args.local_model_route,
    )
    preflight_command, rollback_command, monday_runtime_entrypoint_command = build_commands(
        packet_id=packet_id,
        launch_mode=launch_mode,
        planner_profile=planner_profile,
    )

    immediate_actions = [str(line) for line in list(handoff_record.get("immediate_action_lines") or []) if str(line).strip()]
    target_lines = [str(line) for line in list(handoff_record.get("target_lines") or []) if str(line).strip()]
    mission_objective = build_mission_objective(handoff_record)
    (
        local_validation_snapshot_status,
        local_validation_records,
        local_validation_summary_lines,
        local_validation_action_lines,
    ) = build_local_validation_snapshot(handoff_record)
    (
        cross_repo_validation_snapshot_status,
        cross_repo_validation_snapshot_summary,
        cross_repo_validation_action_line,
        cross_repo_validation_detail_lines,
        monday_source_validation_report_lines,
        cross_repo_validation_action_lines,
    ) = build_cross_repo_validation_snapshot(handoff_record)
    cross_repo_validation_packet_report_id = normalize_optional_string(
        handoff_record.get("cross_repo_validation_packet_report_id")
    )
    cross_repo_validation_packet_path = normalize_optional_string(
        handoff_record.get("cross_repo_validation_packet_path")
    )
    if should_promote_cross_repo_primary_action(
        immediate_actions=immediate_actions,
        cross_repo_validation_action_line=cross_repo_validation_action_line,
        cross_repo_validation_packet_report_id=cross_repo_validation_packet_report_id,
        cross_repo_validation_packet_path=cross_repo_validation_packet_path,
    ):
        immediate_actions = prepend_once(immediate_actions, cross_repo_validation_action_line)
    primary_action = immediate_actions[0] if immediate_actions else (target_lines[0] if target_lines else mission_objective)
    cross_repo_validation_steering_scope, cross_repo_validation_primary_action_promoted = (
        build_cross_repo_validation_steering(
            primary_action=primary_action,
            cross_repo_validation_action_line=cross_repo_validation_action_line,
            cross_repo_validation_packet_report_id=cross_repo_validation_packet_report_id,
            cross_repo_validation_packet_path=cross_repo_validation_packet_path,
        )
    )

    expected_evidence_outputs = [
        str(latest_packet_path.resolve()),
        str(stamped_packet_path.resolve()),
        str((WORKSPACE_ROOT / "planningops/runtime-artifacts/local/monday-local-operator-stack" / f"{packet_id}.json").resolve()),
        str((WORKSPACE_ROOT / "planningops/runtime-artifacts/local/monday-local-operator-stack" / packet_id).resolve()),
        str((validation_root / "monday-local-operator-stack-report.json").resolve()),
        str((validation_root / f"{packet_id}-monday-local-operator-stack-report.json").resolve()),
    ]
    if cross_repo_validation_packet_path is not None:
        expected_evidence_outputs.append(cross_repo_validation_packet_path)

    mission_packet = {
        "version": "v1",
        "packet_id": packet_id,
        "mission_objective": mission_objective,
        "mission_prompt": (
            f"Use monday planner profile `{planner_profile}` via `{local_model_route}`. "
            f"Start with `{primary_action}` and preserve the expected evidence outputs."
        ),
        "planner_profile": planner_profile,
        "launch_mode": launch_mode,
        "local_model_route": local_model_route,
        "source_kind": str(handoff_record.get("source_kind") or "unknown"),
        "attention_summary": str(handoff_record.get("attention_summary") or ""),
        "newest_failing_summary": str(handoff_record.get("newest_failing_summary") or ""),
        "local_runtime_summary": str(handoff_record.get("local_operator_summary") or ""),
        "local_runtime_next_step": str(handoff_record.get("local_operator_next_step") or ""),
        "primary_action": primary_action,
        "cross_repo_validation_steering_scope": cross_repo_validation_steering_scope,
        "cross_repo_validation_primary_action_promoted": cross_repo_validation_primary_action_promoted,
        "immediate_actions": immediate_actions,
        "target_lines": target_lines,
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
        "preflight_command": preflight_command,
        "monday_runtime_entrypoint_command": monday_runtime_entrypoint_command,
        "rollback_command": rollback_command,
        "expected_evidence_outputs": expected_evidence_outputs,
        "source_artifacts": {
            "handoff_report_path": str(handoff_report_path.resolve()),
            "local_operator_report_path": str(local_operator_report_path.resolve()),
        },
    }

    packet_doc = {
        "generated_at_utc": now_utc(),
        "packet_id": packet_id,
        "contract_ref": CONTRACT_REF,
        "artifact_paths": {
            "latest_packet_path": str(latest_packet_path.resolve()),
            "stamped_packet_path": str(stamped_packet_path.resolve()),
            "output_path": None if output_path is None else str(output_path.resolve()),
        },
        "mission_packet": mission_packet,
    }

    for path in {latest_packet_path, stamped_packet_path}:
        write_json(path, packet_doc)
    if output_path is not None:
        write_json(output_path, packet_doc)

    print(json.dumps(packet_doc, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
