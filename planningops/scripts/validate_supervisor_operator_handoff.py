#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-report.schema.json"
DEFAULT_PAYLOAD_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-inbox-payload.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/supervisor-operator-handoff-validation.json"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def resolve_doc_path(value) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = (WORKSPACE_ROOT / path).resolve()
    else:
        path = path.resolve()
    return path


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def _resolve_ref(root_schema, ref):
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ValueError(f"unsupported schema ref: {ref}")
    cursor = root_schema
    for token in ref[2:].split("/"):
        cursor = cursor[token]
    return cursor


def _is_type(value, type_name: str) -> bool:
    if type_name == "object":
        return isinstance(value, dict)
    if type_name == "array":
        return isinstance(value, list)
    if type_name == "string":
        return isinstance(value, str)
    if type_name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "boolean":
        return isinstance(value, bool)
    if type_name == "null":
        return value is None
    return True


def _validate_schema_value(value, schema, root_schema, path: str, errors: list[str]) -> None:
    if not isinstance(schema, dict):
        return

    if "$ref" in schema:
        schema = _resolve_ref(root_schema, schema["$ref"])

    expected_type = schema.get("type")
    if isinstance(expected_type, list):
        if not any(_is_type(value, type_name) for type_name in expected_type):
            append_unique(errors, f"schema: {path} expected type in {expected_type}")
            return
    elif expected_type and not _is_type(value, expected_type):
        append_unique(errors, f"schema: {path} expected type {expected_type}")
        return

    if "enum" in schema and value not in schema["enum"]:
        append_unique(errors, f"schema: {path} invalid enum value: {value}")

    if isinstance(value, str):
        min_len = schema.get("minLength")
        if isinstance(min_len, int) and len(value) < min_len:
            append_unique(errors, f"schema: {path} minLength violation")

    if isinstance(value, int) and not isinstance(value, bool):
        minimum = schema.get("minimum")
        if isinstance(minimum, int) and value < minimum:
            append_unique(errors, f"schema: {path} below minimum {minimum}")

    if isinstance(value, dict):
        required = schema.get("required", [])
        props = schema.get("properties", {})
        for key in required:
            if key not in value:
                append_unique(errors, f"schema: {path}.{key} is required")
        additional_props = schema.get("additionalProperties", True)
        for key, child_value in value.items():
            if key in props:
                continue
            if additional_props is False:
                append_unique(errors, f"schema: {path} unexpected key: {key}")
                continue
            if isinstance(additional_props, dict):
                _validate_schema_value(child_value, additional_props, root_schema, f"{path}.{key}", errors)
        for key, prop_schema in props.items():
            if key in value:
                _validate_schema_value(value[key], prop_schema, root_schema, f"{path}.{key}", errors)

    if isinstance(value, list):
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for idx, row in enumerate(value):
                _validate_schema_value(row, item_schema, root_schema, f"{path}[{idx}]", errors)


def validate_schema(doc, schema_doc):
    errors: list[str] = []
    if not isinstance(doc, dict):
        return ["document must be object"]
    if not isinstance(schema_doc, dict):
        return ["schema document must be object"]
    _validate_schema_value(doc, schema_doc, schema_doc, "$", errors)
    return errors


def _validate_iso8601(value: str, field: str, errors: list[str]) -> None:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        append_unique(errors, f"{field} must be an ISO-8601 timestamp")


def _require_equal(errors: list[str], report_doc: dict, payload_doc: dict, report_key: str, payload_key: str | None = None) -> None:
    effective_payload_key = payload_key or report_key
    report_value = report_doc.get(report_key)
    payload_value = payload_doc.get(effective_payload_key)
    if report_value != payload_value:
        append_unique(errors, f"{effective_payload_key} must match operator-report.{report_key}")


def _require_attachment(errors: list[str], attachment_paths: set[Path], value, label: str) -> None:
    path = resolve_doc_path(value)
    if path is None:
        return
    if path not in attachment_paths:
        append_unique(errors, f"attachments must include {label}")


def derive_message_class_hint(report_doc: dict) -> str:
    stop_reason = str(report_doc.get("stop_reason") or "")
    status = str(report_doc.get("status") or "")
    needs_human_attention = bool(report_doc.get("needs_human_attention"))
    if stop_reason == "goal_completed":
        return "goal_completed"
    if status == "blocked":
        return "blocked_report"
    if needs_human_attention:
        return "decision_request"
    return "status_update"


def validate_semantics(report_doc: dict, payload_doc: dict, operator_summary_path: Path | None):
    errors: list[str] = []
    warnings: list[str] = []

    for field, doc in (
        ("operator_report.generated_at_utc", report_doc),
        ("inbox_payload.generated_at_utc", payload_doc),
    ):
        value = doc.get("generated_at_utc")
        if isinstance(value, str):
            _validate_iso8601(value, field, errors)

    expected_hint = derive_message_class_hint(report_doc)
    if report_doc.get("message_class_hint") != expected_hint:
        append_unique(errors, "operator-report.message_class_hint must follow deterministic mapping")
    if payload_doc.get("message_class_hint") != expected_hint:
        append_unique(errors, "inbox-payload.message_class_hint must match deterministic mapping")

    for key in (
        "status",
        "headline",
        "priority_headline",
        "operator_action",
        "recommended_wait_minutes",
        "retry_mode",
        "needs_human_attention",
        "message_class_hint",
        "handoff_contract_ref",
        "priority_summary_markdown",
        "operator_handoff_validation_path",
        "priority_preview_ref",
        "priority_display_packet_ref",
        "operator_handoff_bundle_path",
        "operator_handoff_bundle_validation_path",
        "operator_handoff_bundle_readiness_path",
        "operator_handoff_bundle_readiness_validation_path",
    ):
        _require_equal(errors, report_doc, payload_doc, key)

    for key in (
        "first_action_command",
        "priority_cta_command",
        "goal_key",
        "goal_transition_report_path",
        "primary_operator_channel",
        "terminal_notification_channel",
    ):
        report_has = key in report_doc
        payload_has = key in payload_doc
        if report_has != payload_has:
            append_unique(errors, f"{key} presence must match between operator-report and inbox-payload")
        elif report_has:
            _require_equal(errors, report_doc, payload_doc, key)

    payload_title = str(payload_doc.get("title") or "")
    expected_title_prefix = f"[{str(report_doc.get('status') or '').upper()}] "
    if not payload_title.startswith(expected_title_prefix):
        append_unique(errors, "inbox-payload.title must start with uppercased status prefix")
    priority_headline = str(report_doc.get("priority_headline") or "")
    if priority_headline and priority_headline not in payload_title:
        append_unique(errors, "inbox-payload.title must include priority_headline")

    attachments = payload_doc.get("attachments")
    attachment_paths: set[Path] = set()
    if isinstance(attachments, list):
        for idx, value in enumerate(attachments):
            if not isinstance(value, str) or not value.strip():
                append_unique(errors, f"attachments[{idx}] must be a non-empty string")
                continue
            resolved = resolve_doc_path(value)
            if resolved is not None:
                attachment_paths.add(resolved)
    else:
        append_unique(errors, "attachments must be an array")

    _require_attachment(errors, attachment_paths, report_doc.get("summary_path"), "operator-report.summary_path")
    _require_attachment(errors, attachment_paths, report_doc.get("cycle_report_path"), "operator-report.cycle_report_path")
    _require_attachment(
        errors,
        attachment_paths,
        report_doc.get("goal_completion_delivery_report_path"),
        "operator-report.goal_completion_delivery_report_path",
    )
    if operator_summary_path is not None:
        if operator_summary_path.resolve() not in attachment_paths:
            append_unique(errors, "attachments must include operator summary path")
    _require_attachment(
        errors,
        attachment_paths,
        payload_doc.get("operator_handoff_validation_path"),
        "inbox-payload.operator_handoff_validation_path",
    )
    for label, key in (
        ("operator-report.operator_handoff_bundle_path", "operator_handoff_bundle_path"),
        ("operator-report.operator_handoff_bundle_validation_path", "operator_handoff_bundle_validation_path"),
        ("operator-report.operator_handoff_bundle_readiness_path", "operator_handoff_bundle_readiness_path"),
        (
            "operator-report.operator_handoff_bundle_readiness_validation_path",
            "operator_handoff_bundle_readiness_validation_path",
        ),
    ):
        _require_attachment(errors, attachment_paths, report_doc.get(key), label)

    federated_summary = report_doc.get("federated_ci_summary")
    if isinstance(federated_summary, dict):
        _require_attachment(errors, attachment_paths, federated_summary.get("summary_path"), "federated summary_path")
        _require_attachment(errors, attachment_paths, federated_summary.get("readiness_path"), "federated readiness_path")
        _require_attachment(
            errors,
            attachment_paths,
            federated_summary.get("validation_report_path"),
            "federated validation_report_path",
        )
        if federated_summary.get("ready") is False and report_doc.get("status") == "ok":
            append_unique(errors, "operator-report status=ok is invalid when federated_ci_summary.ready=false")
        remediation_commands = list(federated_summary.get("remediation_commands") or [])
        if remediation_commands:
            first_command = remediation_commands[0]
            if report_doc.get("first_action_command") != first_command:
                append_unique(errors, "operator-report.first_action_command must promote the first remediation command")
            if payload_doc.get("first_action_command") != first_command:
                append_unique(errors, "inbox-payload.first_action_command must promote the first remediation command")
            if report_doc.get("priority_cta_command") != first_command:
                append_unique(errors, "operator-report.priority_cta_command must match the first remediation command")

    body_markdown = str(payload_doc.get("body_markdown") or "")
    priority_summary_markdown = str(report_doc.get("priority_summary_markdown") or "")
    if priority_summary_markdown and priority_summary_markdown not in body_markdown:
        append_unique(errors, "inbox-payload.body_markdown must embed priority_summary_markdown")

    promoted_command = str(report_doc.get("first_action_command") or "").strip()
    if promoted_command:
        if "First Action:" not in body_markdown:
            append_unique(errors, "inbox-payload.body_markdown must include a First Action section")
        if promoted_command not in body_markdown:
            append_unique(errors, "inbox-payload.body_markdown must include the promoted command")

    if operator_summary_path is not None:
        if not operator_summary_path.exists():
            append_unique(errors, "operator summary markdown path does not exist")
        else:
            operator_summary = operator_summary_path.read_text(encoding="utf-8")
            headline = str(report_doc.get("headline") or "")
            if headline and headline not in operator_summary:
                append_unique(errors, "operator summary markdown must include headline")
            if priority_summary_markdown and priority_summary_markdown not in operator_summary:
                append_unique(errors, "operator summary markdown must embed priority_summary_markdown")
            if promoted_command and promoted_command not in operator_summary:
                append_unique(errors, "operator summary markdown must include the promoted command")
            handoff_validation_path = str(payload_doc.get("operator_handoff_validation_path") or "").strip()
            if handoff_validation_path and handoff_validation_path not in operator_summary:
                append_unique(errors, "operator summary markdown must include operator_handoff_validation_path")
            for key in (
                "operator_handoff_bundle_path",
                "operator_handoff_bundle_validation_path",
                "operator_handoff_bundle_readiness_path",
                "operator_handoff_bundle_readiness_validation_path",
            ):
                value = str(report_doc.get(key) or "").strip()
                if value and value not in operator_summary:
                    append_unique(errors, f"operator summary markdown must include {key}")

    return errors, warnings


def build_report(
    operator_report_path: Path,
    inbox_payload_path: Path,
    operator_summary_path: Path | None,
    operator_report_doc: dict,
    inbox_payload_doc: dict,
    report_schema_path: Path,
    payload_schema_path: Path,
    report_schema_doc: dict,
    payload_schema_doc: dict,
) -> dict:
    schema_errors = validate_schema(operator_report_doc, report_schema_doc)
    schema_errors.extend(validate_schema(inbox_payload_doc, payload_schema_doc))
    semantic_errors, warnings = validate_semantics(operator_report_doc, inbox_payload_doc, operator_summary_path)
    errors = schema_errors + semantic_errors
    doc = {
        "generated_at_utc": now_utc(),
        "operator_report_path": str(operator_report_path.resolve()),
        "operator_report_run_id": operator_report_doc.get("run_id"),
        "operator_report_status": operator_report_doc.get("status"),
        "inbox_payload_path": str(inbox_payload_path.resolve()),
        "inbox_payload_status": inbox_payload_doc.get("status"),
        "inbox_payload_title": inbox_payload_doc.get("title"),
        "operator_report_schema_path": str(report_schema_path.resolve()),
        "inbox_payload_schema_path": str(payload_schema_path.resolve()),
        "operator_handoff_validation_path": operator_report_doc.get("operator_handoff_validation_path"),
        "priority_preview_ref": operator_report_doc.get("priority_preview_ref"),
        "priority_display_packet_ref": operator_report_doc.get("priority_display_packet_ref"),
        "operator_handoff_bundle_path": operator_report_doc.get("operator_handoff_bundle_path"),
        "operator_handoff_bundle_validation_path": operator_report_doc.get("operator_handoff_bundle_validation_path"),
        "operator_handoff_bundle_readiness_path": operator_report_doc.get("operator_handoff_bundle_readiness_path"),
        "operator_handoff_bundle_readiness_validation_path": operator_report_doc.get(
            "operator_handoff_bundle_readiness_validation_path"
        ),
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }
    if operator_summary_path is not None:
        doc["operator_summary_path"] = str(operator_summary_path.resolve())
    return doc


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate supervisor operator handoff artifacts")
    parser.add_argument("--operator-report", required=True)
    parser.add_argument("--inbox-payload", required=True)
    parser.add_argument("--operator-summary")
    parser.add_argument("--operator-report-schema", default=str(DEFAULT_REPORT_SCHEMA))
    parser.add_argument("--inbox-payload-schema", default=str(DEFAULT_PAYLOAD_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    operator_report_path = Path(args.operator_report)
    inbox_payload_path = Path(args.inbox_payload)
    operator_summary_path = Path(args.operator_summary).resolve() if args.operator_summary else None
    report_schema_path = Path(args.operator_report_schema)
    payload_schema_path = Path(args.inbox_payload_schema)
    output_path = Path(args.output)

    operator_report_doc = load_json(operator_report_path)
    inbox_payload_doc = load_json(inbox_payload_path)
    report_schema_doc = load_json(report_schema_path)
    payload_schema_doc = load_json(payload_schema_path)

    report = build_report(
        operator_report_path=operator_report_path,
        inbox_payload_path=inbox_payload_path,
        operator_summary_path=operator_summary_path,
        operator_report_doc=operator_report_doc,
        inbox_payload_doc=inbox_payload_doc,
        report_schema_path=report_schema_path,
        payload_schema_path=payload_schema_path,
        report_schema_doc=report_schema_doc,
        payload_schema_doc=payload_schema_doc,
    )
    write_json(output_path, report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
