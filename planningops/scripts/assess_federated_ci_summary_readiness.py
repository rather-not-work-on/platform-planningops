#!/usr/bin/env python3

from __future__ import annotations

import argparse
import importlib.util
import sys
from pathlib import Path

from doctor_federated_ci_summary import DEFAULT_SUMMARY, DEFAULT_VALIDATION, WORKSPACE_ROOT, build_status
from federation.federated_ci_runtime_state import (
    build_readiness_artifact_write_plan,
    build_readiness_report,
    write_readiness_artifacts,
)


DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness.json"
DEFAULT_VALIDATION_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/federated-ci-summary-readiness-validation.json"


def load_validator_module():
    module_path = Path(__file__).resolve().parent / "validate_federated_ci_summary_readiness.py"
    spec = importlib.util.spec_from_file_location("validate_federated_ci_summary_readiness", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load readiness validator module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def assess_readiness_artifacts(
    *,
    summary_path: Path,
    validation_path: Path,
    output_path: Path,
    validation_output_path: Path,
) -> tuple[dict, dict]:
    report = build_readiness_report(build_status(summary_path, validation_path))
    validator = load_validator_module()
    schema_path = Path(__file__).resolve().parent.parent / "schemas" / "federated-ci-summary-readiness.schema.json"
    validation_report = write_readiness_artifacts(
        report,
        plan=build_readiness_artifact_write_plan(
            output_path=output_path,
            validation_output=validation_output_path,
        ),
        validator_module=validator,
        schema_path=schema_path,
    )
    return report, validation_report


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

    report, validation_report = assess_readiness_artifacts(
        summary_path=summary_path,
        validation_path=validation_path,
        output_path=output_path,
        validation_output_path=validation_output_path,
    )
    if validation_report["verdict"] != "pass":
        print(f"federated summary readiness validation failed: {validation_report['errors']}", file=sys.stderr)
        return 1
    print(f"report written: {output_path}")
    print(f"readiness_status={report['readiness_status']} ready={report['ready']}")
    return 0 if report["ready"] or not args.strict else 1


if __name__ == "__main__":
    sys.exit(main())
