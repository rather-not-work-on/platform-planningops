#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import resolve_plain_python_compat_manifest as resolver
import resolve_plain_python_compat_manifest_status as status_bundle_resolver
import validate_plain_python_compat_manifest_status as status_validation
import validate_plain_python_compat_manifest_status_bundle as status_bundle_validation
from validate_plain_python_compat_manifest import (
    DEFAULT_OUTPUT as DEFAULT_VALIDATION_OUTPUT,
    load_json,
    now_utc,
    validate_schema,
    validate_semantics,
    write_json,
)


DEFAULT_MANIFEST = resolver.default_manifest_path()
DEFAULT_SCHEMA = resolver.repo_root() / "planningops/schemas/plain-python-compat-manifest.schema.json"
DEFAULT_STATUS_OUTPUT = resolver.repo_root() / "planningops/artifacts/validation/plain-python-compat-manifest-status.json"
DEFAULT_STATUS_SCHEMA = status_validation.DEFAULT_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = status_bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_STATUS_VALIDATION_OUTPUT = status_validation.DEFAULT_OUTPUT
DEFAULT_STATUS_BUNDLE_OUTPUT = status_bundle_resolver.DEFAULT_OUTPUT
DEFAULT_STATUS_BUNDLE_SCHEMA = status_bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_BUNDLE_VALIDATION_OUTPUT = status_bundle_validation.DEFAULT_OUTPUT


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Print plain python compatibility manifest status")
    parser.add_argument("--manifest-file", default=str(DEFAULT_MANIFEST))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--validation-output", default=str(DEFAULT_VALIDATION_OUTPUT))
    parser.add_argument("--status-output", default=str(DEFAULT_STATUS_OUTPUT))
    parser.add_argument("--status-schema-file", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--status-validation-output", default=str(DEFAULT_STATUS_VALIDATION_OUTPUT))
    parser.add_argument("--status-bundle-schema-file", default=str(DEFAULT_STATUS_BUNDLE_SCHEMA))
    parser.add_argument("--status-bundle-output", default=str(DEFAULT_STATUS_BUNDLE_OUTPUT))
    parser.add_argument("--status-bundle-validation-output", default=str(DEFAULT_STATUS_BUNDLE_VALIDATION_OUTPUT))
    parser.add_argument("--require-pass", action="store_true")
    return parser.parse_args()


def build_report(manifest_file: Path, schema_file: Path) -> dict:
    doc = load_json(manifest_file)
    schema_doc = load_json(schema_file)

    schema_errors = validate_schema(doc, schema_doc)
    semantic_errors, warnings, resolved_report, resolved_guardrail_script_paths = validate_semantics(
        manifest_file,
        doc,
    )
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    report = {
        "manifest_path": str(manifest_file.resolve()),
        "schema_path": str(schema_file.resolve()),
        "generated_at_utc": now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "entrypoint_count": len(doc.get("entrypoints", [])) if isinstance(doc.get("entrypoints"), list) else 0,
        "runtime_stack_sequence": doc.get("runtime_stack_sequence"),
        "loop_guardrails_chain": doc.get("loop_guardrails_chain"),
        "resolved_guardrail_script_paths": resolved_guardrail_script_paths,
    }
    if resolved_report is not None:
        report["resolved_entrypoint_count"] = resolved_report["entrypoint_count"]
        report["resolved_runtime_stack_sequence"] = resolved_report["runtime_stack_sequence"]
        report["resolved_loop_guardrails_chain"] = resolved_report["loop_guardrails_chain"]
    return report


def build_status_report(validation_report: dict, status_output: Path, status_validation_output: Path) -> dict:
    status_report = dict(validation_report)
    status_report["status_output_path"] = str(status_output.resolve())
    status_report["status_validation_output_path"] = str(status_validation_output.resolve())
    status_report["ready"] = validation_report.get("verdict") == "pass"
    if status_report["ready"]:
        status_report["next_step"] = "none"
    else:
        status_report["next_step"] = (
            "python3 planningops/scripts/validate_plain_python_compat_manifest.py --manifest-file "
            f"{validation_report.get('manifest_path')} --schema-file {validation_report.get('schema_path')} "
            "--output <plain-python-compat-manifest-validation.json> --strict"
        )
    return status_report


def render_lines(
    report: dict,
    status_validation_report: dict,
    status_bundle_report: dict,
    status_bundle_validation_report: dict,
) -> list[str]:
    sequence = report.get("resolved_runtime_stack_sequence") or report.get("runtime_stack_sequence") or {}
    loop_guardrails_chain = report.get("resolved_loop_guardrails_chain") or report.get("loop_guardrails_chain") or []
    loop_guardrails_ids = [
        step.get("id")
        for step in loop_guardrails_chain
        if isinstance(step, dict) and isinstance(step.get("id"), str) and step.get("id")
    ]
    errors = list(report.get("errors") or [])
    warnings = list(report.get("warnings") or [])
    lines = [
        f"manifest path: {report.get('manifest_path') or 'missing'}",
        f"schema path: {report.get('schema_path') or 'missing'}",
        f"validation output path: {report.get('validation_output_path') or 'missing'}",
        f"status output path: {report.get('status_output_path') or 'missing'}",
        f"status validation output path: {report.get('status_validation_output_path') or 'missing'}",
        f"status bundle output path: {status_bundle_report.get('resolved_status_bundle_path') or 'missing'}",
        f"status bundle validation output path: {status_bundle_validation_report.get('output_path') or 'missing'}",
        f"verdict: {report.get('verdict') or 'unknown'}",
        f"status validation verdict: {status_validation_report.get('verdict') or 'unknown'}",
        f"status bundle verdict: {status_bundle_report.get('status_validation_verdict') or 'unknown'}",
        f"status bundle validation verdict: {status_bundle_validation_report.get('verdict') or 'unknown'}",
        f"entrypoint count: {report.get('entrypoint_count', 0)}",
        f"resolved entrypoint count: {report.get('resolved_entrypoint_count', 'unknown')}",
        f"issue-driven entrypoint id: {sequence.get('issue_driven_entrypoint_id') or 'missing'}",
        f"issue-driven resolved path: {sequence.get('issue_driven_resolved_path') or 'missing'}",
        f"local entrypoint id: {sequence.get('local_entrypoint_id') or 'missing'}",
        f"local resolved path: {sequence.get('local_resolved_path') or 'missing'}",
        f"loop-guardrails step count: {len(loop_guardrails_ids)}",
        "loop-guardrails chain ids: missing"
        if not loop_guardrails_ids
        else f"loop-guardrails chain ids: {' -> '.join(loop_guardrails_ids)}",
        f"warning count: {report.get('warning_count', 0)}",
        f"error count: {report.get('error_count', 0)}",
        f"status validation error count: {status_validation_report.get('error_count', 0)}",
        f"status bundle validation error count: {status_bundle_validation_report.get('error_count', 0)}",
        "errors: none" if not errors else f"errors: {'; '.join(errors)}",
        "warnings: none" if not warnings else f"warnings: {'; '.join(warnings)}",
    ]
    lines.append(f"ready: {report.get('ready')}")
    lines.append(f"next step: {report.get('next_step') or 'none'}")
    return lines


def main() -> int:
    args = parse_args()
    validation_report = build_report(Path(args.manifest_file), Path(args.schema_file))
    validation_report["validation_output_path"] = str(Path(args.validation_output).resolve())
    write_json(Path(args.validation_output), validation_report)
    status_report = build_status_report(
        validation_report,
        Path(args.status_output),
        Path(args.status_validation_output),
    )
    write_json(Path(args.status_output), status_report)
    status_validation_report = status_validation.build_validation_report(
        Path(args.status_output),
        Path(args.status_schema_file),
        Path(args.status_validation_output),
    )
    write_json(Path(args.status_validation_output), status_validation_report)
    status_bundle_report = status_bundle_resolver.resolve_status_bundle(
        artifact_file=None,
        status_file=args.status_output,
        status_validation_file=None,
        status_schema=args.status_schema_file,
        status_validation_schema=args.status_validation_schema_file,
        bundle_schema=args.status_bundle_schema_file,
        output=args.status_bundle_output,
    )
    status_bundle_validation_report = status_bundle_validation.build_validation_report(
        Path(args.status_bundle_output),
        Path(args.status_bundle_schema_file),
        Path(args.status_bundle_validation_output),
        status_schema_path=Path(args.status_schema_file),
        status_validation_schema_path=Path(args.status_validation_schema_file),
    )
    write_json(Path(args.status_bundle_validation_output), status_bundle_validation_report)
    for line in render_lines(
        status_report,
        status_validation_report,
        status_bundle_report,
        status_bundle_validation_report,
    ):
        print(line)
    if args.require_pass and (
        not status_report.get("ready")
        or status_validation_report.get("verdict") != "pass"
        or status_bundle_report.get("status_validation_verdict") != "pass"
        or status_bundle_validation_report.get("verdict") != "pass"
    ):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
