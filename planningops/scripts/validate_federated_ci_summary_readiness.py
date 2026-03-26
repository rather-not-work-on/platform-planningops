#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/federated-ci-summary-readiness.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness-validation.json"
DEFAULT_LATEST_READINESS = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness.json"
DEFAULT_LATEST_SUMMARY = WORKSPACE_ROOT / "planningops/artifacts/ci/federated-ci-summary.json"
DEFAULT_LATEST_SUMMARY_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-validation.json"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def resolve_doc_path(value) -> Path | None:
    if not isinstance(value, str) or not value:
        return None
    path = Path(value)
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


def validate_semantics(doc: dict, readiness_path: Path):
    errors: list[str] = []
    warnings: list[str] = []

    generated_at_utc = doc.get("generated_at_utc")
    if isinstance(generated_at_utc, str):
        _validate_iso8601(generated_at_utc, "generated_at_utc", errors)

    summary_present = doc.get("summary_present")
    validation_present = doc.get("validation_present")
    summary_generated_at_utc = doc.get("summary_generated_at_utc")
    summary_verdict = doc.get("summary_verdict")
    validation_verdict = doc.get("validation_verdict")
    validation_state = doc.get("validation_state")
    ready = doc.get("ready")
    readiness_status = doc.get("readiness_status")
    blocking_reasons = list(doc.get("blocking_reasons") or [])
    failed_checks = list(doc.get("failed_checks") or [])
    missing_required = list(doc.get("missing_required_checks") or [])
    next_step = doc.get("next_step")
    summary_path_value = doc.get("summary_path")
    validation_report_path_value = doc.get("validation_report_path")

    if summary_present is False:
        if blocking_reasons != ["summary_missing"]:
            append_unique(errors, "summary_missing must be the only blocking reason when summary is absent")
        if ready is not False or readiness_status != "blocked":
            append_unique(errors, "absent summary must yield blocked readiness")
    else:
        if not isinstance(summary_generated_at_utc, str) or not summary_generated_at_utc:
            append_unique(errors, "summary_generated_at_utc must be present when summary_present=true")
        else:
            _validate_iso8601(summary_generated_at_utc, "summary_generated_at_utc", errors)
        if summary_verdict is None:
            append_unique(errors, "summary_verdict must be present when summary_present=true")
        if not isinstance(summary_path_value, str) or not summary_path_value:
            append_unique(errors, "summary_path must be present when summary_present=true")

    if validation_present is not False and (not isinstance(validation_report_path_value, str) or not validation_report_path_value):
        append_unique(errors, "validation_report_path must be present when validation_present=true")

    if validation_present is False and validation_verdict != "missing":
        append_unique(errors, "validation_verdict must be missing when validation_present=false")
    if validation_state == "fresh" and validation_verdict != "pass":
        append_unique(errors, "validation_state=fresh requires validation_verdict=pass")
    if validation_state == "stale" and "validation_stale" not in blocking_reasons:
        append_unique(errors, "validation_state=stale requires validation_stale blocking reason")
    if validation_state == "missing" and validation_present is not False and validation_verdict == "pass":
        warnings.append("validation_state missing despite validation verdict pass")

    if ready is True:
        if readiness_status != "ready":
            append_unique(errors, "ready=true requires readiness_status=ready")
        if blocking_reasons:
            append_unique(errors, "ready=true requires no blocking_reasons")
        if summary_verdict != "pass":
            append_unique(errors, "ready=true requires summary_verdict=pass")
        if validation_verdict != "pass" or validation_state != "fresh":
            append_unique(errors, "ready=true requires validation_verdict=pass and validation_state=fresh")
        if next_step != "none":
            append_unique(errors, "ready=true requires next_step=none")
    else:
        if readiness_status != "blocked":
            append_unique(errors, "ready=false requires readiness_status=blocked")
        if not blocking_reasons:
            append_unique(errors, "ready=false requires at least one blocking reason")
        if next_step == "none":
            append_unique(errors, "ready=false requires a remediation next_step")

    if failed_checks and summary_verdict != "fail":
        append_unique(errors, "failed_checks require summary_verdict=fail")
    if missing_required and summary_verdict != "fail":
        append_unique(errors, "missing_required_checks require summary_verdict=fail")

    canonical_latest_readiness = (Path.cwd() / DEFAULT_LATEST_READINESS).resolve()
    if readiness_path.resolve() == canonical_latest_readiness:
        expected_summary = (Path.cwd() / DEFAULT_LATEST_SUMMARY).resolve()
        expected_validation = (Path.cwd() / DEFAULT_LATEST_SUMMARY_VALIDATION).resolve()
        actual_summary = resolve_doc_path(summary_path_value)
        actual_validation = resolve_doc_path(validation_report_path_value)
        if actual_summary != expected_summary:
            append_unique(
                errors,
                f"canonical latest readiness must reference latest summary path: {DEFAULT_LATEST_SUMMARY}",
            )
        if actual_validation != expected_validation:
            append_unique(
                errors,
                f"canonical latest readiness must reference latest summary validation path: {DEFAULT_LATEST_SUMMARY_VALIDATION}",
            )

    return errors, warnings


def build_report(readiness_path: Path, schema_path: Path, readiness_doc: dict, schema_doc: dict) -> dict:
    schema_errors = validate_schema(readiness_doc, schema_doc)
    semantic_errors, warnings = validate_semantics(readiness_doc, readiness_path)
    errors = schema_errors + semantic_errors
    return {
        "generated_at_utc": now_utc(),
        "readiness_path": str(readiness_path.resolve()),
        "readiness_generated_at_utc": readiness_doc.get("generated_at_utc"),
        "readiness_summary_run_id": readiness_doc.get("summary_run_id"),
        "readiness_status": readiness_doc.get("readiness_status"),
        "readiness_ready": readiness_doc.get("ready"),
        "schema_path": str(schema_path.resolve()),
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate federated CI summary readiness artifact")
    parser.add_argument("--readiness", required=True)
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    readiness_path = Path(args.readiness)
    schema_path = Path(args.schema_file)
    readiness_doc = load_json(readiness_path)
    schema_doc = load_json(schema_path)
    report = build_report(readiness_path, schema_path, readiness_doc, schema_doc)

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = (Path.cwd() / output_path).resolve()
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"error_count={report['error_count']} warning_count={report['warning_count']} verdict={report['verdict']}")
    return 0 if report["verdict"] == "pass" or not args.strict else 1


if __name__ == "__main__":
    sys.exit(main())
