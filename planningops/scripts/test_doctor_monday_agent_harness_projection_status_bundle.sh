#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
BASE_REPORT="${TMP_DIR}/projection-validation.json"
BASE_BUNDLE="${TMP_DIR}/projection-bundle.json"
BASE_STATUS="${TMP_DIR}/projection-status.json"
BASE_STATUS_VALIDATION="${TMP_DIR}/projection-status-validation.json"
RESOLVED_BUNDLE="${TMP_DIR}/projection-status-bundle.json"
RESOLVED_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-validation.json"
DOCTOR_STATUS="${TMP_DIR}/projection-status-bundle-status.json"
DOCTOR_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-validation.json"
REPORT_READY="${TMP_DIR}/doctor-status-bundle.txt"
BROKEN_BUNDLE="${TMP_DIR}/broken-status-bundle.json"
REPORT_BROKEN="${TMP_DIR}/doctor-status-bundle-broken.txt"
RESOLVED_BUNDLE_REAL="$(python3 - <<'PY' "${RESOLVED_BUNDLE}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
RESOLVED_BUNDLE_VALIDATION_REAL="$(python3 - <<'PY' "${RESOLVED_BUNDLE_VALIDATION}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_REAL="$(python3 - <<'PY' "${DOCTOR_STATUS}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
DOCTOR_STATUS_VALIDATION_REAL="$(python3 - <<'PY' "${DOCTOR_STATUS_VALIDATION}"
from pathlib import Path
import sys

print(Path(sys.argv[1]).resolve())
PY
)"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T09:10:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T09:10:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T09:10:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T09:10:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BASE_BUNDLE}" \
  --output "${BASE_REPORT}" \
  --status-output "${BASE_STATUS}" \
  --status-validation-output "${BASE_STATUS_VALIDATION}" \
  --require-pass >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py" \
  --artifact-file "${BASE_STATUS}" \
  --bundle-output "${RESOLVED_BUNDLE}" \
  --bundle-validation-output "${RESOLVED_BUNDLE_VALIDATION}" \
  --status-output "${DOCTOR_STATUS}" \
  --status-validation-output "${DOCTOR_STATUS_VALIDATION}" >"${REPORT_READY}"

grep -q "source kind: artifact" "${REPORT_READY}"
grep -q "bundle path: ${RESOLVED_BUNDLE_REAL}" "${REPORT_READY}"
grep -q "bundle validation output path: ${RESOLVED_BUNDLE_VALIDATION_REAL}" "${REPORT_READY}"
grep -q "bundle status output path: ${DOCTOR_STATUS_REAL}" "${REPORT_READY}"
grep -q "bundle status validation verdict: pass" "${REPORT_READY}"
grep -q "bundle status validation output path: ${DOCTOR_STATUS_VALIDATION_REAL}" "${REPORT_READY}"
grep -q "run id: mh60-run" "${REPORT_READY}"
grep -q "ready: True" "${REPORT_READY}"
grep -q "projection validation verdict: pass" "${REPORT_READY}"
grep -q "projection validation state: fresh" "${REPORT_READY}"
grep -q "status sidecar validation verdict: pass" "${REPORT_READY}"
grep -q "bundle validation verdict: pass" "${REPORT_READY}"
grep -q "doctor verdict: pass" "${REPORT_READY}"
grep -q "next step: none" "${REPORT_READY}"

python3 - <<'PY' "${RESOLVED_BUNDLE}" "${RESOLVED_BUNDLE_VALIDATION}" "${BASE_STATUS}" "${BASE_STATUS_VALIDATION}" "${BASE_BUNDLE}" "${BASE_REPORT}" "${DOCTOR_STATUS}" "${DOCTOR_STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
doctor_status = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))
doctor_status_validation = json.loads(Path(sys.argv[8]).read_text(encoding="utf-8"))

assert bundle["resolved_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), bundle
assert bundle["status_path"] == str(Path(sys.argv[3]).resolve()), bundle
assert bundle["status_validation_path"] == str(Path(sys.argv[4]).resolve()), bundle
assert bundle["bundle_path"] == str(Path(sys.argv[5]).resolve()), bundle
assert bundle["validation_report_path"] == str(Path(sys.argv[6]).resolve()), bundle
assert bundle["ready"] is True, bundle
assert bundle["projection_validation_verdict"] == "pass", bundle
assert bundle["projection_validation_state"] == "fresh", bundle
assert bundle["status_sidecar_validation_verdict"] == "pass", bundle

assert validation["status_bundle_path"] == str(Path(sys.argv[1]).resolve()), validation
assert validation["output_path"] == str(Path(sys.argv[2]).resolve()), validation
assert validation["verdict"] == "pass", validation
assert validation["bundle_ready"] is True, validation

assert doctor_status["bundle_path"] == str(Path(sys.argv[1]).resolve()), doctor_status
assert doctor_status["bundle_status_output_path"] == str(Path(sys.argv[7]).resolve()), doctor_status
assert doctor_status["bundle_status_validation_output_path"] == str(Path(sys.argv[8]).resolve()), doctor_status
assert doctor_status["bundle_validation_output_path"] == str(Path(sys.argv[2]).resolve()), doctor_status
assert doctor_status["verdict"] == "pass", doctor_status
assert doctor_status["ready"] is True, doctor_status
assert doctor_status["next_step"] == "none", doctor_status

assert doctor_status_validation["bundle_status_path"] == str(Path(sys.argv[7]).resolve()), doctor_status_validation
assert doctor_status_validation["bundle_status_output_path"] == str(Path(sys.argv[7]).resolve()), doctor_status_validation
assert doctor_status_validation["bundle_status_validation_output_path"] == str(Path(sys.argv[8]).resolve()), doctor_status_validation
assert doctor_status_validation["verdict"] == "pass", doctor_status_validation
PY

python3 - <<'PY' "${RESOLVED_BUNDLE}" "${BROKEN_BUNDLE}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "inspect broken monday projection status bundle"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py" \
  --bundle-file "${BROKEN_BUNDLE}" \
  --bundle-validation-output "${RESOLVED_BUNDLE_VALIDATION}" \
  --status-output "${DOCTOR_STATUS}" \
  --status-validation-output "${DOCTOR_STATUS_VALIDATION}" \
  --require-pass >"${REPORT_BROKEN}" 2>&1; then
  echo "expected monday projection status-bundle doctor to fail on broken bundle" >&2
  exit 1
fi

grep -q "source kind: bundle" "${REPORT_BROKEN}"
grep -q "doctor verdict: fail" "${REPORT_BROKEN}"
grep -q "resolved status bundle ready is false" "${REPORT_BROKEN}"
grep -q "bundle status validation output path:" "${REPORT_BROKEN}"

echo "doctor monday agent harness projection status bundle ok"
