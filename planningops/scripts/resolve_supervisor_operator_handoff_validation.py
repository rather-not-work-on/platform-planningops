#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path

from validate_supervisor_operator_handoff import load_json, validate_schema


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-validation.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/supervisor-operator-handoff-validation-resolved.json"


def parse_args():
    parser = argparse.ArgumentParser(
        description="Resolve a canonical supervisor operator handoff validation report from either a monday/planningops artifact or a validation report path"
    )
    parser.add_argument("--artifact-file", default=None)
    parser.add_argument("--validation-report-path", default=None)
    parser.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def resolve_doc_path(value: object, *, base: Path) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = (base / path).resolve()
    else:
        path = path.resolve()
    return path


def string_at_path(doc: dict, path: tuple[str, ...]) -> str | None:
    current: object = doc
    for segment in path:
        if not isinstance(current, dict):
            return None
        current = current.get(segment)
    value = str(current or "").strip()
    return value or None


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def find_embedded_validation_paths(doc: dict) -> list[str]:
    candidate_paths = [
        ("operator_handoff_validation_path",),
        ("operatorHandoffValidationPath",),
        ("payload", "metadata", "operator_handoff_validation_path"),
        ("payload", "metadata", "operatorHandoffValidationPath"),
        ("delivery_report", "operator_handoff_validation_path"),
        ("delivery_report", "operatorHandoffValidationPath"),
        ("delegate_report", "operator_handoff_validation_path"),
        ("delegate_report", "operatorHandoffValidationPath"),
        ("delegate_report", "delivery_report", "operator_handoff_validation_path"),
        ("delegate_report", "delivery_report", "operatorHandoffValidationPath"),
        ("ack_checkpoint", "operator_handoff_validation_path"),
        ("ack_checkpoint", "operatorHandoffValidationPath"),
    ]
    values: list[str] = []
    for path in candidate_paths:
        if value := string_at_path(doc, path):
            values.append(value)
    return values


def resolve_validation_path(*candidates: object) -> str | None:
    resolved: str | None = None
    for candidate in candidates:
        value = str(candidate or "").strip()
        if not value or value == "-":
            continue
        if resolved is None:
            resolved = value
            continue
        if value != resolved:
            raise SystemExit("conflicting operator_handoff_validation_path values")
    return resolved


def write_output(output: str | None, doc: dict) -> Path | None:
    if not output:
        return None
    output_path = Path(output)
    if not output_path.is_absolute():
        output_path = (WORKSPACE_ROOT / output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return output_path


def validate_report_schema(report_doc: dict, schema_path: Path) -> None:
    schema_doc = load_json(schema_path)
    errors = validate_schema(report_doc, schema_doc)
    if errors:
        raise SystemExit("invalid supervisor operator handoff validation report: " + "; ".join(errors))


def load_validation_report(path_value: str, *, base: Path, schema_path: Path) -> tuple[Path, dict]:
    report_path = resolve_doc_path(path_value, base=base)
    if report_path is None:
        raise SystemExit("missing operator_handoff_validation_path")
    report_doc = load_json(report_path)
    if not isinstance(report_doc, dict):
        raise SystemExit(f"validation report not found: {report_path}")
    validate_report_schema(report_doc, schema_path)
    return report_path, report_doc


def resolve_handoff_validation_report(
    *,
    artifact_file: str | None,
    validation_report_path: str | None,
    schema_path: str | None,
    output: str | None,
) -> tuple[Path | None, dict]:
    resolved_schema_path = Path(str(schema_path or DEFAULT_SCHEMA))
    if not resolved_schema_path.is_absolute():
        resolved_schema_path = (WORKSPACE_ROOT / resolved_schema_path).resolve()

    if bool(artifact_file) == bool(validation_report_path):
        raise SystemExit("provide exactly one of --artifact-file or --validation-report-path")

    if validation_report_path:
        report_path, report_doc = load_validation_report(
            str(validation_report_path),
            base=WORKSPACE_ROOT,
            schema_path=resolved_schema_path,
        )
        output_path = write_output(output, report_doc)
        if output_path is not None:
            report_doc = dict(report_doc)
            report_doc["resolved_operator_handoff_validation_path"] = str(output_path)
        return output_path, report_doc

    artifact_path = Path(str(artifact_file or "").strip())
    if not artifact_path.is_absolute():
        artifact_path = (WORKSPACE_ROOT / artifact_path).resolve()
    else:
        artifact_path = artifact_path.resolve()
    artifact_doc = load_json(artifact_path)
    if not isinstance(artifact_doc, dict):
        raise SystemExit(f"artifact not found: {artifact_path}")

    embedded_paths = find_embedded_validation_paths(artifact_doc)
    validation_path = resolve_validation_path(*embedded_paths)
    if validation_path is None:
        raise SystemExit("artifact does not carry operator_handoff_validation_path")
    _report_path, report_doc = load_validation_report(
        validation_path,
        base=artifact_path.parent,
        schema_path=resolved_schema_path,
    )
    output_path = write_output(output, report_doc)
    if output_path is not None:
        report_doc = dict(report_doc)
        report_doc["resolved_operator_handoff_validation_path"] = str(output_path)
    return output_path, report_doc


def main() -> int:
    args = parse_args()
    _output_path, report_doc = resolve_handoff_validation_report(
        artifact_file=args.artifact_file,
        validation_report_path=args.validation_report_path,
        schema_path=args.schema,
        output=args.output,
    )
    print(json.dumps(report_doc, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
