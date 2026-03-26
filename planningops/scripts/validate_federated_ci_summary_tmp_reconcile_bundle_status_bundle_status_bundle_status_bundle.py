#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import validate_plain_python_compat_manifest as schema_validation

from resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status import (
    resolve_status_bundle_status_bundle_status,
)


WORKSPACE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BUNDLE = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"
)
DEFAULT_BUNDLE_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.schema.json"
)
DEFAULT_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"
)


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def validate_semantics(
    bundle_path: Path | None,
    output_path: Path,
    doc: dict[str, Any],
    canonical_bundle: dict[str, Any] | None,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    if bundle_path is not None and not bundle_path.exists():
        append_unique(errors, "bundle_path must point at an existing bundle")

    path_fields = (
        ("artifact_file", "artifact_file must be a non-empty string", "artifact_file must point at an existing file"),
        ("status_path", "status_path must be a non-empty string", "status_path must point at an existing file"),
        (
            "status_validation_path",
            "status_validation_path must be a non-empty string",
            "status_validation_path must point at an existing file",
        ),
        ("bundle_path", "bundle_path must be a non-empty string", "bundle_path must point at an existing file"),
        (
            "bundle_validation_report_path",
            "bundle_validation_report_path must be a non-empty string",
            "bundle_validation_report_path must point at an existing file",
        ),
    )
    for field, empty_message, missing_message in path_fields:
        value = doc.get(field)
        if not isinstance(value, str) or not value.strip():
            append_unique(errors, empty_message)
            continue
        if not Path(value).exists():
            append_unique(errors, missing_message)

    run_id = doc.get("run_id")
    if not isinstance(run_id, str) or not run_id.strip():
        append_unique(errors, "run_id must be a non-empty string")
    reconcile_status = doc.get("reconcile_status")
    if reconcile_status not in {"healthy", "restored"}:
        append_unique(errors, "reconcile_status must be one of: healthy, restored")
    check_name = doc.get("check_name")
    if check_name is not None and (not isinstance(check_name, str) or not check_name.strip()):
        append_unique(errors, "check_name must be null or a non-empty string")
    reconcile_count = doc.get("reconcile_count")
    if not isinstance(reconcile_count, int) or isinstance(reconcile_count, bool) or reconcile_count < 0:
        append_unique(errors, "reconcile_count must be a non-negative integer")
    if not isinstance(doc.get("ready"), bool):
        append_unique(errors, "ready must be a boolean")
    next_step = doc.get("next_step")
    if not isinstance(next_step, str) or not next_step.strip():
        append_unique(errors, "next_step must be a non-empty string")

    status_report = doc.get("status_report")
    if not isinstance(status_report, dict):
        append_unique(errors, "status_report must be an object")
    else:
        if status_report.get("output_path") != doc.get("status_path"):
            append_unique(errors, "status_report.output_path must match status_path")
        if status_report.get("status_validation_output_path") != doc.get("status_validation_path"):
            append_unique(errors, "status_report.status_validation_output_path must match status_validation_path")
        if status_report.get("bundle_path") != doc.get("bundle_path"):
            append_unique(errors, "status_report.bundle_path must match bundle_path")
        if status_report.get("validation_report_path") != doc.get("bundle_validation_report_path"):
            append_unique(errors, "status_report.validation_report_path must match bundle_validation_report_path")
        for field in (
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
            if status_report.get(field) != doc.get(field):
                append_unique(errors, f"{field} must match status_report.{field}")

    status_validation_report = doc.get("status_validation_report")
    if not isinstance(status_validation_report, dict):
        append_unique(errors, "status_validation_report must be an object")
    else:
        if status_validation_report.get("status_path") != doc.get("status_path"):
            append_unique(errors, "status_validation_report.status_path must match status_path")
        if status_validation_report.get("output_path") != doc.get("status_validation_path"):
            append_unique(errors, "status_validation_report.output_path must match status_validation_path")
        if status_validation_report.get("status_output_path") != doc.get("status_path"):
            append_unique(errors, "status_validation_report.status_output_path must match status_path")
        if status_validation_report.get("status_validation_output_path") != doc.get("status_validation_path"):
            append_unique(errors, "status_validation_report.status_validation_output_path must match status_validation_path")
        if status_validation_report.get("bundle_path") != doc.get("bundle_path"):
            append_unique(errors, "status_validation_report.bundle_path must match bundle_path")
        if status_validation_report.get("bundle_validation_report_path") != doc.get("bundle_validation_report_path"):
            append_unique(
                errors,
                "status_validation_report.bundle_validation_report_path must match bundle_validation_report_path",
            )
        if status_validation_report.get("verdict") != "pass":
            append_unique(errors, "status_validation_report.verdict must be pass")
        for doc_field, validation_field in (
            ("run_id", "status_run_id"),
            ("reconcile_status", "status_reconcile_status"),
            ("check_name", "status_check_name"),
            ("reconcile_count", "status_reconcile_count"),
            ("reconcile_validation_verdict", "status_reconcile_validation_verdict"),
            ("bundle_validation_verdict", "status_bundle_validation_verdict"),
            ("bundle_validation_state", "status_bundle_validation_state"),
            ("ready", "status_ready"),
            ("next_step", "status_next_step"),
        ):
            if status_validation_report.get(validation_field) != doc.get(doc_field):
                append_unique(errors, f"{doc_field} must match status_validation_report.{validation_field}")

    if canonical_bundle is not None:
        canonical = dict(canonical_bundle)
        actual = dict(doc)
        canonical.pop("generated_at_utc", None)
        actual.pop("generated_at_utc", None)
        if actual != canonical:
            append_unique(
                errors,
                "bundle does not match canonical tmp-summary reconcile bundle status-bundle-status bundle status resolution",
            )

    return errors, warnings


def build_validation_report(
    *,
    bundle_path: Path | None,
    bundle_doc: dict[str, Any],
    bundle_schema_path: Path,
    validation_schema_path: Path,
    output_path: Path,
    canonical_bundle: dict[str, Any] | None,
) -> dict[str, Any]:
    bundle_schema = schema_validation.load_json(bundle_schema_path)
    validation_schema = schema_validation.load_json(validation_schema_path)
    schema_errors = schema_validation.validate_schema(bundle_doc, bundle_schema)
    semantic_errors, warnings = validate_semantics(bundle_path, output_path, bundle_doc, canonical_bundle)
    errors = schema_errors + semantic_errors

    report = {
        "generated_at_utc": schema_validation.now_utc(),
        "bundle_path": None if bundle_path is None else str(bundle_path.resolve()),
        "artifact_file": bundle_doc.get("artifact_file"),
        "bundle_generated_at_utc": bundle_doc.get("generated_at_utc"),
        "bundle_schema_path": str(bundle_schema_path.resolve()),
        "validation_schema_path": str(validation_schema_path.resolve()),
        "status_path": bundle_doc.get("status_path"),
        "status_validation_path": bundle_doc.get("status_validation_path"),
        "run_id": bundle_doc.get("run_id"),
        "reconcile_status": bundle_doc.get("reconcile_status"),
        "check_name": bundle_doc.get("check_name"),
        "reconcile_count": bundle_doc.get("reconcile_count"),
        "reconcile_validation_verdict": bundle_doc.get("reconcile_validation_verdict"),
        "bundle_validation_verdict": bundle_doc.get("bundle_validation_verdict"),
        "bundle_validation_state": bundle_doc.get("bundle_validation_state"),
        "ready": bundle_doc.get("ready"),
        "next_step": bundle_doc.get("next_step"),
        "output_path": str(output_path.resolve()),
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }

    validation_errors = schema_validation.validate_schema(report, validation_schema)
    if validation_errors:
        report["errors"] = report["errors"] + validation_errors
        report["error_count"] = len(report["errors"])
        report["verdict"] = "fail"

    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate a canonical federated CI tmp-summary reconcile bundle status-bundle-status bundle status bundle"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--bundle-file")
    group.add_argument("--artifact-file")
    parser.add_argument("--bundle-schema", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--validation-schema", default=str(DEFAULT_VALIDATION_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    bundle_schema_path = Path(args.bundle_schema).resolve()
    validation_schema_path = Path(args.validation_schema).resolve()
    output_path = Path(args.output).resolve()

    bundle_path: Path | None = None
    canonical_bundle: dict[str, Any] | None = None
    if args.bundle_file is not None:
        bundle_path = Path(args.bundle_file).resolve()
        bundle_doc = schema_validation.load_json(bundle_path)
        artifact_file = bundle_doc.get("artifact_file")
        if isinstance(artifact_file, str) and artifact_file.strip():
            _, canonical_bundle = resolve_status_bundle_status_bundle_status(
                artifact_file=artifact_file,
                status_schema=str(
                    WORKSPACE_ROOT
                    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.schema.json"
                ),
                status_validation_schema=str(
                    WORKSPACE_ROOT
                    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.schema.json"
                ),
                bundle_schema=str(bundle_schema_path),
                output=None,
            )
    else:
        _, bundle_doc = resolve_status_bundle_status_bundle_status(
            artifact_file=args.artifact_file,
            status_schema=str(
                WORKSPACE_ROOT
                / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.schema.json"
            ),
            status_validation_schema=str(
                WORKSPACE_ROOT
                / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.schema.json"
            ),
            bundle_schema=str(bundle_schema_path),
            output=None,
        )
        canonical_bundle = dict(bundle_doc)

    report = build_validation_report(
        bundle_path=bundle_path,
        bundle_doc=bundle_doc,
        bundle_schema_path=bundle_schema_path,
        validation_schema_path=validation_schema_path,
        output_path=output_path,
        canonical_bundle=canonical_bundle,
    )
    schema_validation.write_json(output_path, report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
