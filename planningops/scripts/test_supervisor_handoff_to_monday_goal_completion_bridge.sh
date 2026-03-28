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
MONDAY_TEST_OUTBOX_ROOT="runtime-artifacts/test-supervisor-goal-completion-bridge"
trap 'rm -rf "$TMP_DIR" "${MONDAY_DIR}/${MONDAY_TEST_OUTBOX_ROOT}" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-packets" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-acks"' EXIT

cd "$ROOT_DIR"

OPERATOR_REPORT="${TMP_DIR}/operator-report.json"
OPERATOR_SUMMARY="${TMP_DIR}/operator-summary.md"
GOAL_TRANSITION_REPORT="${TMP_DIR}/goal-transition-report.json"
HANDOFF_VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION="${TMP_DIR}/operator-handoff-bundle-validation.json"
HANDOFF_BUNDLE_READINESS="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"
PROFILES_CONFIG="${TMP_DIR}/local-operator-channel-profiles.json"
GOAL_COMPLETION_REPORT="${TMP_DIR}/monday-supervisor-goal-completion-report.json"
DISPATCH_PACKET="${MONDAY_DIR}/${MONDAY_TEST_OUTBOX_ROOT}/dispatch-packets/supervisor-goal-completion-dispatch-packet.json"
GOAL_COMPLETION_PREVIEW="${TMP_DIR}/goal-completion-preview.json"
DISPATCH_PREVIEW="${TMP_DIR}/goal-completion-dispatch-preview.json"
DISPLAY_PACKET="${TMP_DIR}/goal-completion-display-packet.json"
DISPATCH_DISPLAY_PACKET="${TMP_DIR}/goal-completion-dispatch-display-packet.json"
GOAL_HANDOFF_VALIDATION="${TMP_DIR}/goal-completion-handoff-validation.json"
DISPATCH_HANDOFF_VALIDATION="${TMP_DIR}/goal-completion-dispatch-handoff-validation.json"
GOAL_BUNDLE="${TMP_DIR}/goal-completion-handoff-bundle.json"
DISPATCH_BUNDLE="${TMP_DIR}/goal-completion-dispatch-handoff-bundle.json"
GOAL_BUNDLE_VALIDATION="${TMP_DIR}/goal-completion-handoff-bundle-validation.json"
DISPATCH_BUNDLE_VALIDATION="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-validation.json"
GOAL_BUNDLE_READINESS="${TMP_DIR}/goal-completion-handoff-bundle-readiness.json"
DISPATCH_BUNDLE_READINESS="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-readiness.json"
GOAL_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/goal-completion-handoff-bundle-readiness-validation.json"
DISPATCH_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-readiness-validation.json"
GOAL_BUNDLE_DOCTOR="${TMP_DIR}/goal-completion-handoff-bundle-doctor.txt"
DISPATCH_BUNDLE_DOCTOR="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-doctor.txt"
GOAL_BUNDLE_DOCTOR_READINESS="${TMP_DIR}/goal-completion-handoff-bundle-doctor-readiness.json"
DISPATCH_BUNDLE_DOCTOR_READINESS="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-doctor-readiness.json"
GOAL_BUNDLE_DOCTOR_READINESS_VALIDATION="${TMP_DIR}/goal-completion-handoff-bundle-doctor-readiness-validation.json"
DISPATCH_BUNDLE_DOCTOR_READINESS_VALIDATION="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-doctor-readiness-validation.json"
GOAL_BUNDLE_DOCTOR_VALIDATION="${TMP_DIR}/goal-completion-handoff-bundle-doctor-validation.json"
DISPATCH_BUNDLE_DOCTOR_VALIDATION="${TMP_DIR}/goal-completion-dispatch-handoff-bundle-doctor-validation.json"

cat >"$OPERATOR_REPORT" <<'JSON'
{
  "run_id": "supervisor-goal-completion-bridge",
  "summary_path": "/tmp/planningops/summary.json",
  "status": "ok",
  "headline": "Supervisor completed the active goal and stopped cleanly.",
  "first_action_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "operator_action": "notify_goal_completion",
  "goal_key": "uap-goal-driven-autonomy-wave3",
  "message_class_hint": "goal_completed",
  "handoff_contract_ref": "planningops/contracts/supervisor-operator-handoff-contract.md",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "goal_transition_report_path": "GOAL_TRANSITION_REPORT_PLACEHOLDER",
  "federated_ci_summary": {
    "summary_run_id": "federated-ci-runtime-gates-20260319-rerun25",
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

cat >"$GOAL_TRANSITION_REPORT" <<'JSON'
{
  "generated_at_utc": "2026-03-19T12:00:00Z",
  "goal_key": "uap-goal-driven-autonomy-wave3",
  "to_status": "achieved",
  "goal_transition_kind": "terminal_completion",
  "verdict": "pass"
}
JSON

cat >"$HANDOFF_VALIDATION" <<'JSON'
{
  "generated_at_utc": "2026-03-20T01:02:05+00:00",
  "operator_report_path": "OPERATOR_REPORT_PLACEHOLDER",
  "operator_report_run_id": "supervisor-goal-completion-bridge",
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

python3 "${MONDAY_DIR}/scripts/send_supervisor_goal_completion.py" \
  --operator-report-file "$OPERATOR_REPORT" \
  --operator-summary-file "$OPERATOR_SUMMARY" \
  --goal-transition-report-file "$GOAL_TRANSITION_REPORT" \
  --profiles-config "$PROFILES_CONFIG" \
  --mode apply \
  --output "$GOAL_COMPLETION_REPORT" >/dev/null

python3 "${MONDAY_DIR}/scripts/export_local_outbox_dispatch_packet.py" \
  --delivery-report-file "$GOAL_COMPLETION_REPORT" \
  --output "$DISPATCH_PACKET" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_preview.py" \
  --artifact-file "$GOAL_COMPLETION_REPORT" \
  --output "$GOAL_COMPLETION_PREVIEW" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_preview.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_PREVIEW" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_display_packet.py" \
  --artifact-file "$GOAL_COMPLETION_REPORT" \
  --output "$DISPLAY_PACKET" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_display_packet.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_DISPLAY_PACKET" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_validation.py" \
  --artifact-file "$GOAL_COMPLETION_REPORT" \
  --output "$GOAL_HANDOFF_VALIDATION" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_validation.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_HANDOFF_VALIDATION" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$GOAL_COMPLETION_REPORT" \
  --output "$GOAL_BUNDLE" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_BUNDLE" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "$GOAL_BUNDLE" \
  --output "$GOAL_BUNDLE_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "$DISPATCH_BUNDLE" \
  --output "$DISPATCH_BUNDLE_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "$GOAL_COMPLETION_REPORT" \
  --bundle-validation-output "$GOAL_BUNDLE_VALIDATION" \
  --output "$GOAL_BUNDLE_READINESS" \
  --readiness-validation-output "$GOAL_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --bundle-validation-output "$DISPATCH_BUNDLE_VALIDATION" \
  --output "$DISPATCH_BUNDLE_READINESS" \
  --readiness-validation-output "$DISPATCH_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "$GOAL_BUNDLE_READINESS" \
  --output "$GOAL_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "$DISPATCH_BUNDLE_READINESS" \
  --output "$DISPATCH_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$GOAL_COMPLETION_REPORT" \
  --bundle-validation-output "$GOAL_BUNDLE_DOCTOR_VALIDATION" \
  --readiness-output "$GOAL_BUNDLE_DOCTOR_READINESS" \
  --readiness-validation-output "$GOAL_BUNDLE_DOCTOR_READINESS_VALIDATION" >"$GOAL_BUNDLE_DOCTOR"

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --bundle-validation-output "$DISPATCH_BUNDLE_DOCTOR_VALIDATION" \
  --readiness-output "$DISPATCH_BUNDLE_DOCTOR_READINESS" \
  --readiness-validation-output "$DISPATCH_BUNDLE_DOCTOR_READINESS_VALIDATION" >"$DISPATCH_BUNDLE_DOCTOR"

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "$GOAL_COMPLETION_REPORT" >/dev/null

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "$DISPATCH_PACKET" >/dev/null

grep -q "bundle validation verdict: pass" "$GOAL_BUNDLE_DOCTOR"
grep -q "readiness status: ready" "$GOAL_BUNDLE_DOCTOR"
grep -q "ready: True" "$GOAL_BUNDLE_DOCTOR"
grep -q "next step: none" "$GOAL_BUNDLE_DOCTOR"
grep -q "bundle validation verdict: pass" "$DISPATCH_BUNDLE_DOCTOR"
grep -q "readiness status: ready" "$DISPATCH_BUNDLE_DOCTOR"
grep -q "ready: True" "$DISPATCH_BUNDLE_DOCTOR"
grep -q "next step: none" "$DISPATCH_BUNDLE_DOCTOR"

python3 - <<'PY' "$GOAL_COMPLETION_REPORT" "$DISPATCH_PACKET" "$MONDAY_DIR" "$GOAL_COMPLETION_PREVIEW" "$DISPATCH_PREVIEW" "$DISPLAY_PACKET" "$DISPATCH_DISPLAY_PACKET" "$GOAL_HANDOFF_VALIDATION" "$DISPATCH_HANDOFF_VALIDATION" "$HANDOFF_VALIDATION" "$GOAL_BUNDLE" "$DISPATCH_BUNDLE" "$GOAL_BUNDLE_READINESS" "$DISPATCH_BUNDLE_READINESS" "$GOAL_BUNDLE_READINESS_VALIDATION" "$DISPATCH_BUNDLE_READINESS_VALIDATION" "$GOAL_BUNDLE_VALIDATION" "$DISPATCH_BUNDLE_VALIDATION" "$GOAL_BUNDLE_DOCTOR_READINESS" "$DISPATCH_BUNDLE_DOCTOR_READINESS" "$GOAL_BUNDLE_DOCTOR_READINESS_VALIDATION" "$DISPATCH_BUNDLE_DOCTOR_READINESS_VALIDATION" "$GOAL_BUNDLE_DOCTOR_VALIDATION" "$DISPATCH_BUNDLE_DOCTOR_VALIDATION"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
monday_dir = Path(sys.argv[3]).resolve()
preview = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
dispatch_preview = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))
display_packet = json.loads(Path(sys.argv[6]).read_text(encoding="utf-8"))
dispatch_display_packet = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))
goal_handoff_validation = json.loads(Path(sys.argv[8]).read_text(encoding="utf-8"))
dispatch_handoff_validation = json.loads(Path(sys.argv[9]).read_text(encoding="utf-8"))
goal_bundle = json.loads(Path(sys.argv[11]).read_text(encoding="utf-8"))
dispatch_bundle = json.loads(Path(sys.argv[12]).read_text(encoding="utf-8"))
goal_bundle_readiness = json.loads(Path(sys.argv[13]).read_text(encoding="utf-8"))
dispatch_bundle_readiness = json.loads(Path(sys.argv[14]).read_text(encoding="utf-8"))
goal_bundle_readiness_validation = json.loads(Path(sys.argv[15]).read_text(encoding="utf-8"))
dispatch_bundle_readiness_validation = json.loads(Path(sys.argv[16]).read_text(encoding="utf-8"))
goal_bundle_validation = json.loads(Path(sys.argv[17]).read_text(encoding="utf-8"))
dispatch_bundle_validation = json.loads(Path(sys.argv[18]).read_text(encoding="utf-8"))
goal_bundle_doctor_readiness = json.loads(Path(sys.argv[19]).read_text(encoding="utf-8"))
dispatch_bundle_doctor_readiness = json.loads(Path(sys.argv[20]).read_text(encoding="utf-8"))
goal_bundle_doctor_readiness_validation = json.loads(Path(sys.argv[21]).read_text(encoding="utf-8"))
dispatch_bundle_doctor_readiness_validation = json.loads(Path(sys.argv[22]).read_text(encoding="utf-8"))
goal_bundle_doctor_validation = json.loads(Path(sys.argv[23]).read_text(encoding="utf-8"))
dispatch_bundle_doctor_validation = json.loads(Path(sys.argv[24]).read_text(encoding="utf-8"))
handoff_validation_path = Path(sys.argv[10]).resolve()
assert doc["verdict"] == "pass", doc
assert doc["operator_handoff_validation_path"] == str(handoff_validation_path), doc
assert doc["payload"]["messageClass"] == "goal_completed", doc
assert doc["payload"]["metadata"]["operator_handoff_validation_path"] == str(handoff_validation_path), doc
assert doc["payload"]["metadata"]["headline"] == "Supervisor completed the active goal and stopped cleanly.", doc
assert doc["payload"]["metadata"]["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", doc
assert doc["payload"]["metadata"]["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert doc["payload"]["metadata"]["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in doc["payload"]["metadata"]["priority_summary_markdown"], doc
assert "## First Action" in doc["payload"]["body"], doc
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in doc["payload"]["body"], doc
federated = doc["payload"]["metadata"]["federated_ci_summary"]
assert federated["summary_run_id"] == "federated-ci-runtime-gates-20260319-rerun25", doc
assert federated["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert federated["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert federated["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], doc

delivery = doc["delegate_report"]["delivery_report"]
assert delivery["deliveryVerdict"] == "delivered_local_outbox", doc
assert delivery["operatorHandoffValidationPath"] == str(handoff_validation_path), doc
assert delivery["headline"] == "Supervisor completed the active goal and stopped cleanly.", doc
assert delivery["firstActionCommand"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert delivery["primaryRemediationCommand"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert delivery["priorityHeadline"] == "Supervisor completed the active goal and stopped cleanly.", doc
assert delivery["priorityCtaCommand"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in delivery["prioritySummaryMarkdown"], doc
assert delivery["remediationCommands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], doc

outbox_message_ref = Path(doc["delegate_report"]["outbox_message_ref"])
if not outbox_message_ref.is_absolute():
    outbox_message_ref = monday_dir / outbox_message_ref
envelope = json.loads(outbox_message_ref.read_text(encoding="utf-8"))
assert envelope["operator_handoff_validation_path"] == str(handoff_validation_path), envelope
assert envelope["headline"] == "Supervisor completed the active goal and stopped cleanly.", envelope
assert envelope["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", envelope
assert envelope["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", envelope
assert envelope["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", envelope
assert envelope["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", envelope
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in envelope["priority_summary_markdown"], envelope
assert envelope["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], envelope
assert "## First Action" in envelope["payload"]["body"], envelope

packet = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert packet["dispatch_verdict"] == "ready_for_dispatch", packet
assert packet["operator_handoff_validation_path"] == str(handoff_validation_path), packet
assert packet["headline"] == "Supervisor completed the active goal and stopped cleanly.", packet
assert packet["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", packet
assert packet["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", packet
assert packet["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", packet
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in packet["priority_summary_markdown"], packet
assert packet["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", packet
assert packet["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], packet
assert doc["priority_preview_ref"] == packet["priority_preview_ref"], (doc, packet)
assert doc["priority_display_packet_ref"] == packet["priority_display_packet_ref"], (doc, packet)
assert doc["delegate_report"]["priority_preview_ref"] == packet["priority_preview_ref"], (doc, packet)
assert doc["delegate_report"]["priority_display_packet_ref"] == packet["priority_display_packet_ref"], (doc, packet)
assert delivery["priorityPreviewRef"] == packet["priority_preview_ref"], (delivery, packet)
assert delivery["priorityDisplayPacketRef"] == packet["priority_display_packet_ref"], (delivery, packet)

preview_path = Path(packet["priority_preview_ref"])
if not preview_path.is_absolute():
    preview_path = monday_dir / preview_path
canonical_preview = json.loads(preview_path.read_text(encoding="utf-8"))
assert preview == canonical_preview, (preview, canonical_preview)
assert dispatch_preview == canonical_preview, (dispatch_preview, canonical_preview)
assert canonical_preview["operator_handoff_validation_path"] == str(handoff_validation_path), canonical_preview
assert canonical_preview["operator_handoff_bundle_path"] == packet["operator_handoff_bundle_path"], canonical_preview
assert canonical_preview["operator_handoff_bundle_validation_path"] == packet["operator_handoff_bundle_validation_path"], canonical_preview
assert canonical_preview["operator_handoff_bundle_readiness_path"] == packet["operator_handoff_bundle_readiness_path"], canonical_preview
assert canonical_preview["operator_handoff_bundle_readiness_validation_path"] == packet["operator_handoff_bundle_readiness_validation_path"], canonical_preview
assert canonical_preview["priority_headline"] == "Supervisor completed the active goal and stopped cleanly.", canonical_preview
assert canonical_preview["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", canonical_preview

display_packet_path = Path(packet["priority_display_packet_ref"])
if not display_packet_path.is_absolute():
    display_packet_path = monday_dir / display_packet_path
canonical_display_packet = json.loads(display_packet_path.read_text(encoding="utf-8"))
assert display_packet == canonical_display_packet, (display_packet, canonical_display_packet)
assert dispatch_display_packet == canonical_display_packet, (dispatch_display_packet, canonical_display_packet)
assert canonical_display_packet["operator_handoff_validation_path"] == str(handoff_validation_path), canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_path"] == packet["operator_handoff_bundle_path"], canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_validation_path"] == packet["operator_handoff_bundle_validation_path"], canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_readiness_path"] == packet["operator_handoff_bundle_readiness_path"], canonical_display_packet
assert canonical_display_packet["operator_handoff_bundle_readiness_validation_path"] == packet["operator_handoff_bundle_readiness_validation_path"], canonical_display_packet
assert display_packet["display_title"] == "Supervisor completed the active goal and stopped cleanly.", display_packet
assert display_packet["cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", display_packet
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in display_packet["display_markdown"], display_packet
assert display_packet["priority_preview_ref"] == packet["priority_preview_ref"], display_packet
canonical_handoff_validation = json.loads(handoff_validation_path.read_text(encoding="utf-8"))
goal_handoff_validation_doc = dict(goal_handoff_validation)
goal_handoff_validation_doc.pop("resolved_operator_handoff_validation_path", None)
dispatch_handoff_validation_doc = dict(dispatch_handoff_validation)
dispatch_handoff_validation_doc.pop("resolved_operator_handoff_validation_path", None)
assert goal_handoff_validation_doc == canonical_handoff_validation, (goal_handoff_validation_doc, canonical_handoff_validation)
assert dispatch_handoff_validation_doc == canonical_handoff_validation, (dispatch_handoff_validation_doc, canonical_handoff_validation)
assert goal_bundle["artifact_file"] == str(Path(sys.argv[1]).resolve()), goal_bundle
assert goal_bundle["operator_handoff_validation_path"] == str(handoff_validation_path), goal_bundle
assert goal_bundle["priority_preview_ref"] == packet["priority_preview_ref"], goal_bundle
assert goal_bundle["priority_display_packet_ref"] == packet["priority_display_packet_ref"], goal_bundle
assert goal_bundle["operator_handoff_validation"] == canonical_handoff_validation, goal_bundle
assert goal_bundle["priority_preview"] == canonical_preview, goal_bundle
assert goal_bundle["priority_display_packet"] == canonical_display_packet, goal_bundle
assert dispatch_bundle["artifact_file"] == str(Path(sys.argv[2]).resolve()), dispatch_bundle
assert dispatch_bundle["operator_handoff_validation_path"] == str(handoff_validation_path), dispatch_bundle
assert dispatch_bundle["priority_preview_ref"] == packet["priority_preview_ref"], dispatch_bundle
assert dispatch_bundle["priority_display_packet_ref"] == packet["priority_display_packet_ref"], dispatch_bundle
assert dispatch_bundle["operator_handoff_validation"] == canonical_handoff_validation, dispatch_bundle
assert dispatch_bundle["priority_preview"] == canonical_preview, dispatch_bundle
assert dispatch_bundle["priority_display_packet"] == canonical_display_packet, dispatch_bundle

def assert_ready_readiness(report, validation, *, artifact_path, readiness_path, bundle_validation_path):
    assert report["ready"] is True, report
    assert report["readiness_status"] == "ready", report
    assert report["source_kind"] == "artifact", report
    assert report["artifact_file"] == str(Path(artifact_path).resolve()), report
    assert report["validation_report_path"] == str(Path(bundle_validation_path).resolve()), report
    assert report["bundle_validation_verdict"] == "pass", report
    assert report["operator_handoff_validation_verdict"] == "pass", report
    assert report["priority_preview_ref"] == packet["priority_preview_ref"], report
    assert report["priority_display_packet_ref"] == packet["priority_display_packet_ref"], report
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

assert_ready_readiness(
    goal_bundle_readiness,
    goal_bundle_readiness_validation,
    artifact_path=sys.argv[1],
    readiness_path=sys.argv[13],
    bundle_validation_path=sys.argv[17],
)
assert_ready_readiness(
    dispatch_bundle_readiness,
    dispatch_bundle_readiness_validation,
    artifact_path=sys.argv[2],
    readiness_path=sys.argv[14],
    bundle_validation_path=sys.argv[18],
)
assert_ready_readiness(
    goal_bundle_doctor_readiness,
    goal_bundle_doctor_readiness_validation,
    artifact_path=sys.argv[1],
    readiness_path=sys.argv[19],
    bundle_validation_path=sys.argv[23],
)
assert_ready_readiness(
    dispatch_bundle_doctor_readiness,
    dispatch_bundle_doctor_readiness_validation,
    artifact_path=sys.argv[2],
    readiness_path=sys.argv[20],
    bundle_validation_path=sys.argv[24],
)

for doctor_report, canonical_report in (
    (goal_bundle_doctor_readiness, goal_bundle_readiness),
    (dispatch_bundle_doctor_readiness, dispatch_bundle_readiness),
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

assert goal_bundle_validation["verdict"] == "pass", goal_bundle_validation
assert goal_bundle_validation["artifact_file"] == str(Path(sys.argv[1]).resolve()), goal_bundle_validation
assert goal_bundle_validation["operator_handoff_validation_path"] == str(handoff_validation_path), goal_bundle_validation
assert goal_bundle_validation["priority_preview_ref"] == packet["priority_preview_ref"], goal_bundle_validation
assert goal_bundle_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], goal_bundle_validation
assert goal_bundle_validation["display_title"] == canonical_display_packet["display_title"], goal_bundle_validation
assert goal_bundle_validation["cta_command"] == canonical_display_packet["cta_command"], goal_bundle_validation
assert goal_bundle_doctor_validation["verdict"] == "pass", goal_bundle_doctor_validation
assert goal_bundle_doctor_validation["priority_preview_ref"] == packet["priority_preview_ref"], goal_bundle_doctor_validation
assert goal_bundle_doctor_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], goal_bundle_doctor_validation
assert goal_bundle_doctor_validation["cta_command"] == canonical_display_packet["cta_command"], goal_bundle_doctor_validation
assert dispatch_bundle_validation["verdict"] == "pass", dispatch_bundle_validation
assert dispatch_bundle_validation["artifact_file"] == str(Path(sys.argv[2]).resolve()), dispatch_bundle_validation
assert dispatch_bundle_validation["operator_handoff_validation_path"] == str(handoff_validation_path), dispatch_bundle_validation
assert dispatch_bundle_validation["priority_preview_ref"] == packet["priority_preview_ref"], dispatch_bundle_validation
assert dispatch_bundle_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], dispatch_bundle_validation
assert dispatch_bundle_validation["display_title"] == canonical_display_packet["display_title"], dispatch_bundle_validation
assert dispatch_bundle_validation["cta_command"] == canonical_display_packet["cta_command"], dispatch_bundle_validation
assert dispatch_bundle_doctor_validation["verdict"] == "pass", dispatch_bundle_doctor_validation
assert dispatch_bundle_doctor_validation["priority_preview_ref"] == packet["priority_preview_ref"], dispatch_bundle_doctor_validation
assert dispatch_bundle_doctor_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], dispatch_bundle_doctor_validation
assert dispatch_bundle_doctor_validation["cta_command"] == canonical_display_packet["cta_command"], dispatch_bundle_doctor_validation
PY

echo "supervisor handoff to monday goal completion bridge ok"
