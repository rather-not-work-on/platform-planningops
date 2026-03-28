#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONDAY_DIR="$(cd "${ROOT_DIR}/../monday" && pwd)"
TMP_DIR="$(mktemp -d)"
RUNTIME_DIR="$(mktemp -d "${MONDAY_DIR}/runtime-artifacts/test-handoff-bundle-gate.XXXXXX")"
trap 'rm -rf "${TMP_DIR}" "${RUNTIME_DIR}"' EXIT

VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION_SIDECAR="${TMP_DIR}/operator-handoff-bundle-validation.json"
HANDOFF_BUNDLE_READINESS_SIDECAR="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"
PREVIEW="${RUNTIME_DIR}/preview.json"
DISPLAY_PACKET="${RUNTIME_DIR}/display-packet.json"
ARTIFACT="${RUNTIME_DIR}/artifact.json"
BUNDLE="${TMP_DIR}/bundle.json"
BROKEN_BUNDLE="${TMP_DIR}/broken-bundle.json"
BUNDLE_VALIDATION="${TMP_DIR}/handoff-bundle-validation.json"
READINESS="${TMP_DIR}/handoff-bundle-readiness.json"
READINESS_VALIDATION="${TMP_DIR}/handoff-bundle-readiness-validation.json"

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
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
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
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-gate.source/wrapper.json",
  "source_artifact_kind": "local_outbox_envelope",
  "source_priority_path": "payload.metadata.priority_summary_markdown",
  "preview_state": "present",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
  "priority_headline": "Gate bundle headline.",
  "priority_cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "priority_summary_markdown": "## Priority\n- headline: Gate bundle headline.\n- first action: \`bash planningops/scripts/gate_federated_ci_summary.sh\`"
}
JSON

cat >"${DISPLAY_PACKET}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:02Z",
  "input_kind": "artifact",
  "input_ref": "runtime-artifacts/test-handoff-bundle-gate/artifact.json",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-gate.source/wrapper.json",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "preview_source_artifact_kind": "local_outbox_envelope",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
  "priority_headline": "Gate bundle headline.",
  "priority_cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "priority_summary_markdown": "## Priority\n- headline: Gate bundle headline.\n- first action: \`bash planningops/scripts/gate_federated_ci_summary.sh\`",
  "display_title": "Gate bundle headline.",
  "cta_command": "bash planningops/scripts/gate_federated_ci_summary.sh",
  "display_markdown": "## Priority\n- headline: Gate bundle headline.\n- first action: \`bash planningops/scripts/gate_federated_ci_summary.sh\`"
}
JSON

cat >"${ARTIFACT}" <<JSON
{
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET}")"
}
JSON

bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --artifact-file "${ARTIFACT}" \
  --bundle-validation-output "${BUNDLE_VALIDATION}" \
  --readiness-output "${READINESS}" \
  --readiness-validation-output "${READINESS_VALIDATION}" >/dev/null

python3 - <<'PY' "${READINESS}" "${READINESS_VALIDATION}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}" "${HANDOFF_BUNDLE_READINESS_SIDECAR}" "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}"
import json
import sys
from pathlib import Path

readiness = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert readiness["ready"] is True, readiness
assert Path(readiness["operator_handoff_bundle_path"]).resolve() == Path(sys.argv[3]).resolve(), readiness
assert Path(readiness["operator_handoff_bundle_validation_path"]).resolve() == Path(sys.argv[4]).resolve(), readiness
assert Path(readiness["operator_handoff_bundle_readiness_path"]).resolve() == Path(sys.argv[5]).resolve(), readiness
assert Path(readiness["operator_handoff_bundle_readiness_validation_path"]).resolve() == Path(sys.argv[6]).resolve(), readiness
assert validation["verdict"] == "pass", validation
PY

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT}" \
  --output "${BUNDLE}" >/dev/null

python3 - <<'PY' "${BUNDLE}" "${BROKEN_BUNDLE}"
import json
import sys
from pathlib import Path
source = Path(sys.argv[1])
target = Path(sys.argv[2])
doc = json.loads(source.read_text(encoding="utf-8"))
doc["priority_display_packet"]["priority_cta_command"] = "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass"
target.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if bash "${ROOT_DIR}/planningops/scripts/gate_supervisor_operator_handoff_bundle.sh" \
  --bundle-file "${BROKEN_BUNDLE}" >/dev/null 2>&1; then
  echo "expected gate to fail on broken bundle" >&2
  exit 1
fi

echo "gate supervisor operator handoff bundle ok"
