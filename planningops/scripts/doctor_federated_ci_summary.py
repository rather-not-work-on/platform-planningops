#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SUMMARY = WORKSPACE_ROOT / "planningops/artifacts/ci/federated-ci-summary.json"
DEFAULT_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-validation.json"
DEFAULT_READINESS = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness.json"
DEFAULT_READINESS_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness-validation.json"
DEFAULT_RECONCILE = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile.json"
DEFAULT_RECONCILE_VALIDATION = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-validation.json"
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


def summarize_failures(summary_doc: dict) -> list[str]:
    failures = []
    for check in summary_doc.get("checks", []):
        if isinstance(check, dict) and check.get("verdict") == "fail":
            name = str(check.get("name") or "unknown")
            domain = str(check.get("domain") or "unknown")
            failures.append(f"{name} ({domain})")
    return failures


def validation_matches_summary(summary_doc: dict, validation_doc: dict | None) -> bool:
    if not isinstance(validation_doc, dict):
        return False
    return (
        validation_doc.get("summary_run_id") == summary_doc.get("run_id")
        and validation_doc.get("summary_generated_at_utc") == summary_doc.get("generated_at_utc")
        and validation_doc.get("summary_verdict") == summary_doc.get("verdict")
    )


def build_status(summary_path: Path, validation_path: Path) -> dict:
    status = {
        "summary_path": str(summary_path),
        "validation_report_path": str(validation_path),
        "summary_present": summary_path.exists(),
        "validation_present": validation_path.exists(),
        "summary_run_id": None,
        "summary_generated_at_utc": None,
        "summary_verdict": None,
        "overall_status": None,
        "check_count": None,
        "failed_checks": [],
        "missing_required_checks": [],
        "validation_verdict": "missing",
        "validation_state": "missing",
        "ready": False,
        "readiness_status": "blocked",
        "blocking_reasons": [],
        "next_step": RERUN_HINT,
    }

    if not summary_path.exists():
        status["blocking_reasons"].append("summary_missing")
        return status

    summary_doc = load_json(summary_path)
    validation_doc = load_json(validation_path) if validation_path.exists() else None

    status["summary_run_id"] = summary_doc.get("run_id")
    status["summary_generated_at_utc"] = summary_doc.get("generated_at_utc")
    status["summary_verdict"] = summary_doc.get("verdict")
    status["overall_status"] = summary_doc.get("overall_status")
    status["check_count"] = summary_doc.get("check_count")
    status["failed_checks"] = summarize_failures(summary_doc)
    status["missing_required_checks"] = list(summary_doc.get("missing_required_checks") or [])

    if isinstance(validation_doc, dict):
        status["validation_verdict"] = str(validation_doc.get("verdict") or "unknown")
        status["validation_state"] = "fresh" if validation_matches_summary(summary_doc, validation_doc) else "stale"

    if status["summary_verdict"] != "pass":
        status["blocking_reasons"].append("summary_verdict_fail")
    if status["validation_verdict"] == "missing":
        status["blocking_reasons"].append("validation_missing")
    elif status["validation_verdict"] != "pass":
        status["blocking_reasons"].append("validation_verdict_fail")
    if status["validation_state"] == "stale":
        status["blocking_reasons"].append("validation_stale")

    if not status["blocking_reasons"]:
        status["ready"] = True
        status["readiness_status"] = "ready"
        status["next_step"] = "none"

    return status


def readiness_matches_status(status: dict, readiness_doc: dict | None, summary_path: Path, validation_path: Path) -> bool:
    if not isinstance(readiness_doc, dict):
        return False
    if resolve_artifact_path(readiness_doc.get("summary_path")) != summary_path.resolve():
        return False
    if resolve_artifact_path(readiness_doc.get("validation_report_path")) != validation_path.resolve():
        return False
    expected_fields = (
        "summary_run_id",
        "summary_generated_at_utc",
        "summary_verdict",
        "overall_status",
        "check_count",
        "validation_verdict",
        "validation_state",
        "ready",
        "readiness_status",
        "next_step",
    )
    for field in expected_fields:
        if readiness_doc.get(field) != status.get(field):
            return False
    if list(readiness_doc.get("failed_checks") or []) != list(status.get("failed_checks") or []):
        return False
    if list(readiness_doc.get("missing_required_checks") or []) != list(status.get("missing_required_checks") or []):
        return False
    if list(readiness_doc.get("blocking_reasons") or []) != list(status.get("blocking_reasons") or []):
        return False
    return True


def readiness_validation_matches(readiness_doc: dict | None, readiness_validation_doc: dict | None, readiness_path: Path) -> bool:
    if not isinstance(readiness_doc, dict) or not isinstance(readiness_validation_doc, dict):
        return False
    if resolve_artifact_path(readiness_validation_doc.get("readiness_path")) != readiness_path.resolve():
        return False
    if readiness_validation_doc.get("readiness_generated_at_utc") != readiness_doc.get("generated_at_utc"):
        return False
    if readiness_validation_doc.get("readiness_summary_run_id") != readiness_doc.get("summary_run_id"):
        return False
    if readiness_validation_doc.get("readiness_status") != readiness_doc.get("readiness_status"):
        return False
    if readiness_validation_doc.get("readiness_ready") != readiness_doc.get("ready"):
        return False
    return True


def reconcile_matches_status(status: dict, reconcile_doc: dict | None, reconcile_path: Path) -> bool:
    if not isinstance(reconcile_doc, dict):
        return False
    if resolve_artifact_path(reconcile_doc.get("output_path")) != reconcile_path.resolve():
        return False
    if reconcile_doc.get("run_id") != status.get("summary_run_id"):
        return False
    reconcile_status = reconcile_doc.get("status")
    if reconcile_status not in {"healthy", "restored"}:
        return False
    reconcile_count = reconcile_doc.get("reconcile_count")
    restored_check_names = reconcile_doc.get("restored_check_names")
    if not isinstance(reconcile_count, int) or isinstance(reconcile_count, bool) or reconcile_count < 0:
        return False
    if not isinstance(restored_check_names, list):
        return False
    if len(restored_check_names) != reconcile_count:
        return False
    if any(not isinstance(name, str) or not name.strip() for name in restored_check_names):
        return False
    return True


def reconcile_validation_matches(
    reconcile_doc: dict | None,
    reconcile_validation_doc: dict | None,
    reconcile_path: Path,
) -> bool:
    if not isinstance(reconcile_doc, dict) or not isinstance(reconcile_validation_doc, dict):
        return False
    if resolve_artifact_path(reconcile_validation_doc.get("reconcile_report_path")) != reconcile_path.resolve():
        return False
    if reconcile_validation_doc.get("reconcile_generated_at_utc") != reconcile_doc.get("generated_at_utc"):
        return False
    if reconcile_validation_doc.get("reconcile_run_id") != reconcile_doc.get("run_id"):
        return False
    if reconcile_validation_doc.get("reconcile_status") != reconcile_doc.get("status"):
        return False
    if reconcile_validation_doc.get("reconcile_restored") != reconcile_doc.get("restored"):
        return False
    if reconcile_validation_doc.get("reconcile_count") != reconcile_doc.get("reconcile_count"):
        return False
    return True


def render_status_lines(status: dict) -> list[str]:
    if not status["summary_present"]:
        return [
            f"summary status: missing ({status['summary_path']})",
            f"next step: {status['next_step']}",
        ]

    return [
        f"summary run_id: {status['summary_run_id'] or 'unknown'}",
        f"summary verdict: {status['summary_verdict'] or 'unknown'}",
        f"overall status: {status['overall_status'] or 'unknown'}",
        f"check count: {status['check_count'] or 'unknown'}",
        "failed checks: none"
        if not status["failed_checks"]
        else f"failed checks: {', '.join(status['failed_checks'])}",
        "missing required checks: none"
        if not status["missing_required_checks"]
        else f"missing required checks: {', '.join(status['missing_required_checks'])}",
        f"validation verdict: {status['validation_verdict']}",
        f"validation state: {status['validation_state']}",
        f"readiness artifact state: {status.get('readiness_artifact_state', 'missing')}",
        f"readiness validation verdict: {status.get('readiness_validation_verdict', 'missing')}",
        f"readiness validation state: {status.get('readiness_validation_state', 'missing')}",
        f"tmp-summary reconcile state: {status.get('reconcile_artifact_state', 'missing')}",
        f"tmp-summary reconcile count: {status.get('reconcile_count', 'unknown')}",
        "tmp-summary reconcile restored checks: none"
        if not status.get("reconcile_restored_check_names")
        else f"tmp-summary reconcile restored checks: {', '.join(status['reconcile_restored_check_names'])}",
        f"tmp-summary reconcile validation verdict: {status.get('reconcile_validation_verdict', 'missing')}",
        f"tmp-summary reconcile validation state: {status.get('reconcile_validation_state', 'missing')}",
        f"next step: {status['next_step']}",
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Print the latest federated CI summary status")
    parser.add_argument("--summary", default=str(DEFAULT_SUMMARY))
    parser.add_argument("--validation-report", default=str(DEFAULT_VALIDATION))
    parser.add_argument("--readiness-report", default=str(DEFAULT_READINESS))
    parser.add_argument("--readiness-validation-report", default=str(DEFAULT_READINESS_VALIDATION))
    parser.add_argument("--reconcile-report", default=str(DEFAULT_RECONCILE))
    parser.add_argument("--reconcile-validation-report", default=str(DEFAULT_RECONCILE_VALIDATION))
    parser.add_argument("--require-pass", action="store_true")
    args = parser.parse_args()

    summary_path = Path(args.summary).resolve()
    validation_path = Path(args.validation_report).resolve()
    readiness_path = Path(args.readiness_report).resolve()
    readiness_validation_path = Path(args.readiness_validation_report).resolve()
    reconcile_path = Path(args.reconcile_report).resolve()
    reconcile_validation_path = Path(args.reconcile_validation_report).resolve()
    status = build_status(summary_path, validation_path)
    readiness_doc = load_json(readiness_path) if readiness_path.exists() else None
    readiness_validation_doc = load_json(readiness_validation_path) if readiness_validation_path.exists() else None
    reconcile_doc = load_json(reconcile_path) if reconcile_path.exists() else None
    reconcile_validation_doc = load_json(reconcile_validation_path) if reconcile_validation_path.exists() else None
    status["readiness_report_path"] = str(readiness_path)
    status["readiness_validation_report_path"] = str(readiness_validation_path)
    status["readiness_artifact_state"] = "fresh" if readiness_matches_status(status, readiness_doc, summary_path, validation_path) else ("stale" if readiness_path.exists() else "missing")
    status["readiness_validation_verdict"] = (
        str(readiness_validation_doc.get("verdict") or "unknown") if isinstance(readiness_validation_doc, dict) else "missing"
    )
    status["readiness_validation_state"] = (
        "fresh"
        if readiness_validation_matches(readiness_doc, readiness_validation_doc, readiness_path)
        else ("stale" if readiness_validation_path.exists() else "missing")
    )
    if status["readiness_artifact_state"] == "stale":
        if "readiness_artifact_stale" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("readiness_artifact_stale")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    elif status["readiness_artifact_state"] == "missing":
        if status["ready"]:
            status["next_step"] = "none"
    if status["readiness_validation_verdict"] == "missing":
        if "readiness_validation_missing" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("readiness_validation_missing")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    elif status["readiness_validation_verdict"] != "pass":
        if "readiness_validation_verdict_fail" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("readiness_validation_verdict_fail")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    if status["readiness_validation_state"] == "stale":
        if "readiness_validation_stale" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("readiness_validation_stale")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    status["reconcile_report_path"] = str(reconcile_path)
    status["reconcile_validation_report_path"] = str(reconcile_validation_path)
    status["reconcile_artifact_state"] = (
        "fresh"
        if reconcile_matches_status(status, reconcile_doc, reconcile_path)
        else ("stale" if reconcile_path.exists() else "missing")
    )
    status["reconcile_validation_verdict"] = (
        str(reconcile_validation_doc.get("verdict") or "unknown") if isinstance(reconcile_validation_doc, dict) else "missing"
    )
    status["reconcile_validation_state"] = (
        "fresh"
        if reconcile_validation_matches(reconcile_doc, reconcile_validation_doc, reconcile_path)
        else ("stale" if reconcile_validation_path.exists() else "missing")
    )
    status["reconcile_count"] = (
        reconcile_doc.get("reconcile_count")
        if isinstance(reconcile_doc, dict) and isinstance(reconcile_doc.get("reconcile_count"), int)
        else "unknown"
    )
    status["reconcile_restored_check_names"] = (
        list(reconcile_doc.get("restored_check_names") or []) if isinstance(reconcile_doc, dict) else []
    )
    if status["reconcile_artifact_state"] == "missing":
        if "reconcile_artifact_missing" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("reconcile_artifact_missing")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    elif status["reconcile_artifact_state"] == "stale":
        if "reconcile_artifact_stale" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("reconcile_artifact_stale")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    if status["reconcile_validation_verdict"] == "missing":
        if "reconcile_validation_missing" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("reconcile_validation_missing")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    elif status["reconcile_validation_verdict"] != "pass":
        if "reconcile_validation_verdict_fail" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("reconcile_validation_verdict_fail")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    if status["reconcile_validation_state"] == "stale":
        if "reconcile_validation_stale" not in status["blocking_reasons"]:
            status["blocking_reasons"].append("reconcile_validation_stale")
        status["ready"] = False
        status["readiness_status"] = "blocked"
        if status["next_step"] == "none":
            status["next_step"] = RERUN_HINT
    for line in render_status_lines(status):
        print(line)
    return 1 if args.require_pass and not status["ready"] else 0


if __name__ == "__main__":
    sys.exit(main())
