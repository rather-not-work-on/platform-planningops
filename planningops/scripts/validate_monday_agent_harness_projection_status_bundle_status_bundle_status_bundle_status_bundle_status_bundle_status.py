#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status as bundle_resolver
import validate_monday_agent_harness_projection as projection_validation


WORKSPACE_ROOT = bundle_resolver.WORKSPACE_ROOT
DEFAULT_STATUS = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
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


def validate_semantics(status_path: Path, doc: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    bundle_path = resolve_doc_path(doc.get("bundle_path"), base=status_path.parent)
    resolved_bundle_path = doc.get(
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
    )
    bundle_status_output_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"
    )
    bundle_status_validation_output_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"
    )
    bundle_validation_output_path = resolve_doc_path(doc.get("bundle_validation_output_path"), base=status_path.parent)
    bundle_status_bundle_status_bundle_status_bundle_status_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_status_path"
    )
    bundle_status_bundle_status_bundle_status_bundle_validation_path = doc.get(
        "bundle_status_bundle_status_bundle_status_bundle_validation_path"
    )
    bundle_status_bundle_status_bundle_status_path = doc.get("bundle_status_bundle_status_bundle_status_path")
    bundle_status_bundle_status_bundle_validation_path = doc.get(
        "bundle_status_bundle_status_bundle_validation_path"
    )
    bundle_status_bundle_status_path = doc.get("bundle_status_bundle_status_path")
    bundle_status_bundle_validation_path = doc.get("bundle_status_bundle_validation_path")
    bundle_status_path = doc.get("bundle_status_path")
    bundle_status_validation_path = doc.get("bundle_status_validation_path")
    projection_bundle_path = doc.get("projection_bundle_path")
    projection_validation_report_path = doc.get("projection_validation_report_path")
    status_path_sidecar = doc.get("status_path")
    status_validation_path = doc.get("status_validation_path")
    verdict = doc.get("verdict")
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    status_verdict = doc.get("status_verdict")
    status_validation_verdict = doc.get("status_validation_verdict")
    bundle_status_verdict = doc.get("bundle_status_verdict")
    bundle_status_validation_verdict = doc.get("bundle_status_validation_verdict")
    projection_validation_verdict = doc.get("projection_validation_verdict")
    projection_validation_state = doc.get("projection_validation_state")
    status_sidecar_validation_verdict = doc.get("status_sidecar_validation_verdict")
    bundle_validation_verdict = doc.get("bundle_validation_verdict")

    if bundle_status_output_path != str(status_path.resolve()):
        append_unique(
            errors,
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path must match the validated status file path",
        )
    if not isinstance(bundle_status_validation_output_path, str) or not bundle_status_validation_output_path.strip():
        append_unique(
            errors,
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path must be a non-empty string",
        )

    for key, value in (
        ("bundle_path", bundle_path),
        (
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path",
            resolved_bundle_path,
        ),
        ("bundle_validation_output_path", bundle_validation_output_path),
        (
            "bundle_status_bundle_status_bundle_status_bundle_status_path",
            bundle_status_bundle_status_bundle_status_bundle_status_path,
        ),
        (
            "bundle_status_bundle_status_bundle_status_bundle_validation_path",
            bundle_status_bundle_status_bundle_status_bundle_validation_path,
        ),
        ("bundle_status_bundle_status_bundle_status_path", bundle_status_bundle_status_bundle_status_path),
        (
            "bundle_status_bundle_status_bundle_validation_path",
            bundle_status_bundle_status_bundle_validation_path,
        ),
        ("bundle_status_bundle_status_path", bundle_status_bundle_status_path),
        ("bundle_status_bundle_validation_path", bundle_status_bundle_validation_path),
        ("bundle_status_path", bundle_status_path),
        ("bundle_status_validation_path", bundle_status_validation_path),
        ("projection_bundle_path", projection_bundle_path),
        ("projection_validation_report_path", projection_validation_report_path),
        ("status_path", status_path_sidecar),
        ("status_validation_path", status_validation_path),
    ):
        if value is None or (isinstance(value, str) and not value.strip()):
            append_unique(errors, f"{key} must be a non-empty string")

    if (
        isinstance(bundle_path, Path)
        and isinstance(resolved_bundle_path, str)
        and str(bundle_path.resolve()) != resolved_bundle_path
    ):
        append_unique(
            errors,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path must match bundle_path",
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
    if (
        status_verdict != "pass"
        or status_validation_verdict != "pass"
        or bundle_status_verdict != "pass"
        or bundle_status_validation_verdict != "pass"
        or projection_validation_verdict != "pass"
        or projection_validation_state != "fresh"
        or status_sidecar_validation_verdict != "pass"
        or bundle_validation_verdict != "pass"
        or ready is not True
        or next_step != "none"
    ):
        expected_verdict = "fail"
    if verdict != expected_verdict:
        append_unique(
            errors,
            "verdict must match propagated monday projection status-bundle-status-bundle-status-bundle-status-bundle-status-bundle aggregation",
        )

    bundle_doc: dict[str, Any] | None = None
    if isinstance(bundle_path, Path):
        if not bundle_path.exists():
            append_unique(
                errors,
                "bundle_path must point at an existing resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle artifact",
            )
        else:
            bundle_doc = projection_validation.load_json(bundle_path)

    validation_doc: dict[str, Any] | None = None
    if isinstance(bundle_validation_output_path, Path):
        if not bundle_validation_output_path.exists():
            append_unique(errors, "bundle_validation_output_path must point at an existing bundle-validation report")
        else:
            validation_doc = projection_validation.load_json(bundle_validation_output_path)

    if isinstance(bundle_doc, dict):
        for status_field, bundle_field in (
            (
                "bundle_status_bundle_status_bundle_status_bundle_status_path",
                "bundle_status_bundle_status_bundle_status_bundle_status_path",
            ),
            (
                "bundle_status_bundle_status_bundle_status_bundle_validation_path",
                "bundle_status_bundle_status_bundle_status_bundle_validation_path",
            ),
            ("bundle_status_bundle_status_bundle_status_path", "bundle_status_bundle_status_bundle_status_path"),
            (
                "bundle_status_bundle_status_bundle_validation_path",
                "bundle_status_bundle_status_bundle_validation_path",
            ),
            ("bundle_status_bundle_status_path", "bundle_status_bundle_status_path"),
            ("bundle_status_bundle_validation_path", "bundle_status_bundle_validation_path"),
            ("bundle_status_path", "bundle_status_path"),
            ("bundle_status_validation_path", "bundle_status_validation_path"),
            ("projection_bundle_path", "projection_bundle_path"),
            ("projection_validation_report_path", "projection_validation_report_path"),
            ("status_path", "status_path"),
            ("status_validation_path", "status_validation_path"),
            ("mission_id", "mission_id"),
            ("run_id", "run_id"),
            ("session_id", "session_id"),
            ("ready", "ready"),
            ("next_step", "next_step"),
            ("status_verdict", "status_verdict"),
            ("status_validation_verdict", "status_validation_verdict"),
            ("bundle_status_verdict", "bundle_status_verdict"),
            ("bundle_status_validation_verdict", "bundle_status_validation_verdict"),
            ("projection_validation_verdict", "projection_validation_verdict"),
            ("projection_validation_state", "projection_validation_state"),
            ("status_sidecar_validation_verdict", "status_sidecar_validation_verdict"),
            ("bundle_validation_verdict", "bundle_validation_verdict"),
        ):
            if doc.get(status_field) != bundle_doc.get(bundle_field):
                append_unique(errors, f"{status_field} must match resolved bundle {bundle_field}")

    if isinstance(validation_doc, dict):
        if validation_doc.get("output_path") != str(bundle_validation_output_path.resolve()):
            append_unique(errors, "bundle-validation report output_path must match bundle_validation_output_path")
        if bundle_path is not None and validation_doc.get(
            "status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ) != str(bundle_path.resolve()):
            append_unique(
                errors,
                "bundle_path must match bundle-validation report status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path",
            )
        for status_field, validation_field in (
            (
                "bundle_status_bundle_status_bundle_status_bundle_status_path",
                "bundle_status_bundle_status_bundle_status_bundle_status_path",
            ),
            (
                "bundle_status_bundle_status_bundle_status_bundle_validation_path",
                "bundle_status_bundle_status_bundle_status_bundle_validation_path",
            ),
            ("bundle_status_bundle_status_bundle_status_path", "bundle_status_bundle_status_bundle_status_path"),
            (
                "bundle_status_bundle_status_bundle_validation_path",
                "bundle_status_bundle_status_bundle_validation_path",
            ),
            ("bundle_status_bundle_status_path", "bundle_status_bundle_status_path"),
            ("bundle_status_bundle_validation_path", "bundle_status_bundle_validation_path"),
            ("bundle_status_path", "bundle_status_path"),
            ("bundle_status_validation_path", "bundle_status_validation_path"),
            ("projection_bundle_path", "projection_bundle_path"),
            ("projection_validation_report_path", "projection_validation_report_path"),
            ("status_path", "status_path"),
            ("status_validation_path", "status_validation_path"),
            ("mission_id", "mission_id"),
            ("run_id", "run_id"),
            ("session_id", "session_id"),
            ("ready", "bundle_ready"),
            ("next_step", "bundle_next_step"),
            ("status_verdict", "status_verdict"),
            ("status_validation_verdict", "status_validation_verdict"),
            ("bundle_status_verdict", "bundle_status_verdict"),
            ("bundle_status_validation_verdict", "bundle_status_validation_verdict"),
            ("projection_validation_verdict", "projection_validation_verdict"),
            ("projection_validation_state", "projection_validation_state"),
            ("status_sidecar_validation_verdict", "status_sidecar_validation_verdict"),
            ("bundle_validation_verdict", "bundle_validation_verdict"),
        ):
            if doc.get(status_field) != validation_doc.get(validation_field):
                append_unique(errors, f"{status_field} must match bundle-validation report {validation_field}")
        if resolved_bundle_path != validation_doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ):
            append_unique(
                errors,
                "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path must match bundle-validation report resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path",
            )

    return errors, warnings


def build_validation_report(status_path: Path, schema_path: Path, output_path: Path) -> dict[str, Any]:
    doc = projection_validation.load_json(status_path)
    schema_doc = projection_validation.load_json(schema_path)

    schema_errors = projection_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings = validate_semantics(status_path, doc)
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    if (
        doc.get("bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path")
        != str(output_path.resolve())
    ):
        append_unique(
            errors,
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path must match the validation output path",
        )
        verdict = "fail"

    return {
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path": str(status_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": projection_validation.now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "bundle_path": doc.get("bundle_path"),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path": doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ),
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path": doc.get(
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_output_path"
        ),
        "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path": doc.get(
            "bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_output_path"
        ),
        "bundle_validation_output_path": doc.get("bundle_validation_output_path"),
        "bundle_status_bundle_status_bundle_status_bundle_status_path": doc.get(
            "bundle_status_bundle_status_bundle_status_bundle_status_path"
        ),
        "bundle_status_bundle_status_bundle_status_bundle_validation_path": doc.get(
            "bundle_status_bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_status_bundle_status_bundle_status_path": doc.get("bundle_status_bundle_status_bundle_status_path"),
        "bundle_status_bundle_status_bundle_validation_path": doc.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_status_bundle_status_path": doc.get("bundle_status_bundle_status_path"),
        "bundle_status_bundle_validation_path": doc.get("bundle_status_bundle_validation_path"),
        "bundle_status_path": doc.get("bundle_status_path"),
        "bundle_status_validation_path": doc.get("bundle_status_validation_path"),
        "projection_bundle_path": doc.get("projection_bundle_path"),
        "projection_validation_report_path": doc.get("projection_validation_report_path"),
        "status_path": doc.get("status_path"),
        "status_validation_path": doc.get("status_validation_path"),
        "mission_id": doc.get("mission_id"),
        "run_id": doc.get("run_id"),
        "session_id": doc.get("session_id"),
        "status_verdict": doc.get("verdict"),
        "status_ready": doc.get("ready"),
        "status_next_step": doc.get("next_step"),
        "status_validation_verdict": doc.get("status_validation_verdict"),
        "bundle_status_verdict": doc.get("bundle_status_verdict"),
        "bundle_status_validation_verdict": doc.get("bundle_status_validation_verdict"),
        "projection_validation_verdict": doc.get("projection_validation_verdict"),
        "projection_validation_state": doc.get("projection_validation_state"),
        "status_sidecar_validation_verdict": doc.get("status_sidecar_validation_verdict"),
        "bundle_validation_verdict": doc.get("bundle_validation_verdict"),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate monday agent harness projection "
            "status-bundle-status-bundle-status-bundle-status-bundle-status-bundle status report."
        )
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
    projection_validation.write_json(output_path, report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
