#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import sys


def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def validate_required(doc: dict, schema: dict):
    errors = []
    for key in schema.get("required", []):
        if key not in doc:
            errors.append(f"missing required key: {key}")
    return errors


def validate_enums(doc: dict, schema: dict, prefix: str = ""):
    errors = []
    props = schema.get("properties", {})
    for key, prop in props.items():
        full_key = f"{prefix}{key}"
        if key not in doc:
            continue
        val = doc[key]

        if prop.get("type") == "object" and isinstance(val, dict):
            errors.extend(validate_required(val, prop))
            errors.extend(validate_enums(val, prop, prefix=f"{full_key}."))

        if "enum" in prop and val not in prop["enum"]:
            allowed = ",".join(prop["enum"])
            errors.append(f"invalid enum {full_key}={val} (allowed: {allowed})")
    return errors


def validate_pair(schema_path: Path, sample_path: Path):
    schema = load_json(schema_path)
    sample = load_json(sample_path)
    errors = []
    errors.extend(validate_required(sample, schema))
    errors.extend(validate_enums(sample, schema))
    return errors


def main():
    parser = argparse.ArgumentParser(description="Validate C1~C5 contract fixtures")
    parser.add_argument(
        "--root",
        default="planningops",
        help="workspace root that contains schemas/ and fixtures/",
    )
    args = parser.parse_args()

    root = Path(args.root)
    pairs = [
        ("c1-run-lifecycle.schema.json", "c1-run-lifecycle.valid.json"),
        ("c2-subtask-handoff.schema.json", "c2-subtask-handoff.valid.json"),
        ("c3-executor-result.schema.json", "c3-executor-result.valid.json"),
        ("c4-provider-invocation.schema.json", "c4-provider-invocation.valid.json"),
        ("c5-observability-event.schema.json", "c5-observability-event.valid.json"),
    ]

    total_errors = 0
    for schema_name, sample_name in pairs:
        schema_path = root / "schemas" / schema_name
        sample_path = root / "fixtures" / "contracts" / sample_name
        errs = validate_pair(schema_path, sample_path)
        if errs:
            print(f"[FAIL] {schema_name} <- {sample_name}")
            for err in errs:
                print(f"  - {err}")
            total_errors += len(errs)
        else:
            print(f"[PASS] {schema_name} <- {sample_name}")

    if total_errors > 0:
        print(f"validation failed: {total_errors} error(s)")
        return 1

    print("validation passed: all C1~C5 fixtures are valid")
    return 0


if __name__ == "__main__":
    sys.exit(main())
