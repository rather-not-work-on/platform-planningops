#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status as bundle_resolver
import validate_monday_agent_harness_projection as projection_validation


DEFAULT_BUNDLE = bundle_resolver.DEFAULT_OUTPUT
DEFAULT_SCHEMA = bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_SCHEMA = bundle_resolver.DEFAULT_STATUS_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_OUTPUT = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
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

    bundle_status_bundle_status_bundle_status_path = resolve_doc_path(
        doc.get("bundle_status_bundle_status_bundle_status_path"),
        base=bundle_path.parent,
    )
    bundle_status_bundle_status_bundle_validation_path = resolve_doc_path(
        doc.get("bundle_status_bundle_status_bundle_validation_path"),
        base=bundle_path.parent,
    )
    outer_bundle_path = doc.get("bundle_path")
    resolved_outer_bundle_path = doc.get("resolved_status_bundle_status_bundle_status_bundle_path")
    bundle_validation_output_path = doc.get("bundle_validation_output_path")
    bundle_status_bundle_status_path = doc.get("bundle_status_bundle_status_path")
    bundle_status_bundle_validation_path = doc.get("bundle_status_bundle_validation_path")
    bundle_status_path = doc.get("bundle_status_path")
    bundle_status_validation_path = doc.get("bundle_status_validation_path")
    projection_bundle_path = doc.get("projection_bundle_path")
    projection_validation_report_path = doc.get("projection_validation_report_path")
    status_path = doc.get("status_path")
    status_validation_path = doc.get("status_validation_path")
    mission_id = doc.get("mission_id")
    run_id = doc.get("run_id")
    session_id = doc.get("session_id")
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
    resolved_bundle_path = doc.get("resolved_status_bundle_status_bundle_status_bundle_status_bundle_path")

    if resolved_bundle_path is not None and resolved_bundle_path != str(bundle_path.resolve()):
        append_unique(
            errors,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path must match the validated bundle file path",
        )

    for key, value in (
        ("bundle_status_bundle_status_bundle_status_path", bundle_status_bundle_status_bundle_status_path),
        (
            "bundle_status_bundle_status_bundle_validation_path",
            bundle_status_bundle_status_bundle_validation_path,
        ),
        ("bundle_path", outer_bundle_path),
        ("resolved_status_bundle_status_bundle_status_bundle_path", resolved_outer_bundle_path),
        ("bundle_validation_output_path", bundle_validation_output_path),
        ("bundle_status_bundle_status_path", bundle_status_bundle_status_path),
        ("bundle_status_bundle_validation_path", bundle_status_bundle_validation_path),
        ("bundle_status_path", bundle_status_path),
        ("bundle_status_validation_path", bundle_status_validation_path),
        ("projection_bundle_path", projection_bundle_path),
        ("projection_validation_report_path", projection_validation_report_path),
        ("status_path", status_path),
        ("status_validation_path", status_validation_path),
    ):
        if value is None or (isinstance(value, str) and not value.strip()):
            append_unique(errors, f"{key} must be a non-empty string")

    bundle_status_bundle_status_bundle_report = doc.get("bundle_status_bundle_status_bundle_report")
    if not isinstance(bundle_status_bundle_status_bundle_report, dict):
        append_unique(errors, "bundle_status_bundle_status_bundle_report must be an object")
    bundle_status_bundle_status_bundle_validation_report = doc.get(
        "bundle_status_bundle_status_bundle_validation_report"
    )
    if not isinstance(bundle_status_bundle_status_bundle_validation_report, dict):
        append_unique(errors, "bundle_status_bundle_status_bundle_validation_report must be an object")

    canonical_bundle: dict[str, Any] | None = None
    if bundle_status_bundle_status_bundle_status_path is not None:
        try:
            canonical_bundle = (
                bundle_resolver.resolve_status_bundle_status_bundle_status_bundle_status_bundle(
                    artifact_file=None,
                    status_file=str(bundle_status_bundle_status_bundle_status_path),
                    status_validation_file=None,
                    status_schema=str(status_schema_path),
                    status_validation_schema=str(status_validation_schema_path),
                    bundle_schema=str(bundle_schema_path),
                    output=None,
                )
            )
        except SystemExit as exc:
            append_unique(
                errors,
                f"could not resolve canonical status-bundle-status-bundle-status-bundle-status bundle: {exc}",
            )

    if isinstance(bundle_status_bundle_status_bundle_report, dict):
        if ready != bundle_status_bundle_status_bundle_report.get("ready"):
            append_unique(errors, "ready must match bundle_status_bundle_status_bundle_report.ready")
        if next_step != bundle_status_bundle_status_bundle_report.get("next_step"):
            append_unique(errors, "next_step must match bundle_status_bundle_status_bundle_report.next_step")
        if status_verdict != bundle_status_bundle_status_bundle_report.get("verdict"):
            append_unique(errors, "status_verdict must match bundle_status_bundle_status_bundle_report.verdict")
        if status_validation_verdict != bundle_status_bundle_status_bundle_report.get("status_validation_verdict"):
            append_unique(
                errors,
                "status_validation_verdict must match bundle_status_bundle_status_bundle_report.status_validation_verdict",
            )
        if bundle_status_verdict != bundle_status_bundle_status_bundle_report.get("bundle_status_verdict"):
            append_unique(
                errors,
                "bundle_status_verdict must match bundle_status_bundle_status_bundle_report.bundle_status_verdict",
            )
        if (
            bundle_status_validation_verdict
            != bundle_status_bundle_status_bundle_report.get("bundle_status_validation_verdict")
        ):
            append_unique(
                errors,
                "bundle_status_validation_verdict must match bundle_status_bundle_status_bundle_report.bundle_status_validation_verdict",
            )
        if projection_validation_verdict != bundle_status_bundle_status_bundle_report.get(
            "projection_validation_verdict"
        ):
            append_unique(
                errors,
                "projection_validation_verdict must match bundle_status_bundle_status_bundle_report.projection_validation_verdict",
            )
        if projection_validation_state != bundle_status_bundle_status_bundle_report.get(
            "projection_validation_state"
        ):
            append_unique(
                errors,
                "projection_validation_state must match bundle_status_bundle_status_bundle_report.projection_validation_state",
            )
        if status_sidecar_validation_verdict != bundle_status_bundle_status_bundle_report.get(
            "status_sidecar_validation_verdict"
        ):
            append_unique(
                errors,
                "status_sidecar_validation_verdict must match bundle_status_bundle_status_bundle_report.status_sidecar_validation_verdict",
            )
        if bundle_validation_verdict != bundle_status_bundle_status_bundle_report.get(
            "bundle_validation_verdict"
        ):
            append_unique(
                errors,
                "bundle_validation_verdict must match bundle_status_bundle_status_bundle_report.bundle_validation_verdict",
            )
        if (
            bundle_status_bundle_status_bundle_status_path is not None
            and resolve_doc_path(
                bundle_status_bundle_status_bundle_report.get(
                    "bundle_status_bundle_status_bundle_output_path"
                ),
                base=bundle_path.parent,
            )
            != bundle_status_bundle_status_bundle_status_path
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_output_path must match bundle_status_bundle_status_bundle_status_path",
            )
        if (
            bundle_status_bundle_status_bundle_validation_path is not None
            and resolve_doc_path(
                bundle_status_bundle_status_bundle_report.get(
                    "bundle_status_bundle_status_bundle_validation_output_path"
                ),
                base=bundle_path.parent,
            )
            != bundle_status_bundle_status_bundle_validation_path
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_report.bundle_status_bundle_status_bundle_validation_output_path must match bundle_status_bundle_status_bundle_validation_path",
            )
        for bundle_field, report_field in (
            ("bundle_path", "bundle_path"),
            (
                "resolved_status_bundle_status_bundle_status_bundle_path",
                "resolved_status_bundle_status_bundle_status_bundle_path",
            ),
            ("bundle_validation_output_path", "bundle_validation_output_path"),
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
        ):
            if doc.get(bundle_field) != bundle_status_bundle_status_bundle_report.get(report_field):
                append_unique(
                    errors,
                    f"{bundle_field} must match bundle_status_bundle_status_bundle_report.{report_field}",
                )

    if isinstance(bundle_status_bundle_status_bundle_validation_report, dict):
        if (
            bundle_status_bundle_status_bundle_status_path is not None
            and resolve_doc_path(
                bundle_status_bundle_status_bundle_validation_report.get(
                    "bundle_status_bundle_status_bundle_status_path"
                ),
                base=bundle_path.parent,
            )
            != bundle_status_bundle_status_bundle_status_path
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_status_path must match bundle_status_bundle_status_bundle_status_path",
            )
        if (
            bundle_status_bundle_status_bundle_status_path is not None
            and resolve_doc_path(
                bundle_status_bundle_status_bundle_validation_report.get(
                    "bundle_status_bundle_status_bundle_output_path"
                ),
                base=bundle_path.parent,
            )
            != bundle_status_bundle_status_bundle_status_path
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_output_path must match bundle_status_bundle_status_bundle_status_path",
            )
        if (
            bundle_status_bundle_status_bundle_validation_path is not None
            and resolve_doc_path(
                bundle_status_bundle_status_bundle_validation_report.get(
                    "bundle_status_bundle_status_bundle_validation_output_path"
                ),
                base=bundle_path.parent,
            )
            != bundle_status_bundle_status_bundle_validation_path
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_validation_report.bundle_status_bundle_status_bundle_validation_output_path must match bundle_status_bundle_status_bundle_validation_path",
            )
        if (
            bundle_status_bundle_status_bundle_validation_path is not None
            and resolve_doc_path(
                bundle_status_bundle_status_bundle_validation_report.get("output_path"),
                base=bundle_path.parent,
            )
            != bundle_status_bundle_status_bundle_validation_path
        ):
            append_unique(
                errors,
                "bundle_status_bundle_status_bundle_validation_report.output_path must match bundle_status_bundle_status_bundle_validation_path",
            )
        for bundle_field, report_field in (
            ("bundle_path", "bundle_path"),
            (
                "resolved_status_bundle_status_bundle_status_bundle_path",
                "resolved_status_bundle_status_bundle_status_bundle_path",
            ),
            ("bundle_validation_output_path", "bundle_validation_output_path"),
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
            ("ready", "status_ready"),
            ("next_step", "status_next_step"),
            ("status_verdict", "status_verdict"),
            ("status_validation_verdict", "verdict"),
            ("bundle_status_verdict", "bundle_status_verdict"),
            ("bundle_status_validation_verdict", "bundle_status_validation_verdict"),
            ("projection_validation_verdict", "projection_validation_verdict"),
            ("projection_validation_state", "projection_validation_state"),
            ("status_sidecar_validation_verdict", "status_sidecar_validation_verdict"),
            ("bundle_validation_verdict", "bundle_validation_verdict"),
        ):
            if doc.get(bundle_field) != bundle_status_bundle_status_bundle_validation_report.get(
                report_field
            ):
                append_unique(
                    errors,
                    f"{bundle_field} must match bundle_status_bundle_status_bundle_validation_report.{report_field}",
                )

    if canonical_bundle is not None:
        expected_bundle = dict(canonical_bundle)
        expected_bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_path"] = str(
            bundle_path.resolve()
        )
        if doc != expected_bundle:
            append_unique(
                errors,
                "bundle must match canonical monday harness projection status-bundle-status-bundle-status-bundle-status bundle resolution",
            )

    report: dict[str, Any] | None = None
    if not errors:
        report = {
            "status_bundle_status_bundle_status_bundle_status_bundle_path": str(bundle_path.resolve()),
            "schema_path": str(bundle_schema_path.resolve()),
            "output_path": str(output_path.resolve()),
            "bundle_status_bundle_status_bundle_status_path": (
                str(bundle_status_bundle_status_bundle_status_path.resolve())
                if bundle_status_bundle_status_bundle_status_path is not None
                else None
            ),
            "bundle_status_bundle_status_bundle_validation_path": (
                str(bundle_status_bundle_status_bundle_validation_path.resolve())
                if bundle_status_bundle_status_bundle_validation_path is not None
                else None
            ),
            "bundle_path": outer_bundle_path,
            "resolved_status_bundle_status_bundle_status_bundle_path": resolved_outer_bundle_path,
            "bundle_validation_output_path": bundle_validation_output_path,
            "bundle_status_bundle_status_path": bundle_status_bundle_status_path,
            "bundle_status_bundle_validation_path": bundle_status_bundle_validation_path,
            "bundle_status_path": bundle_status_path,
            "bundle_status_validation_path": bundle_status_validation_path,
            "projection_bundle_path": projection_bundle_path,
            "projection_validation_report_path": projection_validation_report_path,
            "status_path": status_path,
            "status_validation_path": status_validation_path,
            "mission_id": mission_id,
            "run_id": run_id,
            "session_id": session_id,
            "bundle_ready": ready,
            "bundle_next_step": next_step,
            "status_verdict": status_verdict,
            "status_validation_verdict": status_validation_verdict,
            "bundle_status_verdict": bundle_status_verdict,
            "bundle_status_validation_verdict": bundle_status_validation_verdict,
            "projection_validation_verdict": projection_validation_verdict,
            "projection_validation_state": projection_validation_state,
            "status_sidecar_validation_verdict": status_sidecar_validation_verdict,
            "bundle_validation_verdict": bundle_validation_verdict,
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path": doc.get(
                "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path"
            ),
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
    doc = projection_validation.load_json(bundle_path)
    schema_doc = projection_validation.load_json(bundle_schema_path)

    schema_errors = projection_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings, semantic_report = validate_semantics(
        bundle_path.resolve(),
        doc,
        status_schema_path=status_schema_path.resolve(),
        status_validation_schema_path=status_validation_schema_path.resolve(),
        bundle_schema_path=bundle_schema_path.resolve(),
        output_path=output_path.resolve(),
    )
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    report = {
        "status_bundle_status_bundle_status_bundle_status_bundle_path": str(bundle_path.resolve()),
        "schema_path": str(bundle_schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": projection_validation.now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "bundle_status_bundle_status_bundle_status_path": doc.get(
            "bundle_status_bundle_status_bundle_status_path"
        ),
        "bundle_status_bundle_status_bundle_validation_path": doc.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_path": doc.get("bundle_path"),
        "resolved_status_bundle_status_bundle_status_bundle_path": doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_path"
        ),
        "bundle_validation_output_path": doc.get("bundle_validation_output_path"),
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
        "bundle_ready": doc.get("ready"),
        "bundle_next_step": doc.get("next_step"),
        "status_verdict": doc.get("status_verdict"),
        "status_validation_verdict": doc.get("status_validation_verdict"),
        "bundle_status_verdict": doc.get("bundle_status_verdict"),
        "bundle_status_validation_verdict": doc.get("bundle_status_validation_verdict"),
        "projection_validation_verdict": doc.get("projection_validation_verdict"),
        "projection_validation_state": doc.get("projection_validation_state"),
        "status_sidecar_validation_verdict": doc.get("status_sidecar_validation_verdict"),
        "bundle_validation_verdict": doc.get("bundle_validation_verdict"),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path": doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ),
    }
    if semantic_report:
        report.update(semantic_report)
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Validate monday agent harness projection "
            "status-bundle-status-bundle-status-bundle-status bundle."
        )
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
    bundle_path = Path(args.bundle_file)
    schema_path = Path(args.schema_file)
    status_schema_path = Path(args.status_schema_file)
    status_validation_schema_path = Path(args.status_validation_schema_file)
    output_path = Path(args.output)

    report = build_validation_report(
        bundle_path,
        schema_path,
        output_path,
        status_schema_path=status_schema_path,
        status_validation_schema_path=status_validation_schema_path,
    )
    projection_validation.write_json(output_path, report)
    print(json.dumps(report, ensure_ascii=True, indent=2))
    if args.strict and report["verdict"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
