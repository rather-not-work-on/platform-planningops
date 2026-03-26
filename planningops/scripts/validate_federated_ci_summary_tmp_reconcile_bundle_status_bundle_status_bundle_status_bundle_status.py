#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import validate_plain_python_compat_manifest as schema_validation

from doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle import build_status


WORKSPACE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_STATUS = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_BUNDLE = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"
)
DEFAULT_BUNDLE_VALIDATION = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"
)
DEFAULT_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
)


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
        "artifact_file",
        "status_path",
        "status_validation_path",
        "nested_bundle_path",
        "nested_bundle_validation_report_path",
        "run_id",
        "reconcile_status",
        "check_name",
        "reconcile_count",
        "reconcile_validation_verdict",
        "bundle_validation_verdict",
        "bundle_validation_state",
        "ready",
        "next_step",
    ):
        if status_doc.get(field) != expected_status.get(field):
            append_unique(errors, f"{field} must match canonical status-bundle-status bundle status bundle doctor status")

    return errors, warnings


def build_validation_report(
    *,
    status_path: Path,
    bundle_path: Path,
    bundle_validation_path: Path,
    schema_path: Path,
    validation_schema_path: Path,
    output_path: Path,
) -> dict[str, Any]:
    status_doc = schema_validation.load_json(status_path)
    schema_doc = schema_validation.load_json(schema_path)
    validation_schema_doc = schema_validation.load_json(validation_schema_path)
    schema_errors = schema_validation.validate_schema(status_doc, schema_doc)
    expected_status = build_status(bundle_path.resolve(), bundle_validation_path.resolve())
    semantic_errors, warnings = validate_semantics(
        status_path,
        status_doc,
        expected_status=expected_status,
        output_path=output_path,
    )
    errors = schema_errors + semantic_errors

    report = {
        "status_path": str(status_path.resolve()),
        "bundle_path": str(bundle_path.resolve()),
        "bundle_validation_report_path": str(bundle_validation_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "validation_schema_path": str(validation_schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": schema_validation.now_utc(),
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "status_generated_at_utc": status_doc.get("generated_at_utc"),
        "status_output_path": status_doc.get("output_path"),
        "status_validation_output_path": str(output_path.resolve()),
        "status_run_id": status_doc.get("run_id"),
        "status_reconcile_status": status_doc.get("reconcile_status"),
        "status_check_name": status_doc.get("check_name"),
        "status_reconcile_count": status_doc.get("reconcile_count"),
        "status_reconcile_validation_verdict": status_doc.get("reconcile_validation_verdict"),
        "status_bundle_validation_verdict": status_doc.get("bundle_validation_verdict"),
        "status_bundle_validation_state": status_doc.get("bundle_validation_state"),
        "status_ready": status_doc.get("ready"),
        "status_next_step": status_doc.get("next_step"),
    }
    validation_errors = schema_validation.validate_schema(report, validation_schema_doc)
    if validation_errors:
        report["errors"] = report["errors"] + validation_errors
        report["error_count"] = len(report["errors"])
        report["verdict"] = "fail"
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate federated CI tmp-summary reconcile bundle status-bundle-status bundle status bundle status artifacts."
    )
    parser.add_argument("--status-file", default=str(DEFAULT_STATUS))
    parser.add_argument("--bundle-file", default=str(DEFAULT_BUNDLE))
    parser.add_argument("--bundle-validation-report", default=str(DEFAULT_BUNDLE_VALIDATION))
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
        bundle_validation_path=Path(args.bundle_validation_report),
        schema_path=Path(args.schema_file),
        validation_schema_path=Path(args.validation_schema_file),
        output_path=Path(args.output),
    )
    schema_validation.write_json(Path(args.output), report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
