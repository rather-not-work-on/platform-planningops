#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status as bundle_resolver
import validate_plain_python_compat_manifest as manifest_validation


DEFAULT_BUNDLE = bundle_resolver.DEFAULT_OUTPUT
DEFAULT_SCHEMA = bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_SCHEMA = bundle_resolver.DEFAULT_STATUS_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_OUTPUT = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
)


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def _string(value: object, fallback: str) -> str:
    if isinstance(value, str) and value.strip():
        return value
    return fallback


def _bool(value: object) -> bool:
    return value if isinstance(value, bool) else False


def _verdict(value: object) -> str:
    return value if value in {"pass", "fail"} else "fail"


def build_report_payload(bundle_path: Path, bundle_schema_path: Path, doc: dict[str, Any]) -> dict[str, Any]:
    bundle_path_str = str(bundle_path.resolve())
    return {
        "bundle_path": bundle_path_str,
        "schema_path": str(bundle_schema_path.resolve()),
        "generated_at_utc": manifest_validation.now_utc(),
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path": _string(
            doc.get("bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"),
            bundle_path_str,
        ),
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path": _string(
            doc.get("bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path"),
            bundle_path_str,
        ),
        "bundle_validation_output_path": _string(doc.get("bundle_validation_output_path"), bundle_path_str),
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path": _string(
            doc.get("bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"),
            bundle_path_str,
        ),
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path": _string(
            doc.get("bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path"),
            bundle_path_str,
        ),
        "bundle_status_bundle_status_bundle_status_path": _string(
            doc.get("bundle_status_bundle_status_bundle_status_path"),
            bundle_path_str,
        ),
        "bundle_status_bundle_status_bundle_validation_path": _string(
            doc.get("bundle_status_bundle_status_bundle_validation_path"),
            bundle_path_str,
        ),
        "bundle_status_bundle_status_path": _string(doc.get("bundle_status_bundle_status_path"), bundle_path_str),
        "bundle_status_bundle_validation_path": _string(
            doc.get("bundle_status_bundle_validation_path"),
            bundle_path_str,
        ),
        "status_bundle_path": _string(doc.get("status_bundle_path"), bundle_path_str),
        "bundle_status_path": _string(doc.get("bundle_status_path"), bundle_path_str),
        "bundle_status_validation_path": _string(doc.get("bundle_status_validation_path"), bundle_path_str),
        "manifest_path": _string(doc.get("manifest_path"), bundle_path_str),
        "status_path": _string(doc.get("status_path"), bundle_path_str),
        "status_validation_path": _string(doc.get("status_validation_path"), bundle_path_str),
        "bundle_ready": _bool(doc.get("ready")),
        "bundle_next_step": _string(doc.get("next_step"), "unknown"),
        "status_verdict": _verdict(doc.get("status_verdict")),
        "status_validation_verdict": _verdict(doc.get("status_validation_verdict")),
        "bundle_status_verdict": _verdict(doc.get("bundle_status_verdict")),
        "bundle_status_validation_verdict": _verdict(doc.get("bundle_status_validation_verdict")),
        "bundle_validation_verdict": _verdict(doc.get("bundle_validation_verdict")),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path": _string(
            doc.get("resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"),
            bundle_path_str,
        ),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path": _string(
            doc.get(
                "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
            ),
            bundle_path_str,
        ),
    }


def validate_semantics(
    bundle_path: Path,
    doc: dict[str, Any],
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
    bundle_schema_path: Path,
) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    status_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"
    )
    status_validation_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path"
    )
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    status_verdict = doc.get("status_verdict")
    status_validation_verdict = doc.get("status_validation_verdict")
    resolved_bundle_path = doc.get(
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
    )

    for key in (
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path",
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path",
        "bundle_path",
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path",
        "bundle_validation_output_path",
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path",
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path",
        "bundle_status_bundle_status_bundle_status_path",
        "bundle_status_bundle_status_bundle_validation_path",
        "bundle_status_bundle_status_path",
        "bundle_status_bundle_validation_path",
        "status_bundle_path",
        "bundle_status_path",
        "bundle_status_validation_path",
        "manifest_path",
        "status_path",
        "status_validation_path",
    ):
        value = doc.get(key)
        if not isinstance(value, str) or not value.strip():
            append_unique(errors, f"{key} must be a non-empty string")

    if resolved_bundle_path is not None and resolved_bundle_path != str(bundle_path.resolve()):
        append_unique(
            errors,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path must match the validated bundle file path",
        )

    status_report = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report"
    )
    if not isinstance(status_report, dict):
        append_unique(
            errors,
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report must be an object",
        )
    else:
        if ready != status_report.get("ready"):
            append_unique(
                errors,
                "ready must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report.ready",
            )
        if next_step != status_report.get("next_step"):
            append_unique(
                errors,
                "next_step must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report.next_step",
            )
        if status_verdict != status_report.get("verdict"):
            append_unique(
                errors,
                "status_verdict must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report.verdict",
            )
        if (
            status_path
            != status_report.get(
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"
            )
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path",
            )
        if (
            status_validation_path
            != status_report.get(
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"
            )
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path",
            )

    status_validation_report = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report"
    )
    if not isinstance(status_validation_report, dict):
        append_unique(
            errors,
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report must be an object",
        )
    else:
        if status_validation_verdict != status_validation_report.get("verdict"):
            append_unique(
                errors,
                "status_validation_verdict must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.verdict",
            )
        if ready != status_validation_report.get("status_ready"):
            append_unique(
                errors,
                "ready must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.status_ready",
            )
        if next_step != status_validation_report.get("status_next_step"):
            append_unique(
                errors,
                "next_step must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.status_next_step",
            )
        if status_verdict != status_validation_report.get("status_verdict"):
            append_unique(
                errors,
                "status_verdict must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.status_verdict",
            )
        if (
            status_path
            != status_validation_report.get(
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"
            )
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path",
            )
        if (
            status_path
            != status_validation_report.get(
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"
            )
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path",
            )
        if (
            status_validation_path
            != status_validation_report.get(
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"
            )
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path",
            )
        if status_validation_path != status_validation_report.get("output_path"):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_path must match bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_report.output_path",
            )

    if isinstance(status_path, str) and status_path.strip():
        try:
            canonical_bundle = bundle_resolver.resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status(
                artifact_file=None,
                status_file=status_path,
                status_validation_file=None,
                status_schema=str(status_schema_path),
                status_validation_schema=str(status_validation_schema_path),
                bundle_schema=str(bundle_schema_path),
                output=None,
            )
        except SystemExit as exc:
            append_unique(errors, str(exc))
        else:
            expected_bundle = dict(canonical_bundle)
            if (
                "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
                in doc
            ):
                expected_bundle[
                    "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
                ] = str(bundle_path.resolve())
            if doc != expected_bundle:
                append_unique(
                    errors,
                    "bundle must match canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status bundle resolution",
                )

    return errors, warnings


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
    semantic_errors, warnings = validate_semantics(
        bundle_path,
        bundle_doc,
        status_schema_path=status_schema_path,
        status_validation_schema_path=status_validation_schema_path,
        bundle_schema_path=bundle_schema_path,
    )
    errors = schema_errors + semantic_errors
    report = build_report_payload(bundle_path, bundle_schema_path, bundle_doc)
    report.update(
        {
            "output_path": str(output_path.resolve()),
            "verdict": "pass" if not errors else "fail",
            "error_count": len(errors),
            "warning_count": len(warnings),
            "errors": errors,
            "warnings": warnings,
        }
    )
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate plain python compatibility manifest status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status bundle."
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
    if args.strict and report["verdict"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
