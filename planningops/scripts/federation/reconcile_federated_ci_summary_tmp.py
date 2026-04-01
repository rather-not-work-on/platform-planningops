#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any

from federated_ci_runtime_state import (
    build_reconcile_report,
    build_reconcile_state,
    load_json,
    validate_checkpoint_doc,
    write_json,
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Reconcile a federated CI tmp summary against its checkpoint")
    parser.add_argument("--summary", required=True)
    parser.add_argument("--checkpoint", required=True)
    parser.add_argument("--output", default=None)
    parser.add_argument("--previous-report", default=None)
    parser.add_argument("--check-name", default=None)
    parser.add_argument("--restore-in-place", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    summary_path = Path(args.summary)
    checkpoint_path = Path(args.checkpoint)

    if not checkpoint_path.exists():
        print(f"checkpoint missing: {checkpoint_path}", file=sys.stderr)
        return 1

    checkpoint_doc = load_json(checkpoint_path)
    checkpoint_errors = validate_checkpoint_doc(checkpoint_doc)
    if checkpoint_errors:
        print(f"invalid checkpoint: {checkpoint_errors}", file=sys.stderr)
        return 1

    summary_doc: dict[str, Any] | None
    try:
        summary_doc = load_json(summary_path) if summary_path.exists() else None
    except (UnicodeDecodeError, json.JSONDecodeError):
        summary_doc = None

    previous_report_path = None if args.previous_report is None else Path(args.previous_report)
    previous_doc: dict[str, Any] | None = None
    if previous_report_path is not None and previous_report_path.exists():
        try:
            previous_doc = load_json(previous_report_path)
        except (UnicodeDecodeError, json.JSONDecodeError):
            previous_doc = None

    reconcile_state = build_reconcile_state(
        summary_doc,
        checkpoint_doc,
        previous_report_doc=previous_doc,
        check_name=args.check_name,
    )
    effective_summary_doc = summary_doc
    if reconcile_state.restored and args.restore_in_place:
        write_json(summary_path, checkpoint_doc)
        effective_summary_doc = checkpoint_doc

    output_path = None if args.output is None else Path(args.output)
    report = build_reconcile_report(
        summary_path=summary_path,
        checkpoint_path=checkpoint_path,
        output_path=output_path,
        checkpoint_doc=checkpoint_doc,
        summary_doc=effective_summary_doc,
        reconcile_state=reconcile_state,
    )

    if args.output is not None:
        write_json(output_path, report)
    else:
        print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
