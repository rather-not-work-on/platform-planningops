#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import validate_monday_agent_harness_projection as projection_validation

from doctor_monday_agent_harness_projection import build_status


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATUS = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-status.json"
DEFAULT_BUNDLE = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-bundle.json"
DEFAULT_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-validation.json"
DEFAULT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/monday-agent-harness-projection-status.schema.json"
DEFAULT_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT / "planningops/schemas/monday-agent-harness-projection-status-validation.schema.json"
)
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-status-validation.json"


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def validate_semantics(
    status_path: Path,
    status_doc: dict[str, Any],
    *,
    expected_status: dict[str, Any],
    output_path: Path,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    generated_at_utc = status_doc.get("generated_at_utc")
    if not isinstance(generated_at_utc, str) or not generated_at_utc.strip():
        append_unique(errors, "generated_at_utc must be a non-empty string")
    if status_doc.get("output_path") != str(status_path.resolve()):
        append_unique(errors, "output_path must match the validated status path")
    if status_doc.get("status_validation_output_path") != str(output_path.resolve()):
        append_unique(errors, "status_validation_output_path must match the validation output path")

    for field in (
        "bundle_path",
        "validation_report_path",
        "bundle_present",
        "validation_present",
        "projection_root",
        "monday_root",
        "mission_id",
        "run_id",
        "session_id",
        "final_status",
        "readiness_status",
        "verification_verdict",
        "handoff_status",
        "next_required_actor",
        "recommended_next_step",
        "ready",
        "validation_verdict",
        "validation_state",
        "next_step",
    ):
        if status_doc.get(field) != expected_status.get(field):
            append_unique(errors, f"{field} must match canonical monday harness projection doctor status")

    return errors, warnings


def build_validation_report(
    *,
    status_path: Path,
    bundle_path: Path,
    validation_path: Path,
    schema_path: Path,
    validation_schema_path: Path,
    output_path: Path,
) -> dict[str, Any]:
    status_doc = projection_validation.load_json(status_path)
    validation_doc = projection_validation.load_json(validation_path)
    schema_doc = projection_validation.load_json(schema_path)
    validation_schema_doc = projection_validation.load_json(validation_schema_path)
    schema_errors = projection_validation.validate_schema(status_doc, schema_doc)
    expected_status = build_status(validation_doc, bundle_path=bundle_path.resolve(), validation_path=validation_path.resolve())
    semantic_errors, warnings = validate_semantics(
        status_path.resolve(),
        status_doc,
        expected_status=expected_status,
        output_path=output_path.resolve(),
    )
    errors = schema_errors + semantic_errors

    report = {
        "status_path": str(status_path.resolve()),
        "bundle_path": str(bundle_path.resolve()),
        "validation_report_path": str(validation_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "validation_schema_path": str(validation_schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": projection_validation.now_utc(),
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "status_generated_at_utc": status_doc.get("generated_at_utc"),
        "status_output_path": status_doc.get("output_path"),
        "status_validation_output_path": status_doc.get("status_validation_output_path"),
        "status_mission_id": status_doc.get("mission_id"),
        "status_run_id": status_doc.get("run_id"),
        "status_session_id": status_doc.get("session_id"),
        "status_ready": status_doc.get("ready"),
        "projection_status_verdict": "pass" if status_doc.get("ready") is True else "fail",
        "projection_validation_verdict": validation_doc.get("verdict"),
        "projection_validation_state": status_doc.get("validation_state"),
        "status_validation_verdict": status_doc.get("validation_verdict"),
        "status_validation_state": status_doc.get("validation_state"),
        "status_next_step": status_doc.get("next_step"),
    }
    validation_errors = projection_validation.validate_schema(report, validation_schema_doc)
    if validation_errors:
        report["errors"] = report["errors"] + validation_errors
        report["error_count"] = len(report["errors"])
        report["verdict"] = "fail"
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate monday agent harness projection status artifacts.")
    parser.add_argument("--status-file", default=str(DEFAULT_STATUS))
    parser.add_argument("--bundle-file", default=str(DEFAULT_BUNDLE))
    parser.add_argument("--validation-report", default=str(DEFAULT_VALIDATION))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--validation-schema-file", default=str(DEFAULT_VALIDATION_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_validation_report(
        status_path=Path(args.status_file),
        bundle_path=Path(args.bundle_file),
        validation_path=Path(args.validation_report),
        schema_path=Path(args.schema_file),
        validation_schema_path=Path(args.validation_schema_file),
        output_path=Path(args.output),
    )
    projection_validation.write_json(Path(args.output), report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
