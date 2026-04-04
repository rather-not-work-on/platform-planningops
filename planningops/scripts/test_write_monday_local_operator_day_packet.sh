#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_DIR="$TMP_DIR/validation"
MISSION_PACKET="$VALIDATION_DIR/monday-local-mission-packet.json"
HANDOFF_REPORT="$VALIDATION_DIR/operator-handoff-report.json"
LOCAL_OPERATOR_REPORT="$VALIDATION_DIR/monday-local-operator-stack-report.json"
OUTPUT_PATH="$TMP_DIR/day-packet-output.json"
STDOUT_PATH="$TMP_DIR/day-packet-stdout.json"
DAY_PACKET_ID="monday-local-day-20260401T083000Z"

mkdir -p "$VALIDATION_DIR"

cat >"$MISSION_PACKET" <<'JSON'
{
  "generated_at_utc": "2026-04-01T08:00:00+00:00",
  "packet_id": "monday-local-mission-20260401T080000Z",
  "contract_ref": "planningops/contracts/monday-local-mission-packet-contract.md",
  "artifact_paths": {
    "latest_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
    "stamped_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-20260401T080000Z-monday-local-mission-packet.json",
    "output_path": null
  },
  "mission_packet": {
    "version": "v1",
    "packet_id": "monday-local-mission-20260401T080000Z",
    "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_prompt": "Use monday planner profile `local_ollama` via `direct_local_ollama`.",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "source_kind": "stamped",
    "attention_summary": "active=1, lagging=1, clear=0",
    "newest_failing_summary": "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun29 / lagging",
    "local_runtime_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_runtime_next_step": "Expose Codex and add a direct local LLM profile.",
    "local_validation_snapshot_status": "present",
    "local_validation_records": [
      {
        "artifact_family": "monday_local_operator_stack_report",
        "artifact_kind": "report",
        "promoted_id": "monday-local-operator-stack-20260401T060524Z",
        "freshness_state": "fresh",
        "promotability_status": "promotable",
        "reasons": [],
        "dependency_states": {}
      }
    ],
    "local_validation_summary_lines": [
      "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
      "operator_handoff_report: freshness=fresh promotability=promotable"
    ],
    "local_validation_action_lines": [],
    "cross_repo_validation_packet_report_id": "cross-repo-validation-20260401T110000Z",
    "cross_repo_validation_packet_path": "VALIDATION_ROOT_PLACEHOLDER/cross-repo-validation-report.json",
    "primary_action": "local-runtime: Expose Codex and add a direct local LLM profile.",
    "immediate_actions": [
      "local-runtime: Expose Codex and add a direct local LLM profile."
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "preflight_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
    "monday_runtime_entrypoint_command": "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-mission-20260401T080000Z",
    "rollback_command": "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start",
    "expected_evidence_outputs": [
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-20260401T080000Z-monday-local-mission-packet.json"
    ],
    "source_artifacts": {
      "handoff_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "local_operator_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    }
  }
}
JSON

python3 - <<'PY' "$MISSION_PACKET" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_packet_path"] = str((validation_dir / "monday-local-mission-packet.json").resolve())
doc["artifact_paths"]["stamped_packet_path"] = str((validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").resolve())
doc["mission_packet"]["expected_evidence_outputs"] = [
    str((validation_dir / "monday-local-mission-packet.json").resolve()),
    str((validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").resolve()),
]
doc["mission_packet"]["cross_repo_validation_packet_path"] = str((validation_dir / "cross-repo-validation-report.json").resolve())
doc["mission_packet"]["source_artifacts"]["handoff_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["mission_packet"]["source_artifacts"]["local_operator_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").write_text(payload, encoding="utf-8")
(validation_dir / "cross-repo-validation-report.json").write_text("{}\n", encoding="utf-8")
PY

cat >"$HANDOFF_REPORT" <<'JSON'
{
  "generated_at_utc": "2026-04-01T07:00:00+00:00",
  "report_id": "operator-handoff-20260401T070000Z",
  "artifact_paths": {
    "latest_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
    "stamped_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-20260401T070000Z-operator-handoff-report.json",
    "output_path": null
  },
  "record": {
    "source_kind": "stamped",
    "target_limit": 3,
    "headline": "Operator handoff report: 2 attention families",
    "attention_summary": "active=1, lagging=1, clear=0",
    "newest_failing_summary": "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun29 / lagging",
    "local_operator_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_operator_next_step": "Expose Codex and add a direct local LLM profile.",
    "queue_lines": [
      "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1"
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "immediate_action_lines": [
      "local-runtime: Expose Codex and add a direct local LLM profile.",
      "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "local_validation_records": [
      {
        "artifact_family": "monday_local_operator_stack_report",
        "artifact_kind": "report",
        "promoted_id": "monday-local-operator-stack-20260401T060524Z",
        "freshness_state": "fresh",
        "promotability_status": "promotable",
        "reasons": [],
        "dependency_states": {}
      }
    ],
    "local_validation_summary_lines": [
      "monday_local_operator_stack_report: freshness=fresh promotability=promotable"
    ],
    "local_validation_action_lines": [],
    "markdown": "## Operator Handoff Report"
  }
}
JSON

python3 - <<'PY' "$HANDOFF_REPORT" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["artifact_paths"]["stamped_report_path"] = str((validation_dir / "operator-handoff-20260401T070000Z-operator-handoff-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "operator-handoff-20260401T070000Z-operator-handoff-report.json").write_text(payload, encoding="utf-8")
PY

cat >"$LOCAL_OPERATOR_REPORT" <<'JSON'
{
  "generated_at_utc": "2026-04-01T06:05:24+00:00",
  "run_id": "monday-local-operator-stack-20260401T060524Z",
  "workspace_root": "/tmp/workspace",
  "execution_mode": "both",
  "direct_profile": "local_ollama",
  "dry_run": false,
  "verdict": "fail",
  "reason_code": "readiness_blocked",
  "readiness": {
    "status": "blocked",
    "report_path": "/tmp/readiness.json",
    "report": {},
    "step": {
      "status": "report_only"
    }
  },
  "stack_smoke": {
    "status": "skipped",
    "report_path": "/tmp/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "skipped",
    "report_path": "/tmp/local_ollama.json"
  },
  "recommended_next_steps": [
    "Expose Codex and add a direct local LLM profile."
  ],
  "artifact_paths": {
    "detail_dir": "/tmp/monday-local-operator-stack-20260401T060524Z",
    "runtime_report_path": "/tmp/monday-local-operator-stack-20260401T060524Z.json",
    "validation_latest_report_path": "/tmp/monday-local-operator-stack-report.json",
    "validation_stamped_report_path": "/tmp/monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json"
  }
}
JSON

python3 planningops/scripts/write_monday_local_operator_day_packet.py \
  --validation-root "$VALIDATION_DIR" \
  --mission-packet "$MISSION_PACKET" \
  --handoff-report "$HANDOFF_REPORT" \
  --local-operator-report "$LOCAL_OPERATOR_REPORT" \
  --day-packet-id "$DAY_PACKET_ID" \
  --output "$OUTPUT_PATH" >"$STDOUT_PATH"

python3 - <<'PY' "$STDOUT_PATH" "$OUTPUT_PATH" "$VALIDATION_DIR" "$DAY_PACKET_ID"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()
day_packet_id = sys.argv[4]
latest_path = validation_dir / "monday-local-operator-day-packet.json"
stamped_path = validation_dir / f"{day_packet_id}-monday-local-operator-day-packet.json"
latest_doc = json.loads(latest_path.read_text(encoding="utf-8"))
stamped_doc = json.loads(stamped_path.read_text(encoding="utf-8"))

contract_text = Path("planningops/contracts/monday-local-operator-day-packet-contract.md").read_text(encoding="utf-8")
assert "mission_packet_id" in contract_text, contract_text
assert "first_action_command" in contract_text, contract_text
assert "attachments" in contract_text, contract_text
assert "local_validation_snapshot_status" in contract_text, contract_text
assert "body_markdown" in contract_text, contract_text

for doc in (stdout_doc, output_doc, latest_doc, stamped_doc):
    assert doc["day_packet_id"] == day_packet_id, doc
    assert doc["contract_ref"] == "planningops/contracts/monday-local-operator-day-packet-contract.md", doc
    assert doc["artifact_paths"]["latest_packet_path"] == str(latest_path), doc
    assert doc["artifact_paths"]["stamped_packet_path"] == str(stamped_path), doc
    packet = doc["day_packet"]
    assert packet["version"] == "v1", packet
    assert packet["day_packet_id"] == day_packet_id, packet
    assert packet["mission_packet_id"] == "monday-local-mission-20260401T080000Z", packet
    assert packet["headline"].startswith("Monday local operator day packet: Resolve [active/latest-gap]"), packet
    assert packet["mission_objective"] == (
        "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ), packet
    assert packet["planner_profile"] == "local_ollama", packet
    assert packet["launch_mode"] == "direct", packet
    assert packet["local_model_route"] == "direct_local_ollama", packet
    assert packet["first_action_command"] == (
        "python3 planningops/scripts/run_monday_local_operator_stack.py "
        "--execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id "
        "monday-local-mission-20260401T080000Z"
    ), packet
    assert packet["monday_runtime_entrypoint_command"] == (
        "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama "
        "--run-id monday-local-mission-20260401T080000Z"
    ), packet
    assert packet["rollback_command"] == "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start", packet
    assert packet["local_validation_snapshot_status"] == "present", packet
    assert packet["local_validation_summary_lines"] == [
        "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
        "operator_handoff_report: freshness=fresh promotability=promotable",
    ], packet
    assert packet["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", packet
    assert packet["cross_repo_validation_packet_path"] == str((validation_dir / "cross-repo-validation-report.json").resolve()), packet
    assert packet["queue_lines"] == [
        "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1"
    ], packet
    assert packet["target_lines"] == [
        "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ], packet
    assert packet["immediate_actions"] == [
        "local-runtime: Expose Codex and add a direct local LLM profile.",
        "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    ], packet
    assert str(latest_path) in packet["attachments"], packet
    assert str(stamped_path) in packet["attachments"], packet
    assert str((validation_dir / "monday-local-mission-packet.json").resolve()) in packet["attachments"], packet
    assert str((validation_dir / "operator-handoff-report.json").resolve()) in packet["attachments"], packet
    assert str((validation_dir / "monday-local-operator-stack-report.json").resolve()) in packet["attachments"], packet
    assert str((validation_dir / "cross-repo-validation-report.json").resolve()) in packet["attachments"], packet
    assert packet["source_artifacts"]["mission_packet_path"] == str((validation_dir / "monday-local-mission-packet.json").resolve()), packet
    assert packet["source_artifacts"]["handoff_report_path"] == str((validation_dir / "operator-handoff-report.json").resolve()), packet
    assert packet["source_artifacts"]["local_operator_report_path"] == str((validation_dir / "monday-local-operator-stack-report.json").resolve()), packet
    assert "## Monday Local Operator Day Packet" in packet["body_markdown"], packet
    assert "### Commands" in packet["body_markdown"], packet
    assert "### Cross-Repo Validation Packet" in packet["body_markdown"], packet
    assert "detail packet report id: `cross-repo-validation-20260401T110000Z`" in packet["body_markdown"], packet
    assert str((validation_dir / "cross-repo-validation-report.json").resolve()) in packet["body_markdown"], packet
    assert "### Local Validation" in packet["body_markdown"], packet
    assert "### Attachments" in packet["body_markdown"], packet

assert stdout_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stdout_doc
assert output_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), output_doc
assert latest_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), latest_doc
assert stamped_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stamped_doc
PY

echo "write monday local operator day packet ok"
