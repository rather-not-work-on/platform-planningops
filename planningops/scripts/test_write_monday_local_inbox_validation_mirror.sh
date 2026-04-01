#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_DIR="$TMP_DIR/validation"
CONSUMER_DIR="$TMP_DIR/monday/runtime-artifacts/integration/planningops-local-operator-inbox"
OUTPUT_PATH="$TMP_DIR/mirror-output.json"
STDOUT_PATH="$TMP_DIR/mirror-stdout.json"
PINNED_OUTPUT_PATH="$TMP_DIR/mirror-pinned-output.json"
PINNED_STDOUT_PATH="$TMP_DIR/mirror-pinned-stdout.json"

mkdir -p \
  "$VALIDATION_DIR" \
  "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z" \
  "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z"

cat >"$VALIDATION_DIR/monday-local-operator-inbox-payload.json" <<'JSON'
{
  "bridge_id": "monday-local-inbox-20260401T084500Z"
}
JSON

cat >"$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json" <<'JSON'
{
  "planner_profile": "local_ollama",
  "launch_mode": "direct",
  "local_model_route": "direct_local_ollama",
  "runtime_input_overrides": {
    "planner_runtime_config": "/tmp/planner-runtime.json",
    "runtime_profile_file": "/tmp/runtime-profiles.json"
  }
}
JSON

cat >"$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/local-runtime-smoke.json" <<'JSON'
{
  "verdict": "pass",
  "reason_code": "ok"
}
JSON

cat >"$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/consumer-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:20:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T102000Z",
  "bridge_id": "monday-local-inbox-20260401T084500Z",
  "mode": "apply",
  "verdict": "pass",
  "consumer_status": "ready_to_launch",
  "artifact_paths": {
    "launch_request_path": "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json",
    "runtime_report_path": "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/local-runtime-smoke.json",
    "report_path": "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/consumer-report.json"
  },
  "launch_request": $(cat "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json")
}
JSON

cat >"$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json" <<'JSON'
{
  "planner_profile": "local_ollama",
  "launch_mode": "direct",
  "local_model_route": "direct_local_ollama"
}
JSON

cat >"$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:30:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z",
  "bridge_id": "monday-local-inbox-20260401T084500Z",
  "mode": "apply",
  "verdict": "blocked",
  "consumer_status": "blocked",
  "artifact_paths": {
    "launch_request_path": "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json",
    "runtime_report_path": "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/local-runtime-smoke.json",
    "report_path": "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json"
  },
  "launch_request": $(cat "$CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json")
}
JSON

python3 planningops/scripts/write_monday_local_inbox_validation_mirror.py \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$CONSUMER_DIR" \
  --output "$OUTPUT_PATH" >"$STDOUT_PATH"

python3 - <<'PY' "$STDOUT_PATH" "$OUTPUT_PATH" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()

assert stdout_doc["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", stdout_doc
assert output_doc["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", output_doc
assert Path("planningops/contracts/monday-local-inbox-validation-mirror-contract.md").exists()

launch_latest = json.loads((validation_dir / "monday-local-inbox-launch-request.json").read_text(encoding="utf-8"))
runtime_latest = json.loads((validation_dir / "monday-local-inbox-runtime-report.json").read_text(encoding="utf-8"))
consumer_latest = json.loads((validation_dir / "monday-local-inbox-consumer-report.json").read_text(encoding="utf-8"))

assert launch_latest["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", launch_latest
assert launch_latest["artifact_family"] == "monday_local_inbox_launch_request", launch_latest
assert launch_latest["mirror"]["source_artifact_present"] is True, launch_latest
assert launch_latest["mirror"]["payload"]["planner_profile"] == "local_ollama", launch_latest
assert launch_latest["mirror"]["validation_dependency_paths"] == {
    "monday_local_operator_inbox_payload": str((validation_dir / "monday-local-operator-inbox-payload.json").resolve())
}, launch_latest

assert runtime_latest["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", runtime_latest
assert runtime_latest["artifact_family"] == "monday_local_inbox_runtime_report", runtime_latest
assert runtime_latest["mirror"]["source_artifact_present"] is False, runtime_latest
assert runtime_latest["mirror"]["payload"] is None, runtime_latest
assert runtime_latest["mirror"]["validation_dependency_paths"] == {
    "monday_local_operator_inbox_payload": str((validation_dir / "monday-local-operator-inbox-payload.json").resolve()),
    "monday_local_inbox_launch_request": str((validation_dir / "monday-local-inbox-launch-request.json").resolve()),
}, runtime_latest

assert consumer_latest["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", consumer_latest
assert consumer_latest["artifact_family"] == "monday_local_inbox_consumer_report", consumer_latest
assert consumer_latest["mirror"]["source_artifact_present"] is True, consumer_latest
assert consumer_latest["mirror"]["payload"]["consumer_status"] == "blocked", consumer_latest
assert consumer_latest["mirror"]["validation_dependency_paths"] == {
    "monday_local_operator_inbox_payload": str((validation_dir / "monday-local-operator-inbox-payload.json").resolve()),
    "monday_local_inbox_launch_request": str((validation_dir / "monday-local-inbox-launch-request.json").resolve()),
    "monday_local_inbox_runtime_report": str((validation_dir / "monday-local-inbox-runtime-report.json").resolve()),
}, consumer_latest
PY

python3 planningops/scripts/write_monday_local_inbox_validation_mirror.py \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$CONSUMER_DIR" \
  --run-id "planningops-local-inbox-consumer-20260401T102000Z" \
  --output "$PINNED_OUTPUT_PATH" >"$PINNED_STDOUT_PATH"

python3 - <<'PY' "$PINNED_STDOUT_PATH" "$PINNED_OUTPUT_PATH" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()

assert stdout_doc["run_id"] == "planningops-local-inbox-consumer-20260401T102000Z", stdout_doc
assert output_doc["run_id"] == "planningops-local-inbox-consumer-20260401T102000Z", output_doc

runtime_latest = json.loads((validation_dir / "monday-local-inbox-runtime-report.json").read_text(encoding="utf-8"))
consumer_latest = json.loads((validation_dir / "monday-local-inbox-consumer-report.json").read_text(encoding="utf-8"))

assert runtime_latest["mirror"]["source_artifact_present"] is True, runtime_latest
assert runtime_latest["mirror"]["payload"]["verdict"] == "pass", runtime_latest
assert consumer_latest["mirror"]["has_runtime_input_overrides"] is True, consumer_latest
assert consumer_latest["mirror"]["override_kinds"] == [
    "planner_runtime_config",
    "runtime_profile_file",
], consumer_latest
PY

echo "write monday local inbox validation mirror ok"
