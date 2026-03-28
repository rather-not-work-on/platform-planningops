#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONDAY_DIR="$(cd "${ROOT_DIR}/../monday" && pwd)"
TMP_DIR="$(mktemp -d)"
RUNTIME_DIR="$(mktemp -d "${MONDAY_DIR}/runtime-artifacts/test-handoff-bundle-doctor.XXXXXX")"
trap 'rm -rf "${TMP_DIR}" "${RUNTIME_DIR}"' EXIT

VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION_SIDECAR="${TMP_DIR}/operator-handoff-bundle-validation-sidecar.json"
HANDOFF_BUNDLE_READINESS_SIDECAR="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"
PREVIEW="${RUNTIME_DIR}/preview.json"
DISPLAY_PACKET="${RUNTIME_DIR}/display-packet.json"
ARTIFACT="${RUNTIME_DIR}/artifact.json"
REPORT="${TMP_DIR}/doctor-report.txt"
VALIDATION_REPORT="${TMP_DIR}/handoff-bundle-validation.json"
READINESS_REPORT="${TMP_DIR}/handoff-bundle-readiness.json"
READINESS_VALIDATION_REPORT="${TMP_DIR}/handoff-bundle-readiness-validation.json"
BROKEN_BUNDLE="${TMP_DIR}/broken-bundle.json"
BROKEN_OUTPUT="${TMP_DIR}/doctor-broken.txt"

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
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-doctor.source/wrapper.json",
  "source_artifact_kind": "local_outbox_envelope",
  "source_priority_path": "payload.metadata.priority_summary_markdown",
  "preview_state": "present",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
  "priority_headline": "Doctor bundle headline.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "priority_summary_markdown": "## Priority\n- headline: Doctor bundle headline.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`"
}
JSON

cat >"${DISPLAY_PACKET}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:02Z",
  "input_kind": "artifact",
  "input_ref": "runtime-artifacts/test-handoff-bundle-doctor/artifact.json",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-doctor.source/wrapper.json",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "preview_source_artifact_kind": "local_outbox_envelope",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
  "priority_headline": "Doctor bundle headline.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "priority_summary_markdown": "## Priority\n- headline: Doctor bundle headline.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`",
  "display_title": "Doctor bundle headline.",
  "cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "display_markdown": "## Priority\n- headline: Doctor bundle headline.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`"
}
JSON

cat >"${ARTIFACT}" <<JSON
{
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET}")"
}
JSON

python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT}" \
  --bundle-validation-output "${VALIDATION_REPORT}" \
  --readiness-output "${READINESS_REPORT}" \
  --readiness-validation-output "${READINESS_VALIDATION_REPORT}" >"${REPORT}"

grep -q "source kind: artifact" "${REPORT}"
grep -q "bundle validation verdict: pass" "${REPORT}"
grep -q "readiness status: ready" "${REPORT}"
grep -q "ready: True" "${REPORT}"
grep -q "handoff bundle path: ${HANDOFF_BUNDLE}" "${REPORT}"
grep -q "handoff bundle validation path: ${HANDOFF_BUNDLE_VALIDATION_SIDECAR}" "${REPORT}"
grep -q "handoff bundle readiness path: ${HANDOFF_BUNDLE_READINESS_SIDECAR}" "${REPORT}"
grep -q "handoff bundle readiness validation path: ${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}" "${REPORT}"
grep -q "priority headline: Doctor bundle headline." "${REPORT}"
grep -q "display cta command: python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass" "${REPORT}"
grep -q "next step: none" "${REPORT}"

python3 - <<'PY' "${VALIDATION_REPORT}" "${READINESS_REPORT}" "${READINESS_VALIDATION_REPORT}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION_SIDECAR}" "${HANDOFF_BUNDLE_READINESS_SIDECAR}" "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}"
import json
import sys
from pathlib import Path
validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
readiness = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
readiness_validation = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
handoff_bundle = Path(sys.argv[4]).resolve()
handoff_bundle_validation = Path(sys.argv[5]).resolve()
handoff_bundle_readiness = Path(sys.argv[6]).resolve()
handoff_bundle_readiness_validation = Path(sys.argv[7]).resolve()
assert validation["verdict"] == "pass", validation
assert validation["display_title"] == "Doctor bundle headline.", validation
assert Path(validation["operator_handoff_bundle_path"]).resolve() == handoff_bundle, validation
assert Path(validation["operator_handoff_bundle_validation_path"]).resolve() == handoff_bundle_validation, validation
assert Path(validation["operator_handoff_bundle_readiness_path"]).resolve() == handoff_bundle_readiness, validation
assert Path(validation["operator_handoff_bundle_readiness_validation_path"]).resolve() == handoff_bundle_readiness_validation, validation
assert readiness["ready"] is True, readiness
assert readiness["readiness_status"] == "ready", readiness
assert Path(readiness["operator_handoff_bundle_path"]).resolve() == handoff_bundle, readiness
assert Path(readiness["operator_handoff_bundle_validation_path"]).resolve() == handoff_bundle_validation, readiness
assert Path(readiness["operator_handoff_bundle_readiness_path"]).resolve() == handoff_bundle_readiness, readiness
assert Path(readiness["operator_handoff_bundle_readiness_validation_path"]).resolve() == handoff_bundle_readiness_validation, readiness
assert readiness_validation["verdict"] == "pass", readiness_validation
PY

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT}" \
  --output "${BROKEN_BUNDLE}" >/dev/null

python3 - <<'PY' "${BROKEN_BUNDLE}"
import json
import sys
from pathlib import Path
path = Path(sys.argv[1])
doc = json.loads(path.read_text(encoding="utf-8"))
doc["priority_display_packet"]["display_title"] = "Broken bundle headline."
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/doctor_supervisor_operator_handoff_bundle.py" \
  --bundle-file "${BROKEN_BUNDLE}" \
  --require-pass >"${BROKEN_OUTPUT}" 2>&1; then
  echo "expected doctor to fail on broken bundle" >&2
  exit 1
fi

grep -q "bundle validation verdict: fail" "${BROKEN_OUTPUT}"
grep -q "readiness status: blocked" "${BROKEN_OUTPUT}"
grep -q "next step: python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py --bundle-file ${BROKEN_BUNDLE} --output <handoff-bundle-validation.json> --strict" "${BROKEN_OUTPUT}"

echo "doctor supervisor operator handoff bundle ok"
