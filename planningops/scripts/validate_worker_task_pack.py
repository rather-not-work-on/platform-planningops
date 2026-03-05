#!/usr/bin/env python3

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from ralph_loop_local import load_runtime_context, resolve_worker_command


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")


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

    if expected_type == "array":
        min_items = schema.get("minItems")
        if isinstance(min_items, int) and len(value) < min_items:
            append_error(errors, f"schema: {path} minItems violation")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for idx, row in enumerate(value):
                _validate_schema_value(row, item_schema, root_schema, f"{path}[{idx}]", errors)

    if expected_type == "object":
        required = schema.get("required", [])
        props = schema.get("properties", {})
        for key in required:
            if key not in value:
                append_error(errors, f"schema: {path}.{key} is required")
        if schema.get("additionalProperties") is False:
            for key in value.keys():
                if key not in props:
                    append_error(errors, f"schema: {path} unexpected key: {key}")
        for key, prop_schema in props.items():
            if key in value:
                _validate_schema_value(value[key], prop_schema, root_schema, f"{path}.{key}", errors)


def validate_schema(doc, schema_doc):
    errors = []
    if not isinstance(doc, dict):
        return ["document must be object"]
    if not isinstance(schema_doc, dict):
        return ["schema document must be object"]
    _validate_schema_value(doc, schema_doc, schema_doc, "$", errors)
    return errors


def build_worker_task_pack(runtime_ctx, issue_number: int, mode: str, loop_profile: str, task_key: str, target_repo: str):
    worker_plan = resolve_worker_command(issue_number, mode, f"worker-pack-issue-{issue_number}", runtime_ctx)
    provider_policy = runtime_ctx.get("provider_policy") or {}
    max_retries = int(provider_policy.get("max_retries", 0))
    timeout_ms = int(provider_policy.get("timeout_ms", 60000))
    fingerprint = "|".join(
        [
            task_key,
            str(issue_number),
            mode,
            loop_profile,
            worker_plan["kind"],
            " ".join(worker_plan["command"]),
        ]
    )
    idempotency_key = hashlib.sha256(fingerprint.encode("utf-8")).hexdigest()
    pack = {
        "worker_task_pack": {
            "version": "v1",
            "task_key": task_key,
            "issue_number": issue_number,
            "mode": mode,
            "loop_profile": loop_profile,
            "runtime_profile": runtime_ctx.get("selected_profile", ""),
            "worker_policy_kind": worker_plan["kind"],
            "command": worker_plan["command"],
            "retry_policy": {"max_retries": max_retries},
            "timeout_ms": timeout_ms,
            "idempotency_key": idempotency_key,
            "target_repo": target_repo,
            "metadata": {
                "profile_file": runtime_ctx.get("profile_file"),
                "task_key": runtime_ctx.get("task_key"),
            },
        }
    }
    return pack


def main():
    parser = argparse.ArgumentParser(description="Validate and materialize worker task pack contract")
    parser.add_argument("--runtime-profile-file", default="planningops/config/runtime-profiles.json")
    parser.add_argument("--schema-file", default="planningops/schemas/worker-task-pack.schema.json")
    parser.add_argument("--task-key", required=True)
    parser.add_argument("--issue-number", type=int, required=True)
    parser.add_argument("--mode", choices=["dry-run", "apply"], required=True)
    parser.add_argument("--loop-profile", required=True)
    parser.add_argument("--target-repo", default="rather-not-work-on/platform-planningops")
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/worker-task-pack-report.json",
    )
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    report = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "runtime_profile_file": args.runtime_profile_file,
        "schema_file": args.schema_file,
        "task_key": args.task_key,
        "issue_number": args.issue_number,
        "mode": args.mode,
        "loop_profile": args.loop_profile,
        "target_repo": args.target_repo,
        "validation_errors": [],
    }

    try:
        runtime_ctx = load_runtime_context(Path(args.runtime_profile_file), args.task_key)
    except Exception as exc:  # noqa: BLE001
        report["verdict"] = "fail"
        report["reason"] = "runtime_context_invalid"
        report["validation_errors"] = [str(exc)]
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    try:
        pack_doc = build_worker_task_pack(
            runtime_ctx=runtime_ctx,
            issue_number=args.issue_number,
            mode=args.mode,
            loop_profile=args.loop_profile,
            task_key=args.task_key,
            target_repo=args.target_repo,
        )
    except Exception as exc:  # noqa: BLE001
        report["verdict"] = "fail"
        report["reason"] = "worker_policy_render_failed"
        report["validation_errors"] = [str(exc)]
        write_json(Path(args.output), report)
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1 if args.strict else 0

    schema_doc = read_json(Path(args.schema_file))
    validation_errors = validate_schema(pack_doc, schema_doc)

    report["worker_task_pack"] = pack_doc["worker_task_pack"]
    report["validation_errors"] = validation_errors
    if validation_errors:
        report["verdict"] = "fail"
        report["reason"] = "schema_invalid"
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
