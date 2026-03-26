#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

import validate_plain_python_compat_manifest as schema_validation

import resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status as bundle_resolver
import validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle as bundle_validation


WORKSPACE_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ARTIFACT = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_BUNDLE = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
)
DEFAULT_BUNDLE_VALIDATION = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
)
DEFAULT_BUNDLE_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json"
)
DEFAULT_BUNDLE_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json"
)
DEFAULT_STATUS_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"
)
DEFAULT_DOCTOR_STATUS_OUTPUT = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_DOCTOR_STATUS_VALIDATION_OUTPUT = (
    WORKSPACE_ROOT
    / "artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
)
DEFAULT_DOCTOR_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"
)
STATUS_VALIDATOR = (
    WORKSPACE_ROOT
    / "scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py"
)
RERUN_HINT = "bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_path(path_str: str) -> Path:
    path = Path(path_str)
    if not path.is_absolute():
        return (WORKSPACE_ROOT / path).resolve()
    return path.resolve()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print the latest federated CI tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle health"
    )
    parser.add_argument("--bundle-file", default=None)
    parser.add_argument("--artifact-file", default=str(DEFAULT_ARTIFACT))
    parser.add_argument("--bundle-output", default=str(DEFAULT_BUNDLE))
    parser.add_argument("--bundle-validation-output", default=str(DEFAULT_BUNDLE_VALIDATION))
    parser.add_argument("--bundle-schema-file", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--bundle-validation-schema-file", default=str(DEFAULT_BUNDLE_VALIDATION_SCHEMA))
    parser.add_argument("--status-schema-file", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--status-output", default=str(DEFAULT_DOCTOR_STATUS_OUTPUT))
    parser.add_argument("--status-validation-output", default=str(DEFAULT_DOCTOR_STATUS_VALIDATION_OUTPUT))
    parser.add_argument(
        "--doctor-status-validation-schema-file",
        default=str(DEFAULT_DOCTOR_STATUS_VALIDATION_SCHEMA),
    )
    parser.add_argument("--require-pass", action="store_true")
    return parser.parse_args()


def source_kind(args: argparse.Namespace) -> str:
    return "bundle" if args.bundle_file else "artifact"


def load_bundle(args: argparse.Namespace) -> tuple[Path, dict, dict | None]:
    bundle_schema_path = resolve_path(args.bundle_schema_file)
    if args.bundle_file:
        bundle_path = resolve_path(args.bundle_file)
        bundle_doc = schema_validation.load_json(bundle_path)
        artifact_file = bundle_doc.get("artifact_file")
        canonical_bundle = None
        if isinstance(artifact_file, str) and artifact_file.strip():
            _, canonical_bundle = bundle_resolver.resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status(
                artifact_file=artifact_file,
                status_schema=str(resolve_path(args.status_schema_file)),
                status_validation_schema=str(resolve_path(args.status_validation_schema_file)),
                bundle_schema=str(bundle_schema_path),
                output=None,
            )
        return bundle_path, bundle_doc, canonical_bundle

    bundle_output = resolve_path(args.bundle_output)
    _, bundle_doc = bundle_resolver.resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status(
        artifact_file=args.artifact_file,
        status_schema=str(resolve_path(args.status_schema_file)),
        status_validation_schema=str(resolve_path(args.status_validation_schema_file)),
        bundle_schema=str(bundle_schema_path),
        output=str(bundle_output),
    )
    return bundle_output, bundle_doc, dict(bundle_doc)


def validation_matches_bundle(
    bundle_doc: dict | None,
    validation_doc: dict | None,
    bundle_path: Path,
    validation_path: Path,
) -> bool:
    if not isinstance(bundle_doc, dict) or not isinstance(validation_doc, dict):
        return False
    if Path(str(validation_doc.get("bundle_path") or "")).resolve() != bundle_path.resolve():
        return False
    if Path(str(validation_doc.get("output_path") or "")).resolve() != validation_path.resolve():
        return False
    for field in (
        "artifact_file",
        "status_path",
        "status_validation_path",
        "run_id",
        "reconcile_status",
        "check_name",
        "reconcile_count",
        "reconcile_validation_verdict",
        "bundle_validation_verdict",
        "bundle_validation_state",
        "ready",
        "next_step",
    ):
        if validation_doc.get(field) != bundle_doc.get(field):
            return False
    return validation_doc.get("verdict") == "pass"


def build_status(bundle_path: Path, validation_path: Path) -> dict:
    status = {
        "bundle_path": str(bundle_path.resolve()),
        "validation_report_path": str(validation_path.resolve()),
        "bundle_present": bundle_path.exists(),
        "validation_present": validation_path.exists(),
        "artifact_file": None,
        "status_path": None,
        "status_validation_path": None,
        "nested_bundle_path": None,
        "nested_bundle_validation_report_path": None,
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

    bundle_doc = schema_validation.load_json(bundle_path)
    validation_doc = schema_validation.load_json(validation_path) if validation_path.exists() else None

    status["artifact_file"] = bundle_doc.get("artifact_file")
    status["status_path"] = bundle_doc.get("status_path")
    status["status_validation_path"] = bundle_doc.get("status_validation_path")
    status["nested_bundle_path"] = bundle_doc.get("bundle_path")
    status["nested_bundle_validation_report_path"] = bundle_doc.get("bundle_validation_report_path")
    status["run_id"] = bundle_doc.get("run_id")
    status["reconcile_status"] = bundle_doc.get("reconcile_status")
    status["check_name"] = bundle_doc.get("check_name")
    status["reconcile_count"] = bundle_doc.get("reconcile_count")
    status["reconcile_validation_verdict"] = str(bundle_doc.get("reconcile_validation_verdict") or "unknown")

    if isinstance(validation_doc, dict):
        status["bundle_validation_verdict"] = str(validation_doc.get("verdict") or "unknown")
        status["bundle_validation_state"] = (
            "fresh" if validation_matches_bundle(bundle_doc, validation_doc, bundle_path, validation_path) else "stale"
        )

    if (
        status["bundle_validation_verdict"] == "pass"
        and status["bundle_validation_state"] == "fresh"
        and status["reconcile_validation_verdict"] == "pass"
        and bundle_doc.get("ready") is True
        and bundle_doc.get("next_step") == "none"
    ):
        status["ready"] = True
        status["next_step"] = "none"

    return status


def write_status(output: str | None, status: dict, *, status_validation_output: str | None = None) -> Path | None:
    if not output:
        return None
    output_path = resolve_path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    rendered = dict(status)
    rendered["generated_at_utc"] = now_utc()
    rendered["output_path"] = str(output_path)
    rendered["status_validation_output_path"] = (
        str(resolve_path(status_validation_output)) if status_validation_output else None
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
    output_path = resolve_path(output)
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
        str(resolve_path(validation_schema_file)),
        "--output",
        str(output_path),
        "--strict",
    ]
    result = subprocess.run(command, capture_output=True, text=True)
    verdict = "missing"
    if output_path.exists():
        validation_doc = schema_validation.load_json(output_path)
        verdict = str(validation_doc.get("verdict") or "unknown")
    elif result.returncode == 0:
        verdict = "unknown"
    return output_path, verdict, result.returncode


def render_lines(kind: str, bundle_path: Path, bundle_doc: dict, validation_report: dict, status_report: dict) -> list[str]:
    errors = list(validation_report.get("errors") or [])
    warnings = list(validation_report.get("warnings") or [])
    return [
        f"source kind: {kind}",
        f"bundle path: {bundle_path}",
        f"bundle validation output path: {validation_report.get('output_path') or 'missing'}",
        f"status output path: {status_report.get('output_path') or 'missing'}",
        f"artifact file: {bundle_doc.get('artifact_file') or 'missing'}",
        f"status path: {bundle_doc.get('status_path') or 'missing'}",
        f"status validation path: {bundle_doc.get('status_validation_path') or 'missing'}",
        f"nested bundle path: {bundle_doc.get('bundle_path') or 'missing'}",
        f"nested bundle validation path: {bundle_doc.get('bundle_validation_report_path') or 'missing'}",
        f"run_id: {bundle_doc.get('run_id') or 'unknown'}",
        f"reconcile status: {bundle_doc.get('reconcile_status') or 'unknown'}",
        f"check name: {bundle_doc.get('check_name') or 'none'}",
        f"reconcile count: {bundle_doc.get('reconcile_count') if bundle_doc.get('reconcile_count') is not None else 'unknown'}",
        f"reconcile validation verdict: {bundle_doc.get('reconcile_validation_verdict') or 'unknown'}",
        f"bundle validation verdict: {bundle_doc.get('bundle_validation_verdict') or 'unknown'}",
        f"bundle validation state: {bundle_doc.get('bundle_validation_state') or 'unknown'}",
        f"ready: {bundle_doc.get('ready')}",
        f"next step: {bundle_doc.get('next_step') or 'none'}",
        f"validation verdict: {validation_report.get('verdict') or 'unknown'}",
        f"warning count: {validation_report.get('warning_count', 0)}",
        f"error count: {validation_report.get('error_count', 0)}",
        "errors: none" if not errors else f"errors: {'; '.join(errors)}",
        "warnings: none" if not warnings else f"warnings: {'; '.join(warnings)}",
    ]


def main() -> int:
    args = parse_args()
    kind = source_kind(args)
    bundle_path, bundle_doc, canonical_bundle = load_bundle(args)
    bundle_validation_output = resolve_path(args.bundle_validation_output)
    validation_report = bundle_validation.build_validation_report(
        bundle_path=Path(bundle_path),
        bundle_doc=bundle_doc,
        bundle_schema_path=resolve_path(args.bundle_schema_file),
        validation_schema_path=resolve_path(args.bundle_validation_schema_file),
        output_path=bundle_validation_output,
        canonical_bundle=canonical_bundle,
    )
    schema_validation.write_json(bundle_validation_output, validation_report)

    status = build_status(bundle_path, bundle_validation_output)
    status_output_path = write_status(
        args.status_output,
        status,
        status_validation_output=args.status_validation_output,
    )
    status_validation_output_path, status_validation_verdict, status_validation_rc = write_status_validation(
        status_path=status_output_path,
        bundle_path=bundle_path,
        validation_path=bundle_validation_output,
        output=args.status_validation_output,
        validation_schema_file=args.doctor_status_validation_schema_file,
    )

    rendered_status = dict(status, output_path=str(status_output_path) if status_output_path else None)
    for line in render_lines(kind, bundle_path, bundle_doc, validation_report, rendered_status):
        print(line)
    if status_validation_output_path is not None:
        print(f"status validation output path: {status_validation_output_path}")
        print(f"status validation verdict: {status_validation_verdict}")

    if status_validation_rc != 0:
        return 1
    if args.require_pass and (
        validation_report.get("verdict") != "pass"
        or status.get("ready") is not True
        or status.get("next_step") != "none"
        or status.get("reconcile_validation_verdict") != "pass"
        or status.get("bundle_validation_verdict") != "pass"
        or status.get("bundle_validation_state") != "fresh"
    ):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
