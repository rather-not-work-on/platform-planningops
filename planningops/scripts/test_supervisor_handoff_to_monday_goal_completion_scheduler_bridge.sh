#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
MONDAY_DIR="${WORKSPACE_DIR}/monday"

if [[ ! -d "${MONDAY_DIR}" ]]; then
  echo "missing sibling monday repo at ${MONDAY_DIR}" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
GOAL_KEY="uap-goal-completion-scheduler-bridge-wave31"
MONDAY_TEST_OUTBOX_ROOT="runtime-artifacts/test-supervisor-goal-completion-scheduler-bridge"
MONDAY_TEST_SCHEDULER_ROOT="runtime-artifacts/test-supervisor-goal-completion-scheduler-bridge-scheduler"
DELIVERY_CYCLE_REPORT="${MONDAY_DIR}/${MONDAY_TEST_SCHEDULER_ROOT}/goal-completion-scheduler-report-delivery-cycle.json"
QUEUE_DB="${TMP_DIR}/runtime-queue.sqlite3"
ADMISSION_REPORT="${MONDAY_DIR}/${MONDAY_TEST_SCHEDULER_ROOT}/goal-completion-admission-report.json"
SCHEDULER_REPORT="${MONDAY_DIR}/${MONDAY_TEST_SCHEDULER_ROOT}/goal-completion-scheduler-report.json"
IDEMPOTENCY_PATH="${TMP_DIR}/idempotency.json"
TRANSITION_LOG="${TMP_DIR}/transition.ndjson"
OPERATOR_REPORT="${TMP_DIR}/operator-report.json"
OPERATOR_SUMMARY="${TMP_DIR}/operator-summary.md"
GOAL_TRANSITION_REPORT="${TMP_DIR}/goal-transition-report.json"
HANDOFF_VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION="${TMP_DIR}/operator-handoff-bundle-validation.json"
HANDOFF_BUNDLE_READINESS="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"
PROFILES_CONFIG="${TMP_DIR}/local-operator-channel-profiles.json"
RESOLVED_PREVIEW="${TMP_DIR}/resolved-priority-preview.json"
DELIVERY_CYCLE_PREVIEW="${TMP_DIR}/delivery-cycle-priority-preview.json"
DISPLAY_PACKET="${TMP_DIR}/scheduler-priority-display-packet.json"
DELIVERY_CYCLE_DISPLAY_PACKET="${TMP_DIR}/scheduler-delivery-cycle-display-packet.json"
SCHEDULER_HANDOFF_VALIDATION="${TMP_DIR}/scheduler-handoff-validation.json"
DELIVERY_CYCLE_HANDOFF_VALIDATION="${TMP_DIR}/delivery-cycle-handoff-validation.json"
SCHEDULER_BUNDLE="${TMP_DIR}/scheduler-handoff-bundle.json"
DELIVERY_CYCLE_BUNDLE="${TMP_DIR}/delivery-cycle-handoff-bundle.json"
SCHEDULER_BUNDLE_VALIDATION="${TMP_DIR}/scheduler-handoff-bundle-validation.json"
DELIVERY_CYCLE_BUNDLE_VALIDATION="${TMP_DIR}/delivery-cycle-handoff-bundle-validation.json"
SCHEDULER_BUNDLE_READINESS="${TMP_DIR}/scheduler-handoff-bundle-readiness.json"
DELIVERY_CYCLE_BUNDLE_READINESS="${TMP_DIR}/delivery-cycle-handoff-bundle-readiness.json"
SCHEDULER_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/scheduler-handoff-bundle-readiness-validation.json"
DELIVERY_CYCLE_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/delivery-cycle-handoff-bundle-readiness-validation.json"
SCHEDULER_BUNDLE_DOCTOR="${TMP_DIR}/scheduler-handoff-bundle-doctor.txt"
DELIVERY_CYCLE_BUNDLE_DOCTOR="${TMP_DIR}/delivery-cycle-handoff-bundle-doctor.txt"
SCHEDULER_BUNDLE_DOCTOR_READINESS="${TMP_DIR}/scheduler-handoff-bundle-doctor-readiness.json"
DELIVERY_CYCLE_BUNDLE_DOCTOR_READINESS="${TMP_DIR}/delivery-cycle-handoff-bundle-doctor-readiness.json"
SCHEDULER_BUNDLE_DOCTOR_READINESS_VALIDATION="${TMP_DIR}/scheduler-handoff-bundle-doctor-readiness-validation.json"
DELIVERY_CYCLE_BUNDLE_DOCTOR_READINESS_VALIDATION="${TMP_DIR}/delivery-cycle-handoff-bundle-doctor-readiness-validation.json"
SCHEDULER_BUNDLE_DOCTOR_VALIDATION="${TMP_DIR}/scheduler-handoff-bundle-doctor-validation.json"
DELIVERY_CYCLE_BUNDLE_DOCTOR_VALIDATION="${TMP_DIR}/delivery-cycle-handoff-bundle-doctor-validation.json"

trap 'rm -rf "$TMP_DIR" "${MONDAY_DIR}/${MONDAY_TEST_OUTBOX_ROOT}" "${MONDAY_DIR}/${MONDAY_TEST_SCHEDULER_ROOT}" "${DELIVERY_CYCLE_REPORT}" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-packets" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-acks" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-execution-packets" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-receipts" "${MONDAY_DIR}/runtime-artifacts/messaging/delivery-reports" "${MONDAY_DIR}/runtime-artifacts/messaging/delivery-cycles" "${MONDAY_DIR}/runtime-artifacts/messaging/scheduled-delivery-work-items/${GOAL_KEY}"*' EXIT

cd "$ROOT_DIR"

cat >"$OPERATOR_REPORT" <<JSON
{
  "run_id": "supervisor-goal-completion-scheduler-bridge",
  "summary_path": "/tmp/planningops/summary.json",
  "status": "ok",
  "priority_headline": "Supervisor completed the active goal and stopped cleanly.",
  "priority_cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "operator_action": "notify_goal_completion",
  "goal_key": "${GOAL_KEY}",
  "message_class_hint": "goal_completed",
  "handoff_contract_ref": "planningops/contracts/supervisor-operator-handoff-contract.md",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "goal_transition_report_path": "GOAL_TRANSITION_REPORT_PLACEHOLDER",
  "federated_ci_summary": {
    "summary_run_id": "federated-ci-runtime-gates-20260319-rerun27",
    "readiness_status": "blocked",
    "ready": false,
    "next_step": "bash planningops/scripts/gate_federated_ci_summary.sh",
    "remediation_commands": [
      "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
      "bash planningops/scripts/gate_federated_ci_summary.sh"
    ]
  },
  "terminal_notification_channel": {
    "kind": "email_cli",
    "transport": "cli"
  }
}
JSON

cat >"$OPERATOR_SUMMARY" <<'MD'
# Supervisor Operator Summary

Goal completed cleanly.
MD

cat >"$GOAL_TRANSITION_REPORT" <<JSON
{
  "generated_at_utc": "2026-03-19T12:00:31Z",
  "goal_key": "${GOAL_KEY}",
  "to_status": "achieved",
  "goal_transition_kind": "terminal_completion",
  "verdict": "pass"
}
JSON

cat >"$HANDOFF_VALIDATION" <<'JSON'
{
  "generated_at_utc": "2026-03-20T01:02:05+00:00",
  "operator_report_path": "OPERATOR_REPORT_PLACEHOLDER",
  "operator_report_run_id": "supervisor-goal-completion-scheduler-bridge",
  "operator_report_status": "ok",
  "inbox_payload_path": "INBOX_PAYLOAD_PLACEHOLDER",
  "inbox_payload_status": "ok",
  "inbox_payload_title": "[OK] Supervisor completed the active goal and stopped cleanly.",
  "operator_summary_path": "OPERATOR_SUMMARY_PLACEHOLDER",
  "operator_report_schema_path": "OPERATOR_REPORT_SCHEMA_PLACEHOLDER",
  "inbox_payload_schema_path": "INBOX_PAYLOAD_SCHEMA_PLACEHOLDER",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "runtime-artifacts/messaging/operator-priority-previews/example.json",
  "priority_display_packet_ref": "runtime-artifacts/messaging/operator-priority-display-packets/example.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "verdict": "pass"
}
JSON

cat >"$HANDOFF_BUNDLE" <<'JSON'
{
  "artifact_file": "OPERATOR_REPORT_PLACEHOLDER",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "runtime-artifacts/messaging/operator-priority-previews/example.json",
  "priority_display_packet_ref": "runtime-artifacts/messaging/operator-priority-display-packets/example.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "verdict": "pass"
}
JSON

cat >"$HANDOFF_BUNDLE_VALIDATION" <<'JSON'
{
  "bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "runtime-artifacts/messaging/operator-priority-previews/example.json",
  "priority_display_packet_ref": "runtime-artifacts/messaging/operator-priority-display-packets/example.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "verdict": "pass"
}
JSON

cat >"$HANDOFF_BUNDLE_READINESS" <<'JSON'
{
  "bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "runtime-artifacts/messaging/operator-priority-previews/example.json",
  "priority_display_packet_ref": "runtime-artifacts/messaging/operator-priority-display-packets/example.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "readiness_status": "ready",
  "ready": true
}
JSON

cat >"$HANDOFF_BUNDLE_READINESS_VALIDATION" <<'JSON'
{
  "bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "runtime-artifacts/messaging/operator-priority-previews/example.json",
  "priority_display_packet_ref": "runtime-artifacts/messaging/operator-priority-display-packets/example.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "verdict": "pass"
}
JSON

python3 - <<'PY' "$OPERATOR_REPORT" "$GOAL_TRANSITION_REPORT" "$HANDOFF_VALIDATION" "$HANDOFF_BUNDLE" "$HANDOFF_BUNDLE_VALIDATION" "$HANDOFF_BUNDLE_READINESS" "$HANDOFF_BUNDLE_READINESS_VALIDATION"
from pathlib import Path
import sys

operator_report_path = Path(sys.argv[1])
goal_transition_report_path = Path(sys.argv[2]).resolve()
handoff_validation_path = Path(sys.argv[3]).resolve()
handoff_bundle_path = Path(sys.argv[4]).resolve()
handoff_bundle_validation_path = Path(sys.argv[5]).resolve()
handoff_bundle_readiness_path = Path(sys.argv[6]).resolve()
handoff_bundle_readiness_validation_path = Path(sys.argv[7]).resolve()
operator_summary_path = operator_report_path.parent / "operator-summary.md"
inbox_payload_path = operator_report_path.parent / "inbox-payload.json"
operator_report_schema_path = Path("/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/schemas/supervisor-operator-report.schema.json").resolve()
inbox_payload_schema_path = Path("/Volumes/T7 Touch/mini/rather-not-work-on/platform-planningops/planningops/schemas/supervisor-inbox-payload.schema.json").resolve()

text = operator_report_path.read_text(encoding="utf-8").replace(
    "GOAL_TRANSITION_REPORT_PLACEHOLDER",
    str(goal_transition_report_path),
)
text = text.replace(
    "HANDOFF_VALIDATION_PLACEHOLDER",
    str(handoff_validation_path),
)
text = text.replace(
    "HANDOFF_BUNDLE_PLACEHOLDER",
    str(handoff_bundle_path),
)
text = text.replace(
    "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
    str(handoff_bundle_validation_path),
)
text = text.replace(
    "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
    str(handoff_bundle_readiness_path),
)
text = text.replace(
    "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
    str(handoff_bundle_readiness_validation_path),
)
operator_report_path.write_text(text, encoding="utf-8")

replacement_map = {
    "OPERATOR_REPORT_PLACEHOLDER": str(operator_report_path.resolve()),
    "INBOX_PAYLOAD_PLACEHOLDER": str(inbox_payload_path.resolve()),
    "OPERATOR_SUMMARY_PLACEHOLDER": str(operator_summary_path.resolve()),
    "OPERATOR_REPORT_SCHEMA_PLACEHOLDER": str(operator_report_schema_path),
    "INBOX_PAYLOAD_SCHEMA_PLACEHOLDER": str(inbox_payload_schema_path),
    "HANDOFF_VALIDATION_PLACEHOLDER": str(handoff_validation_path),
    "HANDOFF_BUNDLE_PLACEHOLDER": str(handoff_bundle_path),
    "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER": str(handoff_bundle_validation_path),
    "HANDOFF_BUNDLE_READINESS_PLACEHOLDER": str(handoff_bundle_readiness_path),
    "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER": str(handoff_bundle_readiness_validation_path),
}

for artifact_path in [
    handoff_validation_path,
    handoff_bundle_path,
    handoff_bundle_validation_path,
    handoff_bundle_readiness_path,
    handoff_bundle_readiness_validation_path,
]:
    doc = artifact_path.read_text(encoding="utf-8")
    for placeholder, replacement in replacement_map.items():
        doc = doc.replace(placeholder, replacement)
    artifact_path.write_text(doc, encoding="utf-8")
PY

cat >"$PROFILES_CONFIG" <<JSON
{
  "config_version": 1,
  "profiles": {
    "email_cli": {
      "channel_kind": "email_cli",
      "transport_kind": "local_outbox",
      "outbox_root": "$MONDAY_TEST_OUTBOX_ROOT/email",
      "default_target_name": "terminal-notifications",
      "supports_threads": false
    }
  }
}
JSON

(
  cd "$MONDAY_DIR"
  python3 scripts/enqueue_scheduled_delivery_work_item.py \
    --operator-report-file "$OPERATOR_REPORT" \
    --operator-summary-file "$OPERATOR_SUMMARY" \
    --goal-transition-report-file "$GOAL_TRANSITION_REPORT" \
    --schedule-key recurring-delivery \
    --mode apply \
    --queue-db "$QUEUE_DB" \
    --output "$ADMISSION_REPORT" >/dev/null

  python3 scripts/run_scheduled_queue_cycle.py \
    --queue-db "$QUEUE_DB" \
    --profiles-config "$PROFILES_CONFIG" \
    --run-id test-goal-completion-scheduler-bridge-report \
    --idempotency "$IDEMPOTENCY_PATH" \
    --report "$SCHEDULER_REPORT" \
    --transition-log "$TRANSITION_LOG" >/dev/null

  python3 scripts/resolve_operator_priority_preview.py \
    --artifact-file "$SCHEDULER_REPORT" \
    --output "$RESOLVED_PREVIEW" >/dev/null

  python3 scripts/resolve_operator_priority_display_packet.py \
    --artifact-file "$SCHEDULER_REPORT" \
    --output "$DISPLAY_PACKET" >/dev/null
)

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_display_packet.py" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" \
  --output "$DELIVERY_CYCLE_DISPLAY_PACKET" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_preview.py" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" \
  --output "$DELIVERY_CYCLE_PREVIEW" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_validation.py" \
  --artifact-file "$SCHEDULER_REPORT" \
  --output "$SCHEDULER_HANDOFF_VALIDATION" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_validation.py" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" \
  --output "$DELIVERY_CYCLE_HANDOFF_VALIDATION" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$SCHEDULER_REPORT" \
  --output "$SCHEDULER_BUNDLE" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" \
  --output "$DELIVERY_CYCLE_BUNDLE" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "$SCHEDULER_BUNDLE" \
  --output "$SCHEDULER_BUNDLE_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "$DELIVERY_CYCLE_BUNDLE" \
  --output "$DELIVERY_CYCLE_BUNDLE_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "$SCHEDULER_REPORT" \
  --bundle-validation-output "$SCHEDULER_BUNDLE_VALIDATION" \
  --output "$SCHEDULER_BUNDLE_READINESS" \
  --readiness-validation-output "$SCHEDULER_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" \
  --bundle-validation-output "$DELIVERY_CYCLE_BUNDLE_VALIDATION" \
  --output "$DELIVERY_CYCLE_BUNDLE_READINESS" \
  --readiness-validation-output "$DELIVERY_CYCLE_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "$SCHEDULER_BUNDLE_READINESS" \
  --output "$SCHEDULER_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "$DELIVERY_CYCLE_BUNDLE_READINESS" \
  --output "$DELIVERY_CYCLE_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$SCHEDULER_REPORT" \
  --bundle-validation-output "$SCHEDULER_BUNDLE_DOCTOR_VALIDATION" \
  --readiness-output "$SCHEDULER_BUNDLE_DOCTOR_READINESS" \
  --readiness-validation-output "$SCHEDULER_BUNDLE_DOCTOR_READINESS_VALIDATION" >"$SCHEDULER_BUNDLE_DOCTOR"

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" \
  --bundle-validation-output "$DELIVERY_CYCLE_BUNDLE_DOCTOR_VALIDATION" \
  --readiness-output "$DELIVERY_CYCLE_BUNDLE_DOCTOR_READINESS" \
  --readiness-validation-output "$DELIVERY_CYCLE_BUNDLE_DOCTOR_READINESS_VALIDATION" >"$DELIVERY_CYCLE_BUNDLE_DOCTOR"

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "$SCHEDULER_REPORT" >/dev/null

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "$DELIVERY_CYCLE_REPORT" >/dev/null

grep -q "bundle validation verdict: pass" "$SCHEDULER_BUNDLE_DOCTOR"
grep -q "readiness status: ready" "$SCHEDULER_BUNDLE_DOCTOR"
grep -q "ready: True" "$SCHEDULER_BUNDLE_DOCTOR"
grep -q "next step: none" "$SCHEDULER_BUNDLE_DOCTOR"
grep -q "bundle validation verdict: pass" "$DELIVERY_CYCLE_BUNDLE_DOCTOR"
grep -q "readiness status: ready" "$DELIVERY_CYCLE_BUNDLE_DOCTOR"
grep -q "ready: True" "$DELIVERY_CYCLE_BUNDLE_DOCTOR"
grep -q "next step: none" "$DELIVERY_CYCLE_BUNDLE_DOCTOR"

python3 - <<'PY' "$ADMISSION_REPORT" "$SCHEDULER_REPORT" "$MONDAY_DIR" "$RESOLVED_PREVIEW" "$DELIVERY_CYCLE_PREVIEW" "$DISPLAY_PACKET" "$DELIVERY_CYCLE_DISPLAY_PACKET" "$SCHEDULER_HANDOFF_VALIDATION" "$DELIVERY_CYCLE_HANDOFF_VALIDATION" "$HANDOFF_VALIDATION" "$SCHEDULER_BUNDLE" "$DELIVERY_CYCLE_BUNDLE" "$SCHEDULER_BUNDLE_READINESS" "$DELIVERY_CYCLE_BUNDLE_READINESS" "$SCHEDULER_BUNDLE_READINESS_VALIDATION" "$DELIVERY_CYCLE_BUNDLE_READINESS_VALIDATION" "$SCHEDULER_BUNDLE_VALIDATION" "$DELIVERY_CYCLE_BUNDLE_VALIDATION" "$SCHEDULER_BUNDLE_DOCTOR_READINESS" "$DELIVERY_CYCLE_BUNDLE_DOCTOR_READINESS" "$SCHEDULER_BUNDLE_DOCTOR_READINESS_VALIDATION" "$DELIVERY_CYCLE_BUNDLE_DOCTOR_READINESS_VALIDATION" "$SCHEDULER_BUNDLE_DOCTOR_VALIDATION" "$DELIVERY_CYCLE_BUNDLE_DOCTOR_VALIDATION" "$DELIVERY_CYCLE_REPORT"
import json
import sys
from pathlib import Path

admission = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
scheduler = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
monday_dir = Path(sys.argv[3]).resolve()
preview = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
delivery_cycle_preview = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))
display_packet = json.loads(Path(sys.argv[6]).read_text(encoding="utf-8"))
delivery_cycle_display_packet = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))
scheduler_handoff_validation = json.loads(Path(sys.argv[8]).read_text(encoding="utf-8"))
delivery_cycle_handoff_validation = json.loads(Path(sys.argv[9]).read_text(encoding="utf-8"))
handoff_validation_path = Path(sys.argv[10]).resolve()
scheduler_bundle = json.loads(Path(sys.argv[11]).read_text(encoding="utf-8"))
delivery_cycle_bundle = json.loads(Path(sys.argv[12]).read_text(encoding="utf-8"))
scheduler_bundle_readiness = json.loads(Path(sys.argv[13]).read_text(encoding="utf-8"))
delivery_cycle_bundle_readiness = json.loads(Path(sys.argv[14]).read_text(encoding="utf-8"))
scheduler_bundle_readiness_validation = json.loads(Path(sys.argv[15]).read_text(encoding="utf-8"))
delivery_cycle_bundle_readiness_validation = json.loads(Path(sys.argv[16]).read_text(encoding="utf-8"))
scheduler_bundle_validation = json.loads(Path(sys.argv[17]).read_text(encoding="utf-8"))
delivery_cycle_bundle_validation = json.loads(Path(sys.argv[18]).read_text(encoding="utf-8"))
scheduler_bundle_doctor_readiness = json.loads(Path(sys.argv[19]).read_text(encoding="utf-8"))
delivery_cycle_bundle_doctor_readiness = json.loads(Path(sys.argv[20]).read_text(encoding="utf-8"))
scheduler_bundle_doctor_readiness_validation = json.loads(Path(sys.argv[21]).read_text(encoding="utf-8"))
delivery_cycle_bundle_doctor_readiness_validation = json.loads(Path(sys.argv[22]).read_text(encoding="utf-8"))
scheduler_bundle_doctor_validation = json.loads(Path(sys.argv[23]).read_text(encoding="utf-8"))
delivery_cycle_bundle_doctor_validation = json.loads(Path(sys.argv[24]).read_text(encoding="utf-8"))
delivery_cycle_preview_ref = delivery_cycle_bundle["priority_preview_ref"]
delivery_cycle_display_packet_ref = delivery_cycle_bundle["priority_display_packet_ref"]

assert admission["verdict"] == "pass", admission
assert admission["delivery_work_item_kind"] == "goal_completion_delivery", admission
assert admission["selected_delivery_entrypoint"] == "scripts/run_goal_completion_delivery_cycle.py", admission
assert admission["operator_handoff_validation_path"] == str(handoff_validation_path), admission
assert admission["headline"] == "Supervisor completed the active goal and stopped cleanly.", admission
assert admission["first_action_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", admission
assert admission["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", admission
assert admission["priority_cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", admission
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in admission["priority_summary_markdown"], admission
assert admission["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", admission
assert admission["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], admission

work_item_path = Path(admission["scheduled_delivery_work_item_ref"])
if not work_item_path.is_absolute():
    work_item_path = monday_dir / work_item_path
work_item = json.loads(work_item_path.read_text(encoding="utf-8"))
assert work_item["operator_handoff_validation_path"] == str(handoff_validation_path), work_item
assert work_item["headline"] == "Supervisor completed the active goal and stopped cleanly.", work_item
assert work_item["first_action_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", work_item
assert work_item["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", work_item
assert work_item["priority_cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", work_item
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in work_item["priority_summary_markdown"], work_item
assert work_item["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", work_item
assert work_item["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], work_item

payload_path = Path(work_item["payload_ref"])
if not payload_path.is_absolute():
    payload_path = monday_dir / payload_path
payload = json.loads(payload_path.read_text(encoding="utf-8"))
assert payload["metadata"]["operator_handoff_validation_path"] == str(handoff_validation_path), payload
assert payload["metadata"]["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", payload
assert payload["metadata"]["priority_cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", payload
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in payload["metadata"]["priority_summary_markdown"], payload
assert "## First Action" in payload["body"], payload

assert scheduler["verdict"] == "pass", scheduler
assert scheduler["reason_code"] == "ok", scheduler
assert scheduler["selected_delivery_entrypoint"] == "scripts/run_goal_completion_delivery_cycle.py", scheduler
assert scheduler["operator_handoff_validation_path"] == str(handoff_validation_path), scheduler
assert scheduler["headline"] == "Supervisor completed the active goal and stopped cleanly.", scheduler
assert scheduler["first_action_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", scheduler
assert scheduler["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", scheduler
assert scheduler["priority_cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", scheduler
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in scheduler["priority_summary_markdown"], scheduler
assert scheduler["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", scheduler
assert scheduler["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], scheduler

delivery_cycle_path = Path(scheduler["delivery_cycle_report_ref"])
if not delivery_cycle_path.is_absolute():
    delivery_cycle_path = monday_dir / delivery_cycle_path
delivery_cycle = json.loads(delivery_cycle_path.read_text(encoding="utf-8"))
assert delivery_cycle["operator_handoff_validation_path"] == str(handoff_validation_path), delivery_cycle
assert delivery_cycle["headline"] == "Supervisor completed the active goal and stopped cleanly.", delivery_cycle
assert delivery_cycle["first_action_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", delivery_cycle
assert delivery_cycle["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", delivery_cycle
assert delivery_cycle["priority_cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", delivery_cycle
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in delivery_cycle["priority_summary_markdown"], delivery_cycle
assert delivery_cycle["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", delivery_cycle
assert delivery_cycle["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], delivery_cycle

assert preview["source_artifact_kind"] == "delivery_cycle_report", preview
assert preview["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", preview
assert preview["priority_cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", preview
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in preview["priority_summary_markdown"], preview
preview_path = Path(scheduler["priority_preview_ref"])
if not preview_path.is_absolute():
    preview_path = monday_dir / preview_path
canonical_preview = json.loads(preview_path.read_text(encoding="utf-8"))
assert preview == canonical_preview, (preview, canonical_preview)
assert canonical_preview["source_artifact_kind"] == "delivery_cycle_report", canonical_preview
assert canonical_preview["operator_handoff_validation_path"] == str(handoff_validation_path), canonical_preview
assert canonical_preview["operator_handoff_bundle_path"] == scheduler["operator_handoff_bundle_path"], canonical_preview
assert canonical_preview["operator_handoff_bundle_validation_path"] == scheduler["operator_handoff_bundle_validation_path"], canonical_preview
assert canonical_preview["operator_handoff_bundle_readiness_path"] == scheduler["operator_handoff_bundle_readiness_path"], canonical_preview
assert canonical_preview["operator_handoff_bundle_readiness_validation_path"] == scheduler["operator_handoff_bundle_readiness_validation_path"], canonical_preview
assert delivery_cycle_preview["source_artifact_kind"] == "delivery_cycle_report", delivery_cycle_preview
for field in (
    "priority_headline",
    "priority_cta_command",
    "priority_summary_markdown",
    "headline",
    "first_action_command",
    "primary_remediation_command",
    "operator_handoff_validation_path",
    "operator_handoff_bundle_path",
    "operator_handoff_bundle_validation_path",
    "operator_handoff_bundle_readiness_path",
    "operator_handoff_bundle_readiness_validation_path",
):
    assert delivery_cycle_preview[field] == canonical_preview[field], (field, delivery_cycle_preview, canonical_preview)
assert delivery_cycle_preview["remediation_commands"] == canonical_preview["remediation_commands"], (delivery_cycle_preview, canonical_preview)
display_packet_path = Path(scheduler["priority_display_packet_ref"])
if not display_packet_path.is_absolute():
    display_packet_path = monday_dir / display_packet_path
canonical_display_packet = json.loads(display_packet_path.read_text(encoding="utf-8"))
assert display_packet == canonical_display_packet, (display_packet, canonical_display_packet)
assert canonical_display_packet["operator_handoff_validation_path"] == str(handoff_validation_path), canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_path"] == scheduler["operator_handoff_bundle_path"], canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_validation_path"] == scheduler["operator_handoff_bundle_validation_path"], canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_readiness_path"] == scheduler["operator_handoff_bundle_readiness_path"], canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_readiness_validation_path"] == scheduler["operator_handoff_bundle_readiness_validation_path"], canonical_display_packet
for field in (
    "priority_headline",
    "priority_cta_command",
    "priority_summary_markdown",
    "display_title",
    "cta_command",
    "display_markdown",
    "operator_handoff_validation_path",
    "operator_handoff_bundle_path",
    "operator_handoff_bundle_validation_path",
    "operator_handoff_bundle_readiness_path",
    "operator_handoff_bundle_readiness_validation_path",
):
    assert delivery_cycle_display_packet[field] == canonical_display_packet[field], (field, delivery_cycle_display_packet, canonical_display_packet)
assert display_packet["priority_preview_ref"] == scheduler["priority_preview_ref"], display_packet
assert display_packet["display_title"] == "Supervisor completed the active goal and stopped cleanly.", display_packet
assert display_packet["cta_command"] == "bash planningops/scripts/gate_federated_ci_summary.sh", display_packet
assert "`bash planningops/scripts/gate_federated_ci_summary.sh`" in display_packet["display_markdown"], display_packet
canonical_handoff_validation = json.loads(handoff_validation_path.read_text(encoding="utf-8"))
scheduler_handoff_validation_doc = dict(scheduler_handoff_validation)
scheduler_handoff_validation_doc.pop("resolved_operator_handoff_validation_path", None)
delivery_cycle_handoff_validation_doc = dict(delivery_cycle_handoff_validation)
delivery_cycle_handoff_validation_doc.pop("resolved_operator_handoff_validation_path", None)
assert scheduler_handoff_validation_doc == canonical_handoff_validation, (scheduler_handoff_validation_doc, canonical_handoff_validation)
assert delivery_cycle_handoff_validation_doc == canonical_handoff_validation, (delivery_cycle_handoff_validation_doc, canonical_handoff_validation)
assert scheduler_bundle["artifact_file"] == str(Path(sys.argv[2]).resolve()), scheduler_bundle
assert scheduler_bundle["operator_handoff_validation_path"] == str(handoff_validation_path), scheduler_bundle
assert scheduler_bundle["priority_preview_ref"] == scheduler["priority_preview_ref"], scheduler_bundle
assert scheduler_bundle["priority_display_packet_ref"] == scheduler["priority_display_packet_ref"], scheduler_bundle
assert scheduler_bundle["operator_handoff_validation"] == canonical_handoff_validation, scheduler_bundle
assert scheduler_bundle["priority_preview"] == canonical_preview, scheduler_bundle
assert scheduler_bundle["priority_display_packet"] == canonical_display_packet, scheduler_bundle

def assert_ready_readiness(report, validation, *, artifact_path, readiness_path, bundle_validation_path, preview_ref, display_ref):
    assert report["ready"] is True, report
    assert report["readiness_status"] == "ready", report
    assert report["source_kind"] == "artifact", report
    assert report["artifact_file"] == str(Path(artifact_path).resolve()), report
    assert report["validation_report_path"] == str(Path(bundle_validation_path).resolve()), report
    assert report["bundle_validation_verdict"] == "pass", report
    assert report["operator_handoff_validation_verdict"] == "pass", report
    assert report["priority_preview_ref"] == preview_ref, report
    assert report["priority_display_packet_ref"] == display_ref, report
    assert report["priority_headline"] == canonical_preview["priority_headline"], report
    assert report["priority_cta_command"] == canonical_preview["priority_cta_command"], report
    assert report["display_title"] == canonical_display_packet["display_title"], report
    assert report["cta_command"] == canonical_display_packet["cta_command"], report
    assert report["blocking_reasons"] == [], report
    assert report["next_step"] == "none", report
    assert report["errors"] == [], report
    assert validation["verdict"] == "pass", validation
    assert validation["readiness_status"] == "ready", validation
    assert validation["readiness_ready"] is True, validation
    assert validation["artifact_file"] == str(Path(artifact_path).resolve()), validation
    assert validation["validation_report_path"] == str(Path(bundle_validation_path).resolve()), validation
    assert validation["readiness_path"] == str(Path(readiness_path).resolve()), validation

delivery_cycle_report_path = Path(sys.argv[25]).resolve()
assert_ready_readiness(
    scheduler_bundle_readiness,
    scheduler_bundle_readiness_validation,
    artifact_path=sys.argv[2],
    readiness_path=sys.argv[13],
    bundle_validation_path=sys.argv[17],
    preview_ref=scheduler["priority_preview_ref"],
    display_ref=scheduler["priority_display_packet_ref"],
)
assert_ready_readiness(
    delivery_cycle_bundle_readiness,
    delivery_cycle_bundle_readiness_validation,
    artifact_path=delivery_cycle_report_path,
    readiness_path=sys.argv[14],
    bundle_validation_path=sys.argv[18],
    preview_ref=delivery_cycle_preview_ref,
    display_ref=delivery_cycle_display_packet_ref,
)
assert_ready_readiness(
    scheduler_bundle_doctor_readiness,
    scheduler_bundle_doctor_readiness_validation,
    artifact_path=sys.argv[2],
    readiness_path=sys.argv[19],
    bundle_validation_path=sys.argv[23],
    preview_ref=scheduler["priority_preview_ref"],
    display_ref=scheduler["priority_display_packet_ref"],
)
assert_ready_readiness(
    delivery_cycle_bundle_doctor_readiness,
    delivery_cycle_bundle_doctor_readiness_validation,
    artifact_path=delivery_cycle_report_path,
    readiness_path=sys.argv[20],
    bundle_validation_path=sys.argv[24],
    preview_ref=delivery_cycle_preview_ref,
    display_ref=delivery_cycle_display_packet_ref,
)

for doctor_report, canonical_report in (
    (scheduler_bundle_doctor_readiness, scheduler_bundle_readiness),
    (delivery_cycle_bundle_doctor_readiness, delivery_cycle_bundle_readiness),
):
    for field in (
        "bundle_validation_verdict",
        "operator_handoff_validation_verdict",
        "priority_preview_ref",
        "priority_display_packet_ref",
        "priority_headline",
        "priority_cta_command",
        "display_title",
        "cta_command",
        "ready",
        "readiness_status",
        "blocking_reasons",
        "next_step",
        "error_count",
        "warning_count",
    ):
        assert doctor_report[field] == canonical_report[field], (field, doctor_report, canonical_report)

assert scheduler_bundle_validation["verdict"] == "pass", scheduler_bundle_validation
assert scheduler_bundle_validation["artifact_file"] == str(Path(sys.argv[2]).resolve()), scheduler_bundle_validation
assert scheduler_bundle_validation["operator_handoff_validation_path"] == str(handoff_validation_path), scheduler_bundle_validation
assert scheduler_bundle_validation["priority_preview_ref"] == scheduler["priority_preview_ref"], scheduler_bundle_validation
assert scheduler_bundle_validation["priority_display_packet_ref"] == scheduler["priority_display_packet_ref"], scheduler_bundle_validation
assert scheduler_bundle_validation["display_title"] == canonical_display_packet["display_title"], scheduler_bundle_validation
assert scheduler_bundle_validation["cta_command"] == canonical_display_packet["cta_command"], scheduler_bundle_validation
assert scheduler_bundle_doctor_validation["verdict"] == "pass", scheduler_bundle_doctor_validation
assert scheduler_bundle_doctor_validation["priority_preview_ref"] == scheduler["priority_preview_ref"], scheduler_bundle_doctor_validation
assert scheduler_bundle_doctor_validation["priority_display_packet_ref"] == scheduler["priority_display_packet_ref"], scheduler_bundle_doctor_validation
assert scheduler_bundle_doctor_validation["cta_command"] == canonical_display_packet["cta_command"], scheduler_bundle_doctor_validation
assert delivery_cycle_bundle["artifact_file"] == str(delivery_cycle_report_path.resolve()), delivery_cycle_bundle
assert delivery_cycle_bundle["operator_handoff_validation_path"] == str(handoff_validation_path), delivery_cycle_bundle
assert delivery_cycle_bundle["priority_preview_ref"] == delivery_cycle_preview_ref, delivery_cycle_bundle
assert delivery_cycle_bundle["priority_display_packet_ref"] == delivery_cycle_display_packet_ref, delivery_cycle_bundle
assert delivery_cycle_bundle["operator_handoff_validation"] == canonical_handoff_validation, delivery_cycle_bundle
assert delivery_cycle_bundle["priority_preview"] == delivery_cycle_preview, delivery_cycle_bundle
assert delivery_cycle_bundle["priority_display_packet"] == delivery_cycle_display_packet, delivery_cycle_bundle
assert delivery_cycle_bundle_validation["verdict"] == "pass", delivery_cycle_bundle_validation
assert delivery_cycle_bundle_validation["artifact_file"] == str(delivery_cycle_report_path.resolve()), delivery_cycle_bundle_validation
assert delivery_cycle_bundle_validation["operator_handoff_validation_path"] == str(handoff_validation_path), delivery_cycle_bundle_validation
assert delivery_cycle_bundle_validation["priority_preview_ref"] == delivery_cycle_preview_ref, delivery_cycle_bundle_validation
assert delivery_cycle_bundle_validation["priority_display_packet_ref"] == delivery_cycle_display_packet_ref, delivery_cycle_bundle_validation
assert delivery_cycle_bundle_validation["display_title"] == canonical_display_packet["display_title"], delivery_cycle_bundle_validation
assert delivery_cycle_bundle_validation["cta_command"] == canonical_display_packet["cta_command"], delivery_cycle_bundle_validation
assert delivery_cycle_bundle_doctor_validation["verdict"] == "pass", delivery_cycle_bundle_doctor_validation
assert delivery_cycle_bundle_doctor_validation["priority_preview_ref"] == delivery_cycle_preview_ref, delivery_cycle_bundle_doctor_validation
assert delivery_cycle_bundle_doctor_validation["priority_display_packet_ref"] == delivery_cycle_display_packet_ref, delivery_cycle_bundle_doctor_validation
assert delivery_cycle_bundle_doctor_validation["cta_command"] == canonical_display_packet["cta_command"], delivery_cycle_bundle_doctor_validation
PY

echo "supervisor handoff to monday goal completion scheduler bridge ok"
