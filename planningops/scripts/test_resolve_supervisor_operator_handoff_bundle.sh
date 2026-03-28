#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONDAY_DIR="$(cd "${ROOT_DIR}/../monday" && pwd)"
TMP_DIR="$(mktemp -d)"
RUNTIME_DIR="$(mktemp -d "${MONDAY_DIR}/runtime-artifacts/test-handoff-bundle.XXXXXX")"
trap 'rm -rf "${TMP_DIR}" "${RUNTIME_DIR}"' EXIT

VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION="${TMP_DIR}/operator-handoff-bundle-validation.json"
HANDOFF_BUNDLE_READINESS="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"
PREVIEW="${RUNTIME_DIR}/preview.json"
PREVIEW_ALT="${RUNTIME_DIR}/preview-alt.json"
DISPLAY_PACKET="${RUNTIME_DIR}/display-packet.json"
DISPLAY_PACKET_CONFLICT="${RUNTIME_DIR}/display-packet-conflict.json"
ARTIFACT="${RUNTIME_DIR}/artifact.json"
ARTIFACT_CONFLICT="${RUNTIME_DIR}/artifact-conflict.json"
BUNDLE="${TMP_DIR}/handoff-bundle.json"
CONFLICT_STDERR="${TMP_DIR}/conflict.stderr"

preview_ref() {
  python3 - <<'PY' "$MONDAY_DIR" "$1"
from pathlib import Path
import sys
root = Path(sys.argv[1]).resolve()
target = Path(sys.argv[2]).resolve()
print(target.relative_to(root))
PY
}

cat >"${VALIDATION}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:00Z",
  "operator_report_path": "${TMP_DIR}/operator-report.json",
  "inbox_payload_path": "${TMP_DIR}/inbox-payload.json",
  "operator_report_schema_path": "${ROOT_DIR}/planningops/schemas/supervisor-operator-report.schema.json",
  "inbox_payload_schema_path": "${ROOT_DIR}/planningops/schemas/supervisor-inbox-payload.schema.json",
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET}")",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION}",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "verdict": "pass"
}
JSON

cat >"${PREVIEW}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:01Z",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle.source/wrapper.json",
  "source_artifact_kind": "local_outbox_envelope",
  "source_priority_path": "payload.metadata.priority_summary_markdown",
  "preview_state": "present",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION}",
  "priority_headline": "Supervisor converged, but the latest federated runtime gate is blocked.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "priority_summary_markdown": "## Priority\n- headline: Supervisor converged, but the latest federated runtime gate is blocked.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`"
}
JSON

cat >"${PREVIEW_ALT}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:01Z",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle.source/wrapper.json",
  "source_artifact_kind": "local_outbox_envelope",
  "source_priority_path": "payload.metadata.priority_summary_markdown",
  "preview_state": "present",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION}",
  "priority_headline": "Conflicting preview headline",
  "priority_cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "priority_summary_markdown": "## Priority\n- headline: Conflicting preview headline\n- first action: \`bash planningops/scripts/gate_federated_ci_summary.sh\`"
}
JSON

cat >"${DISPLAY_PACKET}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:02Z",
  "input_kind": "artifact",
  "input_ref": "runtime-artifacts/test-handoff-bundle/artifact.json",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle.source/wrapper.json",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "preview_source_artifact_kind": "local_outbox_envelope",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION}",
  "priority_headline": "Supervisor converged, but the latest federated runtime gate is blocked.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "priority_summary_markdown": "## Priority\n- headline: Supervisor converged, but the latest federated runtime gate is blocked.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`",
  "display_title": "Supervisor converged, but the latest federated runtime gate is blocked.",
  "cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "display_markdown": "## Priority\n- headline: Supervisor converged, but the latest federated runtime gate is blocked.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`"
}
JSON

cat >"${DISPLAY_PACKET_CONFLICT}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:02Z",
  "input_kind": "artifact",
  "input_ref": "runtime-artifacts/test-handoff-bundle/artifact-conflict.json",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle.source/wrapper.json",
  "priority_preview_ref": "$(preview_ref "${PREVIEW_ALT}")",
  "preview_source_artifact_kind": "local_outbox_envelope",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION}",
  "priority_headline": "Conflicting preview headline",
  "priority_cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "priority_summary_markdown": "## Priority\n- headline: Conflicting preview headline\n- first action: \`bash planningops/scripts/gate_federated_ci_summary.sh\`",
  "display_title": "Conflicting preview headline",
  "cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "display_markdown": "## Priority\n- headline: Conflicting preview headline\n- first action: \`bash planningops/scripts/gate_federated_ci_summary.sh\`"
}
JSON

cat >"${ARTIFACT}" <<JSON
{
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET}")"
}
JSON

cat >"${ARTIFACT_CONFLICT}" <<JSON
{
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET_CONFLICT}")"
}
JSON

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT}" \
  --output "${BUNDLE}" >/dev/null

python3 - <<'PY' "${ARTIFACT}" "${VALIDATION}" "${PREVIEW}" "${DISPLAY_PACKET}" "${BUNDLE}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE_READINESS}" "${HANDOFF_BUNDLE_READINESS_VALIDATION}" "${MONDAY_DIR}"
import json
import sys
from pathlib import Path

artifact = Path(sys.argv[1]).resolve()
validation = Path(sys.argv[2]).resolve()
preview_path = Path(sys.argv[3]).resolve()
display_packet_path = Path(sys.argv[4]).resolve()
bundle = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))
handoff_bundle = Path(sys.argv[6]).resolve()
handoff_bundle_validation = Path(sys.argv[7]).resolve()
handoff_bundle_readiness = Path(sys.argv[8]).resolve()
handoff_bundle_readiness_validation = Path(sys.argv[9]).resolve()
monday_root = Path(sys.argv[10]).resolve()

assert Path(bundle["artifact_file"]).resolve() == artifact, bundle
assert Path(bundle["operator_handoff_validation_path"]).resolve() == validation, bundle
assert Path(bundle["operator_handoff_bundle_path"]).resolve() == handoff_bundle, bundle
assert Path(bundle["operator_handoff_bundle_validation_path"]).resolve() == handoff_bundle_validation, bundle
assert Path(bundle["operator_handoff_bundle_readiness_path"]).resolve() == handoff_bundle_readiness, bundle
assert Path(bundle["operator_handoff_bundle_readiness_validation_path"]).resolve() == handoff_bundle_readiness_validation, bundle
assert bundle["priority_preview_ref"] == str(preview_path.relative_to(monday_root)), bundle
assert bundle["priority_display_packet_ref"] == str(display_packet_path.relative_to(monday_root)), bundle
assert bundle["operator_handoff_validation"] == json.loads(validation.read_text(encoding="utf-8")), bundle
assert bundle["priority_preview"] == json.loads(preview_path.read_text(encoding="utf-8")), bundle
assert bundle["priority_display_packet"] == json.loads(display_packet_path.read_text(encoding="utf-8")), bundle
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT_CONFLICT}" \
  --output "${TMP_DIR}/bundle-conflict.json" >"${TMP_DIR}/conflict.stdout" 2>"${CONFLICT_STDERR}"; then
  echo "expected conflicting bundle refs to fail" >&2
  exit 1
fi

grep -q "priority display packet priority_preview_ref does not match resolved priority preview ref" "${CONFLICT_STDERR}"

echo "resolve supervisor operator handoff bundle ok"
