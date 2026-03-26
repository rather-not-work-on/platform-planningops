#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import resolve_plain_python_compat_manifest_status as bundle_resolver
import validate_plain_python_compat_manifest as manifest_validation


DEFAULT_BUNDLE = bundle_resolver.DEFAULT_OUTPUT
DEFAULT_SCHEMA = bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_SCHEMA = bundle_resolver.DEFAULT_STATUS_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_OUTPUT = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-validation.json"
)


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def resolve_doc_path(value: object, *, base: Path) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = (base / path).resolve()
    else:
        path = path.resolve()
    return path


def validate_semantics(
    bundle_path: Path,
    doc: dict[str, Any],
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
    bundle_schema_path: Path,
    output_path: Path,
) -> tuple[list[str], list[str], dict[str, Any] | None]:
    errors: list[str] = []
    warnings: list[str] = []

    if doc.get("resolved_status_bundle_path") != str(bundle_path.resolve()):
        append_unique(errors, "resolved_status_bundle_path must match the validated bundle file path")

    status_path = resolve_doc_path(doc.get("status_path"), base=bundle_path.parent)
    status_validation_path = resolve_doc_path(doc.get("status_validation_path"), base=bundle_path.parent)
    manifest_path = doc.get("manifest_path")
    resolved_guardrail_script_paths = doc.get("resolved_guardrail_script_paths")
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    status_verdict = doc.get("status_verdict")
    status_validation_verdict = doc.get("status_validation_verdict")

    if status_path is None:
        append_unique(errors, "status_path must be a non-empty string")
    if status_validation_path is None:
        append_unique(errors, "status_validation_path must be a non-empty string")
    if not isinstance(manifest_path, str) or not manifest_path.strip():
        append_unique(errors, "manifest_path must be a non-empty string")
    if not isinstance(resolved_guardrail_script_paths, list) or not resolved_guardrail_script_paths:
        append_unique(errors, "resolved_guardrail_script_paths must be a non-empty array")

    status_report = doc.get("status_report")
    if not isinstance(status_report, dict):
        append_unique(errors, "status_report must be an object")
    status_validation_report = doc.get("status_validation_report")
    if not isinstance(status_validation_report, dict):
        append_unique(errors, "status_validation_report must be an object")

    canonical_bundle: dict[str, Any] | None = None
    if status_path is not None:
        try:
            canonical_bundle = bundle_resolver.resolve_status_bundle(
                artifact_file=None,
                status_file=str(status_path),
                status_validation_file=None,
                status_schema=str(status_schema_path),
                status_validation_schema=str(status_validation_schema_path),
                bundle_schema=str(bundle_schema_path),
                output=None,
            )
        except SystemExit as exc:
            append_unique(errors, str(exc))

    if isinstance(status_report, dict):
        if status_verdict != status_report.get("verdict"):
            append_unique(errors, "status_verdict must match status_report.verdict")
        if ready != status_report.get("ready"):
            append_unique(errors, "ready must match status_report.ready")
        if next_step != status_report.get("next_step"):
            append_unique(errors, "next_step must match status_report.next_step")
        if isinstance(manifest_path, str) and manifest_path != status_report.get("manifest_path"):
            append_unique(errors, "manifest_path must match status_report.manifest_path")
        if resolved_guardrail_script_paths != status_report.get("resolved_guardrail_script_paths"):
            append_unique(errors, "resolved_guardrail_script_paths must match status_report.resolved_guardrail_script_paths")
        if status_path is not None and resolve_doc_path(status_report.get("status_output_path"), base=bundle_path.parent) != status_path:
            append_unique(errors, "status_report.status_output_path must match status_path")
        if status_validation_path is not None and resolve_doc_path(
            status_report.get("status_validation_output_path"),
            base=bundle_path.parent,
        ) != status_validation_path:
            append_unique(errors, "status_report.status_validation_output_path must match status_validation_path")

    if isinstance(status_validation_report, dict):
        if status_validation_verdict != status_validation_report.get("verdict"):
            append_unique(errors, "status_validation_verdict must match status_validation_report.verdict")
        if isinstance(manifest_path, str) and manifest_path != status_validation_report.get("manifest_path"):
            append_unique(errors, "manifest_path must match status_validation_report.manifest_path")
        if resolved_guardrail_script_paths != status_validation_report.get("resolved_guardrail_script_paths"):
            append_unique(
                errors,
                "resolved_guardrail_script_paths must match status_validation_report.resolved_guardrail_script_paths",
            )
        if status_path is not None and resolve_doc_path(status_validation_report.get("status_path"), base=bundle_path.parent) != status_path:
            append_unique(errors, "status_validation_report.status_path must match status_path")
        if status_path is not None and resolve_doc_path(
            status_validation_report.get("status_output_path"),
            base=bundle_path.parent,
        ) != status_path:
            append_unique(errors, "status_validation_report.status_output_path must match status_path")
        if status_validation_path is not None and resolve_doc_path(
            status_validation_report.get("output_path"),
            base=bundle_path.parent,
        ) != status_validation_path:
            append_unique(errors, "status_validation_report.output_path must match status_validation_path")
        if status_validation_path is not None and resolve_doc_path(
            status_validation_report.get("status_validation_output_path"),
            base=bundle_path.parent,
        ) != status_validation_path:
            append_unique(
                errors,
                "status_validation_report.status_validation_output_path must match status_validation_path",
            )

    if canonical_bundle is not None:
        expected_bundle = dict(canonical_bundle)
        expected_bundle["resolved_status_bundle_path"] = str(bundle_path.resolve())
        if doc != expected_bundle:
            append_unique(errors, "bundle must match canonical status bundle resolution")

    report: dict[str, Any] | None = None
    if not errors:
        report = {
            "bundle_path": str(bundle_path.resolve()),
            "schema_path": str(bundle_schema_path.resolve()),
            "output_path": str(output_path.resolve()),
            "manifest_path": manifest_path,
            "status_path": str(status_path.resolve()) if status_path is not None else None,
            "status_validation_path": str(status_validation_path.resolve()) if status_validation_path is not None else None,
            "resolved_guardrail_script_paths": resolved_guardrail_script_paths,
            "bundle_ready": ready,
            "bundle_next_step": next_step,
            "bundle_status_verdict": status_verdict,
            "bundle_status_validation_verdict": status_validation_verdict,
        }
    return errors, warnings, report


def build_validation_report(
    bundle_path: Path,
    bundle_schema_path: Path,
    output_path: Path,
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
) -> dict[str, Any]:
    doc = manifest_validation.load_json(bundle_path)
    schema_doc = manifest_validation.load_json(bundle_schema_path)

    schema_errors = manifest_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings, semantic_report = validate_semantics(
        bundle_path,
        doc,
        status_schema_path=status_schema_path,
        status_validation_schema_path=status_validation_schema_path,
        bundle_schema_path=bundle_schema_path,
        output_path=output_path,
    )
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    report = {
        "bundle_path": str(bundle_path.resolve()),
        "schema_path": str(bundle_schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": manifest_validation.now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "manifest_path": doc.get("manifest_path"),
        "status_path": doc.get("status_path"),
        "status_validation_path": doc.get("status_validation_path"),
        "resolved_guardrail_script_paths": doc.get("resolved_guardrail_script_paths"),
        "bundle_ready": doc.get("ready"),
        "bundle_next_step": doc.get("next_step"),
        "bundle_status_verdict": doc.get("status_verdict"),
        "bundle_status_validation_verdict": doc.get("status_validation_verdict"),
        "resolved_status_bundle_path": doc.get("resolved_status_bundle_path"),
    }
    if semantic_report is not None:
        report.update(semantic_report)
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate plain python compatibility manifest status bundle.")
    parser.add_argument("--bundle-file", default=str(DEFAULT_BUNDLE))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--status-schema-file", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_validation_report(
        Path(args.bundle_file),
        Path(args.schema_file),
        Path(args.output),
        status_schema_path=Path(args.status_schema_file),
        status_validation_schema_path=Path(args.status_validation_schema_file),
    )
    manifest_validation.write_json(Path(args.output), report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
