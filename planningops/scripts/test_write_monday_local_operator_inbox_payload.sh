#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_DIR="$TMP_DIR/validation"
DAY_PACKET="$VALIDATION_DIR/monday-local-operator-day-packet.json"
MISSION_PACKET="$VALIDATION_DIR/monday-local-mission-packet.json"
HANDOFF_REPORT="$VALIDATION_DIR/operator-handoff-report.json"
LOCAL_OPERATOR_REPORT="$VALIDATION_DIR/monday-local-operator-stack-report.json"
OUTPUT_PATH="$TMP_DIR/inbox-payload-output.json"
STDOUT_PATH="$TMP_DIR/inbox-payload-stdout.json"
BRIDGE_ID="monday-local-inbox-20260401T084500Z"

mkdir -p "$VALIDATION_DIR"

cat >"$MISSION_PACKET" <<'JSON'
{
  "packet_id": "monday-local-mission-20260401T080000Z"
}
JSON

cat >"$HANDOFF_REPORT" <<'JSON'
{
  "report_id": "operator-handoff-20260401T070000Z"
}
JSON

cat >"$LOCAL_OPERATOR_REPORT" <<'JSON'
{
  "run_id": "monday-local-operator-stack-20260401T060524Z"
}
JSON

cat >"$DAY_PACKET" <<'JSON'
{
  "generated_at_utc": "2026-04-01T08:30:00+00:00",
  "day_packet_id": "monday-local-day-20260401T083000Z",
  "contract_ref": "planningops/contracts/monday-local-operator-day-packet-contract.md",
  "artifact_paths": {
    "latest_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-day-packet.json",
    "stamped_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-day-20260401T083000Z-monday-local-operator-day-packet.json",
    "output_path": null
  },
  "day_packet": {
    "version": "v1",
    "day_packet_id": "monday-local-day-20260401T083000Z",
    "mission_packet_id": "monday-local-mission-20260401T080000Z",
    "headline": "Monday local operator day packet: Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_prompt": "Use monday planner profile `local_ollama` via `direct_local_ollama`.",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "first_action_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
    "monday_runtime_entrypoint_command": "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-mission-20260401T080000Z",
    "rollback_command": "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start",
    "local_runtime_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_validation_snapshot_status": "present",
    "local_validation_summary_lines": [
      "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
      "operator_handoff_report: freshness=blocked promotability=blocked reasons=stamped_missing"
    ],
    "local_validation_action_lines": [
      "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)"
    ],
    "queue_lines": [
      "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1"
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "immediate_actions": [
      "local-runtime: Expose Codex and add a direct local LLM profile.",
      "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "attachments": [
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-day-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json"
    ],
    "body_markdown": "## Monday Local Operator Day Packet",
    "source_artifacts": {
      "mission_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "handoff_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "local_operator_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    }
  }
}
JSON

python3 - <<'PY' "$DAY_PACKET" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_packet_path"] = str((validation_dir / "monday-local-operator-day-packet.json").resolve())
doc["artifact_paths"]["stamped_packet_path"] = str((validation_dir / "monday-local-day-20260401T083000Z-monday-local-operator-day-packet.json").resolve())
doc["day_packet"]["attachments"] = [
    str((validation_dir / "monday-local-operator-day-packet.json").resolve()),
    str((validation_dir / "monday-local-mission-packet.json").resolve()),
]
doc["day_packet"]["source_artifacts"]["mission_packet_path"] = str((validation_dir / "monday-local-mission-packet.json").resolve())
doc["day_packet"]["source_artifacts"]["handoff_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["day_packet"]["source_artifacts"]["local_operator_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-day-20260401T083000Z-monday-local-operator-day-packet.json").write_text(payload, encoding="utf-8")
PY

python3 planningops/scripts/write_monday_local_operator_inbox_payload.py \
  --validation-root "$VALIDATION_DIR" \
  --day-packet "$DAY_PACKET" \
  --bridge-id "$BRIDGE_ID" \
  --output "$OUTPUT_PATH" >"$STDOUT_PATH"

python3 - <<'PY' "$STDOUT_PATH" "$OUTPUT_PATH" "$VALIDATION_DIR" "$BRIDGE_ID"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()
bridge_id = sys.argv[4]
latest_path = validation_dir / "monday-local-operator-inbox-payload.json"
stamped_path = validation_dir / f"{bridge_id}-monday-local-operator-inbox-payload.json"
latest_doc = json.loads(latest_path.read_text(encoding="utf-8"))
stamped_doc = json.loads(stamped_path.read_text(encoding="utf-8"))

contract_text = Path("planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md").read_text(encoding="utf-8")
assert "message_class_hint" in contract_text, contract_text
assert "first_action_command" in contract_text, contract_text
assert "bridge_contract_ref" in contract_text, contract_text

for doc in (stdout_doc, output_doc, latest_doc, stamped_doc):
    assert doc["bridge_id"] == bridge_id, doc
    assert doc["contract_ref"] == "planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md", doc
    assert doc["artifact_paths"]["latest_payload_path"] == str(latest_path), doc
    assert doc["artifact_paths"]["stamped_payload_path"] == str(stamped_path), doc
    payload = doc["payload"]
    assert payload["status"] == "blocked", payload
    assert payload["needs_human_attention"] is True, payload
    assert payload["message_class_hint"] == "decision_request", payload
    assert payload["recommended_wait_minutes"] == 5, payload
    assert payload["retry_mode"] == "manual_recheck", payload
    assert payload["planner_profile"] == "local_ollama", payload
    assert payload["launch_mode"] == "direct", payload
    assert payload["local_model_route"] == "direct_local_ollama", payload
    assert payload["first_action_command"].startswith("python3 planningops/scripts/run_monday_local_operator_stack.py"), payload
    assert payload["monday_runtime_entrypoint_command"].startswith("cd ../monday && python3 scripts/run_local_runtime_smoke.py"), payload
    assert payload["rollback_command"] == "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start", payload
    assert payload["local_validation_snapshot_status"] == "present", payload
    assert payload["local_validation_action_lines"] == [
        "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)"
    ], payload
    assert payload["bridge_contract_ref"] == "planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md", payload
    assert str(latest_path) in payload["attachments"], payload
    assert str(stamped_path) in payload["attachments"], payload
    assert str((validation_dir / "monday-local-operator-day-packet.json").resolve()) in payload["attachments"], payload
    assert payload["source_artifacts"]["day_packet_path"] == str((validation_dir / "monday-local-operator-day-packet.json").resolve()), payload
    assert payload["source_artifacts"]["mission_packet_path"] == str((validation_dir / "monday-local-mission-packet.json").resolve()), payload
    assert payload["source_artifacts"]["handoff_report_path"] == str((validation_dir / "operator-handoff-report.json").resolve()), payload
    assert payload["source_artifacts"]["local_operator_report_path"] == str((validation_dir / "monday-local-operator-stack-report.json").resolve()), payload
    assert payload["body_markdown"] == "## Monday Local Operator Day Packet", payload

assert stdout_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stdout_doc
assert output_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), output_doc
assert latest_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), latest_doc
assert stamped_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stamped_doc
PY

echo "write monday local operator inbox payload ok"
