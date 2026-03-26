#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

from resolve_monday_agent_harness_projection import DEFAULT_BUNDLE_OUTPUT, resolve_bundle_from_paths
from validate_monday_agent_harness_projection import (
    DEFAULT_BUNDLE_SCHEMA,
    DEFAULT_MONDAY_ROOT,
    DEFAULT_OUTPUT,
    DEFAULT_PROJECTION_ROOT,
    DEFAULT_VALIDATION_SCHEMA,
    build_input_paths,
    build_validation_report,
    resolve_bundle_context,
)
from validate_supervisor_operator_handoff import write_json


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATUS_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-status.json"
DEFAULT_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT / "planningops/schemas/monday-agent-harness-projection-status-validation.schema.json"
)
DEFAULT_STATUS_VALIDATION_OUTPUT = (
    WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-status-validation.json"
)
STATUS_VALIDATOR = WORKSPACE_ROOT / "planningops/scripts/validate_monday_agent_harness_projection_status.py"


def parse_args():
    parser = argparse.ArgumentParser(description="Print monday agent harness projection readiness from planningops")
    parser.add_argument("--monday-root", default=str(DEFAULT_MONDAY_ROOT))
    parser.add_argument("--projection-root", default=str(DEFAULT_PROJECTION_ROOT))
    parser.add_argument("--bundle-file", default=None)
    parser.add_argument("--completion-summary", default=None)
    parser.add_argument("--readiness-projection", default=None)
    parser.add_argument("--verification-projection", default=None)
    parser.add_argument("--operator-handoff-summary", default=None)
    parser.add_argument("--schema-file", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--validation-schema-file", default=str(DEFAULT_VALIDATION_SCHEMA))
    parser.add_argument("--bundle-output", default=str(DEFAULT_BUNDLE_OUTPUT))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--status-output", default=str(DEFAULT_STATUS_OUTPUT))
    parser.add_argument("--status-validation-output", default=str(DEFAULT_STATUS_VALIDATION_OUTPUT))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--require-pass", action="store_true")
    return parser.parse_args()


def now_utc() -> str:
    from datetime import datetime, timezone

    return datetime.now(timezone.utc).isoformat()


def resolve_output_path(output: str) -> Path:
    output_path = Path(output)
    if not output_path.is_absolute():
        return (WORKSPACE_ROOT / output_path).resolve()
    return output_path.resolve()


def validation_matches_bundle(report: dict, *, bundle_path: Path) -> bool:
    bundle_value = report.get("bundle_path")
    if not isinstance(bundle_value, str) or not bundle_value.strip():
        return False
    try:
        report_bundle_path = Path(bundle_value).resolve()
    except OSError:
        return False
    return report_bundle_path == bundle_path.resolve()


def build_status(report: dict, *, bundle_path: Path, validation_path: Path) -> dict:
    validation_present = validation_path.exists()
    validation_verdict = "missing"
    validation_state = "missing"
    if validation_present:
        validation_verdict = str(report.get("verdict") or "unknown")
        validation_state = "fresh" if validation_matches_bundle(report, bundle_path=bundle_path) else "stale"
    return {
        "bundle_path": str(bundle_path.resolve()),
        "validation_report_path": str(validation_path.resolve()),
        "bundle_present": bundle_path.exists(),
        "validation_present": validation_present,
        "projection_root": report.get("projection_root"),
        "monday_root": report.get("monday_root"),
        "mission_id": report.get("mission_id"),
        "run_id": report.get("run_id"),
        "session_id": report.get("session_id"),
        "final_status": report.get("final_status"),
        "readiness_status": report.get("readiness_status"),
        "verification_verdict": report.get("verification_verdict"),
        "handoff_status": report.get("handoff_status"),
        "next_required_actor": report.get("next_required_actor"),
        "recommended_next_step": report.get("recommended_next_step"),
        "ready": bool(report.get("ready")),
        "validation_verdict": validation_verdict,
        "validation_state": validation_state,
        "next_step": report.get("next_step") or "none",
    }


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
        str(status_path.resolve()),
        "--bundle-file",
        str(bundle_path.resolve()),
        "--validation-report",
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
        try:
            validation_doc = json.loads(output_path.read_text(encoding="utf-8"))
        except Exception:
            verdict = "invalid"
        else:
            verdict = str(validation_doc.get("verdict") or "unknown")
    elif result.returncode == 0:
        verdict = "unknown"
    return output_path, verdict, result.returncode


def render_lines(report: dict) -> list[str]:
    errors = list(report.get("errors") or [])
    warnings = list(report.get("warnings") or [])
    return [
        f"bundle path: {report.get('bundle_path') or 'inline'}",
        f"projection root: {report.get('projection_root') or 'missing'}",
        f"monday root: {report.get('monday_root') or 'missing'}",
        f"completion summary path: {report.get('completion_summary_path') or 'missing'}",
        f"readiness projection path: {report.get('readiness_projection_path') or 'missing'}",
        f"verification projection path: {report.get('verification_projection_path') or 'missing'}",
        f"operator handoff summary path: {report.get('operator_handoff_summary_path') or 'missing'}",
        f"run id: {report.get('run_id') or 'unknown'}",
        f"session id: {report.get('session_id') or 'unknown'}",
        f"evidence bundle path: {report.get('evidence_bundle_path') or 'missing'}",
        f"evidence bundle exists: {report.get('evidence_bundle_exists')}",
        f"final status: {report.get('final_status') or 'unknown'}",
        f"readiness status: {report.get('readiness_status') or 'unknown'}",
        f"ready: {report.get('ready')}",
        f"verification verdict: {report.get('verification_verdict') or 'unknown'}",
        f"handoff status: {report.get('handoff_status') or 'unknown'}",
        f"next required actor: {report.get('next_required_actor') or 'unknown'}",
        f"repair attempts: {report.get('repair_attempts')}",
        f"error count: {report.get('error_count', 0)}",
        f"warning count: {report.get('warning_count', 0)}",
        "errors: none" if not errors else f"errors: {'; '.join(errors)}",
        "warnings: none" if not warnings else f"warnings: {'; '.join(warnings)}",
        f"next step: {report.get('next_step') or 'none'}",
    ]


def main() -> int:
    args = parse_args()
    if args.bundle_file:
        bundle_doc, projection_root, monday_root, load_errors = resolve_bundle_context(args)
    else:
        paths = build_input_paths(args)
        bundle_output_path = Path(args.bundle_output).resolve()
        bundle_doc, load_errors = resolve_bundle_from_paths(
            paths,
            schema_path=Path(args.schema_file).resolve(),
            output_path=bundle_output_path,
        )
        projection_root = paths["projection_root"]
        monday_root = paths["monday_root"]
    report = build_validation_report(
        bundle_doc,
        projection_root=projection_root,
        monday_root=monday_root,
        bundle_schema_path=Path(args.schema_file).resolve(),
        validation_schema_path=Path(args.validation_schema_file).resolve(),
        load_errors=load_errors,
    )
    output_path = Path(args.output).resolve()
    write_json(output_path, report)
    bundle_output_path = resolve_output_path(args.bundle_output if not args.bundle_file else report.get("bundle_path") or args.bundle_output)
    status = build_status(report, bundle_path=bundle_output_path, validation_path=output_path)
    status_output_path = write_status(
        args.status_output,
        status,
        status_validation_output=args.status_validation_output,
    )
    status_validation_output_path, status_validation_verdict, status_validation_rc = write_status_validation(
        status_path=status_output_path,
        bundle_path=bundle_output_path,
        validation_path=output_path,
        output=args.status_validation_output,
        validation_schema_file=args.status_validation_schema_file,
    )
    for line in render_lines(report):
        print(line)
    if status_output_path is not None:
        print(f"status output path: {status_output_path}")
    if status_validation_output_path is not None:
        print(f"projection status validation verdict: {status_validation_verdict}")
        print(f"status validation output path: {status_validation_output_path}")
    if status_validation_rc != 0:
        return 1
    return 1 if args.require_pass and (report.get("verdict") != "pass" or not report.get("ready")) else 0


if __name__ == "__main__":
    sys.exit(main())
