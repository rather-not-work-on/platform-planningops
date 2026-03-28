#!/usr/bin/env python3

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from validate_supervisor_operator_handoff import append_unique, write_json
from validate_supervisor_operator_handoff_bundle import (
    DEFAULT_OUTPUT as DEFAULT_BUNDLE_VALIDATION_OUTPUT,
    validate_handoff_bundle,
)


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/supervisor-operator-handoff-bundle-readiness.json"
DEFAULT_VALIDATION_OUTPUT = (
    WORKSPACE_ROOT / "planningops/artifacts/validation/supervisor-operator-handoff-bundle-readiness-validation.json"
)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_validator_module():
    module_path = Path(__file__).resolve().parent / "validate_supervisor_operator_handoff_bundle_readiness.py"
    spec = importlib.util.spec_from_file_location("validate_supervisor_operator_handoff_bundle_readiness", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load bundle readiness validator module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def build_next_step(source_kind: str, artifact_file: str | None, bundle_file: str | None) -> str:
    if source_kind == "artifact" and artifact_file:
        return (
            "python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py "
            f"--artifact-file {artifact_file} --output <handoff-bundle-validation.json> --strict"
        )
    return (
        "python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py "
        f"--bundle-file {bundle_file} --output <handoff-bundle-validation.json> --strict"
    )


def build_blocking_reasons(validation_report: dict) -> list[str]:
    reasons: list[str] = []
    if validation_report.get("verdict") != "pass":
        append_unique(reasons, "bundle_validation_fail")
    if validation_report.get("operator_handoff_validation_verdict") != "pass":
        append_unique(reasons, "handoff_validation_fail")
    for field, reason in (
        ("operator_handoff_bundle_path", "operator_handoff_bundle_path_missing"),
        ("operator_handoff_bundle_validation_path", "operator_handoff_bundle_validation_path_missing"),
        ("operator_handoff_bundle_readiness_path", "operator_handoff_bundle_readiness_path_missing"),
        ("operator_handoff_bundle_readiness_validation_path", "operator_handoff_bundle_readiness_validation_path_missing"),
        ("priority_preview_ref", "priority_preview_ref_missing"),
        ("priority_display_packet_ref", "priority_display_packet_ref_missing"),
        ("priority_headline", "priority_headline_missing"),
        ("priority_cta_command", "priority_cta_command_missing"),
        ("display_title", "display_title_missing"),
        ("cta_command", "display_cta_command_missing"),
    ):
        if not str(validation_report.get(field) or "").strip():
            append_unique(reasons, reason)
    return reasons


def assess_handoff_bundle_readiness(
    *,
    bundle_file: str | None,
    artifact_file: str | None,
    bundle_schema_path: str | None,
    validation_schema_path: str | None,
    bundle_validation_output: str | None,
    output: str | None,
    readiness_validation_output: str | None,
) -> tuple[dict, dict]:
    validation_report = validate_handoff_bundle(
        bundle_file=bundle_file,
        artifact_file=artifact_file,
        bundle_schema_path=bundle_schema_path,
        validation_schema_path=validation_schema_path,
        output=bundle_validation_output,
    )
    readiness_output_path = Path(output or DEFAULT_OUTPUT).resolve()
    readiness_validation_output_path = Path(readiness_validation_output or DEFAULT_VALIDATION_OUTPUT).resolve()
    source_kind = "artifact" if artifact_file else "bundle"
    blocking_reasons = build_blocking_reasons(validation_report)
    ready = not blocking_reasons
    report = {
        "generated_at_utc": now_utc(),
        "source_kind": source_kind,
        "artifact_file": validation_report.get("artifact_file"),
        "bundle_path": validation_report.get("bundle_path"),
        "validation_report_path": str(Path(validation_report.get("resolved_bundle_validation_path") or (bundle_validation_output or DEFAULT_BUNDLE_VALIDATION_OUTPUT)).resolve()),
        "bundle_generated_at_utc": validation_report.get("bundle_generated_at_utc"),
        "validation_generated_at_utc": validation_report.get("generated_at_utc"),
        "bundle_validation_verdict": validation_report.get("verdict") or "fail",
        "operator_handoff_validation_verdict": validation_report.get("operator_handoff_validation_verdict"),
        "operator_handoff_bundle_path": validation_report.get("operator_handoff_bundle_path"),
        "operator_handoff_bundle_validation_path": validation_report.get("operator_handoff_bundle_validation_path"),
        "operator_handoff_bundle_readiness_path": validation_report.get("operator_handoff_bundle_readiness_path"),
        "operator_handoff_bundle_readiness_validation_path": validation_report.get("operator_handoff_bundle_readiness_validation_path"),
        "priority_preview_ref": validation_report.get("priority_preview_ref"),
        "priority_display_packet_ref": validation_report.get("priority_display_packet_ref"),
        "priority_headline": validation_report.get("priority_headline"),
        "priority_cta_command": validation_report.get("priority_cta_command"),
        "display_title": validation_report.get("display_title"),
        "cta_command": validation_report.get("cta_command"),
        "error_count": validation_report.get("error_count", 0),
        "warning_count": validation_report.get("warning_count", 0),
        "errors": list(validation_report.get("errors") or []),
        "warnings": list(validation_report.get("warnings") or []),
        "ready": ready,
        "readiness_status": "ready" if ready else "blocked",
        "blocking_reasons": blocking_reasons,
        "next_step": "none" if ready else build_next_step(source_kind, artifact_file, bundle_file),
    }
    validator = load_validator_module()
    schema_path = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-bundle-readiness.schema.json"
    schema_doc = validator.load_json(schema_path)
    readiness_validation_report = validator.build_report(readiness_output_path, schema_path, report, schema_doc)
    validator.write_json(readiness_validation_output_path, readiness_validation_report)
    if readiness_validation_report["verdict"] != "pass":
        raise SystemExit(
            "invalid supervisor operator handoff bundle readiness report: "
            + "; ".join(readiness_validation_report["errors"])
        )
    write_json(readiness_output_path, report)
    return report, readiness_validation_report


def parse_args():
    parser = argparse.ArgumentParser(description="Assess supervisor operator handoff bundle readiness")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--bundle-file")
    group.add_argument("--artifact-file")
    parser.add_argument("--bundle-schema", default=None)
    parser.add_argument("--validation-schema", default=None)
    parser.add_argument("--bundle-validation-output", default=str(DEFAULT_BUNDLE_VALIDATION_OUTPUT))
    parser.add_argument("--output", "--readiness-report", dest="output", default=str(DEFAULT_OUTPUT))
    parser.add_argument(
        "--readiness-validation-output",
        "--validation-output",
        dest="readiness_validation_output",
        default=str(DEFAULT_VALIDATION_OUTPUT),
    )
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report, _readiness_validation = assess_handoff_bundle_readiness(
        bundle_file=args.bundle_file,
        artifact_file=args.artifact_file,
        bundle_schema_path=args.bundle_schema,
        validation_schema_path=args.validation_schema,
        bundle_validation_output=args.bundle_validation_output,
        output=args.output,
        readiness_validation_output=args.readiness_validation_output,
    )
    print(f"report written: {Path(args.output).resolve()}")
    print(f"readiness_status={report['readiness_status']} ready={report['ready']}")
    return 0 if report["ready"] or not args.strict else 1


if __name__ == "__main__":
    raise SystemExit(main())
