#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from doctor_federated_ci_summary_tmp_reconcile import validation_matches_report
from validate_supervisor_operator_handoff import load_json, validate_schema


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle.schema.json"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_output(output: str | None, doc: dict) -> Path | None:
    if not output:
        return None
    output_path = Path(output)
    if not output_path.is_absolute():
        output_path = (WORKSPACE_ROOT / output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return output_path


def default_validation_path(report_path: Path) -> Path:
    return report_path.with_name(f"{report_path.stem}-validation{report_path.suffix}")


def resolve_report_and_validation_paths(artifact_path: Path, artifact_doc: dict) -> tuple[Path, dict, Path, dict]:
    reconcile_report_path = artifact_doc.get("reconcile_report_path")
    if isinstance(reconcile_report_path, str) and reconcile_report_path.strip():
        validation_path = artifact_path
        report_path = Path(reconcile_report_path)
        if not report_path.is_absolute():
            report_path = (artifact_path.parent / report_path).resolve()
        else:
            report_path = report_path.resolve()
        report_doc = load_json(report_path)
        validation_doc = artifact_doc
        return report_path, report_doc, validation_path, validation_doc

    report_path = artifact_path
    report_doc = artifact_doc
    validation_path = default_validation_path(report_path).resolve()
    if not validation_path.exists():
        raise SystemExit(f"tmp-summary reconcile validation report not found: {validation_path}")
    validation_doc = load_json(validation_path)
    return report_path, report_doc, validation_path, validation_doc


def validate_bundle(bundle: dict, *, schema_path: Path) -> None:
    schema_doc = load_json(schema_path)
    errors = validate_schema(bundle, schema_doc)
    if errors:
        raise SystemExit("invalid federated ci tmp-summary reconcile bundle: " + "; ".join(errors))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve the canonical tmp-summary reconcile report + validation bundle from a report or validation artifact"
    )
    parser.add_argument("--artifact-file", required=True)
    parser.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def resolve_bundle(*, artifact_file: str, schema_path: str | None, output: str | None) -> tuple[Path | None, dict]:
    artifact_path = Path(artifact_file)
    if not artifact_path.is_absolute():
        artifact_path = (WORKSPACE_ROOT / artifact_path).resolve()
    else:
        artifact_path = artifact_path.resolve()
    artifact_doc = load_json(artifact_path)
    if not isinstance(artifact_doc, dict):
        raise SystemExit(f"artifact not found: {artifact_path}")

    resolved_schema = Path(str(schema_path or DEFAULT_SCHEMA))
    if not resolved_schema.is_absolute():
        resolved_schema = (WORKSPACE_ROOT / resolved_schema).resolve()
    else:
        resolved_schema = resolved_schema.resolve()

    report_path, report_doc, validation_path, validation_doc = resolve_report_and_validation_paths(artifact_path, artifact_doc)
    if not validation_matches_report(report_doc, validation_doc, report_path, validation_path):
        raise SystemExit("tmp-summary reconcile validation report does not match resolved tmp-summary reconcile report")

    bundle = {
        "generated_at_utc": now_utc(),
        "artifact_file": str(artifact_path),
        "reconcile_report_path": str(report_path),
        "reconcile_validation_report_path": str(validation_path),
        "run_id": report_doc.get("run_id"),
        "reconcile_status": report_doc.get("status"),
        "reconcile_check_name": report_doc.get("check_name"),
        "reconcile_count": report_doc.get("reconcile_count"),
        "reconcile_report": report_doc,
        "reconcile_validation_report": validation_doc,
    }
    validate_bundle(bundle, schema_path=resolved_schema)
    output_path = write_output(output, bundle)
    return output_path, bundle


def main() -> int:
    args = parse_args()
    output_path, bundle = resolve_bundle(
        artifact_file=args.artifact_file,
        schema_path=args.schema,
        output=args.output,
    )
    rendered = dict(bundle)
    if output_path is not None:
        rendered["output_path"] = str(output_path)
    print(json.dumps(rendered, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
