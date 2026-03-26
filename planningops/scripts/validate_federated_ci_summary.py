#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_SCHEMA = Path("planningops/schemas/federated-ci-summary.schema.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/federated-ci-summary-validation.json")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def _resolve_ref(root_schema, ref):
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ValueError(f"unsupported schema ref: {ref}")
    cursor = root_schema
    for token in ref[2:].split("/"):
        cursor = cursor[token]
    return cursor


def _is_type(value, type_name: str) -> bool:
    if type_name == "object":
        return isinstance(value, dict)
    if type_name == "array":
        return isinstance(value, list)
    if type_name == "string":
        return isinstance(value, str)
    if type_name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    return True


def _validate_schema_value(value, schema, root_schema, path: str, errors: list[str]) -> None:
    if not isinstance(schema, dict):
        return

    if "$ref" in schema:
        schema = _resolve_ref(root_schema, schema["$ref"])

    expected_type = schema.get("type")
    if expected_type and not _is_type(value, expected_type):
        append_unique(errors, f"schema: {path} expected type {expected_type}")
        return

    if "enum" in schema and value not in schema["enum"]:
        append_unique(errors, f"schema: {path} invalid enum value: {value}")

    if expected_type == "string":
        min_len = schema.get("minLength")
        if isinstance(min_len, int) and len(value) < min_len:
            append_unique(errors, f"schema: {path} minLength violation")

    if expected_type == "integer":
        minimum = schema.get("minimum")
        if isinstance(minimum, int) and value < minimum:
            append_unique(errors, f"schema: {path} below minimum {minimum}")

    if expected_type == "object":
        required = schema.get("required", [])
        props = schema.get("properties", {})
        for key in required:
            if key not in value:
                append_unique(errors, f"schema: {path}.{key} is required")
        additional_props = schema.get("additionalProperties", True)
        for key, child_value in value.items():
            if key in props:
                continue
            if additional_props is False:
                append_unique(errors, f"schema: {path} unexpected key: {key}")
                continue
            if isinstance(additional_props, dict):
                _validate_schema_value(child_value, additional_props, root_schema, f"{path}.{key}", errors)
        for key, prop_schema in props.items():
            if key in value:
                _validate_schema_value(value[key], prop_schema, root_schema, f"{path}.{key}", errors)

    if expected_type == "array":
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for idx, row in enumerate(value):
                _validate_schema_value(row, item_schema, root_schema, f"{path}[{idx}]", errors)


def validate_schema(doc, schema_doc):
    errors: list[str] = []
    if not isinstance(doc, dict):
        return ["document must be object"]
    if not isinstance(schema_doc, dict):
        return ["schema document must be object"]
    _validate_schema_value(doc, schema_doc, schema_doc, "$", errors)
    return errors


def _validate_iso8601(value: str, field: str, errors: list[str]) -> None:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        append_unique(errors, f"{field} must be an ISO-8601 timestamp")


def validate_semantics(doc: dict):
    errors: list[str] = []
    warnings: list[str] = []

    run_id = doc.get("run_id")
    checks = doc.get("checks")
    required_checks = doc.get("required_checks")
    overall_status = doc.get("overall_status")
    check_count = doc.get("check_count")
    missing_required_checks = doc.get("missing_required_checks")
    failure_classification = doc.get("failure_classification")
    verdict = doc.get("verdict")
    shell_exit_code = doc.get("shell_exit_code")

    for field in ("started_at_utc", "generated_at_utc", "finished_at_utc"):
        value = doc.get(field)
        if isinstance(value, str):
            _validate_iso8601(value, field, errors)

    if not isinstance(run_id, str) or not run_id.strip():
        append_unique(errors, "run_id must be a non-empty string")

    if not isinstance(checks, list):
        append_unique(errors, "checks must be an array")
        return errors, warnings
    if not isinstance(required_checks, list):
        append_unique(errors, "required_checks must be an array")
        return errors, warnings
    if not isinstance(missing_required_checks, list):
        append_unique(errors, "missing_required_checks must be an array")
        return errors, warnings
    if not isinstance(failure_classification, dict):
        append_unique(errors, "failure_classification must be an object")
        return errors, warnings

    check_names: list[str] = []
    failures = []
    for idx, check in enumerate(checks):
        if not isinstance(check, dict):
            append_unique(errors, f"checks[{idx}] must be an object")
            continue
        name = check.get("name")
        exit_code = check.get("exit_code")
        check_verdict = check.get("verdict")
        domain = check.get("domain")
        result = check.get("result")

        if not isinstance(name, str) or not name.strip():
            append_unique(errors, f"checks[{idx}].name must be a non-empty string")
        else:
            if name in check_names:
                append_unique(errors, f"duplicate check name: {name}")
            check_names.append(name)

        if isinstance(exit_code, int) and not isinstance(exit_code, bool):
            expected_verdict = "pass" if exit_code == 0 else "fail"
            if check_verdict != expected_verdict:
                append_unique(
                    errors,
                    f"checks[{idx}] verdict must be {expected_verdict} when exit_code={exit_code}",
                )
        if result is not None:
            if result == "success" and exit_code != 0:
                append_unique(errors, f"checks[{idx}] result=success requires exit_code=0")
            if result != "success" and exit_code == 0:
                append_unique(errors, f"checks[{idx}] non-success result requires non-zero exit_code")
        if check_verdict == "fail":
            failures.append(check)
        if domain == "federation" and name != "federated-conformance":
            warnings.append(f"unexpected federation-domain check name: {name}")

    if len(set(required_checks)) != len(required_checks):
        append_unique(errors, "required_checks must not contain duplicates")
    if len(set(missing_required_checks)) != len(missing_required_checks):
        append_unique(errors, "missing_required_checks must not contain duplicates")

    derived_missing = [name for name in required_checks if name not in check_names]
    if missing_required_checks != derived_missing:
        append_unique(
            errors,
            "missing_required_checks must match required checks absent from checks",
        )

    if check_count != len(checks):
        append_unique(errors, "check_count must equal len(checks)")

    failure_domains = sorted({check.get("domain") for check in failures if isinstance(check, dict)})
    if failure_classification.get("count") != len(failures):
        append_unique(errors, "failure_classification.count must equal failed check count")
    if failure_classification.get("domains") != failure_domains:
        append_unique(errors, "failure_classification.domains must equal sorted failed check domains")

    if overall_status == "complete" and shell_exit_code not in (None, 0):
        append_unique(errors, "shell_exit_code must be 0 when overall_status=complete")
    if overall_status == "interrupted" and shell_exit_code == 0:
        append_unique(errors, "shell_exit_code must be non-zero when overall_status=interrupted")

    if verdict == "pass":
        if overall_status != "complete":
            append_unique(errors, "pass verdict requires overall_status=complete")
        if failures:
            append_unique(errors, "pass verdict requires zero failed checks")
        if derived_missing:
            append_unique(errors, "pass verdict requires zero missing required checks")
        if shell_exit_code not in (None, 0):
            append_unique(errors, "pass verdict requires shell_exit_code=0 when present")
    elif verdict == "fail":
        if not failures and not derived_missing and overall_status == "complete" and shell_exit_code in (None, 0):
            append_unique(errors, "fail verdict requires a failed check, missing required check, interrupted status, or non-zero shell exit code")

    return errors, warnings


def build_report(summary_path: Path, schema_path: Path, summary_doc: dict, schema_doc: dict) -> dict:
    schema_errors = validate_schema(summary_doc, schema_doc)
    semantic_errors, warnings = validate_semantics(summary_doc)
    errors = schema_errors + semantic_errors
    return {
        "generated_at_utc": now_utc(),
        "summary_path": str(summary_path.resolve()),
        "summary_run_id": summary_doc.get("run_id"),
        "summary_generated_at_utc": summary_doc.get("generated_at_utc"),
        "summary_verdict": summary_doc.get("verdict"),
        "schema_path": str(schema_path.resolve()),
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate federated CI summary artifact")
    parser.add_argument("--summary", required=True)
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    summary_path = Path(args.summary)
    schema_path = Path(args.schema_file)
    summary_doc = load_json(summary_path)
    schema_doc = load_json(schema_path)
    report = build_report(summary_path, schema_path, summary_doc, schema_doc)

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = (Path.cwd() / output_path).resolve()
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"error_count={report['error_count']} warning_count={report['warning_count']} verdict={report['verdict']}")
    return 0 if report["verdict"] == "pass" or not args.strict else 1


if __name__ == "__main__":
    sys.exit(main())
