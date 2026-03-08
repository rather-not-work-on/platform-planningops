#!/usr/bin/env python3

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_SCHEMA = Path("planningops/schemas/memory-archive-manifest.schema.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/memory-archive-manifest-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def validate(instance, schema, path="$"):
    errors = []
    expected_type = schema.get("type")
    if expected_type == "object":
        if not isinstance(instance, dict):
            return [f"{path}: expected object"]
        required = schema.get("required", [])
        for key in required:
            if key not in instance:
                errors.append(f"{path}.{key}: missing required property")
        properties = schema.get("properties", {})
        for key, value in instance.items():
            if key not in properties:
                additional = schema.get("additionalProperties", True)
                if additional is False:
                    errors.append(f"{path}.{key}: additional property not allowed")
                elif isinstance(additional, dict):
                    errors.extend(validate(value, additional, f"{path}.{key}"))
                continue
            errors.extend(validate(value, properties[key], f"{path}.{key}"))
        return errors

    if expected_type == "array":
        if not isinstance(instance, list):
            return [f"{path}: expected array"]
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for idx, value in enumerate(instance):
                errors.extend(validate(value, item_schema, f"{path}[{idx}]"))
        return errors

    if expected_type == "string":
        if not isinstance(instance, str):
            return [f"{path}: expected string"]
        if schema.get("minLength") and len(instance) < schema["minLength"]:
            errors.append(f"{path}: string shorter than minLength {schema['minLength']}")
        if "const" in schema and instance != schema["const"]:
            errors.append(f"{path}: expected const {schema['const']}")
        if "enum" in schema and instance not in schema["enum"]:
            errors.append(f"{path}: expected one of {schema['enum']}")
        return errors

    if expected_type == "integer":
        if not isinstance(instance, int) or isinstance(instance, bool):
            return [f"{path}: expected integer"]
        return errors

    return errors


def main():
    parser = argparse.ArgumentParser(description="Validate memory archive manifest against local schema")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    schema_path = Path(args.schema)
    manifest = load_json(manifest_path)
    schema = load_json(schema_path)
    errors = validate(manifest, schema)

    report = {
        "generated_at_utc": now_utc(),
        "manifest_path": str(manifest_path.resolve()),
        "schema_path": str(schema_path.resolve()),
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = (Path.cwd() / output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(f"report written: {output_path}")
    print(f"error_count={len(errors)} verdict={report['verdict']}")
    return 0 if not errors or not args.strict else 1


if __name__ == "__main__":
    sys.exit(main())
