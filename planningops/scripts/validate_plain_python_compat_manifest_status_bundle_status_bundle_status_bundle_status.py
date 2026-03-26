#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import resolve_plain_python_compat_manifest as resolver
import validate_plain_python_compat_manifest as manifest_validation


WORKSPACE_ROOT = resolver.repo_root()
DEFAULT_STATUS = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-validation.json"
)


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def validate_semantics(status_path: Path, doc: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    bundle_path = doc.get("bundle_path")
    resolved_bundle_path = doc.get("resolved_status_bundle_status_bundle_status_bundle_path")
    bundle_status_output_path = doc.get("bundle_status_bundle_status_bundle_output_path")
    bundle_status_validation_output_path = doc.get("bundle_status_bundle_status_bundle_validation_output_path")
    bundle_validation_output_path = doc.get("bundle_validation_output_path")
    bundle_status_bundle_status_path = doc.get("bundle_status_bundle_status_path")
    bundle_status_bundle_validation_path = doc.get("bundle_status_bundle_validation_path")
    status_bundle_path = doc.get("status_bundle_path")
    bundle_status_path = doc.get("bundle_status_path")
    bundle_status_validation_path = doc.get("bundle_status_validation_path")
    manifest_path = doc.get("manifest_path")
    status_path_sidecar = doc.get("status_path")
    status_validation_path = doc.get("status_validation_path")
    verdict = doc.get("verdict")
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    status_verdict = doc.get("status_verdict")
    status_validation_verdict = doc.get("status_validation_verdict")
    bundle_status_verdict = doc.get("bundle_status_verdict")
    bundle_status_validation_verdict = doc.get("bundle_status_validation_verdict")
    bundle_validation_verdict = doc.get("bundle_validation_verdict")

    if bundle_status_output_path != str(status_path.resolve()):
        append_unique(errors, "bundle_status_bundle_status_bundle_output_path must match the validated status file path")
    if not isinstance(bundle_status_validation_output_path, str) or not bundle_status_validation_output_path.strip():
        append_unique(errors, "bundle_status_bundle_status_bundle_validation_output_path must be a non-empty string")

    for key, value in (
        ("bundle_path", bundle_path),
        ("resolved_status_bundle_status_bundle_status_bundle_path", resolved_bundle_path),
        ("bundle_validation_output_path", bundle_validation_output_path),
        ("bundle_status_bundle_status_path", bundle_status_bundle_status_path),
        ("bundle_status_bundle_validation_path", bundle_status_bundle_validation_path),
        ("status_bundle_path", status_bundle_path),
        ("bundle_status_path", bundle_status_path),
        ("bundle_status_validation_path", bundle_status_validation_path),
        ("manifest_path", manifest_path),
        ("status_path", status_path_sidecar),
        ("status_validation_path", status_validation_path),
    ):
        if not isinstance(value, str) or not value.strip():
            append_unique(errors, f"{key} must be a non-empty string")

    if (
        isinstance(bundle_status_output_path, str)
        and isinstance(resolved_bundle_path, str)
        and bundle_status_output_path != resolved_bundle_path
    ):
        append_unique(
            errors,
            "resolved_status_bundle_status_bundle_status_bundle_path must match bundle_status_bundle_status_bundle_output_path",
        )

    if verdict == "pass" and ready is not True:
        append_unique(errors, "ready must be true when verdict=pass")
    if verdict == "fail" and ready is not False:
        append_unique(errors, "ready must be false when verdict=fail")
    if ready is True and next_step != "none":
        append_unique(errors, "next_step must be 'none' when ready=true")
    if ready is False and (not isinstance(next_step, str) or not next_step.strip() or next_step == "none"):
        append_unique(errors, "next_step must be a non-empty remediation step when ready=false")

    expected_verdict = "pass"
    for value in (
        status_verdict,
        status_validation_verdict,
        bundle_status_verdict,
        bundle_status_validation_verdict,
        bundle_validation_verdict,
    ):
        if value != "pass":
            expected_verdict = "fail"
            break
    if verdict != expected_verdict:
        append_unique(errors, "verdict must match propagated bundle verdict aggregation")

    validation_doc: dict[str, Any] | None = None
    validation_path: Path | None = None
    if isinstance(bundle_validation_output_path, str) and bundle_validation_output_path.strip():
        validation_path = Path(bundle_validation_output_path)
        if not validation_path.is_absolute():
            validation_path = (status_path.parent / validation_path).resolve()
        else:
            validation_path = validation_path.resolve()
        if not validation_path.exists():
            append_unique(errors, "bundle_validation_output_path must point at an existing bundle-validation report")
        else:
            validation_doc = manifest_validation.load_json(validation_path)

    if isinstance(validation_doc, dict) and validation_path is not None:
        if validation_doc.get("output_path") != str(validation_path.resolve()):
            append_unique(errors, "bundle-validation report output_path must match bundle_validation_output_path")
        if bundle_path != validation_doc.get("bundle_path"):
            append_unique(errors, "bundle_path must match bundle-validation report bundle_path")
        if bundle_status_bundle_status_path != validation_doc.get("bundle_status_bundle_status_path"):
            append_unique(
                errors,
                "bundle_status_bundle_status_path must match bundle-validation report bundle_status_bundle_status_path",
            )
        if bundle_status_bundle_validation_path != validation_doc.get("bundle_status_bundle_validation_path"):
            append_unique(
                errors,
                "bundle_status_bundle_validation_path must match bundle-validation report bundle_status_bundle_validation_path",
            )
        if status_bundle_path != validation_doc.get("status_bundle_path"):
            append_unique(errors, "status_bundle_path must match bundle-validation report status_bundle_path")
        if bundle_status_path != validation_doc.get("bundle_status_path"):
            append_unique(errors, "bundle_status_path must match bundle-validation report bundle_status_path")
        if bundle_status_validation_path != validation_doc.get("bundle_status_validation_path"):
            append_unique(
                errors,
                "bundle_status_validation_path must match bundle-validation report bundle_status_validation_path",
            )
        if manifest_path != validation_doc.get("manifest_path"):
            append_unique(errors, "manifest_path must match bundle-validation report manifest_path")
        if status_path_sidecar != validation_doc.get("status_path"):
            append_unique(errors, "status_path must match bundle-validation report status_path")
        if status_validation_path != validation_doc.get("status_validation_path"):
            append_unique(errors, "status_validation_path must match bundle-validation report status_validation_path")
        if ready != validation_doc.get("bundle_ready"):
            append_unique(errors, "ready must match bundle-validation report bundle_ready")
        if next_step != validation_doc.get("bundle_next_step"):
            append_unique(errors, "next_step must match bundle-validation report bundle_next_step")
        if status_verdict != validation_doc.get("status_verdict"):
            append_unique(errors, "status_verdict must match bundle-validation report status_verdict")
        if status_validation_verdict != validation_doc.get("status_validation_verdict"):
            append_unique(errors, "status_validation_verdict must match bundle-validation report status_validation_verdict")
        if bundle_status_verdict != validation_doc.get("bundle_status_verdict"):
            append_unique(errors, "bundle_status_verdict must match bundle-validation report bundle_status_verdict")
        if bundle_status_validation_verdict != validation_doc.get("bundle_status_validation_verdict"):
            append_unique(
                errors,
                "bundle_status_validation_verdict must match bundle-validation report bundle_status_validation_verdict",
            )
        if bundle_validation_verdict != validation_doc.get("bundle_validation_verdict"):
            append_unique(errors, "bundle_validation_verdict must match bundle-validation report bundle_validation_verdict")
    return errors, warnings


def build_validation_report(status_path: Path, schema_path: Path, output_path: Path) -> dict[str, Any]:
    doc = manifest_validation.load_json(status_path)
    schema_doc = manifest_validation.load_json(schema_path)

    schema_errors = manifest_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings = validate_semantics(status_path, doc)
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    if doc.get("bundle_status_bundle_status_bundle_validation_output_path") != str(output_path.resolve()):
        append_unique(
            errors,
            "bundle_status_bundle_status_bundle_validation_output_path must match the validation output path",
        )
        verdict = "fail"

    return {
        "bundle_status_bundle_status_bundle_status_path": str(status_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": manifest_validation.now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "bundle_path": doc.get("bundle_path"),
        "resolved_status_bundle_status_bundle_status_bundle_path": doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_path"
        ),
        "bundle_status_bundle_status_bundle_output_path": doc.get("bundle_status_bundle_status_bundle_output_path"),
        "bundle_status_bundle_status_bundle_validation_output_path": doc.get(
            "bundle_status_bundle_status_bundle_validation_output_path"
        ),
        "bundle_validation_output_path": doc.get("bundle_validation_output_path"),
        "bundle_status_bundle_status_path": doc.get("bundle_status_bundle_status_path"),
        "bundle_status_bundle_validation_path": doc.get("bundle_status_bundle_validation_path"),
        "status_bundle_path": doc.get("status_bundle_path"),
        "bundle_status_path": doc.get("bundle_status_path"),
        "bundle_status_validation_path": doc.get("bundle_status_validation_path"),
        "manifest_path": doc.get("manifest_path"),
        "status_path": doc.get("status_path"),
        "status_validation_path": doc.get("status_validation_path"),
        "status_verdict": doc.get("status_verdict"),
        "status_ready": doc.get("ready"),
        "status_next_step": doc.get("next_step"),
        "status_validation_verdict": doc.get("status_validation_verdict"),
        "bundle_status_verdict": doc.get("bundle_status_verdict"),
        "bundle_status_validation_verdict": doc.get("bundle_status_validation_verdict"),
        "bundle_validation_verdict": doc.get("bundle_validation_verdict"),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate plain python compatibility manifest status-bundle-status-bundle-status-bundle status report."
    )
    parser.add_argument("--status-file", default=str(DEFAULT_STATUS))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    status_path = Path(args.status_file)
    schema_path = Path(args.schema_file)
    output_path = Path(args.output)

    report = build_validation_report(status_path, schema_path, output_path)
    manifest_validation.write_json(output_path, report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
