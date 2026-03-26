#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status as inner


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATUS_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"
)
DEFAULT_BUNDLE_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve the canonical tmp-summary reconcile outer bundle doctor status/status-validation pair from either artifact."
    )
    parser.add_argument("--artifact-file", required=True)
    parser.add_argument("--status-schema", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--bundle-schema", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status(
    *,
    artifact_file: str,
    status_schema: str,
    status_validation_schema: str,
    bundle_schema: str,
    output: str | None,
) -> tuple[Path | None, dict]:
    return inner.resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status(
        artifact_file=artifact_file,
        status_schema=status_schema,
        status_validation_schema=status_validation_schema,
        bundle_schema=bundle_schema,
        output=output,
    )


def main() -> int:
    args = parse_args()
    output_path, bundle = resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status(
        artifact_file=args.artifact_file,
        status_schema=args.status_schema,
        status_validation_schema=args.status_validation_schema,
        bundle_schema=args.bundle_schema,
        output=args.output,
    )
    rendered = dict(bundle)
    if output_path is not None:
        rendered["output_path"] = str(output_path)
    print(json.dumps(rendered, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
