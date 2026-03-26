#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import sys
from typing import Any


REQUIRED_KEYS = ("run_id", "started_at_utc", "required_checks", "checks")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def validate_checkpoint(doc: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for key in REQUIRED_KEYS:
        if key not in doc:
            errors.append(f"checkpoint missing required key: {key}")
    if not isinstance(doc.get("checks"), list):
        errors.append("checkpoint checks must be a list")
    if not isinstance(doc.get("required_checks"), list):
        errors.append("checkpoint required_checks must be a list")
    if not str(doc.get("run_id") or "").strip():
        errors.append("checkpoint run_id must be non-empty")
    if not str(doc.get("started_at_utc") or "").strip():
        errors.append("checkpoint started_at_utc must be non-empty")
    return errors


def build_status(
    summary_doc: dict[str, Any] | None,
    checkpoint_doc: dict[str, Any],
) -> list[str]:
    if summary_doc is None:
        return ["summary_missing_or_invalid"]

    reasons: list[str] = []
    for key in REQUIRED_KEYS:
        if key not in summary_doc:
            reasons.append(f"summary_missing_{key}")
    if reasons:
        return reasons

    if summary_doc["run_id"] != checkpoint_doc["run_id"]:
        reasons.append("summary_run_id_mismatch")
    if summary_doc["started_at_utc"] != checkpoint_doc["started_at_utc"]:
        reasons.append("summary_started_at_utc_mismatch")
    if list(summary_doc.get("required_checks") or []) != list(checkpoint_doc.get("required_checks") or []):
        reasons.append("summary_required_checks_mismatch")
    if len(list(summary_doc.get("checks") or [])) < len(list(checkpoint_doc.get("checks") or [])):
        reasons.append("summary_check_count_regressed")
    return reasons


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
    checkpoint_errors = validate_checkpoint(checkpoint_doc)
    if checkpoint_errors:
        print(f"invalid checkpoint: {checkpoint_errors}", file=sys.stderr)
        return 1

    summary_doc: dict[str, Any] | None
    try:
        summary_doc = load_json(summary_path) if summary_path.exists() else None
    except json.JSONDecodeError:
        summary_doc = None

    reasons = build_status(summary_doc, checkpoint_doc)
    restored = bool(reasons)
    if restored and args.restore_in_place:
        write_json(summary_path, checkpoint_doc)
        summary_doc = checkpoint_doc

    restored_check_names: list[str] = []
    previous_report_path = None if args.previous_report is None else Path(args.previous_report)
    if previous_report_path is not None and previous_report_path.exists():
        try:
            previous_doc = load_json(previous_report_path)
        except json.JSONDecodeError:
            previous_doc = {}
        if previous_doc.get("run_id") == checkpoint_doc["run_id"]:
            previous_names = previous_doc.get("restored_check_names") or []
            if isinstance(previous_names, list):
                restored_check_names = [name for name in previous_names if isinstance(name, str) and name.strip()]

    check_name = args.check_name if isinstance(args.check_name, str) and args.check_name.strip() else None
    if restored and check_name is not None and check_name not in restored_check_names:
        restored_check_names.append(check_name)

    reconcile_count = len(restored_check_names)

    report = {
        "generated_at_utc": now_utc(),
        "summary_path": str(summary_path.resolve()),
        "checkpoint_path": str(checkpoint_path.resolve()),
        "output_path": None if args.output is None else str(Path(args.output).resolve()),
        "run_id": checkpoint_doc["run_id"],
        "check_name": check_name,
        "checkpoint_check_count": len(list(checkpoint_doc.get("checks") or [])),
        "summary_check_count": None if summary_doc is None else len(list(summary_doc.get("checks") or [])),
        "restored": restored,
        "status": "restored" if restored else "healthy",
        "reasons": reasons,
        "reconcile_count": reconcile_count,
        "restored_check_names": restored_check_names,
    }

    if args.output is not None:
        write_json(Path(args.output), report)
    else:
        print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
