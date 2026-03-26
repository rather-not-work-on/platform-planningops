#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import validate_plain_python_compat_manifest as schema_validation

from resolve_federated_ci_summary_tmp_reconcile import resolve_bundle


WORKSPACE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_BUNDLE = WORKSPACE_ROOT / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle.json"
DEFAULT_BUNDLE_SCHEMA = WORKSPACE_ROOT / "schemas/federated-ci-summary-tmp-reconcile-bundle.schema.json"
DEFAULT_VALIDATION_SCHEMA = WORKSPACE_ROOT / "schemas/federated-ci-summary-tmp-reconcile-bundle-validation.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-validation.json"


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

    artifact_file = doc.get("artifact_file")
    reconcile_report_path = doc.get("reconcile_report_path")
    reconcile_validation_report_path = doc.get("reconcile_validation_report_path")
    run_id = doc.get("run_id")
    reconcile_status = doc.get("reconcile_status")
    reconcile_check_name = doc.get("reconcile_check_name")
    reconcile_count = doc.get("reconcile_count")
    reconcile_report = doc.get("reconcile_report")
    reconcile_validation_report = doc.get("reconcile_validation_report")

    if bundle_path is not None and not bundle_path.exists():
        append_unique(errors, "bundle_path must point at an existing bundle")

    artifact_path = Path(str(artifact_file or "")) if isinstance(artifact_file, str) and artifact_file.strip() else None
    if artifact_path is None:
        append_unique(errors, "artifact_file must be a non-empty string")
    elif not artifact_path.exists():
        append_unique(errors, "artifact_file must point at an existing file")

    report_path = Path(str(reconcile_report_path or "")) if isinstance(reconcile_report_path, str) and str(reconcile_report_path).strip() else None
    if report_path is None:
        append_unique(errors, "reconcile_report_path must be a non-empty string")
    elif not report_path.exists():
        append_unique(errors, "reconcile_report_path must point at an existing file")

    validation_path = (
        Path(str(reconcile_validation_report_path or ""))
        if isinstance(reconcile_validation_report_path, str) and str(reconcile_validation_report_path).strip()
        else None
    )
    if validation_path is None:
        append_unique(errors, "reconcile_validation_report_path must be a non-empty string")
    elif not validation_path.exists():
        append_unique(errors, "reconcile_validation_report_path must point at an existing file")

    if not isinstance(run_id, str) or not run_id.strip():
        append_unique(errors, "run_id must be a non-empty string")
    if reconcile_status not in {"healthy", "restored"}:
        append_unique(errors, "reconcile_status must be one of: healthy, restored")
    if reconcile_check_name is not None and (not isinstance(reconcile_check_name, str) or not reconcile_check_name.strip()):
        append_unique(errors, "reconcile_check_name must be null or a non-empty string")
    if not isinstance(reconcile_count, int) or isinstance(reconcile_count, bool) or reconcile_count < 0:
        append_unique(errors, "reconcile_count must be a non-negative integer")

    if not isinstance(reconcile_report, dict):
        append_unique(errors, "reconcile_report must be an object")
    else:
        if report_path is not None and reconcile_report.get("output_path") != str(report_path.resolve()):
            append_unique(errors, "reconcile_report.output_path must match reconcile_report_path")
        if reconcile_report.get("run_id") != run_id:
            append_unique(errors, "run_id must match reconcile_report.run_id")
        if reconcile_report.get("status") != reconcile_status:
            append_unique(errors, "reconcile_status must match reconcile_report.status")
        if reconcile_report.get("check_name") != reconcile_check_name:
            append_unique(errors, "reconcile_check_name must match reconcile_report.check_name")
        if reconcile_report.get("reconcile_count") != reconcile_count:
            append_unique(errors, "reconcile_count must match reconcile_report.reconcile_count")

    if not isinstance(reconcile_validation_report, dict):
        append_unique(errors, "reconcile_validation_report must be an object")
    else:
        if validation_path is not None and reconcile_validation_report.get("output_path") != str(validation_path.resolve()):
            append_unique(errors, "reconcile_validation_report.output_path must match reconcile_validation_report_path")
        if report_path is not None and reconcile_validation_report.get("reconcile_report_path") != str(report_path.resolve()):
            append_unique(errors, "reconcile_validation_report.reconcile_report_path must match reconcile_report_path")
        if reconcile_validation_report.get("reconcile_run_id") != run_id:
            append_unique(errors, "run_id must match reconcile_validation_report.reconcile_run_id")
        if reconcile_validation_report.get("reconcile_status") != reconcile_status:
            append_unique(errors, "reconcile_status must match reconcile_validation_report.reconcile_status")
        if reconcile_validation_report.get("reconcile_check_name") != reconcile_check_name:
            append_unique(errors, "reconcile_check_name must match reconcile_validation_report.reconcile_check_name")
        if reconcile_validation_report.get("reconcile_count") != reconcile_count:
            append_unique(errors, "reconcile_count must match reconcile_validation_report.reconcile_count")
        if reconcile_validation_report.get("verdict") != "pass":
            append_unique(errors, "reconcile_validation_report.verdict must be pass")

    if canonical_bundle is not None:
        canonical = dict(canonical_bundle)
        actual = dict(doc)
        canonical.pop("generated_at_utc", None)
        actual.pop("generated_at_utc", None)
        if actual != canonical:
            append_unique(errors, "bundle does not match canonical tmp-summary reconcile resolution")

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
        "reconcile_report_path": bundle_doc.get("reconcile_report_path"),
        "reconcile_validation_report_path": bundle_doc.get("reconcile_validation_report_path"),
        "run_id": bundle_doc.get("run_id"),
        "reconcile_status": bundle_doc.get("reconcile_status"),
        "reconcile_check_name": bundle_doc.get("reconcile_check_name"),
        "reconcile_count": bundle_doc.get("reconcile_count"),
        "reconcile_validation_verdict": (
            bundle_doc.get("reconcile_validation_report", {}).get("verdict")
            if isinstance(bundle_doc.get("reconcile_validation_report"), dict)
            else None
        ),
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
    parser = argparse.ArgumentParser(description="Validate a canonical federated CI tmp-summary reconcile bundle")
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
            _, canonical_bundle = resolve_bundle(artifact_file=artifact_file, schema_path=str(bundle_schema_path), output=None)
    else:
        _, bundle_doc = resolve_bundle(artifact_file=args.artifact_file, schema_path=str(bundle_schema_path), output=None)
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
