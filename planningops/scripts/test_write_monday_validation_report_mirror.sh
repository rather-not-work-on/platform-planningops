#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_DIR="$TMP_DIR/validation"
MONDAY_VALIDATION_DIR="$TMP_DIR/monday/runtime-artifacts/validation"
OUTPUT_PATH="$TMP_DIR/monday-validation-mirror-output.json"
STDOUT_PATH="$TMP_DIR/monday-validation-mirror-stdout.json"

mkdir -p "$VALIDATION_DIR" "$MONDAY_VALIDATION_DIR"

cat >"$VALIDATION_DIR/monday-local-operator-inbox-payload.json" <<'JSON'
{
  "bridge_id": "monday-local-inbox-20260401T084500Z"
}
JSON

cat >"$VALIDATION_DIR/monday-local-inbox-consumer-report.json" <<'JSON'
{
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/source-bridge-artifact.json" <<'JSON'
{
  "bridge_id": "monday-local-inbox-20260401T084500Z"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/source-consumer-report.json" <<'JSON'
{
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-payload-bridge.schema.json" <<'JSON'
{
  "title": "bridge schema"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-consumer-report.schema.json" <<'JSON'
{
  "title": "consumer schema"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-payload-validation-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:40:00+00:00",
  "kind": "bridge",
  "artifact_path": "$MONDAY_VALIDATION_DIR/source-bridge-artifact.json",
  "schema_path": "$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-payload-bridge.schema.json",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "verdict": "pass"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-consumer-report-validation-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:50:00+00:00",
  "kind": "consumer-report",
  "artifact_path": "$MONDAY_VALIDATION_DIR/source-consumer-report.json",
  "schema_path": "$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-consumer-report.schema.json",
  "error_count": 2,
  "warning_count": 1,
  "errors": [
    "consumer contract ref mismatch",
    "schema validation failed"
  ],
  "warnings": [
    "runtime report path missing"
  ],
  "verdict": "fail"
}
JSON

python3 planningops/scripts/write_monday_validation_report_mirror.py \
  --validation-root "$VALIDATION_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" \
  --output "$OUTPUT_PATH" >"$STDOUT_PATH"

python3 - <<'PY' "$STDOUT_PATH" "$OUTPUT_PATH" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()

for doc in (stdout_doc, output_doc):
    assert [record["artifact_family"] for record in doc["records"]] == [
        "monday_local_inbox_bridge_schema_validation",
        "monday_local_inbox_consumer_schema_validation",
    ], doc

bridge_latest = json.loads((validation_dir / "monday-local-inbox-bridge-schema-validation.json").read_text(encoding="utf-8"))
consumer_latest = json.loads((validation_dir / "monday-local-inbox-consumer-schema-validation.json").read_text(encoding="utf-8"))

assert bridge_latest["artifact_family"] == "monday_local_inbox_bridge_schema_validation", bridge_latest
assert bridge_latest["artifact_kind"] == "validation", bridge_latest
assert bridge_latest["mirror"]["report_kind"] == "bridge", bridge_latest
assert bridge_latest["mirror"]["report_verdict"] == "pass", bridge_latest
assert bridge_latest["mirror"]["error_count"] == 0, bridge_latest
assert bridge_latest["mirror"]["artifact_exists"] is True, bridge_latest
assert bridge_latest["mirror"]["schema_exists"] is True, bridge_latest
assert bridge_latest["mirror"]["validation_dependency_paths"] == {
    "monday_local_operator_inbox_payload": str((validation_dir / "monday-local-operator-inbox-payload.json").resolve())
}, bridge_latest

assert consumer_latest["artifact_family"] == "monday_local_inbox_consumer_schema_validation", consumer_latest
assert consumer_latest["artifact_kind"] == "validation", consumer_latest
assert consumer_latest["mirror"]["report_kind"] == "consumer-report", consumer_latest
assert consumer_latest["mirror"]["report_verdict"] == "fail", consumer_latest
assert consumer_latest["mirror"]["error_count"] == 2, consumer_latest
assert consumer_latest["mirror"]["warning_count"] == 1, consumer_latest
assert consumer_latest["mirror"]["artifact_exists"] is True, consumer_latest
assert consumer_latest["mirror"]["schema_exists"] is True, consumer_latest
assert consumer_latest["mirror"]["validation_dependency_paths"] == {
    "monday_local_inbox_consumer_report": str((validation_dir / "monday-local-inbox-consumer-report.json").resolve())
}, consumer_latest
PY

echo "write monday validation report mirror ok"
