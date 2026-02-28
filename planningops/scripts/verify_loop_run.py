#!/usr/bin/env python3

import argparse
import json
from collections import Counter
from pathlib import Path
import sys
from datetime import datetime, timezone

REQUIRED_TRANSITION_KEYS = [
    "transition_id",
    "run_id",
    "card_id",
    "from_state",
    "to_state",
    "transition_reason",
    "actor_type",
    "actor_id",
    "decided_at_utc",
    "replanning_flag",
]

REQUIRED_LOOP_ARTIFACTS = [
    "intake-check.json",
    "simulation-report.md",
    "verification-report.json",
    "patch-summary.md",
]


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_ndjson(path: Path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append(json.loads(line))
    return rows


def main():
    parser = argparse.ArgumentParser(description="Verify loop artifacts and transition-log schema")
    parser.add_argument("--loop-dir", required=True)
    parser.add_argument("--transition-log", required=True)
    parser.add_argument("--output", default="planningops/artifacts/verification/latest-verification.json")
    parser.add_argument("--project-payload", default="planningops/artifacts/verification/latest-project-payload.json")
    args = parser.parse_args()

    loop_dir = Path(args.loop_dir)
    transition_log = Path(args.transition_log)
    out_path = Path(args.output)
    payload_path = Path(args.project_payload)

    errors = []

    for name in REQUIRED_LOOP_ARTIFACTS:
        if not (loop_dir / name).exists():
            errors.append(f"missing artifact: {name}")

    if not transition_log.exists():
        errors.append("missing transition log")
        rows = []
    else:
        rows = load_ndjson(transition_log)
        for idx, row in enumerate(rows):
            for key in REQUIRED_TRANSITION_KEYS:
                if key not in row:
                    errors.append(f"transition row[{idx}] missing key: {key}")

    verification_doc = {}
    if (loop_dir / "verification-report.json").exists():
        verification_doc = load_json(loop_dir / "verification-report.json")

    verdict = verification_doc.get("verdict", "inconclusive")
    reason = verification_doc.get("reason_code", "unknown")

    if errors:
        verdict = "fail"
        reason = "schema_or_artifact_error"

    current_run_id = verification_doc.get("loop_id")
    current_card_id = verification_doc.get("issue_number")

    scoped_rows = rows
    if current_run_id:
        scoped_rows = [r for r in rows if r.get("run_id") == current_run_id]
    elif current_card_id is not None:
        scoped_rows = [r for r in rows if r.get("card_id") == current_card_id]

    reason_counts = Counter(row.get("transition_reason", "") for row in scoped_rows)
    repeated_reason_trigger = any(cnt >= 3 for cnt in reason_counts.values())
    replanning_flag_trigger = any(bool(row.get("replanning_flag")) for row in scoped_rows)
    inconclusive_trigger = verification_doc.get("verdict") == "inconclusive"

    replanning_triggered = repeated_reason_trigger or replanning_flag_trigger or inconclusive_trigger

    result = {
        "executed_at_utc": datetime.now(timezone.utc).isoformat(),
        "loop_dir": str(loop_dir),
        "transition_log": str(transition_log),
        "verdict": verdict,
        "reason_code": reason,
        "errors": errors,
        "trigger_detection": {
            "scoped_row_count": len(scoped_rows),
            "repeated_reason_trigger": repeated_reason_trigger,
            "replanning_flag_trigger": replanning_flag_trigger,
            "inconclusive_trigger": inconclusive_trigger,
            "replanning_triggered": replanning_triggered,
        },
    }

    project_payload = {
        "status_update": "Done" if verdict == "pass" else "Blocked",
        "last_verdict": verdict,
        "reason_code": reason,
        "replanning_triggered": replanning_triggered,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")

    payload_path.parent.mkdir(parents=True, exist_ok=True)
    payload_path.write_text(json.dumps(project_payload, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"verification result: {out_path}")
    print(f"project payload: {payload_path}")
    print(f"verdict={verdict} reason={reason} replanning_triggered={replanning_triggered}")

    return 0 if verdict == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
