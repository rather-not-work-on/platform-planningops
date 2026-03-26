#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import resolve_plain_python_compat_manifest as resolver
import validate_plain_python_compat_manifest as manifest_validation


DEFAULT_STATUS = resolver.repo_root() / "planningops/artifacts/validation/plain-python-compat-manifest-status.json"
DEFAULT_SCHEMA = resolver.repo_root() / "planningops/schemas/plain-python-compat-manifest-status.schema.json"
DEFAULT_OUTPUT = (
    resolver.repo_root() / "planningops/artifacts/validation/plain-python-compat-manifest-status-validation.json"
)


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def validate_semantics(status_path: Path, doc: dict[str, Any]) -> tuple[list[str], list[str], dict[str, Any] | None]:
    errors: list[str] = []
    warnings: list[str] = []

    status_output_path = doc.get("status_output_path")
    status_validation_output_path = doc.get("status_validation_output_path")
    validation_output_path = doc.get("validation_output_path")
    manifest_path = doc.get("manifest_path")
    resolved_guardrail_script_paths = doc.get("resolved_guardrail_script_paths")
    verdict = doc.get("verdict")
    ready = doc.get("ready")
    next_step = doc.get("next_step")
    runtime_stack_sequence = doc.get("runtime_stack_sequence")
    resolved_runtime_stack_sequence = doc.get("resolved_runtime_stack_sequence")
    loop_guardrails_chain = doc.get("loop_guardrails_chain")
    resolved_loop_guardrails_chain = doc.get("resolved_loop_guardrails_chain")

    if status_output_path != str(status_path.resolve()):
        append_unique(errors, "status_output_path must match the validated status file path")
    if not isinstance(status_validation_output_path, str) or not status_validation_output_path.strip():
        append_unique(errors, "status_validation_output_path must be a non-empty string")
    if not isinstance(validation_output_path, str) or not validation_output_path.strip():
        append_unique(errors, "validation_output_path must be a non-empty string")
    if not isinstance(manifest_path, str) or not manifest_path.strip():
        append_unique(errors, "manifest_path must be a non-empty string")
    if not isinstance(resolved_guardrail_script_paths, list) or not resolved_guardrail_script_paths:
        append_unique(errors, "resolved_guardrail_script_paths must be a non-empty array")

    if verdict == "pass" and ready is not True:
        append_unique(errors, "ready must be true when verdict=pass")
    if verdict == "fail" and ready is not False:
        append_unique(errors, "ready must be false when verdict=fail")
    if ready is True and next_step != "none":
        append_unique(errors, "next_step must be 'none' when ready=true")
    if ready is False and (not isinstance(next_step, str) or not next_step.strip() or next_step == "none"):
        append_unique(errors, "next_step must be a non-empty remediation step when ready=false")

    if isinstance(runtime_stack_sequence, dict) and isinstance(resolved_runtime_stack_sequence, dict):
        if resolved_runtime_stack_sequence.get("issue_driven_entrypoint_id") != runtime_stack_sequence.get(
            "issue_driven_entrypoint_id"
        ):
            append_unique(errors, "resolved_runtime_stack_sequence.issue_driven_entrypoint_id must match runtime_stack_sequence")
        if resolved_runtime_stack_sequence.get("local_entrypoint_id") != runtime_stack_sequence.get("local_entrypoint_id"):
            append_unique(errors, "resolved_runtime_stack_sequence.local_entrypoint_id must match runtime_stack_sequence")

    if isinstance(loop_guardrails_chain, list) and isinstance(resolved_loop_guardrails_chain, list):
        loop_ids = [step.get("id") for step in loop_guardrails_chain if isinstance(step, dict)]
        resolved_loop_ids = [step.get("id") for step in resolved_loop_guardrails_chain if isinstance(step, dict)]
        if resolved_loop_ids != loop_ids:
            append_unique(errors, "resolved_loop_guardrails_chain ids must preserve loop_guardrails_chain order")

    resolved_report: dict[str, Any] | None = None
    if isinstance(manifest_path, str) and manifest_path.strip():
        try:
            resolved_report = resolver.build_report(Path(manifest_path), resolver.repo_root())
        except SystemExit as exc:
            append_unique(errors, str(exc))

    if resolved_report is not None:
        if doc.get("resolved_entrypoint_count") != resolved_report.get("entrypoint_count"):
            append_unique(errors, "resolved_entrypoint_count must match canonical manifest resolution")
        canonical_guardrail_script_paths = manifest_validation.inspect_guardrail_script_paths(
            resolved_report.get("loop_guardrails_chain", []),
            resolver.repo_root(),
            [],
        )
        if resolved_guardrail_script_paths != canonical_guardrail_script_paths:
            append_unique(errors, "resolved_guardrail_script_paths must match canonical manifest resolution")
        canonical_sequence = resolved_report.get("runtime_stack_sequence") or {}
        if isinstance(resolved_runtime_stack_sequence, dict):
            if resolved_runtime_stack_sequence.get("issue_driven_entrypoint_id") != canonical_sequence.get(
                "issue_driven_entrypoint_id"
            ):
                append_unique(
                    errors,
                    "resolved_runtime_stack_sequence.issue_driven_entrypoint_id must match canonical manifest resolution",
                )
            if resolved_runtime_stack_sequence.get("local_entrypoint_id") != canonical_sequence.get("local_entrypoint_id"):
                append_unique(
                    errors,
                    "resolved_runtime_stack_sequence.local_entrypoint_id must match canonical manifest resolution",
                )
        canonical_loop_ids = [step["id"] for step in resolved_report.get("loop_guardrails_chain", [])]
        if isinstance(resolved_loop_guardrails_chain, list):
            resolved_loop_ids = [step.get("id") for step in resolved_loop_guardrails_chain if isinstance(step, dict)]
            if resolved_loop_ids != canonical_loop_ids:
                append_unique(errors, "resolved_loop_guardrails_chain ids must match canonical manifest resolution")

    return errors, warnings, resolved_report


def build_validation_report(status_path: Path, schema_path: Path, output_path: Path) -> dict[str, Any]:
    doc = manifest_validation.load_json(status_path)
    schema_doc = manifest_validation.load_json(schema_path)

    schema_errors = manifest_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings, resolved_report = validate_semantics(status_path, doc)
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    if doc.get("status_validation_output_path") != str(output_path.resolve()):
        append_unique(errors, "status_validation_output_path must match the validation output path")
        verdict = "fail"

    report = {
        "status_path": str(status_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": manifest_validation.now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "status_generated_at_utc": doc.get("generated_at_utc"),
        "status_output_path": doc.get("status_output_path"),
        "status_validation_output_path": doc.get("status_validation_output_path"),
        "validation_output_path": doc.get("validation_output_path"),
        "manifest_path": doc.get("manifest_path"),
        "resolved_guardrail_script_paths": doc.get("resolved_guardrail_script_paths"),
        "status_verdict": doc.get("verdict"),
        "status_ready": doc.get("ready"),
        "status_next_step": doc.get("next_step"),
        "status_loop_guardrails_step_count": len(doc.get("resolved_loop_guardrails_chain") or []),
    }
    if resolved_report is not None:
        report["canonical_loop_guardrails_step_count"] = len(resolved_report.get("loop_guardrails_chain", []))
    return report


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate plain python compatibility manifest status report.")
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
