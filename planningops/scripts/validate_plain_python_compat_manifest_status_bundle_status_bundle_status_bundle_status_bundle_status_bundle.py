#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status as bundle_resolver
import validate_plain_python_compat_manifest as manifest_validation


DEFAULT_BUNDLE = bundle_resolver.DEFAULT_OUTPUT
DEFAULT_SCHEMA = bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_SCHEMA = bundle_resolver.DEFAULT_STATUS_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_OUTPUT = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
)


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def validate_semantics(
    bundle_path: Path,
    doc: dict[str, Any],
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
    bundle_schema_path: Path,
) -> tuple[list[str], list[str], dict[str, Any] | None]:
    errors: list[str] = []
    warnings: list[str] = []

    bundle_status_bundle_status_bundle_status_bundle_status_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_path"
    )
    bundle_status_bundle_status_bundle_status_bundle_validation_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_validation_path"
    )
    outer_bundle_path = doc.get("bundle_path")
    resolved_outer_status_path = doc.get("resolved_status_bundle_status_bundle_status_bundle_status_bundle_path")
    bundle_validation_output_path = doc.get("bundle_validation_output_path")
    bundle_status_bundle_status_bundle_status_path = doc.get("bundle_status_bundle_status_bundle_status_path")
    bundle_status_bundle_status_bundle_validation_path = doc.get(
        "bundle_status_bundle_status_bundle_validation_path"
    )
    bundle_status_bundle_status_path = doc.get("bundle_status_bundle_status_path")
    bundle_status_bundle_validation_path = doc.get("bundle_status_bundle_validation_path")
    status_bundle_path = doc.get("status_bundle_path")
    bundle_status_path = doc.get("bundle_status_path")
    bundle_status_validation_path = doc.get("bundle_status_validation_path")
    manifest_path = doc.get("manifest_path")
    status_path = doc.get("status_path")
    status_validation_path = doc.get("status_validation_path")
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    status_verdict = doc.get("status_verdict")
    status_validation_verdict = doc.get("status_validation_verdict")
    bundle_status_verdict = doc.get("bundle_status_verdict")
    bundle_status_validation_verdict = doc.get("bundle_status_validation_verdict")
    bundle_validation_verdict = doc.get("bundle_validation_verdict")
    resolved_bundle_path = doc.get(
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
    )

    if resolved_bundle_path is not None and resolved_bundle_path != str(bundle_path.resolve()):
        append_unique(
            errors,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path must match the validated bundle file path",
        )

    for key, value in (
        ("bundle_status_bundle_status_bundle_status_bundle_status_path", bundle_status_bundle_status_bundle_status_bundle_status_path),
        ("bundle_status_bundle_status_bundle_status_bundle_validation_path", bundle_status_bundle_status_bundle_status_bundle_validation_path),
        ("bundle_path", outer_bundle_path),
        ("resolved_status_bundle_status_bundle_status_bundle_status_bundle_path", resolved_outer_status_path),
        ("bundle_validation_output_path", bundle_validation_output_path),
        ("bundle_status_bundle_status_bundle_status_path", bundle_status_bundle_status_bundle_status_path),
        ("bundle_status_bundle_status_bundle_validation_path", bundle_status_bundle_status_bundle_validation_path),
        ("bundle_status_bundle_status_path", bundle_status_bundle_status_path),
        ("bundle_status_bundle_validation_path", bundle_status_bundle_validation_path),
        ("status_bundle_path", status_bundle_path),
        ("bundle_status_path", bundle_status_path),
        ("bundle_status_validation_path", bundle_status_validation_path),
        ("manifest_path", manifest_path),
        ("status_path", status_path),
        ("status_validation_path", status_validation_path),
    ):
        if not isinstance(value, str) or not value.strip():
            append_unique(errors, f"{key} must be a non-empty string")

    status_bundle_report = doc.get("bundle_status_bundle_status_bundle_status_bundle_report")
    if not isinstance(status_bundle_report, dict):
        append_unique(errors, "bundle_status_bundle_status_bundle_status_bundle_report must be an object")

    status_bundle_validation_report = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_validation_report"
    )
    if not isinstance(status_bundle_validation_report, dict):
        append_unique(errors, "bundle_status_bundle_status_bundle_status_bundle_validation_report must be an object")

    if isinstance(status_bundle_report, dict):
        if ready != status_bundle_report.get("ready"):
            append_unique(errors, "ready must match bundle_status_bundle_status_bundle_status_bundle_report.ready")
        if next_step != status_bundle_report.get("next_step"):
            append_unique(errors, "next_step must match bundle_status_bundle_status_bundle_status_bundle_report.next_step")
        if status_verdict != status_bundle_report.get("verdict"):
            append_unique(errors, "status_verdict must match bundle_status_bundle_status_bundle_status_bundle_report.verdict")
        if bundle_status_verdict != status_bundle_report.get("bundle_status_verdict"):
            append_unique(
                errors,
                "bundle_status_verdict must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_verdict",
            )
        if bundle_status_validation_verdict != status_bundle_report.get("bundle_status_validation_verdict"):
            append_unique(
                errors,
                "bundle_status_validation_verdict must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_validation_verdict",
            )
        if bundle_validation_verdict != status_bundle_report.get("bundle_validation_verdict"):
            append_unique(
                errors,
                "bundle_validation_verdict must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_validation_verdict",
            )
        if (
            bundle_status_bundle_status_bundle_status_bundle_status_path
            != status_bundle_report.get("bundle_status_bundle_status_bundle_status_bundle_output_path")
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_status_bundle_output_path",
            )
        if (
            bundle_status_bundle_status_bundle_status_bundle_validation_path
            != status_bundle_report.get("bundle_status_bundle_status_bundle_status_bundle_validation_output_path")
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_status_bundle_validation_output_path",
            )
        if outer_bundle_path != status_bundle_report.get("bundle_path"):
            append_unique(errors, "bundle_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_path")
        if (
            resolved_outer_status_path
            != status_bundle_report.get("resolved_status_bundle_status_bundle_status_bundle_status_bundle_path")
        ):
            append_unique(
                errors,
                "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path must match bundle_status_bundle_status_bundle_status_bundle_report.resolved_status_bundle_status_bundle_status_bundle_status_bundle_path",
            )
        if bundle_validation_output_path != status_bundle_report.get("bundle_validation_output_path"):
            append_unique(
                errors,
                "bundle_validation_output_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_validation_output_path",
            )
        if bundle_status_bundle_status_bundle_status_path != status_bundle_report.get(
            "bundle_status_bundle_status_bundle_status_path"
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_status_path",
            )
        if bundle_status_bundle_status_bundle_validation_path != status_bundle_report.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_validation_path",
            )
        if bundle_status_bundle_status_path != status_bundle_report.get("bundle_status_bundle_status_path"):
            append_unique(
                errors,
                "bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_path",
            )
        if bundle_status_bundle_validation_path != status_bundle_report.get("bundle_status_bundle_validation_path"):
            append_unique(
                errors,
                "bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_validation_path",
            )
        if status_bundle_path != status_bundle_report.get("status_bundle_path"):
            append_unique(
                errors,
                "status_bundle_path must match bundle_status_bundle_status_bundle_status_bundle_report.status_bundle_path",
            )
        if bundle_status_path != status_bundle_report.get("bundle_status_path"):
            append_unique(errors, "bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_path")
        if bundle_status_validation_path != status_bundle_report.get("bundle_status_validation_path"):
            append_unique(
                errors,
                "bundle_status_validation_path must match bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_validation_path",
            )
        if manifest_path != status_bundle_report.get("manifest_path"):
            append_unique(errors, "manifest_path must match bundle_status_bundle_status_bundle_status_bundle_report.manifest_path")
        if status_path != status_bundle_report.get("status_path"):
            append_unique(errors, "status_path must match bundle_status_bundle_status_bundle_status_bundle_report.status_path")
        if status_validation_path != status_bundle_report.get("status_validation_path"):
            append_unique(
                errors,
                "status_validation_path must match bundle_status_bundle_status_bundle_status_bundle_report.status_validation_path",
            )

    if isinstance(status_bundle_validation_report, dict):
        if status_validation_verdict != status_bundle_validation_report.get("verdict"):
            append_unique(
                errors,
                "status_validation_verdict must match bundle_status_bundle_status_bundle_status_bundle_validation_report.verdict",
            )
        if ready != status_bundle_validation_report.get("status_ready"):
            append_unique(
                errors,
                "ready must match bundle_status_bundle_status_bundle_status_bundle_validation_report.status_ready",
            )
        if next_step != status_bundle_validation_report.get("status_next_step"):
            append_unique(
                errors,
                "next_step must match bundle_status_bundle_status_bundle_status_bundle_validation_report.status_next_step",
            )
        if status_verdict != status_bundle_validation_report.get("status_verdict"):
            append_unique(
                errors,
                "status_verdict must match bundle_status_bundle_status_bundle_status_bundle_validation_report.status_verdict",
            )
        if bundle_status_verdict != status_bundle_validation_report.get("bundle_status_verdict"):
            append_unique(
                errors,
                "bundle_status_verdict must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_verdict",
            )
        if bundle_status_validation_verdict != status_bundle_validation_report.get("bundle_status_validation_verdict"):
            append_unique(
                errors,
                "bundle_status_validation_verdict must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_validation_verdict",
            )
        if bundle_validation_verdict != status_bundle_validation_report.get("bundle_validation_verdict"):
            append_unique(
                errors,
                "bundle_validation_verdict must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_validation_verdict",
            )
        if (
            bundle_status_bundle_status_bundle_status_bundle_status_path
            != status_bundle_validation_report.get("bundle_status_bundle_status_bundle_status_bundle_status_path")
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_bundle_status_path",
            )
        if (
            bundle_status_bundle_status_bundle_status_bundle_status_path
            != status_bundle_validation_report.get("bundle_status_bundle_status_bundle_status_bundle_output_path")
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_bundle_output_path must match bundle_status_bundle_status_bundle_status_bundle_status_path",
            )
        if (
            bundle_status_bundle_status_bundle_status_bundle_validation_path
            != status_bundle_validation_report.get("bundle_status_bundle_status_bundle_status_bundle_validation_output_path")
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_bundle_validation_output_path",
            )
        if (
            bundle_status_bundle_status_bundle_status_bundle_validation_path
            != status_bundle_validation_report.get("output_path")
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.output_path",
            )
        if outer_bundle_path != status_bundle_validation_report.get("bundle_path"):
            append_unique(
                errors,
                "bundle_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_path",
            )
        if (
            resolved_outer_status_path
            != status_bundle_validation_report.get("resolved_status_bundle_status_bundle_status_bundle_status_bundle_path")
        ):
            append_unique(
                errors,
                "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.resolved_status_bundle_status_bundle_status_bundle_status_bundle_path",
            )
        if bundle_validation_output_path != status_bundle_validation_report.get("bundle_validation_output_path"):
            append_unique(
                errors,
                "bundle_validation_output_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_validation_output_path",
            )
        if bundle_status_bundle_status_bundle_status_path != status_bundle_validation_report.get(
            "bundle_status_bundle_status_bundle_status_path"
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_path",
            )
        if bundle_status_bundle_status_bundle_validation_path != status_bundle_validation_report.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_validation_path",
            )
        if bundle_status_bundle_status_path != status_bundle_validation_report.get("bundle_status_bundle_status_path"):
            append_unique(
                errors,
                "bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_path",
            )
        if bundle_status_bundle_validation_path != status_bundle_validation_report.get(
            "bundle_status_bundle_validation_path"
        ):
            append_unique(
                errors,
                "bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_validation_path",
            )
        if status_bundle_path != status_bundle_validation_report.get("status_bundle_path"):
            append_unique(
                errors,
                "status_bundle_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.status_bundle_path",
            )
        if bundle_status_path != status_bundle_validation_report.get("bundle_status_path"):
            append_unique(
                errors,
                "bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_path",
            )
        if bundle_status_validation_path != status_bundle_validation_report.get("bundle_status_validation_path"):
            append_unique(
                errors,
                "bundle_status_validation_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_validation_path",
            )
        if manifest_path != status_bundle_validation_report.get("manifest_path"):
            append_unique(
                errors,
                "manifest_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.manifest_path",
            )
        if status_path != status_bundle_validation_report.get("status_path"):
            append_unique(
                errors,
                "status_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.status_path",
            )
        if status_validation_path != status_bundle_validation_report.get("status_validation_path"):
            append_unique(
                errors,
                "status_validation_path must match bundle_status_bundle_status_bundle_status_bundle_validation_report.status_validation_path",
            )

    canonical_bundle: dict[str, Any] | None = None
    if isinstance(bundle_status_bundle_status_bundle_status_bundle_status_path, str) and bundle_status_bundle_status_bundle_status_bundle_status_path.strip():
        try:
            canonical_bundle = bundle_resolver.resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle(
                artifact_file=None,
                status_file=bundle_status_bundle_status_bundle_status_bundle_status_path,
                status_validation_file=None,
                status_schema=str(status_schema_path),
                status_validation_schema=str(status_validation_schema_path),
                bundle_schema=str(bundle_schema_path),
                output=None,
            )
        except SystemExit as exc:
            append_unique(errors, str(exc))

    if canonical_bundle is not None:
        expected_bundle = dict(canonical_bundle)
        if "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path" in doc:
            expected_bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] = str(
                bundle_path.resolve()
            )
        if doc != expected_bundle:
            append_unique(
                errors,
                "bundle must match canonical status-bundle-status-bundle-status-bundle-status-bundle-status bundle resolution",
            )

    report: dict[str, Any] | None = None
    if not errors:
        report = {
            "bundle_path": str(bundle_path.resolve()),
            "schema_path": str(bundle_schema_path.resolve()),
            "generated_at_utc": manifest_validation.now_utc(),
            "verdict": "pass",
            "error_count": 0,
            "warning_count": len(warnings),
            "errors": [],
            "warnings": warnings,
            "bundle_status_bundle_status_bundle_status_bundle_status_path": bundle_status_bundle_status_bundle_status_bundle_status_path,
            "bundle_status_bundle_status_bundle_status_bundle_validation_path": bundle_status_bundle_status_bundle_status_bundle_validation_path,
            "bundle_validation_output_path": bundle_validation_output_path,
            "bundle_status_bundle_status_bundle_status_path": bundle_status_bundle_status_bundle_status_path,
            "bundle_status_bundle_status_bundle_validation_path": bundle_status_bundle_status_bundle_validation_path,
            "bundle_status_bundle_status_path": bundle_status_bundle_status_path,
            "bundle_status_bundle_validation_path": bundle_status_bundle_validation_path,
            "status_bundle_path": status_bundle_path,
            "bundle_status_path": bundle_status_path,
            "bundle_status_validation_path": bundle_status_validation_path,
            "manifest_path": manifest_path,
            "status_path": status_path,
            "status_validation_path": status_validation_path,
            "bundle_ready": ready,
            "bundle_next_step": next_step,
            "status_verdict": status_verdict,
            "status_validation_verdict": status_validation_verdict,
            "bundle_status_verdict": bundle_status_verdict,
            "bundle_status_validation_verdict": bundle_status_validation_verdict,
            "bundle_validation_verdict": bundle_validation_verdict,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path": resolved_outer_status_path,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path": str(bundle_path.resolve()),
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
    bundle_path = bundle_path.resolve()
    bundle_doc = manifest_validation.load_json(bundle_path)
    bundle_schema_doc = manifest_validation.load_json(bundle_schema_path)
    schema_errors = manifest_validation.validate_schema(bundle_doc, bundle_schema_doc)

    semantic_errors, warnings, canonical_report = validate_semantics(
        bundle_path,
        bundle_doc,
        status_schema_path=status_schema_path,
        status_validation_schema_path=status_validation_schema_path,
        bundle_schema_path=bundle_schema_path,
    )
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    report: dict[str, Any] = canonical_report or {
        "bundle_path": str(bundle_path.resolve()),
        "schema_path": str(bundle_schema_path.resolve()),
        "generated_at_utc": manifest_validation.now_utc(),
        "bundle_status_bundle_status_bundle_status_bundle_status_path": bundle_doc.get(
            "bundle_status_bundle_status_bundle_status_bundle_status_path"
        ),
        "bundle_status_bundle_status_bundle_status_bundle_validation_path": bundle_doc.get(
            "bundle_status_bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_validation_output_path": bundle_doc.get("bundle_validation_output_path"),
        "bundle_status_bundle_status_bundle_status_path": bundle_doc.get(
            "bundle_status_bundle_status_bundle_status_path"
        ),
        "bundle_status_bundle_status_bundle_validation_path": bundle_doc.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_status_bundle_status_path": bundle_doc.get("bundle_status_bundle_status_path"),
        "bundle_status_bundle_validation_path": bundle_doc.get("bundle_status_bundle_validation_path"),
        "status_bundle_path": bundle_doc.get("status_bundle_path"),
        "bundle_status_path": bundle_doc.get("bundle_status_path"),
        "bundle_status_validation_path": bundle_doc.get("bundle_status_validation_path"),
        "manifest_path": bundle_doc.get("manifest_path"),
        "status_path": bundle_doc.get("status_path"),
        "status_validation_path": bundle_doc.get("status_validation_path"),
        "bundle_ready": bundle_doc.get("ready"),
        "bundle_next_step": bundle_doc.get("next_step"),
        "status_verdict": bundle_doc.get("status_verdict"),
        "status_validation_verdict": bundle_doc.get("status_validation_verdict"),
        "bundle_status_verdict": bundle_doc.get("bundle_status_verdict"),
        "bundle_status_validation_verdict": bundle_doc.get("bundle_status_validation_verdict"),
        "bundle_validation_verdict": bundle_doc.get("bundle_validation_verdict"),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path": bundle_doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path": bundle_doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ),
    }
    report.update(
        {
            "output_path": str(output_path.resolve()),
            "verdict": verdict,
            "error_count": len(errors),
            "warning_count": len(warnings),
            "errors": errors,
            "warnings": warnings,
        }
    )
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate plain python compatibility manifest status-bundle-status-bundle-status-bundle-status-bundle-status bundle."
    )
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
