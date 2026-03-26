#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status as bundle_resolver
import validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle as bundle_validation
import validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status as status_validation


DEFAULT_BUNDLE_OUTPUT = bundle_resolver.DEFAULT_OUTPUT
DEFAULT_BUNDLE_SCHEMA = bundle_resolver.DEFAULT_BUNDLE_SCHEMA
DEFAULT_STATUS_SCHEMA = bundle_resolver.DEFAULT_STATUS_SCHEMA
DEFAULT_STATUS_VALIDATION_SCHEMA = bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA
DEFAULT_BUNDLE_VALIDATION_OUTPUT = bundle_validation.DEFAULT_OUTPUT
DEFAULT_STATUS_OUTPUT = (
    bundle_resolver.WORKSPACE_ROOT
    / "planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_STATUS_VALIDATION_OUTPUT = status_validation.DEFAULT_OUTPUT


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Print plain python compatibility manifest status-bundle-status-bundle-status-bundle-status-bundle status"
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--bundle-file")
    group.add_argument("--artifact-file")
    group.add_argument("--status-file")
    group.add_argument("--status-validation-file")
    parser.add_argument("--bundle-schema-file", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--status-schema-file", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema-file", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--bundle-output", default=str(DEFAULT_BUNDLE_OUTPUT))
    parser.add_argument("--status-output", default=str(DEFAULT_STATUS_OUTPUT))
    parser.add_argument("--status-validation-output", default=str(DEFAULT_STATUS_VALIDATION_OUTPUT))
    parser.add_argument("--bundle-validation-output", default=str(DEFAULT_BUNDLE_VALIDATION_OUTPUT))
    parser.add_argument("--require-pass", action="store_true")
    return parser.parse_args()


def source_kind(args: argparse.Namespace) -> str:
    if args.bundle_file:
        return "bundle"
    if args.artifact_file:
        return "artifact"
    if args.status_file:
        return "status"
    return "status-validation"


def resolve_bundle(args: argparse.Namespace) -> tuple[Path, dict]:
    if args.bundle_file:
        bundle_path = Path(args.bundle_file)
        if not bundle_path.is_absolute():
            bundle_path = (bundle_resolver.WORKSPACE_ROOT / bundle_path).resolve()
        else:
            bundle_path = bundle_path.resolve()
        bundle_doc = bundle_resolver.manifest_validation.load_json(bundle_path)
        return bundle_path, bundle_doc

    bundle_doc = bundle_resolver.resolve_status_bundle_status_bundle_status_bundle_status_bundle(
        artifact_file=args.artifact_file,
        status_file=args.status_file,
        status_validation_file=args.status_validation_file,
        status_schema=args.status_schema_file,
        status_validation_schema=args.status_validation_schema_file,
        bundle_schema=args.bundle_schema_file,
        output=args.bundle_output,
    )
    bundle_path = Path(args.bundle_output)
    if not bundle_path.is_absolute():
        bundle_path = (bundle_resolver.WORKSPACE_ROOT / bundle_path).resolve()
    else:
        bundle_path = bundle_path.resolve()
    return bundle_path, bundle_doc


def build_status_report(
    bundle_path: Path,
    bundle_doc: dict,
    validation_report: dict,
    status_output: Path,
    status_validation_output: Path,
) -> dict:
    errors = list(validation_report.get("errors") or [])
    warnings = list(validation_report.get("warnings") or [])
    if bundle_doc.get("ready") is not True and "bundle ready is false" not in errors:
        errors.append("bundle ready is false")
    if bundle_doc.get("status_verdict") != "pass" and "status verdict is fail" not in errors:
        errors.append("status verdict is fail")
    if bundle_doc.get("status_validation_verdict") != "pass" and "status validation verdict is fail" not in errors:
        errors.append("status validation verdict is fail")
    if bundle_doc.get("bundle_status_verdict") != "pass" and "bundle status verdict is fail" not in errors:
        errors.append("bundle status verdict is fail")
    if bundle_doc.get("bundle_status_validation_verdict") != "pass" and "bundle status validation verdict is fail" not in errors:
        errors.append("bundle status validation verdict is fail")
    if validation_report.get("verdict") != "pass" and "bundle validation verdict is fail" not in errors:
        errors.append("bundle validation verdict is fail")

    verdict = "pass" if not errors else "fail"
    ready = verdict == "pass"
    next_step = "none"
    if not ready:
        next_step = (
            "python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file "
            f"{bundle_path} --require-pass"
        )

    return {
        "bundle_path": str(bundle_path.resolve()),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path": str(status_output.resolve()),
        "bundle_status_bundle_status_bundle_status_bundle_output_path": str(status_output.resolve()),
        "bundle_status_bundle_status_bundle_status_bundle_validation_output_path": str(
            status_validation_output.resolve()
        ),
        "bundle_validation_output_path": validation_report.get("output_path"),
        "bundle_status_bundle_status_bundle_status_path": bundle_doc.get(
            "bundle_status_bundle_status_bundle_status_path"
        ),
        "bundle_status_bundle_status_bundle_validation_path": bundle_doc.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_status_bundle_status_path": bundle_doc.get("bundle_status_bundle_status_path"),
        "bundle_status_bundle_validation_path": bundle_doc.get("bundle_status_bundle_validation_path"),
        "status_bundle_path": bundle_doc.get("status_bundle_path"),
        "bundle_status_path": bundle_doc.get("bundle_status_path"),
        "bundle_status_validation_path": bundle_doc.get("bundle_status_validation_path"),
        "manifest_path": bundle_doc.get("manifest_path"),
        "status_path": bundle_doc.get("status_path"),
        "status_validation_path": bundle_doc.get("status_validation_path"),
        "generated_at_utc": bundle_validation.manifest_validation.now_utc(),
        "verdict": verdict,
        "ready": ready,
        "next_step": next_step,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "status_verdict": bundle_doc.get("status_verdict"),
        "status_validation_verdict": bundle_doc.get("status_validation_verdict"),
        "bundle_status_verdict": bundle_doc.get("bundle_status_verdict"),
        "bundle_status_validation_verdict": bundle_doc.get("bundle_status_validation_verdict"),
        "bundle_validation_verdict": validation_report.get("verdict"),
    }


def render_lines(kind: str, bundle_path: Path, bundle_doc: dict, validation_report: dict, status_report: dict) -> list[str]:
    errors = list(validation_report.get("errors") or [])
    warnings = list(validation_report.get("warnings") or [])
    return [
        f"source kind: {kind}",
        f"bundle path: {bundle_path}",
        f"bundle status output path: {status_report.get('bundle_status_bundle_status_bundle_status_bundle_output_path') or 'missing'}",
        f"bundle status validation output path: {status_report.get('bundle_status_bundle_status_bundle_status_bundle_validation_output_path') or 'missing'}",
        f"bundle validation output path: {validation_report.get('output_path') or 'missing'}",
        f"bundle status bundle status bundle status path: {bundle_doc.get('bundle_status_bundle_status_bundle_status_path') or 'missing'}",
        f"bundle status bundle status bundle validation path: {bundle_doc.get('bundle_status_bundle_status_bundle_validation_path') or 'missing'}",
        f"bundle status bundle status path: {bundle_doc.get('bundle_status_bundle_status_path') or 'missing'}",
        f"bundle status bundle validation path: {bundle_doc.get('bundle_status_bundle_validation_path') or 'missing'}",
        f"status bundle path: {bundle_doc.get('status_bundle_path') or 'missing'}",
        f"bundle status path: {bundle_doc.get('bundle_status_path') or 'missing'}",
        f"bundle status validation path: {bundle_doc.get('bundle_status_validation_path') or 'missing'}",
        f"status path: {bundle_doc.get('status_path') or 'missing'}",
        f"status validation path: {bundle_doc.get('status_validation_path') or 'missing'}",
        f"manifest path: {bundle_doc.get('manifest_path') or 'missing'}",
        f"ready: {bundle_doc.get('ready')}",
        f"next step: {bundle_doc.get('next_step') or 'none'}",
        f"status verdict: {bundle_doc.get('status_verdict') or 'unknown'}",
        f"status validation verdict: {bundle_doc.get('status_validation_verdict') or 'unknown'}",
        f"bundle status verdict: {bundle_doc.get('bundle_status_verdict') or 'unknown'}",
        f"bundle status validation verdict: {bundle_doc.get('bundle_status_validation_verdict') or 'unknown'}",
        f"bundle validation verdict: {validation_report.get('verdict') or 'unknown'}",
        f"warning count: {validation_report.get('warning_count', 0)}",
        f"error count: {validation_report.get('error_count', 0)}",
        "errors: none" if not errors else f"errors: {'; '.join(errors)}",
        "warnings: none" if not warnings else f"warnings: {'; '.join(warnings)}",
    ]


def main() -> int:
    args = parse_args()
    kind = source_kind(args)
    bundle_path, bundle_doc = resolve_bundle(args)
    validation_report = bundle_validation.build_validation_report(
        bundle_path,
        Path(args.bundle_schema_file),
        Path(args.bundle_validation_output),
        status_schema_path=Path(bundle_resolver.DEFAULT_STATUS_SCHEMA),
        status_validation_schema_path=Path(bundle_resolver.DEFAULT_STATUS_VALIDATION_SCHEMA),
    )
    bundle_resolver.manifest_validation.write_json(Path(args.bundle_validation_output), validation_report)
    status_report = build_status_report(
        bundle_path,
        bundle_doc,
        validation_report,
        Path(args.status_output),
        Path(args.status_validation_output),
    )
    bundle_resolver.manifest_validation.write_json(Path(args.status_output), status_report)
    status_validation_report = status_validation.build_validation_report(
        Path(args.status_output),
        Path(status_validation.DEFAULT_SCHEMA),
        Path(args.status_validation_output),
    )
    bundle_resolver.manifest_validation.write_json(Path(args.status_validation_output), status_validation_report)
    for line in render_lines(kind, bundle_path, bundle_doc, validation_report, status_report):
        print(line)
    if args.require_pass and (
        validation_report.get("verdict") != "pass"
        or status_report.get("ready") is not True
        or status_validation_report.get("verdict") != "pass"
        or bundle_doc.get("status_verdict") != "pass"
        or bundle_doc.get("status_validation_verdict") != "pass"
        or bundle_doc.get("bundle_status_verdict") != "pass"
        or bundle_doc.get("bundle_status_validation_verdict") != "pass"
        or bundle_doc.get("bundle_validation_verdict") != "pass"
    ):
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
