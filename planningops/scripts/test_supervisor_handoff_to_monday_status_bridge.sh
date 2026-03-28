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
MONDAY_TEST_OUTBOX_ROOT="runtime-artifacts/test-supervisor-handoff-bridge"
trap 'rm -rf "$TMP_DIR" "${MONDAY_DIR}/${MONDAY_TEST_OUTBOX_ROOT}" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-packets" "${MONDAY_DIR}/runtime-artifacts/messaging/dispatch-acks"' EXIT

cd "$ROOT_DIR"

ARTIFACTS_ROOT="${TMP_DIR}/supervisor-artifacts"
SUMMARY_PATH="${TMP_DIR}/summary.json"
GOAL_REGISTRY="${TMP_DIR}/goal-registry.json"
FEDERATED_SUMMARY="${TMP_DIR}/federated-ci-summary.json"
FEDERATED_READINESS="${TMP_DIR}/federated-ci-summary-readiness.json"
PROFILES_CONFIG="${TMP_DIR}/local-operator-channel-profiles.json"
STATUS_REPORT="${TMP_DIR}/monday-supervisor-status-report.json"
DISPATCH_PACKET="${MONDAY_DIR}/${MONDAY_TEST_OUTBOX_ROOT}/dispatch-packets/supervisor-status-dispatch-packet.json"
STATUS_PREVIEW="${TMP_DIR}/monday-supervisor-status-preview.json"
DISPATCH_PREVIEW="${TMP_DIR}/monday-supervisor-status-dispatch-preview.json"
STATUS_DISPLAY_PACKET="${TMP_DIR}/monday-supervisor-status-display-packet.json"
DISPATCH_DISPLAY_PACKET="${TMP_DIR}/monday-supervisor-status-dispatch-display-packet.json"
STATUS_HANDOFF_VALIDATION="${TMP_DIR}/monday-supervisor-status-handoff-validation.json"
DISPATCH_HANDOFF_VALIDATION="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-validation.json"
STATUS_BUNDLE="${TMP_DIR}/monday-supervisor-status-handoff-bundle.json"
DISPATCH_BUNDLE="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle.json"
STATUS_BUNDLE_VALIDATION="${TMP_DIR}/monday-supervisor-status-handoff-bundle-validation.json"
DISPATCH_BUNDLE_VALIDATION="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-validation.json"
STATUS_BUNDLE_READINESS="${TMP_DIR}/monday-supervisor-status-handoff-bundle-readiness.json"
DISPATCH_BUNDLE_READINESS="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-readiness.json"
STATUS_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/monday-supervisor-status-handoff-bundle-readiness-validation.json"
DISPATCH_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-readiness-validation.json"
STATUS_BUNDLE_DOCTOR="${TMP_DIR}/monday-supervisor-status-handoff-bundle-doctor.txt"
DISPATCH_BUNDLE_DOCTOR="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-doctor.txt"
STATUS_BUNDLE_DOCTOR_READINESS="${TMP_DIR}/monday-supervisor-status-handoff-bundle-doctor-readiness.json"
DISPATCH_BUNDLE_DOCTOR_READINESS="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-doctor-readiness.json"
STATUS_BUNDLE_DOCTOR_READINESS_VALIDATION="${TMP_DIR}/monday-supervisor-status-handoff-bundle-doctor-readiness-validation.json"
DISPATCH_BUNDLE_DOCTOR_READINESS_VALIDATION="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-doctor-readiness-validation.json"
STATUS_BUNDLE_DOCTOR_VALIDATION="${TMP_DIR}/monday-supervisor-status-handoff-bundle-doctor-validation.json"
DISPATCH_BUNDLE_DOCTOR_VALIDATION="${TMP_DIR}/monday-supervisor-status-dispatch-handoff-bundle-doctor-validation.json"
RUN_ID="supervisor-handoff-monday-bridge"

cat >"$GOAL_REGISTRY" <<'JSON'
{
  "registry_version": 1,
  "active_goal_key": "goal-a",
  "goals": [
    {
      "goal_key": "goal-a",
      "title": "Goal A",
      "status": "active",
      "owner_repo": "rather-not-work-on/platform-planningops",
      "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1-goal-brief.md",
      "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1.execution-contract.json",
      "completion_contract_refs": [
        "planningops/contracts/goal-completion-contract.md"
      ],
      "operator_channels": {
        "primary_operator_channel": {
          "kind": "slack_skill_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        },
        "terminal_notification_channel": {
          "kind": "email_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        }
      }
    }
  ]
}
JSON

cat >"$FEDERATED_SUMMARY" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-test",
  "generated_at_utc": "2026-03-19T11:42:10.341286+00:00",
  "verdict": "pass",
  "overall_status": "complete",
  "check_count": 7
}
JSON

cat >"$FEDERATED_READINESS" <<JSON
{
  "generated_at_utc": "2026-03-19T11:42:14.545303+00:00",
  "summary_path": "$FEDERATED_SUMMARY",
  "validation_report_path": "$TMP_DIR/federated-ci-summary-validation.json",
  "summary_present": true,
  "validation_present": true,
  "summary_run_id": "federated-ci-runtime-gates-test",
  "summary_generated_at_utc": "2026-03-19T11:42:10.341286+00:00",
  "summary_verdict": "pass",
  "overall_status": "complete",
  "check_count": 7,
  "failed_checks": [],
  "missing_required_checks": [],
  "validation_verdict": "pass",
  "validation_state": "fresh",
  "ready": false,
  "readiness_status": "blocked",
  "blocking_reasons": ["runtime-operations-ready"],
  "next_step": "bash planningops/scripts/gate_federated_ci_summary.sh"
}
JSON

cat >"$PROFILES_CONFIG" <<JSON
{
  "config_version": 1,
  "profiles": {
    "slack_skill_cli": {
      "channel_kind": "slack_skill_cli",
      "transport_kind": "local_outbox",
      "outbox_root": "$MONDAY_TEST_OUTBOX_ROOT/slack",
      "default_target_name": "monday-operator",
      "supports_threads": true
    }
  }
}
JSON

python3 "${ROOT_DIR}/planningops/scripts/autonomous_supervisor_loop.py" \
  --mode dry-run \
  --max-cycles 3 \
  --convergence-pass-streak 2 \
  --continue-on-experiment \
  --items-file "${ROOT_DIR}/planningops/fixtures/backlog-stock-items-sample.json" \
  --offline \
  --active-goal-registry "$GOAL_REGISTRY" \
  --loop-result-sequence-file "${ROOT_DIR}/planningops/fixtures/supervisor-loop-sequence-sample.json" \
  --federated-ci-summary "$FEDERATED_SUMMARY" \
  --federated-ci-summary-readiness "$FEDERATED_READINESS" \
  --run-id "$RUN_ID" \
  --artifacts-root "$ARTIFACTS_ROOT" \
  --output "$SUMMARY_PATH" >/dev/null

OPERATOR_REPORT="${ARTIFACTS_ROOT}/${RUN_ID}/operator-report.json"
INBOX_PAYLOAD="${ARTIFACTS_ROOT}/${RUN_ID}/inbox-payload.json"

python3 "${MONDAY_DIR}/scripts/send_supervisor_status_update.py" \
  --operator-report-file "$OPERATOR_REPORT" \
  --inbox-payload-file "$INBOX_PAYLOAD" \
  --profiles-config "$PROFILES_CONFIG" \
  --mode apply \
  --output "$STATUS_REPORT" >/dev/null

python3 "${MONDAY_DIR}/scripts/export_local_outbox_dispatch_packet.py" \
  --delivery-report-file "$STATUS_REPORT" \
  --output "$DISPATCH_PACKET" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_preview.py" \
  --artifact-file "$STATUS_REPORT" \
  --output "$STATUS_PREVIEW" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_preview.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_PREVIEW" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_display_packet.py" \
  --artifact-file "$STATUS_REPORT" \
  --output "$STATUS_DISPLAY_PACKET" >/dev/null

python3 "${MONDAY_DIR}/scripts/resolve_operator_priority_display_packet.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_DISPLAY_PACKET" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_validation.py" \
  --artifact-file "$STATUS_REPORT" \
  --output "$STATUS_HANDOFF_VALIDATION" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_validation.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_HANDOFF_VALIDATION" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$STATUS_REPORT" \
  --output "$STATUS_BUNDLE" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --output "$DISPATCH_BUNDLE" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "$STATUS_BUNDLE" \
  --output "$STATUS_BUNDLE_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "$DISPATCH_BUNDLE" \
  --output "$DISPATCH_BUNDLE_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "$STATUS_REPORT" \
  --bundle-validation-output "$STATUS_BUNDLE_VALIDATION" \
  --output "$STATUS_BUNDLE_READINESS" \
  --readiness-validation-output "$STATUS_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --bundle-validation-output "$DISPATCH_BUNDLE_VALIDATION" \
  --output "$DISPATCH_BUNDLE_READINESS" \
  --readiness-validation-output "$DISPATCH_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "$STATUS_BUNDLE_READINESS" \
  --output "$STATUS_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "$DISPATCH_BUNDLE_READINESS" \
  --output "$DISPATCH_BUNDLE_READINESS_VALIDATION" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$STATUS_REPORT" \
  --bundle-validation-output "$STATUS_BUNDLE_DOCTOR_VALIDATION" \
  --readiness-output "$STATUS_BUNDLE_DOCTOR_READINESS" \
  --readiness-validation-output "$STATUS_BUNDLE_DOCTOR_READINESS_VALIDATION" >"$STATUS_BUNDLE_DOCTOR"

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "$DISPATCH_PACKET" \
  --bundle-validation-output "$DISPATCH_BUNDLE_DOCTOR_VALIDATION" \
  --readiness-output "$DISPATCH_BUNDLE_DOCTOR_READINESS" \
  --readiness-validation-output "$DISPATCH_BUNDLE_DOCTOR_READINESS_VALIDATION" >"$DISPATCH_BUNDLE_DOCTOR"

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "$STATUS_REPORT" >/dev/null

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "$DISPATCH_PACKET" >/dev/null

grep -q "bundle validation verdict: pass" "$STATUS_BUNDLE_DOCTOR"
grep -q "readiness status: ready" "$STATUS_BUNDLE_DOCTOR"
grep -q "ready: True" "$STATUS_BUNDLE_DOCTOR"
grep -q "next step: none" "$STATUS_BUNDLE_DOCTOR"
grep -q "bundle validation verdict: pass" "$DISPATCH_BUNDLE_DOCTOR"
grep -q "readiness status: ready" "$DISPATCH_BUNDLE_DOCTOR"
grep -q "ready: True" "$DISPATCH_BUNDLE_DOCTOR"
grep -q "next step: none" "$DISPATCH_BUNDLE_DOCTOR"

python3 - <<'PY' "$STATUS_REPORT" "$DISPATCH_PACKET" "$STATUS_PREVIEW" "$DISPATCH_PREVIEW" "$STATUS_DISPLAY_PACKET" "$DISPATCH_DISPLAY_PACKET" "$STATUS_HANDOFF_VALIDATION" "$DISPATCH_HANDOFF_VALIDATION" "$STATUS_BUNDLE" "$DISPATCH_BUNDLE" "$STATUS_BUNDLE_READINESS" "$DISPATCH_BUNDLE_READINESS" "$STATUS_BUNDLE_READINESS_VALIDATION" "$DISPATCH_BUNDLE_READINESS_VALIDATION" "$STATUS_BUNDLE_VALIDATION" "$DISPATCH_BUNDLE_VALIDATION" "$STATUS_BUNDLE_DOCTOR_READINESS" "$DISPATCH_BUNDLE_DOCTOR_READINESS" "$STATUS_BUNDLE_DOCTOR_READINESS_VALIDATION" "$DISPATCH_BUNDLE_DOCTOR_READINESS_VALIDATION" "$STATUS_BUNDLE_DOCTOR_VALIDATION" "$DISPATCH_BUNDLE_DOCTOR_VALIDATION" "$MONDAY_DIR"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert doc["verdict"] == "pass", doc
handoff_validation_path = str(Path(doc["operator_handoff_validation_path"]).resolve())
handoff_bundle_path = str(Path(doc["payload"]["metadata"]["operator_handoff_bundle_path"]).resolve())
handoff_bundle_validation_path = str(
    Path(doc["payload"]["metadata"]["operator_handoff_bundle_validation_path"]).resolve()
)
handoff_bundle_readiness_path = str(
    Path(doc["payload"]["metadata"]["operator_handoff_bundle_readiness_path"]).resolve()
)
handoff_bundle_readiness_validation_path = str(
    Path(doc["payload"]["metadata"]["operator_handoff_bundle_readiness_validation_path"]).resolve()
)
assert handoff_validation_path.endswith("operator-handoff-validation.json"), handoff_validation_path
assert handoff_bundle_path.endswith("operator-handoff-bundle.json"), handoff_bundle_path
assert handoff_bundle_validation_path.endswith("operator-handoff-bundle-validation.json"), handoff_bundle_validation_path
assert handoff_bundle_readiness_path.endswith("operator-handoff-bundle-readiness.json"), handoff_bundle_readiness_path
assert handoff_bundle_readiness_validation_path.endswith(
    "operator-handoff-bundle-readiness-validation.json"
), handoff_bundle_readiness_validation_path
assert doc["payload"]["metadata"]["supervisor_status"] == "degraded", doc
assert doc["payload"]["metadata"]["operator_action"] == "inspect_federated_ci_gates", doc
assert str(Path(doc["payload"]["metadata"]["operator_handoff_validation_path"]).resolve()) == handoff_validation_path, doc
assert str(Path(doc["operator_handoff_bundle_path"]).resolve()) == handoff_bundle_path, doc
assert str(Path(doc["operator_handoff_bundle_validation_path"]).resolve()) == handoff_bundle_validation_path, doc
assert str(Path(doc["operator_handoff_bundle_readiness_path"]).resolve()) == handoff_bundle_readiness_path, doc
assert str(Path(doc["operator_handoff_bundle_readiness_validation_path"]).resolve()) == handoff_bundle_readiness_validation_path, doc
assert doc["payload"]["metadata"]["headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", doc
assert doc["payload"]["metadata"]["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", doc
assert doc["payload"]["metadata"]["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in doc["payload"]["metadata"]["priority_summary_markdown"], doc
assert "## First Action" in doc["payload"]["body"], doc
federated = doc["payload"]["metadata"]["federated_ci_summary"]
assert federated["summary_run_id"] == "federated-ci-runtime-gates-test", doc
assert federated["readiness_status"] == "blocked", doc
assert federated["ready"] is False, doc
assert federated["next_step"] == "bash planningops/scripts/gate_federated_ci_summary.sh", doc
assert federated["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert federated["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert federated["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], doc
attachments = doc["payload"]["metadata"]["attachments"]
assert any("federated-ci-summary-validation.json" in str(item) for item in attachments), doc
delivery = doc["delegate_report"]["delivery_report"]
assert delivery["deliveryVerdict"] == "delivered_local_outbox", doc
assert str(Path(delivery["operatorHandoffValidationPath"]).resolve()) == handoff_validation_path, doc
assert str(Path(delivery["operatorHandoffBundlePath"]).resolve()) == handoff_bundle_path, delivery
assert str(Path(delivery["operatorHandoffBundleValidationPath"]).resolve()) == handoff_bundle_validation_path, delivery
assert str(Path(delivery["operatorHandoffBundleReadinessPath"]).resolve()) == handoff_bundle_readiness_path, delivery
assert str(Path(delivery["operatorHandoffBundleReadinessValidationPath"]).resolve()) == handoff_bundle_readiness_validation_path, delivery
assert delivery["headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", doc
assert delivery["firstActionCommand"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert delivery["primaryRemediationCommand"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert delivery["priorityHeadline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", doc
assert delivery["priorityCtaCommand"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", doc
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in delivery["prioritySummaryMarkdown"], doc
assert delivery["remediationCommands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], doc

packet = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert packet["dispatch_verdict"] == "ready_for_dispatch", packet
assert str(Path(packet["operator_handoff_validation_path"]).resolve()) == handoff_validation_path, packet
assert str(Path(packet["operator_handoff_bundle_path"]).resolve()) == handoff_bundle_path, packet
assert str(Path(packet["operator_handoff_bundle_validation_path"]).resolve()) == handoff_bundle_validation_path, packet
assert str(Path(packet["operator_handoff_bundle_readiness_path"]).resolve()) == handoff_bundle_readiness_path, packet
assert str(Path(packet["operator_handoff_bundle_readiness_validation_path"]).resolve()) == handoff_bundle_readiness_validation_path, packet
assert packet["headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", packet
assert packet["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", packet
assert packet["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", packet
assert packet["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", packet
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in packet["priority_summary_markdown"], packet
assert packet["primary_remediation_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", packet
assert packet["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], packet
assert doc["priority_preview_ref"] == packet["priority_preview_ref"], (doc, packet)
assert doc["priority_display_packet_ref"] == packet["priority_display_packet_ref"], (doc, packet)
assert str(Path(doc["delegate_report"]["operator_handoff_validation_path"]).resolve()) == handoff_validation_path, doc
assert str(Path(doc["delegate_report"]["operator_handoff_bundle_path"]).resolve()) == handoff_bundle_path, doc
assert str(Path(doc["delegate_report"]["operator_handoff_bundle_validation_path"]).resolve()) == handoff_bundle_validation_path, doc
assert str(Path(doc["delegate_report"]["operator_handoff_bundle_readiness_path"]).resolve()) == handoff_bundle_readiness_path, doc
assert str(Path(doc["delegate_report"]["operator_handoff_bundle_readiness_validation_path"]).resolve()) == handoff_bundle_readiness_validation_path, doc
assert doc["delegate_report"]["priority_preview_ref"] == packet["priority_preview_ref"], (doc, packet)
assert doc["delegate_report"]["priority_display_packet_ref"] == packet["priority_display_packet_ref"], (doc, packet)
assert delivery["priorityPreviewRef"] == packet["priority_preview_ref"], (delivery, packet)
assert delivery["priorityDisplayPacketRef"] == packet["priority_display_packet_ref"], (delivery, packet)

status_preview = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
assert status_preview["source_artifact_kind"] == "local_outbox_envelope", status_preview
assert status_preview["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", status_preview
assert status_preview["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", status_preview
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in status_preview["priority_summary_markdown"], status_preview

dispatch_preview = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
assert dispatch_preview["source_artifact_kind"] == "local_outbox_envelope", dispatch_preview
assert dispatch_preview["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", dispatch_preview
assert dispatch_preview["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", dispatch_preview
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in dispatch_preview["priority_summary_markdown"], dispatch_preview

display_packet = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))
dispatch_display_packet = json.loads(Path(sys.argv[6]).read_text(encoding="utf-8"))
status_handoff_validation = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))
dispatch_handoff_validation = json.loads(Path(sys.argv[8]).read_text(encoding="utf-8"))
status_bundle = json.loads(Path(sys.argv[9]).read_text(encoding="utf-8"))
dispatch_bundle = json.loads(Path(sys.argv[10]).read_text(encoding="utf-8"))
status_bundle_readiness = json.loads(Path(sys.argv[11]).read_text(encoding="utf-8"))
dispatch_bundle_readiness = json.loads(Path(sys.argv[12]).read_text(encoding="utf-8"))
status_bundle_readiness_validation = json.loads(Path(sys.argv[13]).read_text(encoding="utf-8"))
dispatch_bundle_readiness_validation = json.loads(Path(sys.argv[14]).read_text(encoding="utf-8"))
status_bundle_validation = json.loads(Path(sys.argv[15]).read_text(encoding="utf-8"))
dispatch_bundle_validation = json.loads(Path(sys.argv[16]).read_text(encoding="utf-8"))
status_bundle_doctor_readiness = json.loads(Path(sys.argv[17]).read_text(encoding="utf-8"))
dispatch_bundle_doctor_readiness = json.loads(Path(sys.argv[18]).read_text(encoding="utf-8"))
status_bundle_doctor_readiness_validation = json.loads(Path(sys.argv[19]).read_text(encoding="utf-8"))
dispatch_bundle_doctor_readiness_validation = json.loads(Path(sys.argv[20]).read_text(encoding="utf-8"))
status_bundle_doctor_validation = json.loads(Path(sys.argv[21]).read_text(encoding="utf-8"))
dispatch_bundle_doctor_validation = json.loads(Path(sys.argv[22]).read_text(encoding="utf-8"))
preview_path = Path(packet["priority_preview_ref"])
if not preview_path.is_absolute():
    preview_path = Path(sys.argv[23]).resolve() / preview_path
canonical_preview = json.loads(preview_path.read_text(encoding="utf-8"))
assert status_preview == canonical_preview, (status_preview, canonical_preview)
assert dispatch_preview == canonical_preview, (dispatch_preview, canonical_preview)
assert str(Path(canonical_preview["operator_handoff_validation_path"]).resolve()) == handoff_validation_path, canonical_preview
assert str(Path(canonical_preview["operator_handoff_bundle_path"]).resolve()) == handoff_bundle_path, canonical_preview
assert str(Path(canonical_preview["operator_handoff_bundle_validation_path"]).resolve()) == handoff_bundle_validation_path, canonical_preview
assert str(Path(canonical_preview["operator_handoff_bundle_readiness_path"]).resolve()) == handoff_bundle_readiness_path, canonical_preview
assert str(Path(canonical_preview["operator_handoff_bundle_readiness_validation_path"]).resolve()) == handoff_bundle_readiness_validation_path, canonical_preview
assert canonical_preview["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", canonical_preview
assert canonical_preview["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", canonical_preview
display_packet_path = Path(packet["priority_display_packet_ref"])
if not display_packet_path.is_absolute():
    display_packet_path = Path(sys.argv[23]).resolve() / display_packet_path
canonical_display_packet = json.loads(display_packet_path.read_text(encoding="utf-8"))
assert display_packet == canonical_display_packet, (display_packet, canonical_display_packet)
assert dispatch_display_packet == canonical_display_packet, (dispatch_display_packet, canonical_display_packet)
assert str(Path(canonical_display_packet["operator_handoff_validation_path"]).resolve()) == handoff_validation_path, canonical_display_packet
assert str(Path(canonical_display_packet["operator_handoff_bundle_path"]).resolve()) == handoff_bundle_path, canonical_display_packet
assert str(Path(canonical_display_packet["operator_handoff_bundle_validation_path"]).resolve()) == handoff_bundle_validation_path, canonical_display_packet
assert str(Path(canonical_display_packet["operator_handoff_bundle_readiness_path"]).resolve()) == handoff_bundle_readiness_path, canonical_display_packet
assert str(Path(canonical_display_packet["operator_handoff_bundle_readiness_validation_path"]).resolve()) == handoff_bundle_readiness_validation_path, canonical_display_packet
assert display_packet["priority_preview_ref"] == packet["priority_preview_ref"], display_packet
assert display_packet["priority_preview_ref"] == doc["priority_preview_ref"], display_packet
assert display_packet["display_title"] == "Supervisor converged, but the latest federated runtime gate is blocked.", display_packet
assert display_packet["cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", display_packet
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in display_packet["display_markdown"], display_packet
canonical_handoff_validation = json.loads(Path(handoff_validation_path).read_text(encoding="utf-8"))
status_handoff_validation_doc = dict(status_handoff_validation)
status_handoff_validation_doc.pop("resolved_operator_handoff_validation_path", None)
dispatch_handoff_validation_doc = dict(dispatch_handoff_validation)
dispatch_handoff_validation_doc.pop("resolved_operator_handoff_validation_path", None)
assert status_handoff_validation_doc == canonical_handoff_validation, (status_handoff_validation_doc, canonical_handoff_validation)
assert dispatch_handoff_validation_doc == canonical_handoff_validation, (dispatch_handoff_validation_doc, canonical_handoff_validation)
status_bundle_preview = dict(status_bundle["priority_preview"])
status_bundle_preview["operator_handoff_validation_path"] = str(Path(status_bundle_preview["operator_handoff_validation_path"]).resolve())
dispatch_bundle_preview = dict(dispatch_bundle["priority_preview"])
dispatch_bundle_preview["operator_handoff_validation_path"] = str(Path(dispatch_bundle_preview["operator_handoff_validation_path"]).resolve())
canonical_preview_for_bundle = dict(canonical_preview)
canonical_preview_for_bundle["operator_handoff_validation_path"] = str(Path(canonical_preview_for_bundle["operator_handoff_validation_path"]).resolve())
status_bundle_display_packet = dict(status_bundle["priority_display_packet"])
status_bundle_display_packet["operator_handoff_validation_path"] = str(Path(status_bundle_display_packet["operator_handoff_validation_path"]).resolve())
dispatch_bundle_display_packet = dict(dispatch_bundle["priority_display_packet"])
dispatch_bundle_display_packet["operator_handoff_validation_path"] = str(Path(dispatch_bundle_display_packet["operator_handoff_validation_path"]).resolve())
canonical_display_packet_for_bundle = dict(canonical_display_packet)
canonical_display_packet_for_bundle["operator_handoff_validation_path"] = str(Path(canonical_display_packet_for_bundle["operator_handoff_validation_path"]).resolve())
assert status_bundle["artifact_file"] == str(Path(sys.argv[1]).resolve()), status_bundle
assert status_bundle["operator_handoff_validation_path"] == handoff_validation_path, status_bundle
assert status_bundle["priority_preview_ref"] == packet["priority_preview_ref"], status_bundle
assert status_bundle["priority_display_packet_ref"] == packet["priority_display_packet_ref"], status_bundle
assert status_bundle["operator_handoff_validation"] == canonical_handoff_validation, status_bundle
assert status_bundle_preview == canonical_preview_for_bundle, status_bundle
assert status_bundle_display_packet == canonical_display_packet_for_bundle, status_bundle
assert dispatch_bundle["artifact_file"] == str(Path(sys.argv[2]).resolve()), dispatch_bundle
assert dispatch_bundle["operator_handoff_validation_path"] == handoff_validation_path, dispatch_bundle
assert dispatch_bundle["priority_preview_ref"] == packet["priority_preview_ref"], dispatch_bundle
assert dispatch_bundle["priority_display_packet_ref"] == packet["priority_display_packet_ref"], dispatch_bundle
assert dispatch_bundle["operator_handoff_validation"] == canonical_handoff_validation, dispatch_bundle
assert dispatch_bundle_preview == canonical_preview_for_bundle, dispatch_bundle
assert dispatch_bundle_display_packet == canonical_display_packet_for_bundle, dispatch_bundle

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
    status_bundle_readiness,
    status_bundle_readiness_validation,
    artifact_path=sys.argv[1],
    readiness_path=sys.argv[11],
    bundle_validation_path=sys.argv[15],
)
assert_ready_readiness(
    dispatch_bundle_readiness,
    dispatch_bundle_readiness_validation,
    artifact_path=sys.argv[2],
    readiness_path=sys.argv[12],
    bundle_validation_path=sys.argv[16],
)
assert_ready_readiness(
    status_bundle_doctor_readiness,
    status_bundle_doctor_readiness_validation,
    artifact_path=sys.argv[1],
    readiness_path=sys.argv[17],
    bundle_validation_path=sys.argv[21],
)
assert_ready_readiness(
    dispatch_bundle_doctor_readiness,
    dispatch_bundle_doctor_readiness_validation,
    artifact_path=sys.argv[2],
    readiness_path=sys.argv[18],
    bundle_validation_path=sys.argv[22],
)

for doctor_report, canonical_report in (
    (status_bundle_doctor_readiness, status_bundle_readiness),
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

assert status_bundle_validation["verdict"] == "pass", status_bundle_validation
assert status_bundle_validation["artifact_file"] == str(Path(sys.argv[1]).resolve()), status_bundle_validation
assert status_bundle_validation["operator_handoff_validation_path"] == handoff_validation_path, status_bundle_validation
assert status_bundle_validation["priority_preview_ref"] == packet["priority_preview_ref"], status_bundle_validation
assert status_bundle_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], status_bundle_validation
assert status_bundle_validation["display_title"] == canonical_display_packet["display_title"], status_bundle_validation
assert status_bundle_validation["cta_command"] == canonical_display_packet["cta_command"], status_bundle_validation
assert status_bundle_doctor_validation["verdict"] == "pass", status_bundle_doctor_validation
assert status_bundle_doctor_validation["priority_preview_ref"] == packet["priority_preview_ref"], status_bundle_doctor_validation
assert status_bundle_doctor_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], status_bundle_doctor_validation
assert status_bundle_doctor_validation["cta_command"] == canonical_display_packet["cta_command"], status_bundle_doctor_validation
assert dispatch_bundle_validation["verdict"] == "pass", dispatch_bundle_validation
assert dispatch_bundle_validation["artifact_file"] == str(Path(sys.argv[2]).resolve()), dispatch_bundle_validation
assert dispatch_bundle_validation["operator_handoff_validation_path"] == handoff_validation_path, dispatch_bundle_validation
assert dispatch_bundle_validation["priority_preview_ref"] == packet["priority_preview_ref"], dispatch_bundle_validation
assert dispatch_bundle_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], dispatch_bundle_validation
assert dispatch_bundle_validation["display_title"] == canonical_display_packet["display_title"], dispatch_bundle_validation
assert dispatch_bundle_validation["cta_command"] == canonical_display_packet["cta_command"], dispatch_bundle_validation
assert dispatch_bundle_doctor_validation["verdict"] == "pass", dispatch_bundle_doctor_validation
assert dispatch_bundle_doctor_validation["priority_preview_ref"] == packet["priority_preview_ref"], dispatch_bundle_doctor_validation
assert dispatch_bundle_doctor_validation["priority_display_packet_ref"] == packet["priority_display_packet_ref"], dispatch_bundle_doctor_validation
assert dispatch_bundle_doctor_validation["cta_command"] == canonical_display_packet["cta_command"], dispatch_bundle_doctor_validation
PY

echo "supervisor handoff to monday status bridge ok"
