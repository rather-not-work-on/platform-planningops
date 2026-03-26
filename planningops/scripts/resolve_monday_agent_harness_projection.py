#!/usr/bin/env python3

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from validate_monday_agent_harness_projection import (
    DEFAULT_BUNDLE_OUTPUT,
    DEFAULT_BUNDLE_SCHEMA,
    DEFAULT_MONDAY_ROOT,
    DEFAULT_PROJECTION_ROOT,
    build_bundle_doc,
    build_input_paths,
)
from validate_supervisor_operator_handoff import load_json, validate_schema, write_json


def parse_args():
    parser = argparse.ArgumentParser(description="Resolve monday agent harness projection surfaces into one canonical bundle")
    parser.add_argument("--monday-root", default=str(DEFAULT_MONDAY_ROOT))
    parser.add_argument("--projection-root", default=str(DEFAULT_PROJECTION_ROOT))
    parser.add_argument("--completion-summary", default=None)
    parser.add_argument("--readiness-projection", default=None)
    parser.add_argument("--verification-projection", default=None)
    parser.add_argument("--operator-handoff-summary", default=None)
    parser.add_argument("--schema-file", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_BUNDLE_OUTPUT))
    return parser.parse_args()


def resolve_bundle_from_paths(paths: dict[str, Path], *, schema_path: Path, output_path: Path) -> tuple[dict, list[str]]:
    bundle_doc, load_errors = build_bundle_doc(paths)
    bundle_doc = dict(bundle_doc)
    bundle_doc["bundle_path"] = str(output_path)

    schema_doc = load_json(schema_path)
    schema_errors = validate_schema(bundle_doc, schema_doc)
    errors = list(load_errors)
    errors.extend(schema_errors)
    write_json(output_path, bundle_doc)
    return bundle_doc, errors


def main() -> int:
    args = parse_args()
    paths = build_input_paths(args)
    output_path = Path(args.output).resolve()
    bundle_doc, errors = resolve_bundle_from_paths(
        paths,
        schema_path=Path(args.schema_file).resolve(),
        output_path=output_path,
    )
    if errors:
        print(f"bundle written: {output_path}")
        print(f"error_count={len(errors)}")
        for error in errors:
            print(error, file=sys.stderr)
        return 1

    print(f"bundle written: {output_path}")
    print(f"projection_root={bundle_doc['projection_root']}")
    print(f"run_id={bundle_doc['completion_summary'].get('runId')}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
