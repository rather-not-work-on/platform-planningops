#!/usr/bin/env python3

from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path
import sys
from typing import Any

from federated_ci_runtime_state import build_check_record, finalize_summary_doc, load_json, write_json


def load_validator_module():
    module_path = Path(__file__).resolve().parents[1] / "validate_federated_ci_summary.py"
    spec = importlib.util.spec_from_file_location("validate_federated_ci_summary", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"unable to load validator module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def command_init(args: argparse.Namespace) -> int:
    summary_path = Path(args.summary)
    doc = {
        "run_id": args.run_id,
        "started_at_utc": now_utc(),
        "checks": [],
        "required_checks": list(args.required_check),
    }
    write_json(summary_path, doc)
    return 0


def command_append_check(args: argparse.Namespace) -> int:
    summary_path = Path(args.summary)
    doc = load_json(summary_path, default={"checks": []})
    checks = list(doc.get("checks") or [])
    checks.append(
        build_check_record(
            name=args.name,
            domain=args.domain,
            exit_code=args.exit_code,
            stdout_log=args.stdout_log,
            stderr_log=args.stderr_log,
            result=args.result,
        )
    )
    doc["checks"] = checks
    write_json(summary_path, doc)
    return 0


def command_finalize(args: argparse.Namespace) -> int:
    summary_path = Path(args.summary)
    doc = finalize_summary_doc(
        load_json(summary_path, default={"checks": [], "required_checks": []}),
        status=args.status,
        shell_exit_code=args.shell_exit_code,
    )
    failures = [check for check in list(doc.get("checks") or []) if check.get("verdict") == "fail"]

    stamped_path = Path(args.stamped_path)
    latest_path = Path(args.latest_path)
    write_json(stamped_path, doc)
    write_json(latest_path, doc)

    validator = load_validator_module()
    schema_path = Path(__file__).resolve().parents[2] / "schemas" / "federated-ci-summary.schema.json"
    schema_doc = validator.load_json(schema_path)

    stamped_report = validator.build_report(stamped_path, schema_path, doc, schema_doc)
    latest_report = validator.build_report(latest_path, schema_path, doc, schema_doc)

    if args.stamped_validation_output is not None:
        validator.write_json(Path(args.stamped_validation_output), stamped_report)
    if args.latest_validation_output is not None:
        validator.write_json(Path(args.latest_validation_output), latest_report)

    if stamped_report["verdict"] != "pass":
        print(f"federated stamped summary validation failed: {stamped_report['errors']}", file=sys.stderr)
        return 1
    if latest_report["verdict"] != "pass":
        print(f"federated latest summary validation failed: {latest_report['errors']}", file=sys.stderr)
        return 1

    if not args.keep_tmp:
        summary_path.unlink(missing_ok=True)

    print(f"federated summary written: {stamped_path}")
    print(f"federated summary written: {latest_path}")
    print(f"verdict={doc['verdict']} failure_count={len(failures)}")
    return 0 if doc["verdict"] == "pass" else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Manage federated CI summary artifacts")
    subparsers = parser.add_subparsers(dest="command", required=True)

    init_parser = subparsers.add_parser("init")
    init_parser.add_argument("--summary", required=True)
    init_parser.add_argument("--run-id", required=True)
    init_parser.add_argument("--required-check", action="append", default=[])
    init_parser.set_defaults(func=command_init)

    append_parser = subparsers.add_parser("append-check")
    append_parser.add_argument("--summary", required=True)
    append_parser.add_argument("--name", required=True)
    append_parser.add_argument("--domain", required=True)
    append_parser.add_argument("--exit-code", required=True, type=int)
    append_parser.add_argument("--stdout-log", required=True)
    append_parser.add_argument("--stderr-log", required=True)
    append_parser.add_argument("--result", default=None)
    append_parser.set_defaults(func=command_append_check)

    finalize_parser = subparsers.add_parser("finalize")
    finalize_parser.add_argument("--summary", required=True)
    finalize_parser.add_argument("--stamped-path", required=True)
    finalize_parser.add_argument("--latest-path", required=True)
    finalize_parser.add_argument("--status", choices=["complete", "interrupted"], required=True)
    finalize_parser.add_argument("--shell-exit-code", type=int, default=None)
    finalize_parser.add_argument("--stamped-validation-output", default=None)
    finalize_parser.add_argument("--latest-validation-output", default=None)
    finalize_parser.add_argument("--keep-tmp", action="store_true")
    finalize_parser.set_defaults(func=command_finalize)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
