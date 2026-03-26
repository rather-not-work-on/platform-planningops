#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from doctor_federated_ci_summary_tmp_reconcile import RERUN_HINT, load_json, resolve_artifact_path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_BUNDLE = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle.json"
DEFAULT_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-validation.json"
DEFAULT_STATUS_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status.json"
DEFAULT_STATUS_VALIDATION_OUTPUT = (
    WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-validation.json"
)
DEFAULT_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-validation.schema.json"
)
STATUS_VALIDATOR = WORKSPACE_ROOT / "planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py"


def now_utc() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat()


def write_status(output: str | None, status: dict, *, status_validation_output: str | None = None) -> Path | None:
    if not output:
        return None
    output_path = resolve_output_path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    rendered = dict(status)
    rendered["generated_at_utc"] = now_utc()
    rendered["output_path"] = str(output_path)
    rendered["status_validation_output_path"] = (
        str(resolve_output_path(status_validation_output)) if status_validation_output else None
    )
    output_path.write_text(json.dumps(rendered, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return output_path


def resolve_output_path(output: str) -> Path:
    output_path = Path(output)
    if not output_path.is_absolute():
        return (WORKSPACE_ROOT / output_path).resolve()
    return output_path.resolve()


def write_status_validation(
    *,
    status_path: Path | None,
    bundle_path: Path,
    validation_path: Path,
    output: str | None,
    validation_schema_file: str,
) -> tuple[Path | None, str, int]:
    if status_path is None or not output:
        return None, "skipped", 0
    output_path = resolve_output_path(output)
    command = [
        sys.executable,
        str(STATUS_VALIDATOR),
        "--status-file",
        str(status_path),
        "--bundle-file",
        str(bundle_path.resolve()),
        "--bundle-validation-report",
        str(validation_path.resolve()),
        "--validation-schema-file",
        str(resolve_output_path(validation_schema_file)),
        "--output",
        str(output_path),
        "--strict",
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    verdict = "missing"
    if output_path.exists():
        validation_doc = load_json(output_path)
        verdict = str(validation_doc.get("verdict") or "unknown")
    elif result.returncode == 0:
        verdict = "unknown"
    return output_path, verdict, result.returncode


def validation_matches_bundle(bundle_doc: dict | None, validation_doc: dict | None, bundle_path: Path, validation_path: Path) -> bool:
    if not isinstance(bundle_doc, dict) or not isinstance(validation_doc, dict):
        return False
    if resolve_artifact_path(validation_doc.get("bundle_path")) != bundle_path.resolve():
        return False
    if resolve_artifact_path(validation_doc.get("output_path")) != validation_path.resolve():
        return False
    path_fields = (
        ("artifact_file", "artifact_file"),
        ("reconcile_report_path", "reconcile_report_path"),
        ("reconcile_validation_report_path", "reconcile_validation_report_path"),
    )
    for validation_field, bundle_field in path_fields:
        if resolve_artifact_path(validation_doc.get(validation_field)) != resolve_artifact_path(bundle_doc.get(bundle_field)):
            return False
    expected_fields = (
        ("bundle_generated_at_utc", "generated_at_utc"),
        ("run_id", "run_id"),
        ("reconcile_status", "reconcile_status"),
        ("reconcile_check_name", "reconcile_check_name"),
        ("reconcile_count", "reconcile_count"),
    )
    for validation_field, bundle_field in expected_fields:
        if validation_doc.get(validation_field) != bundle_doc.get(bundle_field):
            return False
    nested_validation = bundle_doc.get("reconcile_validation_report")
    nested_verdict = nested_validation.get("verdict") if isinstance(nested_validation, dict) else None
    if validation_doc.get("reconcile_validation_verdict") != nested_verdict:
        return False
    return True


def build_status(bundle_path: Path, validation_path: Path) -> dict:
    status = {
        "bundle_path": str(bundle_path),
        "validation_report_path": str(validation_path),
        "bundle_present": bundle_path.exists(),
        "validation_present": validation_path.exists(),
        "artifact_file": None,
        "reconcile_report_path": None,
        "reconcile_validation_report_path": None,
        "run_id": None,
        "reconcile_status": None,
        "check_name": None,
        "reconcile_count": None,
        "reconcile_validation_verdict": "missing",
        "bundle_validation_verdict": "missing",
        "bundle_validation_state": "missing",
        "ready": False,
        "next_step": RERUN_HINT,
    }

    if not bundle_path.exists():
        return status

    bundle_doc = load_json(bundle_path)
    validation_doc = load_json(validation_path) if validation_path.exists() else None

    status["artifact_file"] = bundle_doc.get("artifact_file")
    status["reconcile_report_path"] = bundle_doc.get("reconcile_report_path")
    status["reconcile_validation_report_path"] = bundle_doc.get("reconcile_validation_report_path")
    status["run_id"] = bundle_doc.get("run_id")
    status["reconcile_status"] = bundle_doc.get("reconcile_status")
    status["check_name"] = bundle_doc.get("reconcile_check_name")
    status["reconcile_count"] = bundle_doc.get("reconcile_count")
    nested_validation = bundle_doc.get("reconcile_validation_report")
    if isinstance(nested_validation, dict):
        status["reconcile_validation_verdict"] = str(nested_validation.get("verdict") or "unknown")

    if isinstance(validation_doc, dict):
        status["bundle_validation_verdict"] = str(validation_doc.get("verdict") or "unknown")
        status["bundle_validation_state"] = (
            "fresh" if validation_matches_bundle(bundle_doc, validation_doc, bundle_path, validation_path) else "stale"
        )

    if (
        status["bundle_validation_verdict"] == "pass"
        and status["bundle_validation_state"] == "fresh"
        and status["reconcile_validation_verdict"] == "pass"
    ):
        status["ready"] = True
        status["next_step"] = "none"

    return status


def render_status_lines(status: dict) -> list[str]:
    if not status["bundle_present"]:
        return [
            f"tmp-summary reconcile bundle status: missing ({status['bundle_path']})",
            f"tmp-summary reconcile bundle validation verdict: {status['bundle_validation_verdict']}",
            f"tmp-summary reconcile bundle validation state: {status['bundle_validation_state']}",
            f"next step: {status['next_step']}",
        ]

    return [
        f"tmp-summary reconcile bundle run_id: {status['run_id'] or 'unknown'}",
        f"tmp-summary reconcile bundle status: {status['reconcile_status'] or 'unknown'}",
        f"tmp-summary reconcile bundle check: {status['check_name'] or 'none'}",
        f"tmp-summary reconcile bundle count: {status['reconcile_count'] if status['reconcile_count'] is not None else 'unknown'}",
        f"tmp-summary reconcile nested validation verdict: {status['reconcile_validation_verdict']}",
        f"tmp-summary reconcile bundle validation verdict: {status['bundle_validation_verdict']}",
        f"tmp-summary reconcile bundle validation state: {status['bundle_validation_state']}",
        f"next step: {status['next_step']}",
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Print the latest federated CI tmp-summary reconcile bundle status")
    parser.add_argument("--bundle-file", default=str(DEFAULT_BUNDLE))
    parser.add_argument("--validation-report", default=str(DEFAULT_VALIDATION))
    parser.add_argument("--status-output", default=str(DEFAULT_STATUS_OUTPUT))
    parser.add_argument("--status-validation-output", default=str(DEFAULT_STATUS_VALIDATION_OUTPUT))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--require-pass", action="store_true")
    args = parser.parse_args()

    bundle_path = Path(args.bundle_file).resolve()
    validation_path = Path(args.validation_report).resolve()
    status = build_status(bundle_path, validation_path)
    status_output_path = write_status(
        args.status_output,
        status,
        status_validation_output=args.status_validation_output,
    )
    status_validation_output_path, status_validation_verdict, status_validation_rc = write_status_validation(
        status_path=status_output_path,
        bundle_path=bundle_path,
        validation_path=validation_path,
        output=args.status_validation_output,
        validation_schema_file=args.status_validation_schema_file,
    )
    for line in render_status_lines(status):
        print(line)
    if status_output_path is not None:
        print(f"status output path: {status_output_path}")
    if status_validation_output_path is not None:
        print(f"tmp-summary reconcile bundle status validation verdict: {status_validation_verdict}")
        print(f"status validation output path: {status_validation_output_path}")
    if status_validation_rc != 0:
        return 1
    return 1 if args.require_pass and not status["ready"] else 0


if __name__ == "__main__":
    sys.exit(main())
