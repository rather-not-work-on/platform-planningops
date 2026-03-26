#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import resolve_plain_python_compat_manifest as resolver


DEFAULT_MANIFEST = resolver.default_manifest_path()
DEFAULT_SCHEMA = resolver.repo_root() / "planningops/schemas/plain-python-compat-manifest.schema.json"
DEFAULT_OUTPUT = resolver.repo_root() / "planningops/artifacts/validation/plain-python-compat-manifest-validation.json"
SCRIPT_REF_PATTERN = re.compile(r"planningops/scripts/[A-Za-z0-9_./-]+\.(?:py|sh)")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def _resolve_ref(root_schema: dict[str, Any], ref: str) -> dict[str, Any]:
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ValueError(f"unsupported schema ref: {ref}")
    cursor: Any = root_schema
    for token in ref[2:].split("/"):
        cursor = cursor[token]
    return cursor


def _is_type(value: Any, type_name: str) -> bool:
    if type_name == "object":
        return isinstance(value, dict)
    if type_name == "array":
        return isinstance(value, list)
    if type_name == "string":
        return isinstance(value, str)
    if type_name == "boolean":
        return isinstance(value, bool)
    if type_name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "number":
        return (isinstance(value, int) and not isinstance(value, bool)) or isinstance(value, float)
    if type_name == "null":
        return value is None
    return True


def _validate_schema_value(
    value: Any,
    schema: dict[str, Any],
    root_schema: dict[str, Any],
    path: str,
    errors: list[str],
) -> None:
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


def validate_schema(doc: Any, schema_doc: Any) -> list[str]:
    errors: list[str] = []
    if not isinstance(doc, dict):
        return ["document must be object"]
    if not isinstance(schema_doc, dict):
        return ["schema document must be object"]
    _validate_schema_value(doc, schema_doc, schema_doc, "$", errors)
    return errors


def inspect_guardrail_script_paths(
    loop_guardrails_chain: list[Any],
    root_dir: Path,
    errors: list[str],
) -> list[str]:
    resolved_paths: list[str] = []
    for idx, step in enumerate(loop_guardrails_chain):
        if not isinstance(step, dict):
            continue
        for field_name in ("local_matrix_command", "workflow_command"):
            command = step.get(field_name)
            if not isinstance(command, str) or not command.strip():
                continue
            for ref in sorted(set(SCRIPT_REF_PATTERN.findall(command))):
                resolved_path = (root_dir / ref).resolve()
                resolved_paths.append(str(resolved_path))
                if not resolved_path.is_file():
                    append_unique(
                        errors,
                        f"loop_guardrails_chain[{idx}].{field_name} references missing script: {ref}",
                    )
                    continue
                if resolved_path.stat().st_size == 0:
                    append_unique(
                        errors,
                        f"loop_guardrails_chain[{idx}].{field_name} references empty script: {ref}",
                    )
    return sorted(set(resolved_paths))


def validate_semantics(
    manifest_path: Path,
    doc: dict[str, Any],
) -> tuple[list[str], list[str], dict[str, Any] | None, list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    entrypoints = doc.get("entrypoints")
    sequence = doc.get("runtime_stack_sequence")
    loop_guardrails_chain = doc.get("loop_guardrails_chain")

    if not isinstance(entrypoints, list):
        append_unique(errors, "entrypoints must be an array")
        return errors, warnings, None, []
    if not isinstance(sequence, dict):
        append_unique(errors, "runtime_stack_sequence must be an object")
        return errors, warnings, None, []
    if not isinstance(loop_guardrails_chain, list):
        append_unique(errors, "loop_guardrails_chain must be an array")
        return errors, warnings, None, []

    ids: list[str] = []
    for idx, entry in enumerate(entrypoints):
        if not isinstance(entry, dict):
            append_unique(errors, f"entrypoints[{idx}] must be an object")
            continue
        entry_id = entry.get("id")
        mode = entry.get("mode")
        path = entry.get("path")

        if not isinstance(entry_id, str) or not entry_id.strip():
            append_unique(errors, f"entrypoints[{idx}].id must be a non-empty string")
        else:
            ids.append(entry_id)
        if isinstance(path, str) and not path.endswith(".py"):
            append_unique(errors, f"entrypoints[{idx}].path must end with .py")
        if mode == "import":
            symbol = entry.get("symbol")
            if not isinstance(symbol, str) or not symbol.strip():
                append_unique(errors, f"entrypoints[{idx}].symbol must be a non-empty string when mode=import")
        elif "symbol" in entry and entry.get("symbol") not in (None, ""):
            append_unique(errors, f"entrypoints[{idx}].symbol is only allowed for mode=import")

    if len(set(ids)) != len(ids):
        append_unique(errors, "entrypoint ids must be unique")

    if not isinstance(sequence.get("issue_driven_entrypoint_id"), str) or not sequence["issue_driven_entrypoint_id"].strip():
        append_unique(errors, "runtime_stack_sequence.issue_driven_entrypoint_id must be a non-empty string")
    if not isinstance(sequence.get("local_entrypoint_id"), str) or not sequence["local_entrypoint_id"].strip():
        append_unique(errors, "runtime_stack_sequence.local_entrypoint_id must be a non-empty string")

    loop_guardrails_ids: list[str] = []
    local_commands: list[str] = []
    workflow_commands: list[str] = []
    for idx, step in enumerate(loop_guardrails_chain):
        if not isinstance(step, dict):
            append_unique(errors, f"loop_guardrails_chain[{idx}] must be an object")
            continue
        step_id = step.get("id")
        local_command = step.get("local_matrix_command")
        workflow_command = step.get("workflow_command")
        if not isinstance(step_id, str) or not step_id.strip():
            append_unique(errors, f"loop_guardrails_chain[{idx}].id must be a non-empty string")
        else:
            loop_guardrails_ids.append(step_id)
        if not isinstance(local_command, str) or not local_command.strip():
            append_unique(errors, f"loop_guardrails_chain[{idx}].local_matrix_command must be a non-empty string")
        else:
            local_commands.append(local_command)
        if not isinstance(workflow_command, str) or not workflow_command.strip():
            append_unique(errors, f"loop_guardrails_chain[{idx}].workflow_command must be a non-empty string")
        else:
            workflow_commands.append(workflow_command)

    if len(set(loop_guardrails_ids)) != len(loop_guardrails_ids):
        append_unique(errors, "loop_guardrails_chain ids must be unique")
    if len(set(local_commands)) != len(local_commands):
        append_unique(errors, "loop_guardrails_chain local_matrix_command values must be unique")
    if len(set(workflow_commands)) != len(workflow_commands):
        append_unique(errors, "loop_guardrails_chain workflow_command values must be unique")

    root_dir = resolver.repo_root()
    resolved_guardrail_script_paths = inspect_guardrail_script_paths(loop_guardrails_chain, root_dir, errors)

    resolved_report: dict[str, Any] | None = None
    try:
        resolved_report = resolver.build_report(manifest_path.resolve(), root_dir)
    except SystemExit as exc:
        append_unique(errors, str(exc))

    if resolved_report is not None:
        if resolved_report.get("entrypoint_count") != len(entrypoints):
            append_unique(errors, "resolved entrypoint_count must equal len(entrypoints)")
        resolved_ids = [entry["id"] for entry in resolved_report.get("entrypoints", [])]
        if resolved_ids != ids:
            append_unique(errors, "resolved entrypoint ids must preserve manifest order")
        resolved_guardrail_ids = [step["id"] for step in resolved_report.get("loop_guardrails_chain", [])]
        if resolved_guardrail_ids != loop_guardrails_ids:
            append_unique(errors, "resolved loop_guardrails_chain ids must preserve manifest order")

    return errors, warnings, resolved_report, resolved_guardrail_script_paths


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate plain-python compatibility manifest.")
    parser.add_argument("--manifest-file", default=str(DEFAULT_MANIFEST))
    parser.add_argument("--schema-file", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    manifest_path = Path(args.manifest_file)
    schema_path = Path(args.schema_file)
    output_path = Path(args.output)

    doc = load_json(manifest_path)
    schema_doc = load_json(schema_path)

    schema_errors = validate_schema(doc, schema_doc)
    semantic_errors, warnings, resolved_report, resolved_guardrail_script_paths = validate_semantics(manifest_path, doc)
    errors = schema_errors + semantic_errors
    verdict = "pass" if not errors else "fail"

    report = {
        "manifest_path": str(manifest_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "validation_output_path": str(output_path.resolve()),
        "generated_at_utc": now_utc(),
        "verdict": verdict,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "entrypoint_count": len(doc.get("entrypoints", [])) if isinstance(doc.get("entrypoints"), list) else 0,
        "runtime_stack_sequence": doc.get("runtime_stack_sequence"),
        "loop_guardrails_chain": doc.get("loop_guardrails_chain"),
        "resolved_guardrail_script_paths": resolved_guardrail_script_paths,
    }
    if resolved_report is not None:
        report["resolved_entrypoint_count"] = resolved_report["entrypoint_count"]
        report["resolved_runtime_stack_sequence"] = resolved_report["runtime_stack_sequence"]
        report["resolved_loop_guardrails_chain"] = resolved_report["loop_guardrails_chain"]

    write_json(output_path, report)

    if verdict != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
