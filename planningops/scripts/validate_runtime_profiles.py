#!/usr/bin/env python3

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def append_error(errors, message):
    if message not in errors:
        errors.append(message)


def _resolve_ref(root_schema, ref):
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ValueError(f"unsupported schema ref: {ref}")
    cursor = root_schema
    for token in ref[2:].split("/"):
        cursor = cursor[token]
    return cursor


def _is_type(value, type_name):
    if type_name == "object":
        return isinstance(value, dict)
    if type_name == "array":
        return isinstance(value, list)
    if type_name == "string":
        return isinstance(value, str)
    if type_name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "boolean":
        return isinstance(value, bool)
    return True


def _validate_schema_value(value, schema, root_schema, path, errors):
    if not isinstance(schema, dict):
        return

    if "$ref" in schema:
        schema = _resolve_ref(root_schema, schema["$ref"])

    expected_type = schema.get("type")
    if expected_type and not _is_type(value, expected_type):
        append_error(errors, f"schema: {path} expected type {expected_type}")
        return

    if "enum" in schema and value not in schema["enum"]:
        append_error(errors, f"schema: {path} invalid enum value: {value}")

    if expected_type == "string":
        min_len = schema.get("minLength")
        if isinstance(min_len, int) and len(value) < min_len:
            append_error(errors, f"schema: {path} minLength violation")
        pattern = schema.get("pattern")
        if pattern and not re.match(pattern, value):
            append_error(errors, f"schema: {path} does not match pattern")

    if expected_type == "integer":
        minimum = schema.get("minimum")
        if isinstance(minimum, int) and value < minimum:
            append_error(errors, f"schema: {path} below minimum {minimum}")

    if expected_type == "object":
        required = schema.get("required", [])
        props = schema.get("properties", {})
        for key in required:
            if key not in value:
                append_error(errors, f"schema: {path}.{key} is required")
        additional_props = schema.get("additionalProperties", True)
        for key, child_value in value.items():
            if key in props:
                continue
            if additional_props is False:
                append_error(errors, f"schema: {path} unexpected key: {key}")
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
    errors = []
    if not isinstance(doc, dict):
        return ["document must be object"]
    if not isinstance(schema_doc, dict):
        return ["schema document must be object"]
    _validate_schema_value(doc, schema_doc, schema_doc, "$", errors)
    return errors


def validate_profile(name: str, profile: dict, errors: list[str]):
    if not isinstance(name, str) or not name.strip():
        append_error(errors, "profile key must be a non-empty string")
    if not isinstance(profile, dict):
        append_error(errors, f"profile '{name}' must be an object")
        return

    for field in ("execution_mode", "litellm_base_url", "langfuse_host"):
        value = profile.get(field)
        if not isinstance(value, str) or not value.strip():
            append_error(errors, f"profile '{name}' missing non-empty string field '{field}'")

    planner_policy = profile.get("planner_policy")
    if planner_policy is not None:
        if not isinstance(planner_policy, dict):
            append_error(errors, f"profile '{name}' planner_policy must be an object")
        else:
            for field in ("engine_hint", "execution_mode", "capability_profile"):
                value = planner_policy.get(field)
                if not isinstance(value, str) or not value.strip():
                    append_error(errors, f"profile '{name}' planner_policy.{field} must be a non-empty string")

    notes = profile.get("notes")
    if notes is not None and not isinstance(notes, str):
        append_error(errors, f"profile '{name}' notes must be a string when present")


def validate_provider_policy(task_key: str, provider_policy: dict, errors: list[str]):
    if not isinstance(provider_policy, dict):
        append_error(errors, f"task_overrides.{task_key}.provider_policy must be an object")
        return
    model = provider_policy.get("model")
    if model is not None and (not isinstance(model, str) or not model.strip()):
        append_error(errors, f"task_overrides.{task_key}.provider_policy.model must be a non-empty string")
    fallback_models = provider_policy.get("fallback_models")
    if fallback_models is not None:
        if not isinstance(fallback_models, list) or any(not isinstance(v, str) or not v.strip() for v in fallback_models):
            append_error(errors, f"task_overrides.{task_key}.provider_policy.fallback_models must be a list of strings")
    max_retries = provider_policy.get("max_retries")
    if max_retries is not None and (not isinstance(max_retries, int) or isinstance(max_retries, bool) or max_retries < 0):
        append_error(errors, f"task_overrides.{task_key}.provider_policy.max_retries must be an integer >= 0")
    timeout_ms = provider_policy.get("timeout_ms")
    if timeout_ms is not None and (not isinstance(timeout_ms, int) or isinstance(timeout_ms, bool) or timeout_ms < 1):
        append_error(errors, f"task_overrides.{task_key}.provider_policy.timeout_ms must be a positive integer")


def validate_worker_policy(task_key: str, worker_policy: dict, errors: list[str]):
    if not isinstance(worker_policy, dict):
        append_error(errors, f"task_overrides.{task_key}.worker_policy must be an object")
        return
    kind = worker_policy.get("kind")
    if kind not in {"parser_diff_dry_run", "python_script", "shell"}:
        append_error(errors, f"task_overrides.{task_key}.worker_policy.kind must be parser_diff_dry_run, python_script, or shell")
        return
    if kind == "python_script":
        script = worker_policy.get("script")
        if not isinstance(script, str) or not script.strip():
            append_error(errors, f"task_overrides.{task_key}.worker_policy.script must be a non-empty string")
        args = worker_policy.get("args")
        if args is not None and (not isinstance(args, list) or any(not isinstance(v, str) for v in args)):
            append_error(errors, f"task_overrides.{task_key}.worker_policy.args must be a list of strings when present")
    if kind == "shell":
        command = worker_policy.get("command")
        if not isinstance(command, str) or not command.strip():
            append_error(errors, f"task_overrides.{task_key}.worker_policy.command must be a non-empty string")


def validate_semantics(doc: dict):
    errors: list[str] = []
    warnings: list[str] = []

    profiles = doc.get("profiles")
    active_profile = doc.get("active_profile")
    task_overrides = doc.get("task_overrides")

    if not isinstance(profiles, dict) or not profiles:
        append_error(errors, "profiles must be a non-empty object")
        return errors, warnings
    if not isinstance(active_profile, str) or not active_profile.strip():
        append_error(errors, "active_profile must be a non-empty string")
    elif active_profile not in profiles:
        append_error(errors, f"active_profile '{active_profile}' is not defined in profiles")

    for name, profile in profiles.items():
        validate_profile(name, profile, errors)

    if not isinstance(task_overrides, dict):
        append_error(errors, "task_overrides must be an object")
        return errors, warnings

    for task_key, override in task_overrides.items():
        if not isinstance(task_key, str) or not task_key.strip():
            append_error(errors, "task override keys must be non-empty strings")
            continue
        if not isinstance(override, dict):
            append_error(errors, f"task_overrides.{task_key} must be an object")
            continue
        runtime_profile = override.get("runtime_profile")
        if runtime_profile is not None:
            if not isinstance(runtime_profile, str) or not runtime_profile.strip():
                append_error(errors, f"task_overrides.{task_key}.runtime_profile must be a non-empty string")
            elif runtime_profile not in profiles:
                append_error(errors, f"task_overrides.{task_key}.runtime_profile '{runtime_profile}' is not defined")
        if "provider_policy" in override:
            validate_provider_policy(task_key, override["provider_policy"], errors)
        if "worker_policy" in override:
            validate_worker_policy(task_key, override["worker_policy"], errors)

    if "default" not in task_overrides:
        warnings.append("task_overrides.default is not defined; fallback behavior will rely on active_profile only")

    return errors, warnings


def main():
    parser = argparse.ArgumentParser(description="Validate planningops runtime profile catalog")
    parser.add_argument("--runtime-profile-file", default="planningops/config/runtime-profiles.json")
    parser.add_argument("--schema-file", default="planningops/schemas/runtime-profiles.schema.json")
    parser.add_argument("--output", default="planningops/artifacts/validation/runtime-profiles-report.json")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    report = {
        "generated_at_utc": now_utc(),
        "runtime_profile_file": args.runtime_profile_file,
        "schema_file": args.schema_file,
        "validation_errors": [],
        "warnings": [],
    }

    try:
        runtime_doc = read_json(Path(args.runtime_profile_file))
        schema_doc = read_json(Path(args.schema_file))
    except Exception as exc:  # noqa: BLE001
        report["verdict"] = "fail"
        report["reason"] = "load_failed"
        report["validation_errors"] = [str(exc)]
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    validation_errors = validate_schema(runtime_doc, schema_doc)
    semantic_errors, warnings = validate_semantics(runtime_doc)
    validation_errors.extend(semantic_errors)

    report["active_profile"] = runtime_doc.get("active_profile")
    report["profile_names"] = sorted(runtime_doc.get("profiles", {}).keys()) if isinstance(runtime_doc.get("profiles"), dict) else []
    report["task_override_keys"] = sorted(runtime_doc.get("task_overrides", {}).keys()) if isinstance(runtime_doc.get("task_overrides"), dict) else []
    report["validation_errors"] = validation_errors
    report["warnings"] = warnings

    if validation_errors:
        report["verdict"] = "fail"
        report["reason"] = "runtime_profiles_invalid"
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    report["verdict"] = "pass"
    report["reason"] = "ok"
    write_json(Path(args.output), report)
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
