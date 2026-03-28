#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONDAY_DIR="$(cd "${ROOT_DIR}/../monday" && pwd)"
TMP_DIR="$(mktemp -d)"
RUNTIME_DIR="$(mktemp -d "${MONDAY_DIR}/runtime-artifacts/test-handoff-bundle-validation.XXXXXX")"
trap 'rm -rf "${TMP_DIR}" "${RUNTIME_DIR}"' EXIT

VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION="${TMP_DIR}/operator-handoff-bundle-validation-sidecar.json"
HANDOFF_BUNDLE_READINESS="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"
PREVIEW="${RUNTIME_DIR}/preview.json"
DISPLAY_PACKET="${RUNTIME_DIR}/display-packet.json"
ARTIFACT="${RUNTIME_DIR}/artifact.json"
BUNDLE="${TMP_DIR}/handoff-bundle.json"
BUNDLE_VALIDATION="${TMP_DIR}/handoff-bundle-validation.json"
CONFLICT_BUNDLE="${TMP_DIR}/handoff-bundle-conflict.json"
CONFLICT_VALIDATION="${TMP_DIR}/handoff-bundle-conflict-validation.json"

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
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-validation.source/wrapper.json",
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

cat >"${DISPLAY_PACKET}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:02Z",
  "input_kind": "artifact",
  "input_ref": "runtime-artifacts/test-handoff-bundle-validation/artifact.json",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-validation.source/wrapper.json",
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

cat >"${ARTIFACT}" <<JSON
{
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET}")"
}
JSON

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT}" \
  --output "${BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "${BUNDLE}" \
  --output "${BUNDLE_VALIDATION}" \
  --strict >/dev/null

python3 - <<'PY' "${ARTIFACT}" "${BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE_READINESS}" "${HANDOFF_BUNDLE_READINESS_VALIDATION}"
import json
import sys
from pathlib import Path

artifact = Path(sys.argv[1]).resolve()
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
handoff_bundle = Path(sys.argv[3]).resolve()
handoff_bundle_validation = Path(sys.argv[4]).resolve()
handoff_bundle_readiness = Path(sys.argv[5]).resolve()
handoff_bundle_readiness_validation = Path(sys.argv[6]).resolve()

assert report["verdict"] == "pass", report
assert Path(report["artifact_file"]).resolve() == artifact, report
assert report["operator_handoff_validation_verdict"] == "pass", report
assert Path(report["operator_handoff_bundle_path"]).resolve() == handoff_bundle, report
assert Path(report["operator_handoff_bundle_validation_path"]).resolve() == handoff_bundle_validation, report
assert Path(report["operator_handoff_bundle_readiness_path"]).resolve() == handoff_bundle_readiness, report
assert Path(report["operator_handoff_bundle_readiness_validation_path"]).resolve() == handoff_bundle_readiness_validation, report
assert report["priority_preview_state"] == "present", report
assert report["display_title"] == "Supervisor converged, but the latest federated runtime gate is blocked.", report
assert report["cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", report
assert report["error_count"] == 0, report
PY

python3 - <<'PY' "${BUNDLE}" "${CONFLICT_BUNDLE}"
import json
import sys
from pathlib import Path

source = Path(sys.argv[1])
target = Path(sys.argv[2])
doc = json.loads(source.read_text(encoding="utf-8"))
doc["priority_display_packet"]["cta_command"] = "bash planningops/scripts/gate_federated_ci_summary.sh"
target.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle.py" \
  --bundle-file "${CONFLICT_BUNDLE}" \
  --output "${CONFLICT_VALIDATION}" \
  --strict >/dev/null 2>&1; then
  echo "expected bundle validator to fail on conflicting display packet" >&2
  exit 1
fi

python3 - <<'PY' "${CONFLICT_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

assert report["verdict"] == "fail", report
assert any("priority_display_packet does not match canonical bundle resolution" in error for error in report["errors"]), report
PY

echo "validate supervisor operator handoff bundle ok"
