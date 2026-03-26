#!/usr/bin/env python3

from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import validate_plain_python_compat_manifest as schema_validation


WORKSPACE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_REPORT = WORKSPACE_ROOT / "artifacts/validation/federated-ci-summary-tmp-reconcile.json"
DEFAULT_SCHEMA = WORKSPACE_ROOT / "schemas/federated-ci-summary-tmp-reconcile.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "artifacts/validation/federated-ci-summary-tmp-reconcile-validation.json"


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def validate_semantics(report_path: Path, output_path: Path, doc: dict[str, Any]) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    generated_at_utc = doc.get("generated_at_utc")
    summary_path = doc.get("summary_path")
    checkpoint_path = doc.get("checkpoint_path")
    report_output_path = doc.get("output_path")
    run_id = doc.get("run_id")
    check_name = doc.get("check_name")
    checkpoint_check_count = doc.get("checkpoint_check_count")
    summary_check_count = doc.get("summary_check_count")
    restored = doc.get("restored")
    status = doc.get("status")
    reasons = doc.get("reasons")
    reconcile_count = doc.get("reconcile_count")
    restored_check_names = doc.get("restored_check_names")

    if not isinstance(generated_at_utc, str) or not generated_at_utc.strip():
        append_unique(errors, "generated_at_utc must be a non-empty string")
    if not isinstance(summary_path, str) or not summary_path.strip():
        append_unique(errors, "summary_path must be a non-empty string")
    if not isinstance(checkpoint_path, str) or not checkpoint_path.strip():
        append_unique(errors, "checkpoint_path must be a non-empty string")
    if report_output_path is not None and report_output_path != str(report_path.resolve()):
        append_unique(errors, "output_path must match the reconciled report path")
    if not isinstance(run_id, str) or not run_id.strip():
        append_unique(errors, "run_id must be a non-empty string")
    if check_name is not None and (not isinstance(check_name, str) or not check_name.strip()):
        append_unique(errors, "check_name must be null or a non-empty string")
    if not isinstance(checkpoint_check_count, int) or isinstance(checkpoint_check_count, bool) or checkpoint_check_count < 0:
        append_unique(errors, "checkpoint_check_count must be a non-negative integer")
    if summary_check_count is not None and (
        not isinstance(summary_check_count, int) or isinstance(summary_check_count, bool) or summary_check_count < 0
    ):
        append_unique(errors, "summary_check_count must be null or a non-negative integer")
    if not isinstance(restored, bool):
        append_unique(errors, "restored must be a boolean")
    if status not in {"healthy", "restored"}:
        append_unique(errors, "status must be one of: healthy, restored")
    if not isinstance(reconcile_count, int) or isinstance(reconcile_count, bool) or reconcile_count < 0:
        append_unique(errors, "reconcile_count must be a non-negative integer")
    if not isinstance(restored_check_names, list):
        append_unique(errors, "restored_check_names must be an array")
        restored_check_names = []
    elif any(not isinstance(name, str) or not name.strip() for name in restored_check_names):
        append_unique(errors, "restored_check_names must only contain non-empty strings")
    elif len(set(restored_check_names)) != len(restored_check_names):
        append_unique(errors, "restored_check_names must not contain duplicates")
    if not isinstance(reasons, list):
        append_unique(errors, "reasons must be an array")
        reasons = []
    elif any(not isinstance(reason, str) or not reason.strip() for reason in reasons):
        append_unique(errors, "reasons must only contain non-empty strings")

    if isinstance(reasons, list):
        if restored and not reasons:
            append_unique(errors, "restored=true requires a non-empty reasons array")
        if not restored and reasons:
            append_unique(errors, "restored=false requires an empty reasons array")

    if restored is True and status != "restored":
        append_unique(errors, "status must be 'restored' when restored=true")
    if restored is False and status != "healthy":
        append_unique(errors, "status must be 'healthy' when restored=false")
    if isinstance(reconcile_count, int) and isinstance(restored_check_names, list) and reconcile_count != len(restored_check_names):
        append_unique(errors, "reconcile_count must equal len(restored_check_names)")
    if restored and check_name is None:
        append_unique(errors, "check_name must be present when restored=true")
    if restored and isinstance(restored_check_names, list) and check_name not in restored_check_names:
        append_unique(errors, "restored_check_names must include check_name when restored=true")

    if isinstance(checkpoint_check_count, int) and isinstance(summary_check_count, int):
        if restored and summary_check_count != checkpoint_check_count:
            append_unique(errors, "summary_check_count must equal checkpoint_check_count when restored=true")
        if not restored and summary_check_count < checkpoint_check_count:
            append_unique(errors, "summary_check_count must be >= checkpoint_check_count when restored=false")

    if summary_check_count is None and not restored:
        append_unique(errors, "summary_check_count must be present when restored=false")

    return errors, warnings


def build_validation_report(report_path: Path, schema_path: Path, output_path: Path) -> dict[str, Any]:
    doc = schema_validation.load_json(report_path)
    schema_doc = schema_validation.load_json(schema_path)

    schema_errors = schema_validation.validate_schema(doc, schema_doc)
    semantic_errors, warnings = validate_semantics(report_path, output_path, doc)
    errors = schema_errors + semantic_errors

    return {
        "reconcile_report_path": str(report_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "output_path": str(output_path.resolve()),
        "generated_at_utc": schema_validation.now_utc(),
        "verdict": "pass" if not errors else "fail",
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "reconcile_generated_at_utc": doc.get("generated_at_utc"),
        "reconcile_run_id": doc.get("run_id"),
        "reconcile_status": doc.get("status"),
        "reconcile_restored": doc.get("restored"),
        "reconcile_check_name": doc.get("check_name"),
        "reconcile_checkpoint_check_count": doc.get("checkpoint_check_count"),
        "reconcile_summary_check_count": doc.get("summary_check_count"),
        "reconcile_count": doc.get("reconcile_count"),
        "reconcile_restored_check_names": doc.get("restored_check_names"),
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate federated CI tmp-summary reconcile reports.")
    parser.add_argument("--report-file", default=str(DEFAULT_REPORT))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    report_path = Path(args.report_file)
    schema_path = Path(args.schema_file)
    output_path = Path(args.output)

    report = build_validation_report(report_path, schema_path, output_path)
    schema_validation.write_json(output_path, report)
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
