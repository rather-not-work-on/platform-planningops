#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from validate_supervisor_operator_handoff import (
    append_unique,
    load_json,
    validate_schema,
    write_json,
)


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-bundle-readiness.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/supervisor-operator-handoff-bundle-readiness-validation.json"
HANDOFF_BUNDLE_SIDECAR_FIELDS = (
    ("operator_handoff_bundle_path", "operator_handoff_bundle_path_missing"),
    ("operator_handoff_bundle_validation_path", "operator_handoff_bundle_validation_path_missing"),
    ("operator_handoff_bundle_readiness_path", "operator_handoff_bundle_readiness_path_missing"),
    ("operator_handoff_bundle_readiness_validation_path", "operator_handoff_bundle_readiness_validation_path_missing"),
)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def _validate_iso8601(value: str, field: str, errors: list[str]) -> None:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        append_unique(errors, f"{field} must be an ISO-8601 timestamp")


def validate_semantics(doc: dict) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    generated_at_utc = doc.get("generated_at_utc")
    if isinstance(generated_at_utc, str):
        _validate_iso8601(generated_at_utc, "generated_at_utc", errors)

    source_kind = doc.get("source_kind")
    artifact_file = doc.get("artifact_file")
    bundle_path = doc.get("bundle_path")
    validation_report_path = doc.get("validation_report_path")
    bundle_validation_verdict = doc.get("bundle_validation_verdict")
    operator_handoff_validation_verdict = doc.get("operator_handoff_validation_verdict")
    ready = doc.get("ready")
    readiness_status = doc.get("readiness_status")
    blocking_reasons = list(doc.get("blocking_reasons") or [])
    next_step = doc.get("next_step")
    error_count = doc.get("error_count")
    warning_count = doc.get("warning_count")
    errors_list = list(doc.get("errors") or [])
    warnings_list = list(doc.get("warnings") or [])

    if source_kind == "artifact":
        if not isinstance(artifact_file, str) or not artifact_file:
            append_unique(errors, "artifact source_kind requires artifact_file")
    if source_kind == "bundle":
        if not isinstance(bundle_path, str) or not bundle_path:
            append_unique(errors, "bundle source_kind requires bundle_path")

    if not isinstance(validation_report_path, str) or not validation_report_path:
        append_unique(errors, "validation_report_path must be present")

    if error_count != len(errors_list):
        append_unique(errors, "error_count must match errors length")
    if warning_count != len(warnings_list):
        append_unique(errors, "warning_count must match warnings length")

    if bundle_validation_verdict == "pass" and error_count not in (0, None):
        append_unique(errors, "bundle_validation_verdict=pass requires error_count=0")
    if bundle_validation_verdict == "fail" and error_count == 0:
        append_unique(errors, "bundle_validation_verdict=fail requires error_count>0")

    for field, reason in HANDOFF_BUNDLE_SIDECAR_FIELDS + (
        ("priority_preview_ref", "priority_preview_ref_missing"),
        ("priority_display_packet_ref", "priority_display_packet_ref_missing"),
        ("priority_headline", "priority_headline_missing"),
        ("priority_cta_command", "priority_cta_command_missing"),
        ("display_title", "display_title_missing"),
        ("cta_command", "display_cta_command_missing"),
    ):
        if not isinstance(doc.get(field), str) or not str(doc.get(field) or "").strip():
            if reason not in blocking_reasons:
                append_unique(errors, f"missing {field} requires {reason} blocking reason")

    if operator_handoff_validation_verdict == "fail" and "handoff_validation_fail" not in blocking_reasons:
        append_unique(errors, "handoff_validation_verdict=fail requires handoff_validation_fail blocking reason")
    if bundle_validation_verdict == "fail" and "bundle_validation_fail" not in blocking_reasons:
        append_unique(errors, "bundle_validation_verdict=fail requires bundle_validation_fail blocking reason")

    if ready is True:
        if readiness_status != "ready":
            append_unique(errors, "ready=true requires readiness_status=ready")
        if blocking_reasons:
            append_unique(errors, "ready=true requires no blocking_reasons")
        if bundle_validation_verdict != "pass":
            append_unique(errors, "ready=true requires bundle_validation_verdict=pass")
        if operator_handoff_validation_verdict != "pass":
            append_unique(errors, "ready=true requires operator_handoff_validation_verdict=pass")
        if next_step != "none":
            append_unique(errors, "ready=true requires next_step=none")
    else:
        if readiness_status != "blocked":
            append_unique(errors, "ready=false requires readiness_status=blocked")
        if not blocking_reasons:
            append_unique(errors, "ready=false requires at least one blocking reason")
        if next_step == "none":
            append_unique(errors, "ready=false requires a remediation next_step")

    return errors, warnings


def build_report(readiness_path: Path, schema_path: Path, readiness_doc: dict, schema_doc: dict) -> dict:
    schema_errors = validate_schema(readiness_doc, schema_doc)
    semantic_errors, semantic_warnings = validate_semantics(readiness_doc)
    errors = schema_errors + semantic_errors
    warnings = semantic_warnings
    return {
        "generated_at_utc": now_utc(),
        "readiness_path": str(readiness_path.resolve()),
        "readiness_generated_at_utc": readiness_doc.get("generated_at_utc"),
        "source_kind": readiness_doc.get("source_kind"),
        "artifact_file": readiness_doc.get("artifact_file"),
        "bundle_path": readiness_doc.get("bundle_path"),
        "validation_report_path": readiness_doc.get("validation_report_path"),
        "operator_handoff_bundle_path": readiness_doc.get("operator_handoff_bundle_path"),
        "operator_handoff_bundle_validation_path": readiness_doc.get("operator_handoff_bundle_validation_path"),
        "operator_handoff_bundle_readiness_path": readiness_doc.get("operator_handoff_bundle_readiness_path"),
        "operator_handoff_bundle_readiness_validation_path": readiness_doc.get("operator_handoff_bundle_readiness_validation_path"),
        "readiness_status": readiness_doc.get("readiness_status"),
        "readiness_ready": bool(readiness_doc.get("ready")),
        "schema_path": str(schema_path.resolve()),
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate supervisor operator handoff bundle readiness artifact")
    parser.add_argument("--readiness", required=True)
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    readiness_path = Path(args.readiness).resolve()
    schema_path = Path(args.schema_file).resolve()
    output_path = Path(args.output).resolve()

    readiness_doc = load_json(readiness_path)
    schema_doc = load_json(schema_path)
    report = build_report(readiness_path, schema_path, readiness_doc, schema_doc)
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"verdict={report['verdict']} error_count={report['error_count']}")
    return 0 if report["verdict"] == "pass" or not args.strict else 1


if __name__ == "__main__":
    raise SystemExit(main())
