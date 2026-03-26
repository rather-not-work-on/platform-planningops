#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import importlib.util
import sys
from datetime import datetime, timezone
from pathlib import Path

from doctor_federated_ci_summary import DEFAULT_SUMMARY, DEFAULT_VALIDATION, WORKSPACE_ROOT, build_status


DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness.json"
DEFAULT_VALIDATION_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness-validation.json"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def write_json(path: Path, doc) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def load_validator_module():
    module_path = Path(__file__).resolve().parent / "validate_federated_ci_summary_readiness.py"
    spec = importlib.util.spec_from_file_location("validate_federated_ci_summary_readiness", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load readiness validator module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> int:
    parser = argparse.ArgumentParser(description="Assess federated CI summary readiness")
    parser.add_argument("--summary", default=str(DEFAULT_SUMMARY))
    parser.add_argument("--validation-report", default=str(DEFAULT_VALIDATION))
    parser.add_argument("--output", "--readiness-report", dest="output", default=str(DEFAULT_OUTPUT))
    parser.add_argument(
        "--validation-output",
        "--readiness-validation-report",
        dest="validation_output",
        default=str(DEFAULT_VALIDATION_OUTPUT),
    )
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    summary_path = Path(args.summary)
    validation_path = Path(args.validation_report)
    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = (Path.cwd() / output_path).resolve()
    validation_output_path = Path(args.validation_output)
    if not validation_output_path.is_absolute():
        validation_output_path = (Path.cwd() / validation_output_path).resolve()

    status = build_status(summary_path, validation_path)
    report = {
        "generated_at_utc": now_utc(),
        **status,
    }
    validator = load_validator_module()
    schema_path = Path(__file__).resolve().parent.parent / "schemas" / "federated-ci-summary-readiness.schema.json"
    schema_doc = validator.load_json(schema_path)
    validation_report = validator.build_report(output_path, schema_path, report, schema_doc)
    validator.write_json(validation_output_path, validation_report)
    if validation_report["verdict"] != "pass":
        print(f"federated summary readiness validation failed: {validation_report['errors']}", file=sys.stderr)
        return 1
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"readiness_status={report['readiness_status']} ready={report['ready']}")
    return 0 if report["ready"] or not args.strict else 1


if __name__ == "__main__":
    sys.exit(main())
