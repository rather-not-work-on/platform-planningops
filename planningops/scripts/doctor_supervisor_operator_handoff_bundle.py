#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys

from assess_supervisor_operator_handoff_bundle_readiness import assess_handoff_bundle_readiness


def parse_args():
    parser = argparse.ArgumentParser(description="Print supervisor operator handoff bundle status")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--bundle-file")
    group.add_argument("--artifact-file")
    parser.add_argument("--bundle-schema", default=None)
    parser.add_argument("--validation-schema", default=None)
    parser.add_argument("--bundle-validation-output", "--validation-output", dest="bundle_validation_output", default=None)
    parser.add_argument("--readiness-output", default=None)
    parser.add_argument("--readiness-validation-output", default=None)
    parser.add_argument("--require-pass", action="store_true")
    return parser.parse_args()


def render_lines(args, readiness_report: dict) -> list[str]:
    source_kind = "artifact" if args.artifact_file else "bundle"
    lines = [
        f"source kind: {source_kind}",
        f"artifact file: {readiness_report.get('artifact_file') or 'missing'}",
        f"bundle path: {readiness_report.get('bundle_path') or 'n/a'}",
        f"validation report path: {readiness_report.get('validation_report_path') or 'not written'}",
        f"bundle validation verdict: {readiness_report.get('bundle_validation_verdict') or 'unknown'}",
        f"handoff validation verdict: {readiness_report.get('operator_handoff_validation_verdict') or 'unknown'}",
        f"handoff bundle path: {readiness_report.get('operator_handoff_bundle_path') or 'missing'}",
        f"handoff bundle validation path: {readiness_report.get('operator_handoff_bundle_validation_path') or 'missing'}",
        f"handoff bundle readiness path: {readiness_report.get('operator_handoff_bundle_readiness_path') or 'missing'}",
        "handoff bundle readiness validation path: "
        f"{readiness_report.get('operator_handoff_bundle_readiness_validation_path') or 'missing'}",
        f"readiness status: {readiness_report.get('readiness_status') or 'unknown'}",
        f"ready: {readiness_report.get('ready')}",
        f"priority preview ref: {readiness_report.get('priority_preview_ref') or 'missing'}",
        f"priority display packet ref: {readiness_report.get('priority_display_packet_ref') or 'missing'}",
        f"priority headline: {readiness_report.get('priority_headline') or 'missing'}",
        f"priority cta command: {readiness_report.get('priority_cta_command') or 'missing'}",
        f"display title: {readiness_report.get('display_title') or 'missing'}",
        f"display cta command: {readiness_report.get('cta_command') or 'missing'}",
        f"warning count: {readiness_report.get('warning_count', 0)}",
        f"error count: {readiness_report.get('error_count', 0)}",
    ]
    errors = list(readiness_report.get("errors") or [])
    warnings = list(readiness_report.get("warnings") or [])
    lines.append("errors: none" if not errors else f"errors: {'; '.join(errors)}")
    lines.append("warnings: none" if not warnings else f"warnings: {'; '.join(warnings)}")
    lines.append(f"next step: {readiness_report.get('next_step') or 'none'}")
    return lines


def main() -> int:
    args = parse_args()
    readiness_report, _readiness_validation_report = assess_handoff_bundle_readiness(
        bundle_file=args.bundle_file,
        artifact_file=args.artifact_file,
        bundle_schema_path=args.bundle_schema,
        validation_schema_path=args.validation_schema,
        bundle_validation_output=args.bundle_validation_output,
        output=args.readiness_output,
        readiness_validation_output=args.readiness_validation_output,
    )
    for line in render_lines(args, readiness_report):
        print(line)
    return 1 if args.require_pass and not readiness_report.get("ready") else 0


if __name__ == "__main__":
    sys.exit(main())
