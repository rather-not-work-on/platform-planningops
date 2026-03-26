#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile.json"
DEFAULT_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-validation.json"
RERUN_HINT = "bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def resolve_artifact_path(value) -> Path | None:
    if not isinstance(value, str) or not value:
        return None
    path = Path(value)
    if not path.is_absolute():
        path = (WORKSPACE_ROOT / path).resolve()
    else:
        path = path.resolve()
    return path


def validation_matches_report(report_doc: dict | None, validation_doc: dict | None, report_path: Path, validation_path: Path) -> bool:
    if not isinstance(report_doc, dict) or not isinstance(validation_doc, dict):
        return False
    if resolve_artifact_path(validation_doc.get("reconcile_report_path")) != report_path.resolve():
        return False
    if resolve_artifact_path(validation_doc.get("output_path")) != validation_path.resolve():
        return False
    expected_fields = (
        ("reconcile_generated_at_utc", "generated_at_utc"),
        ("reconcile_run_id", "run_id"),
        ("reconcile_status", "status"),
        ("reconcile_restored", "restored"),
        ("reconcile_check_name", "check_name"),
        ("reconcile_checkpoint_check_count", "checkpoint_check_count"),
        ("reconcile_summary_check_count", "summary_check_count"),
        ("reconcile_count", "reconcile_count"),
        ("reconcile_restored_check_names", "restored_check_names"),
    )
    for validation_field, report_field in expected_fields:
        if validation_doc.get(validation_field) != report_doc.get(report_field):
            return False
    return True


def build_status(report_path: Path, validation_path: Path) -> dict:
    status = {
        "report_path": str(report_path),
        "validation_report_path": str(validation_path),
        "report_present": report_path.exists(),
        "validation_present": validation_path.exists(),
        "run_id": None,
        "reconcile_status": None,
        "check_name": None,
        "checkpoint_check_count": None,
        "summary_check_count": None,
        "reconcile_count": None,
        "restored_check_names": [],
        "reasons": [],
        "validation_verdict": "missing",
        "validation_state": "missing",
        "ready": False,
        "next_step": RERUN_HINT,
    }

    if not report_path.exists():
        return status

    report_doc = load_json(report_path)
    validation_doc = load_json(validation_path) if validation_path.exists() else None

    status["run_id"] = report_doc.get("run_id")
    status["reconcile_status"] = report_doc.get("status")
    status["check_name"] = report_doc.get("check_name")
    status["checkpoint_check_count"] = report_doc.get("checkpoint_check_count")
    status["summary_check_count"] = report_doc.get("summary_check_count")
    status["reconcile_count"] = report_doc.get("reconcile_count")
    status["restored_check_names"] = list(report_doc.get("restored_check_names") or [])
    status["reasons"] = list(report_doc.get("reasons") or [])

    if isinstance(validation_doc, dict):
        status["validation_verdict"] = str(validation_doc.get("verdict") or "unknown")
        status["validation_state"] = (
            "fresh" if validation_matches_report(report_doc, validation_doc, report_path, validation_path) else "stale"
        )

    if status["validation_verdict"] == "pass" and status["validation_state"] == "fresh":
        status["ready"] = True
        status["next_step"] = "none"

    return status


def render_status_lines(status: dict) -> list[str]:
    if not status["report_present"]:
        return [
            f"tmp-summary reconcile status: missing ({status['report_path']})",
            f"validation verdict: {status['validation_verdict']}",
            f"validation state: {status['validation_state']}",
            f"next step: {status['next_step']}",
        ]

    return [
        f"tmp-summary reconcile run_id: {status['run_id'] or 'unknown'}",
        f"tmp-summary reconcile status: {status['reconcile_status'] or 'unknown'}",
        f"tmp-summary reconcile check: {status['check_name'] or 'none'}",
        f"checkpoint check count: {status['checkpoint_check_count'] if status['checkpoint_check_count'] is not None else 'unknown'}",
        f"summary check count: {status['summary_check_count'] if status['summary_check_count'] is not None else 'unknown'}",
        f"tmp-summary reconcile count: {status['reconcile_count'] if status['reconcile_count'] is not None else 'unknown'}",
        "tmp-summary reconcile restored checks: none"
        if not status["restored_check_names"]
        else f"tmp-summary reconcile restored checks: {', '.join(status['restored_check_names'])}",
        "tmp-summary reconcile reasons: none"
        if not status["reasons"]
        else f"tmp-summary reconcile reasons: {', '.join(status['reasons'])}",
        f"validation verdict: {status['validation_verdict']}",
        f"validation state: {status['validation_state']}",
        f"next step: {status['next_step']}",
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Print the latest federated CI tmp-summary reconcile status")
    parser.add_argument("--report-file", default=str(DEFAULT_REPORT))
    parser.add_argument("--validation-report", default=str(DEFAULT_VALIDATION))
    parser.add_argument("--require-pass", action="store_true")
    args = parser.parse_args()

    status = build_status(Path(args.report_file).resolve(), Path(args.validation_report).resolve())
    for line in render_status_lines(status):
        print(line)
    return 1 if args.require_pass and not status["ready"] else 0


if __name__ == "__main__":
    sys.exit(main())
