#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONDAY_DIR="$(cd "${ROOT_DIR}/../monday" && pwd)"
TMP_DIR="$(mktemp -d)"
RUNTIME_DIR="$(mktemp -d "${MONDAY_DIR}/runtime-artifacts/test-handoff-bundle-readiness.XXXXXX")"
trap 'rm -rf "${TMP_DIR}" "${RUNTIME_DIR}"' EXIT

VALIDATION="${TMP_DIR}/operator-handoff-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION="${TMP_DIR}/operator-handoff-bundle-validation.json"
HANDOFF_BUNDLE_READINESS_SIDECAR="${TMP_DIR}/operator-handoff-bundle-readiness-sidecar.json"
HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR="${TMP_DIR}/operator-handoff-bundle-readiness-validation-sidecar.json"
PREVIEW="${RUNTIME_DIR}/preview.json"
DISPLAY_PACKET="${RUNTIME_DIR}/display-packet.json"
ARTIFACT="${RUNTIME_DIR}/artifact.json"
READINESS="${TMP_DIR}/handoff-bundle-readiness.json"
READINESS_VALIDATION="${TMP_DIR}/handoff-bundle-readiness-validation.json"
BUNDLE_VALIDATION="${TMP_DIR}/handoff-bundle-validation.json"
BUNDLE="${TMP_DIR}/handoff-bundle.json"
BROKEN_BUNDLE="${TMP_DIR}/handoff-bundle-broken.json"
BROKEN_READINESS="${TMP_DIR}/handoff-bundle-broken-readiness.json"
BROKEN_READINESS_VALIDATION="${TMP_DIR}/handoff-bundle-broken-readiness-validation.json"
BROKEN_BUNDLE_VALIDATION="${TMP_DIR}/handoff-bundle-broken-validation.json"

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
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-readiness.source/wrapper.json",
  "source_artifact_kind": "local_outbox_envelope",
  "source_priority_path": "payload.metadata.priority_summary_markdown",
  "preview_state": "present",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
  "priority_headline": "Readiness headline.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "priority_summary_markdown": "## Priority\n- headline: Readiness headline.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`"
}
JSON

cat >"${DISPLAY_PACKET}" <<JSON
{
  "generated_at_utc": "2026-03-20T00:00:02Z",
  "input_kind": "artifact",
  "input_ref": "runtime-artifacts/test-handoff-bundle-readiness/artifact.json",
  "source_artifact_ref": "runtime-artifacts/test-handoff-bundle-readiness.source/wrapper.json",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "preview_source_artifact_kind": "local_outbox_envelope",
  "operator_handoff_validation_path": "${VALIDATION}",
  "operator_handoff_bundle_path": "${HANDOFF_BUNDLE}",
  "operator_handoff_bundle_validation_path": "${HANDOFF_BUNDLE_VALIDATION}",
  "operator_handoff_bundle_readiness_path": "${HANDOFF_BUNDLE_READINESS_SIDECAR}",
  "operator_handoff_bundle_readiness_validation_path": "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}",
  "priority_headline": "Readiness headline.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "priority_summary_markdown": "## Priority\n- headline: Readiness headline.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`",
  "display_title": "Readiness headline.",
  "cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "display_markdown": "## Priority\n- headline: Readiness headline.\n- first action: \`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass\`"
}
JSON

cat >"${ARTIFACT}" <<JSON
{
  "operator_handoff_validation_path": "${VALIDATION}",
  "priority_preview_ref": "$(preview_ref "${PREVIEW}")",
  "priority_display_packet_ref": "$(preview_ref "${DISPLAY_PACKET}")"
}
JSON

python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --artifact-file "${ARTIFACT}" \
  --bundle-validation-output "${BUNDLE_VALIDATION}" \
  --output "${READINESS}" \
  --readiness-validation-output "${READINESS_VALIDATION}" \
  --strict >/dev/null

python3 - <<'PY' "${READINESS}" "${READINESS_VALIDATION}" "${BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE_READINESS_SIDECAR}" "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}"
import json
import sys
from pathlib import Path

readiness = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
bundle_validation = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
handoff_bundle = Path(sys.argv[4]).resolve()
handoff_bundle_validation = Path(sys.argv[5]).resolve()
handoff_bundle_readiness = Path(sys.argv[6]).resolve()
handoff_bundle_readiness_validation = Path(sys.argv[7]).resolve()
assert readiness["ready"] is True, readiness
assert readiness["readiness_status"] == "ready", readiness
assert readiness["blocking_reasons"] == [], readiness
assert readiness["next_step"] == "none", readiness
assert Path(readiness["validation_report_path"]).resolve() == Path(sys.argv[3]).resolve(), readiness
assert Path(readiness["operator_handoff_bundle_path"]).resolve() == handoff_bundle, readiness
assert Path(readiness["operator_handoff_bundle_validation_path"]).resolve() == handoff_bundle_validation, readiness
assert Path(readiness["operator_handoff_bundle_readiness_path"]).resolve() == handoff_bundle_readiness, readiness
assert Path(readiness["operator_handoff_bundle_readiness_validation_path"]).resolve() == handoff_bundle_readiness_validation, readiness
assert validation["verdict"] == "pass", validation
assert bundle_validation["verdict"] == "pass", bundle_validation
PY

python3 "${ROOT_DIR}/planningops/scripts/resolve_supervisor_operator_handoff_bundle.py" \
  --artifact-file "${ARTIFACT}" \
  --output "${BUNDLE}" >/dev/null

python3 - <<'PY' "${BUNDLE}" "${BROKEN_BUNDLE}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["priority_display_packet"]["display_title"] = "Broken readiness headline."
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/assess_supervisor_operator_handoff_bundle_readiness.py" \
  --bundle-file "${BROKEN_BUNDLE}" \
  --bundle-validation-output "${BROKEN_BUNDLE_VALIDATION}" \
  --output "${BROKEN_READINESS}" \
  --readiness-validation-output "${BROKEN_READINESS_VALIDATION}" \
  --strict >/dev/null
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected readiness assess to fail on broken bundle" >&2
  exit 1
fi

python3 - <<'PY' "${BROKEN_READINESS}" "${BROKEN_READINESS_VALIDATION}" "${BROKEN_BUNDLE}" "${BROKEN_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE_READINESS_SIDECAR}" "${HANDOFF_BUNDLE_READINESS_VALIDATION_SIDECAR}"
import json
import sys
from pathlib import Path

readiness = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
bundle = Path(sys.argv[3])
bundle_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
handoff_bundle = Path(sys.argv[5]).resolve()
handoff_bundle_validation = Path(sys.argv[6]).resolve()
handoff_bundle_readiness = Path(sys.argv[7]).resolve()
handoff_bundle_readiness_validation = Path(sys.argv[8]).resolve()
assert readiness["ready"] is False, readiness
assert readiness["readiness_status"] == "blocked", readiness
assert "bundle_validation_fail" in readiness["blocking_reasons"], readiness
assert readiness["next_step"].startswith("python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py --bundle-file "), readiness
assert readiness["next_step"].endswith(f"{bundle} --output <handoff-bundle-validation.json> --strict"), readiness
assert Path(readiness["validation_report_path"]).resolve() == Path(sys.argv[4]).resolve(), readiness
assert Path(readiness["operator_handoff_bundle_path"]).resolve() == handoff_bundle, readiness
assert Path(readiness["operator_handoff_bundle_validation_path"]).resolve() == handoff_bundle_validation, readiness
assert Path(readiness["operator_handoff_bundle_readiness_path"]).resolve() == handoff_bundle_readiness, readiness
assert Path(readiness["operator_handoff_bundle_readiness_validation_path"]).resolve() == handoff_bundle_readiness_validation, readiness
assert validation["verdict"] == "pass", validation
assert bundle_validation["verdict"] == "fail", bundle_validation
PY

echo "assess supervisor operator handoff bundle readiness ok"
