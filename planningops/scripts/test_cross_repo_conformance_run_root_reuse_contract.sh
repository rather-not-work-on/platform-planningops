#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

RUN_ID="cross-repo-conformance-run-root-reuse"
REPORT_PATH="$TMP_DIR/conformance.json"
RUN_ROOT="$TMP_DIR/run-root"
BOOTSTRAP_ROOT="$TMP_DIR/bootstrap-root"

run_check() {
  python3 "$ROOT_DIR/scripts/federation/cross_repo_conformance_check.py" \
    --workspace-root .. \
    --bootstrap-mode auto \
    --bootstrap-root "$BOOTSTRAP_ROOT" \
    --run-id "$RUN_ID" \
    --output "$REPORT_PATH" \
    --run-root "$RUN_ROOT"
}

run_check
touch "$RUN_ROOT/stale-sentinel.txt"
run_check

python3 - <<'PY' "$REPORT_PATH" "$RUN_ROOT"
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
run_root = Path(sys.argv[2])
monday_dir = run_root / "monday"

report = json.loads(report_path.read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert not (run_root / "stale-sentinel.txt").exists(), "run root was not cleaned before rerun"

integration = json.loads((monday_dir / "planningops-handoff-report.json").read_text(encoding="utf-8"))
assert integration["verdict"] == "pass", integration
assert integration["reason_code"] == "ok", integration

scheduler = json.loads((monday_dir / "scheduler-run-report.json").read_text(encoding="utf-8"))
assert scheduler["verdict"] == "pass", scheduler
assert scheduler["duplicate_count"] == 0, scheduler
assert scheduler["dequeued_count"] == 1, scheduler

transition_lines = [
    line
    for line in (monday_dir / "scheduler.ndjson").read_text(encoding="utf-8").splitlines()
    if line.strip()
]
assert len(transition_lines) == 1, transition_lines
assert "duplicate" not in transition_lines[0], transition_lines

print("cross repo conformance run-root reuse contract ok")
PY
