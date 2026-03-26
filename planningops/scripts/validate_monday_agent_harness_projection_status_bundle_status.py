#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import validate_monday_agent_harness_projection as projection_validation


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATUS = (
    WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status.json"
)
DEFAULT_SCHEMA = (
    WORKSPACE_ROOT / "planningops/schemas/monday-agent-harness-projection-status-bundle-status.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-validation.json"
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


def validate_semantics(status_path: Path, doc: dict[str, Any], output_path: Path) -> tuple[list[str], list[str], dict[str, Any] | None]:
    errors: list[str] = []
    warnings: list[str] = []

    bundle_path = resolve_doc_path(doc.get("bundle_path"), base=status_path.parent)
    bundle_validation_output_path = resolve_doc_path(doc.get("bundle_validation_output_path"), base=status_path.parent)
    projection_bundle_path = doc.get("projection_bundle_path")
    projection_validation_report_path = doc.get("projection_validation_report_path")
    resolved_status_bundle_path = doc.get("resolved_status_bundle_path")
    bundle_status_output_path = doc.get("bundle_status_output_path")
    bundle_status_validation_output_path = doc.get("bundle_status_validation_output_path")
    status_path_value = doc.get("status_path")
    status_validation_path = doc.get("status_validation_path")
    mission_id = doc.get("mission_id")
    run_id = doc.get("run_id")
    session_id = doc.get("session_id")
    verdict = doc.get("verdict")
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    projection_validation_verdict = doc.get("projection_validation_verdict")
    projection_validation_state = doc.get("projection_validation_state")
    status_sidecar_validation_verdict = doc.get("status_sidecar_validation_verdict")
    bundle_validation_verdict = doc.get("bundle_validation_verdict")

    if bundle_status_output_path != str(status_path.resolve()):
        append_unique(errors, "bundle_status_output_path must match the validated status file path")
    if bundle_status_validation_output_path != str(output_path.resolve()):
        append_unique(errors, "bundle_status_validation_output_path must match the validation output path")

    for key, value in (
        ("bundle_path", bundle_path),
        ("resolved_status_bundle_path", resolved_status_bundle_path),
        ("bundle_validation_output_path", bundle_validation_output_path),
        ("projection_bundle_path", projection_bundle_path),
        ("projection_validation_report_path", projection_validation_report_path),
        ("status_path", status_path_value),
        ("status_validation_path", status_validation_path),
    ):
        if value is None or (isinstance(value, str) and not value.strip()):
            append_unique(errors, f"{key} must be a non-empty string")

    if isinstance(bundle_path, Path) and resolved_status_bundle_path != str(bundle_path.resolve()):
        append_unique(errors, "resolved_status_bundle_path must match bundle_path")
    if ready is True and next_step != "none":
        append_unique(errors, "next_step must be 'none' when ready=true")
    if ready is False and (not isinstance(next_step, str) or not next_step.strip() or next_step == "none"):
        append_unique(errors, "next_step must be a non-empty remediation step when ready=false")

    expected_verdict = "pass"
    if (
        bundle_validation_verdict != "pass"
        or projection_validation_verdict != "pass"
        or projection_validation_state != "fresh"
        or status_sidecar_validation_verdict != "pass"
        or ready is not True
        or next_step != "none"
    ):
        expected_verdict = "fail"
    if verdict != expected_verdict:
        append_unique(errors, "verdict must match bundle validation and propagated monday readiness aggregation")

    bundle_doc: dict[str, Any] | None = None
    if isinstance(bundle_path, Path):
        if not bundle_path.exists():
            append_unique(errors, "bundle_path must point at an existing resolved status-bundle artifact")
        else:
            bundle_doc = projection_validation.load_json(bundle_path)

    validation_doc: dict[str, Any] | None = None
    if isinstance(bundle_validation_output_path, Path):
        if not bundle_validation_output_path.exists():
            append_unique(errors, "bundle_validation_output_path must point at an existing validation report")
        else:
            validation_doc = projection_validation.load_json(bundle_validation_output_path)

    if isinstance(bundle_doc, dict):
        if status_path_value != bundle_doc.get("status_path"):
            append_unique(errors, "status_path must match resolved bundle status_path")
        if status_validation_path != bundle_doc.get("status_validation_path"):
            append_unique(errors, "status_validation_path must match resolved bundle status_validation_path")
        if projection_bundle_path != bundle_doc.get("bundle_path"):
            append_unique(errors, "projection_bundle_path must match resolved bundle bundle_path")
        if projection_validation_report_path != bundle_doc.get("validation_report_path"):
            append_unique(errors, "projection_validation_report_path must match resolved bundle validation_report_path")
        if mission_id != bundle_doc.get("mission_id"):
            append_unique(errors, "mission_id must match resolved bundle mission_id")
        if run_id != bundle_doc.get("run_id"):
            append_unique(errors, "run_id must match resolved bundle run_id")
        if session_id != bundle_doc.get("session_id"):
            append_unique(errors, "session_id must match resolved bundle session_id")
        if ready != bundle_doc.get("ready"):
            append_unique(errors, "ready must match resolved bundle ready")
        if next_step != bundle_doc.get("next_step"):
            append_unique(errors, "next_step must match resolved bundle next_step")
        if projection_validation_verdict != bundle_doc.get("projection_validation_verdict"):
            append_unique(errors, "projection_validation_verdict must match resolved bundle projection_validation_verdict")
        if projection_validation_state != bundle_doc.get("projection_validation_state"):
            append_unique(errors, "projection_validation_state must match resolved bundle projection_validation_state")
        if status_sidecar_validation_verdict != bundle_doc.get("status_sidecar_validation_verdict"):
            append_unique(
                errors,
                "status_sidecar_validation_verdict must match resolved bundle status_sidecar_validation_verdict",
            )

    if isinstance(validation_doc, dict):
        if validation_doc.get("output_path") != str(bundle_validation_output_path.resolve()):
            append_unique(errors, "bundle-validation report output_path must match bundle_validation_output_path")
        if validation_doc.get("status_bundle_path") != str(bundle_path.resolve()):
            append_unique(errors, "bundle-validation report status_bundle_path must match bundle_path")
        if projection_bundle_path != validation_doc.get("projection_bundle_path"):
            append_unique(errors, "projection_bundle_path must match bundle-validation report projection_bundle_path")
        if projection_validation_report_path != validation_doc.get("projection_validation_report_path"):
            append_unique(
                errors,
                "projection_validation_report_path must match bundle-validation report projection_validation_report_path",
            )
        if status_path_value != validation_doc.get("status_path"):
            append_unique(errors, "status_path must match bundle-validation report status_path")
        if status_validation_path != validation_doc.get("status_validation_path"):
            append_unique(errors, "status_validation_path must match bundle-validation report status_validation_path")
        if mission_id != validation_doc.get("mission_id"):
            append_unique(errors, "mission_id must match bundle-validation report mission_id")
        if run_id != validation_doc.get("run_id"):
            append_unique(errors, "run_id must match bundle-validation report run_id")
        if session_id != validation_doc.get("session_id"):
            append_unique(errors, "session_id must match bundle-validation report session_id")
        if ready != validation_doc.get("bundle_ready"):
            append_unique(errors, "ready must match bundle-validation report bundle_ready")
        if next_step != validation_doc.get("bundle_next_step"):
            append_unique(errors, "next_step must match bundle-validation report bundle_next_step")
        if projection_validation_verdict != validation_doc.get("projection_validation_verdict"):
            append_unique(
                errors,
                "projection_validation_verdict must match bundle-validation report projection_validation_verdict",
            )
        if projection_validation_state != validation_doc.get("projection_validation_state"):
            append_unique(
                errors,
                "projection_validation_state must match bundle-validation report projection_validation_state",
            )
        if status_sidecar_validation_verdict != validation_doc.get("status_sidecar_validation_verdict"):
            append_unique(
                errors,
                "status_sidecar_validation_verdict must match bundle-validation report status_sidecar_validation_verdict",
            )
        if bundle_validation_verdict != validation_doc.get("verdict"):
            append_unique(errors, "bundle_validation_verdict must match bundle-validation report verdict")

    report: dict[str, Any] | None = None
    if not errors:
        report = {
            "bundle_status_path": str(status_path.resolve()),
            "schema_path": str(DEFAULT_SCHEMA.resolve()),
            "bundle_path": str(bundle_path.resolve()) if isinstance(bundle_path, Path) else doc.get("bundle_path"),
            "resolved_status_bundle_path": resolved_status_bundle_path,
            "bundle_status_output_path": bundle_status_output_path,
            "bundle_status_validation_output_path": bundle_status_validation_output_path,
            "bundle_validation_output_path": (
                str(bundle_validation_output_path.resolve())
                if isinstance(bundle_validation_output_path, Path)
                else doc.get("bundle_validation_output_path")
            ),
            "projection_bundle_path": projection_bundle_path,
            "projection_validation_report_path": projection_validation_report_path,
            "status_path": status_path_value,
            "status_validation_path": status_validation_path,
            "mission_id": mission_id,
            "run_id": run_id,
            "session_id": session_id,
            "status_verdict": verdict,
            "status_ready": ready,
            "status_next_step": next_step,
            "projection_validation_verdict": projection_validation_verdict,
            "projection_validation_state": projection_validation_state,
            "status_sidecar_validation_verdict": status_sidecar_validation_verdict,
            "bundle_validation_verdict": bundle_validation_verdict,
        }
    return errors, warnings, report


def build_validation_report(status_path: Path, schema_path: Path, output_path: Path) -> dict[str, Any]:
    doc = projection_validation.load_json(status_path)
    schema_doc = projection_validation.load_json(schema_path)

    schema_errors = projection_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings, semantic_report = validate_semantics(status_path, doc, output_path.resolve())
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    report = {
        "bundle_status_path": str(status_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": projection_validation.now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "bundle_path": doc.get("bundle_path"),
        "resolved_status_bundle_path": doc.get("resolved_status_bundle_path"),
        "bundle_status_output_path": doc.get("bundle_status_output_path"),
        "bundle_status_validation_output_path": doc.get("bundle_status_validation_output_path"),
        "bundle_validation_output_path": doc.get("bundle_validation_output_path"),
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
        "projection_validation_verdict": doc.get("projection_validation_verdict"),
        "projection_validation_state": doc.get("projection_validation_state"),
        "status_sidecar_validation_verdict": doc.get("status_sidecar_validation_verdict"),
        "bundle_validation_verdict": doc.get("bundle_validation_verdict"),
    }
    if semantic_report is not None:
        report.update(semantic_report)
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate monday agent harness projection status-bundle status report.")
    parser.add_argument("--status-file", default=str(DEFAULT_STATUS))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report = build_validation_report(Path(args.status_file), Path(args.schema_file), Path(args.output))
    projection_validation.write_json(Path(args.output), report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
