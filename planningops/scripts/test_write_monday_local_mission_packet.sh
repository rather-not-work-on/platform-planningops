#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

VALIDATION_DIR="$TMP_DIR/validation"
HANDOFF_REPORT="$VALIDATION_DIR/operator-handoff-report.json"
LOCAL_OPERATOR_REPORT="$VALIDATION_DIR/monday-local-operator-stack-report.json"
OUTPUT_PATH="$TMP_DIR/mission-packet-output.json"
STDOUT_PATH="$TMP_DIR/mission-packet-stdout.json"
PACKET_ID="monday-local-mission-20260401T080000Z"
LEGACY_HANDOFF_REPORT="$VALIDATION_DIR/operator-handoff-report-legacy.json"
LEGACY_OUTPUT_PATH="$TMP_DIR/mission-packet-legacy-output.json"
LEGACY_STDOUT_PATH="$TMP_DIR/mission-packet-legacy-stdout.json"
LEGACY_PACKET_ID="monday-local-mission-20260401T080100Z"

mkdir -p "$VALIDATION_DIR"

cat >"$HANDOFF_REPORT" <<'JSON'
{
  "generated_at_utc": "2026-04-01T07:00:00+00:00",
  "report_id": "operator-handoff-20260401T070000Z",
  "artifact_paths": {
    "latest_report_path": "/tmp/operator-handoff-report.json",
    "stamped_report_path": "/tmp/operator-handoff-20260401T070000Z-report.json",
    "output_path": null
  },
  "record": {
    "source_kind": "stamped",
    "target_limit": 3,
    "headline": "Operator handoff report: 2 attention families",
    "attention_summary": "active=1, lagging=1, clear=0",
    "newest_failing_summary": "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun29 / lagging",
    "newest_recovered_summary": null,
    "local_operator_record": null,
    "local_operator_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_operator_next_step": "Expose Codex and add a direct local LLM profile.",
    "queue_lines": [
      "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1",
      "lagging: targets=1 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint=1,readiness=1,reconcile=1"
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
      "[lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile"
    ],
    "immediate_action_lines": [
      "local-runtime: Expose Codex and add a direct local LLM profile.",
      "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
      "follow-up: [lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile"
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
      },
      {
        "artifact_family": "operator_handoff_report",
        "artifact_kind": "report",
        "promoted_id": "operator-handoff-20260401T070000Z",
        "freshness_state": "stale",
        "promotability_status": "blocked",
        "reasons": ["stamped_missing"],
        "dependency_states": {}
      }
    ],
    "local_validation_summary_lines": [
      "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
      "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing"
    ],
    "local_validation_action_lines": [
      "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)"
    ],
    "markdown": "## Operator Handoff Report"
  }
}
JSON

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
    "Expose Codex and add a direct local LLM profile.",
    "Start the provider gateway stack later if you want stack mode."
  ],
  "artifact_paths": {
    "detail_dir": "/tmp/monday-local-operator-stack-20260401T060524Z",
    "runtime_report_path": "/tmp/monday-local-operator-stack-20260401T060524Z.json",
    "validation_latest_report_path": "/tmp/monday-local-operator-stack-report.json",
    "validation_stamped_report_path": "/tmp/monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json"
  }
}
JSON

python3 planningops/scripts/write_monday_local_mission_packet.py \
  --validation-root "$VALIDATION_DIR" \
  --handoff-report "$HANDOFF_REPORT" \
  --local-operator-report "$LOCAL_OPERATOR_REPORT" \
  --packet-id "$PACKET_ID" \
  --output "$OUTPUT_PATH" >"$STDOUT_PATH"

python3 - <<'PY' "$STDOUT_PATH" "$OUTPUT_PATH" "$VALIDATION_DIR" "$PACKET_ID"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()
packet_id = sys.argv[4]
latest_path = validation_dir / "monday-local-mission-packet.json"
stamped_path = validation_dir / f"{packet_id}-monday-local-mission-packet.json"
latest_doc = json.loads(latest_path.read_text(encoding="utf-8"))
stamped_doc = json.loads(stamped_path.read_text(encoding="utf-8"))

contract_text = Path("planningops/contracts/monday-local-mission-packet-contract.md").read_text(encoding="utf-8")
assert Path("planningops/contracts/monday-local-mission-packet-contract.md").exists()
assert "mission_objective" in contract_text, contract_text
assert "planner_profile" in contract_text, contract_text
assert "local_model_route" in contract_text, contract_text
assert "expected_evidence_outputs" in contract_text, contract_text
assert "rollback_command" in contract_text, contract_text
assert "local_validation_snapshot_status" in contract_text, contract_text
assert "local_validation_records" in contract_text, contract_text
assert "local_validation_summary_lines" in contract_text, contract_text
assert "local_validation_action_lines" in contract_text, contract_text

for doc in (stdout_doc, output_doc, latest_doc, stamped_doc):
    assert doc["packet_id"] == packet_id, doc
    assert doc["contract_ref"] == "planningops/contracts/monday-local-mission-packet-contract.md", doc
    assert doc["artifact_paths"]["latest_packet_path"] == str(latest_path), doc
    assert doc["artifact_paths"]["stamped_packet_path"] == str(stamped_path), doc
    mission = doc["mission_packet"]
    assert mission["version"] == "v1", mission
    assert mission["packet_id"] == packet_id, mission
    assert mission["planner_profile"] == "local_ollama", mission
    assert mission["launch_mode"] == "direct", mission
    assert mission["local_model_route"] == "direct_local_ollama", mission
    assert mission["mission_objective"] == (
        "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ), mission
    assert mission["primary_action"] == "local-runtime: Expose Codex and add a direct local LLM profile.", mission
    assert mission["preflight_command"] == (
        "python3 planningops/scripts/run_monday_local_operator_stack.py "
        f"--execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id {packet_id}"
    ), mission
    assert mission["monday_runtime_entrypoint_command"] == (
        f"cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id {packet_id}"
    ), mission
    assert mission["rollback_command"] == "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start", mission
    assert mission["source_artifacts"]["handoff_report_path"] == str((validation_dir / "operator-handoff-report.json").resolve()), mission
    assert mission["source_artifacts"]["local_operator_report_path"] == str((validation_dir / "monday-local-operator-stack-report.json").resolve()), mission
    assert mission["immediate_actions"][0] == "local-runtime: Expose Codex and add a direct local LLM profile.", mission
    assert mission["target_lines"][0].startswith("[active/latest-gap] federated-ci-local"), mission
    assert mission["local_validation_snapshot_status"] == "present", mission
    assert [record["artifact_family"] for record in mission["local_validation_records"]] == [
        "monday_local_operator_stack_report",
        "operator_handoff_report",
    ], mission
    assert mission["local_validation_summary_lines"] == [
        "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
        "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing",
    ], mission
    assert mission["local_validation_action_lines"] == [
        "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)"
    ], mission
    assert str(latest_path) in mission["expected_evidence_outputs"], mission
    assert str(stamped_path) in mission["expected_evidence_outputs"], mission
    assert any(path.endswith(f"{packet_id}.json") for path in mission["expected_evidence_outputs"]), mission
    assert any(path.endswith(f"{packet_id}-monday-local-operator-stack-report.json") for path in mission["expected_evidence_outputs"]), mission

assert stdout_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stdout_doc
assert output_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), output_doc
assert latest_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), latest_doc
assert stamped_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stamped_doc
PY

cat >"$LEGACY_HANDOFF_REPORT" <<'JSON'
{
  "generated_at_utc": "2026-04-01T07:01:00+00:00",
  "report_id": "operator-handoff-20260401T070100Z",
  "artifact_paths": {
    "latest_report_path": "/tmp/operator-handoff-report.json",
    "stamped_report_path": "/tmp/operator-handoff-20260401T070100Z-report.json",
    "output_path": null
  },
  "record": {
    "source_kind": "stamped",
    "target_limit": 1,
    "headline": "Operator handoff report: 1 attention family",
    "attention_summary": "active=1, lagging=0, clear=0",
    "newest_failing_summary": "federated-ci-local / federated-ci-local-20260301 / active",
    "newest_recovered_summary": null,
    "local_operator_record": null,
    "local_operator_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_operator_next_step": "Expose Codex and add a direct local LLM profile.",
    "queue_lines": [],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "immediate_action_lines": [
      "local-runtime: Expose Codex and add a direct local LLM profile."
    ],
    "markdown": "## Operator Handoff Report"
  }
}
JSON

python3 planningops/scripts/write_monday_local_mission_packet.py \
  --validation-root "$VALIDATION_DIR" \
  --handoff-report "$LEGACY_HANDOFF_REPORT" \
  --local-operator-report "$LOCAL_OPERATOR_REPORT" \
  --packet-id "$LEGACY_PACKET_ID" \
  --output "$LEGACY_OUTPUT_PATH" >"$LEGACY_STDOUT_PATH"

python3 - <<'PY' "$LEGACY_STDOUT_PATH"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
mission = doc["mission_packet"]
assert mission["local_validation_snapshot_status"] == "missing", mission
assert mission["local_validation_records"] == [], mission
assert mission["local_validation_summary_lines"] == [], mission
assert mission["local_validation_action_lines"] == [], mission
PY

echo "write monday local mission packet ok"
