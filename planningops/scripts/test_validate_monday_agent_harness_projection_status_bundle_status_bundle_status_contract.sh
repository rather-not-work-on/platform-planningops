#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
BASE_BUNDLE="${TMP_DIR}/projection-bundle.json"
BASE_VALIDATION="${TMP_DIR}/projection-validation.json"
BASE_STATUS="${TMP_DIR}/projection-status.json"
BASE_STATUS_VALIDATION="${TMP_DIR}/projection-status-validation.json"
STATUS_BUNDLE="${TMP_DIR}/projection-status-bundle.json"
STATUS_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-validation.json"
STATUS_BUNDLE_STATUS="${TMP_DIR}/projection-status-bundle-status.json"
STATUS_BUNDLE_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE="${TMP_DIR}/projection-status-bundle-status-bundle.json"
STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-validation.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS="${TMP_DIR}/projection-status-bundle-status-bundle-status.json"
STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-validation.json"
STATUS_SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status.schema.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T12:10:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T12:10:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T12:10:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T12:10:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BASE_BUNDLE}" \
  --output "${BASE_VALIDATION}" \
  --status-output "${BASE_STATUS}" \
  --status-validation-output "${BASE_STATUS_VALIDATION}" \
  --require-pass >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py" \
  --artifact-file "${BASE_STATUS}" \
  --bundle-output "${STATUS_BUNDLE}" \
  --bundle-validation-output "${STATUS_BUNDLE_VALIDATION}" \
  --status-output "${STATUS_BUNDLE_STATUS}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS_BUNDLE_STATUS}" \
  --bundle-output "${STATUS_BUNDLE_STATUS_BUNDLE}" \
  --bundle-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION}" \
  --status-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS}" "${STATUS_SCHEMA_PATH}" "${STATUS_BUNDLE_STATUS_BUNDLE}" "${STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION}" "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
status_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])
bundle_path = Path(sys.argv[4])
bundle_validation_path = Path(sys.argv[5])
status_validation_path = Path(sys.argv[6])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_monday_agent_harness_projection as mod

report = json.loads(status_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["bundle_status_bundle_output_path"] == str(status_path.resolve()), report
assert report["bundle_status_bundle_validation_output_path"] == str(status_validation_path.resolve()), report
assert report["bundle_path"] == str(bundle_path.resolve()), report
assert report["resolved_status_bundle_status_bundle_path"] == str(bundle_path.resolve()), report
assert report["bundle_validation_output_path"] == str(bundle_validation_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["ready"] is True, report
assert report["next_step"] == "none", report
assert report["status_verdict"] == "pass", report
assert report["status_validation_verdict"] == "pass", report
assert report["projection_validation_verdict"] == "pass", report
assert report["projection_validation_state"] == "fresh", report
assert report["status_sidecar_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${STATUS_BUNDLE_STATUS_BUNDLE_STATUS}" "${TMP_DIR}/invalid-status-bundle-status-bundle-status.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = "yes"
doc["next_step"] = 7
doc["bundle_validation_verdict"] = "maybe"
doc.pop("bundle_status_bundle_output_path")
doc.pop("bundle_status_bundle_validation_output_path")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "${ROOT_DIR}" "${TMP_DIR}/invalid-status-bundle-status-bundle-status.json" "${STATUS_SCHEMA_PATH}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
status_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_monday_agent_harness_projection as mod

report = json.loads(status_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert errors, report
assert any("$.ready expected type boolean" in item for item in errors), errors
assert any("$.next_step expected type string" in item for item in errors), errors
assert any("$.bundle_validation_verdict invalid enum value: maybe" in item for item in errors), errors
assert any("$.bundle_status_bundle_output_path is required" in item for item in errors), errors
assert any("$.bundle_status_bundle_validation_output_path is required" in item for item in errors), errors
PY

echo "validate monday agent harness projection status bundle status bundle status contract ok"
