#!/usr/bin/env python3

from __future__ import annotations

import argparse
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import resolve_monday_agent_harness_projection_status_bundle_status_bundle_status as bundle_resolver
import validate_monday_agent_harness_projection as projection_validation
import validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle as bundle_validation
import validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status as status_validation


DEFAULT_ARTIFACT = bundle_resolver.DEFAULT_STATUS
DEFAULT_BUNDLE = bundle_resolver.DEFAULT_OUTPUT
DEFAULT_BUNDLE_SCHEMA = bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_SCHEMA = bundle_resolver.DEFAULT_STATUS_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_BUNDLE_VALIDATION_OUTPUT = bundle_validation.DEFAULT_OUTPUT
BASE_DOCTOR = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py"
)
DEFAULT_DOCTOR_STATUS_OUTPUT = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_DOCTOR_STATUS_VALIDATION_OUTPUT = status_validation.DEFAULT_OUTPUT


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print monday agent harness projection resolved status-bundle-status-bundle-status-bundle health"
    )
    parser.add_argument("--bundle-file", default=None)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--artifact-file", default=None)
    group.add_argument("--status-file", default=None)
    group.add_argument("--status-validation-file", default=None)
    parser.add_argument("--bundle-schema-file", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--status-schema-file", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--bundle-output", default=str(DEFAULT_BUNDLE))
    parser.add_argument("--bundle-validation-output", default=str(DEFAULT_BUNDLE_VALIDATION_OUTPUT))
    parser.add_argument("--status-output", default=str(DEFAULT_DOCTOR_STATUS_OUTPUT))
    parser.add_argument("--status-validation-output", default=str(DEFAULT_DOCTOR_STATUS_VALIDATION_OUTPUT))
    parser.add_argument("--require-pass", action="store_true")
    return parser.parse_args()


def resolve_path(path_str: str) -> Path:
    path = Path(path_str)
    if not path.is_absolute():
        return (bundle_resolver.WORKSPACE_ROOT / path).resolve()
    return path.resolve()


def source_kind(args: argparse.Namespace) -> str:
    if args.bundle_file:
        return "bundle"
    if args.status_file:
        return "status"
    if args.status_validation_file:
        return "status-validation"
    return "artifact"


def load_bundle(args: argparse.Namespace) -> tuple[Path, dict]:
    if args.bundle_file:
        bundle_path = resolve_path(args.bundle_file)
        return bundle_path, projection_validation.load_json(bundle_path)

    artifact_file = args.artifact_file or str(DEFAULT_ARTIFACT)
    explicit_source = bool(args.artifact_file or args.status_file or args.status_validation_file)
    artifact_path = resolve_path(artifact_file)
    if not explicit_source and not artifact_path.exists():
        subprocess.run(
            [sys.executable, str(BASE_DOCTOR)],
            check=True,
            capture_output=True,
            text=True,
        )

    bundle_path = resolve_path(args.bundle_output)
    bundle_doc = bundle_resolver.resolve_status_bundle_status_bundle_status_bundle(
        artifact_file=str(artifact_path),
        status_file=args.status_file,
        status_validation_file=args.status_validation_file,
        status_schema=str(resolve_path(args.status_schema_file)),
        status_validation_schema=str(resolve_path(args.status_validation_schema_file)),
        bundle_schema=str(resolve_path(args.bundle_schema_file)),
        output=str(bundle_path),
    )
    return bundle_path, bundle_doc


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def doctor_errors(bundle_doc: dict, validation_report: dict) -> list[str]:
    errors = list(validation_report.get("errors") or [])
    if validation_report.get("verdict") != "pass":
        append_unique(errors, "bundle validation verdict is fail")
    if bundle_doc.get("ready") is not True:
        append_unique(errors, "resolved status bundle status bundle status bundle ready is false")
    if bundle_doc.get("status_verdict") != "pass":
        append_unique(errors, "status verdict is fail")
    if bundle_doc.get("status_validation_verdict") != "pass":
        append_unique(errors, "status validation verdict is fail")
    if bundle_doc.get("bundle_status_verdict") != "pass":
        append_unique(errors, "bundle status verdict is fail")
    if bundle_doc.get("bundle_status_validation_verdict") != "pass":
        append_unique(errors, "bundle status validation verdict is fail")
    if bundle_doc.get("projection_validation_verdict") != "pass":
        append_unique(errors, "projection validation verdict is fail")
    if bundle_doc.get("projection_validation_state") != "fresh":
        append_unique(errors, "projection validation state is not fresh")
    if bundle_doc.get("status_sidecar_validation_verdict") != "pass":
        append_unique(errors, "status sidecar validation verdict is fail")
    if bundle_doc.get("bundle_validation_verdict") != "pass":
        append_unique(errors, "resolved bundle validation verdict is fail")
    if bundle_doc.get("next_step") != "none":
        append_unique(errors, "resolved status bundle status bundle status bundle next_step is not none")
    return errors


def build_status_report(
    bundle_path: Path,
    bundle_doc: dict,
    validation_report: dict,
    *,
    status_output: Path,
    status_validation_output: Path,
) -> dict:
    errors = doctor_errors(bundle_doc, validation_report)
    warnings = list(validation_report.get("warnings") or [])
    verdict = "pass" if not errors else "fail"
    ready = verdict == "pass"
    next_step = (
        "none"
        if ready
        else (bundle_doc.get("next_step") or "inspect monday projection status bundle status bundle status bundle")
    )
    return {
        "bundle_path": str(bundle_path.resolve()),
        "resolved_status_bundle_status_bundle_status_bundle_path": bundle_doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_path"
        )
        or str(bundle_path.resolve()),
        "bundle_status_bundle_status_bundle_output_path": str(status_output.resolve()),
        "bundle_status_bundle_status_bundle_validation_output_path": str(status_validation_output.resolve()),
        "bundle_validation_output_path": validation_report.get("output_path"),
        "generated_at_utc": now_utc(),
        "mission_id": bundle_doc.get("mission_id"),
        "run_id": bundle_doc.get("run_id"),
        "session_id": bundle_doc.get("session_id"),
        "verdict": verdict,
        "ready": ready,
        "next_step": next_step,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "bundle_status_bundle_status_path": bundle_doc.get("bundle_status_bundle_status_path"),
        "bundle_status_bundle_validation_path": bundle_doc.get("bundle_status_bundle_validation_path"),
        "bundle_status_path": bundle_doc.get("bundle_status_path"),
        "bundle_status_validation_path": bundle_doc.get("bundle_status_validation_path"),
        "projection_bundle_path": bundle_doc.get("projection_bundle_path"),
        "projection_validation_report_path": bundle_doc.get("projection_validation_report_path"),
        "status_path": bundle_doc.get("status_path"),
        "status_validation_path": bundle_doc.get("status_validation_path"),
        "status_verdict": bundle_doc.get("status_verdict"),
        "status_validation_verdict": bundle_doc.get("status_validation_verdict"),
        "bundle_status_verdict": bundle_doc.get("bundle_status_verdict"),
        "bundle_status_validation_verdict": bundle_doc.get("bundle_status_validation_verdict"),
        "projection_validation_verdict": bundle_doc.get("projection_validation_verdict"),
        "projection_validation_state": bundle_doc.get("projection_validation_state"),
        "status_sidecar_validation_verdict": bundle_doc.get("status_sidecar_validation_verdict"),
        "bundle_validation_verdict": validation_report.get("verdict"),
    }


def render_lines(kind: str, bundle_path: Path, bundle_doc: dict, validation_report: dict) -> list[str]:
    warnings = list(validation_report.get("warnings") or [])
    errors = doctor_errors(bundle_doc, validation_report)
    doctor_verdict = "pass" if not errors else "fail"
    next_step = (
        "none"
        if doctor_verdict == "pass"
        else (bundle_doc.get("next_step") or "inspect monday projection status bundle status bundle status bundle")
    )
    return [
        f"source kind: {kind}",
        f"bundle path: {bundle_path}",
        f"bundle validation output path: {validation_report.get('output_path') or 'missing'}",
        f"bundle status bundle status path: {bundle_doc.get('bundle_status_bundle_status_path') or 'missing'}",
        f"bundle status bundle validation path: {bundle_doc.get('bundle_status_bundle_validation_path') or 'missing'}",
        f"bundle status path: {bundle_doc.get('bundle_status_path') or 'missing'}",
        f"bundle status validation path: {bundle_doc.get('bundle_status_validation_path') or 'missing'}",
        f"projection bundle path: {bundle_doc.get('projection_bundle_path') or 'missing'}",
        f"projection validation report path: {bundle_doc.get('projection_validation_report_path') or 'missing'}",
        f"status path: {bundle_doc.get('status_path') or 'missing'}",
        f"status validation path: {bundle_doc.get('status_validation_path') or 'missing'}",
        f"run id: {bundle_doc.get('run_id') or 'unknown'}",
        f"session id: {bundle_doc.get('session_id') or 'unknown'}",
        f"ready: {bundle_doc.get('ready')}",
        f"status verdict: {bundle_doc.get('status_verdict') or 'unknown'}",
        f"status validation verdict: {bundle_doc.get('status_validation_verdict') or 'unknown'}",
        f"bundle status verdict: {bundle_doc.get('bundle_status_verdict') or 'unknown'}",
        f"bundle status validation verdict: {bundle_doc.get('bundle_status_validation_verdict') or 'unknown'}",
        f"projection validation verdict: {bundle_doc.get('projection_validation_verdict') or 'unknown'}",
        f"projection validation state: {bundle_doc.get('projection_validation_state') or 'unknown'}",
        f"status sidecar validation verdict: {bundle_doc.get('status_sidecar_validation_verdict') or 'unknown'}",
        f"bundle validation verdict: {validation_report.get('verdict') or 'unknown'}",
        f"doctor verdict: {doctor_verdict}",
        f"warning count: {validation_report.get('warning_count', 0)}",
        f"error count: {len(errors)}",
        "errors: none" if not errors else f"errors: {'; '.join(errors)}",
        "warnings: none" if not warnings else f"warnings: {'; '.join(warnings)}",
        f"next step: {next_step}",
    ]


def main() -> int:
    args = parse_args()
    kind = source_kind(args)
    bundle_path, bundle_doc = load_bundle(args)
    validation_report = bundle_validation.build_validation_report(
        bundle_path,
        resolve_path(args.bundle_schema_file),
        resolve_path(args.bundle_validation_output),
        status_schema_path=resolve_path(args.status_schema_file),
        status_validation_schema_path=resolve_path(args.status_validation_schema_file),
    )
    projection_validation.write_json(resolve_path(args.bundle_validation_output), validation_report)
    status_output_path = resolve_path(args.status_output)
    status_validation_output_path = resolve_path(args.status_validation_output)
    status_report = build_status_report(
        bundle_path,
        bundle_doc,
        validation_report,
        status_output=status_output_path,
        status_validation_output=status_validation_output_path,
    )
    projection_validation.write_json(status_output_path, status_report)
    status_validation_report = status_validation.build_validation_report(
        status_output_path,
        status_validation.DEFAULT_SCHEMA,
        status_validation_output_path,
    )
    projection_validation.write_json(status_validation_output_path, status_validation_report)
    for line in render_lines(kind, bundle_path, bundle_doc, validation_report):
        print(line)
    print(f"bundle status output path: {status_output_path}")
    print(f"bundle status validation verdict: {status_validation_report.get('verdict')}")
    print(f"bundle status validation output path: {status_validation_output_path}")
    if args.require_pass and (
        doctor_errors(bundle_doc, validation_report) or status_validation_report.get("verdict") != "pass"
    ):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
