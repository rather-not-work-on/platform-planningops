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
GATE_BUNDLE="${TMP_DIR}/projection-status-bundle.json"
GATE_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-validation.json"
GATE_STATUS="${TMP_DIR}/projection-status-bundle-status.json"
GATE_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-validation.json"
BROKEN_BUNDLE="${TMP_DIR}/broken-status-bundle.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T09:20:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T09:20:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T09:20:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T09:20:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BASE_BUNDLE}" \
  --output "${BASE_REPORT}" \
  --status-output "${BASE_STATUS}" \
  --status-validation-output "${BASE_STATUS_VALIDATION}" \
  --require-pass >/dev/null

bash "${ROOT_DIR}/planningops/scripts/gate_monday_agent_harness_projection_status_bundle.sh" \
  --artifact-file "${BASE_STATUS}" \
  --bundle-output "${GATE_BUNDLE}" \
  --bundle-validation-output "${GATE_BUNDLE_VALIDATION}" \
  --status-output "${GATE_STATUS}" \
  --status-validation-output "${GATE_STATUS_VALIDATION}" >/dev/null

python3 - <<'PY' "${GATE_BUNDLE}" "${GATE_BUNDLE_VALIDATION}" "${BASE_STATUS}" "${BASE_STATUS_VALIDATION}" "${GATE_STATUS}" "${GATE_STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
doctor_status = json.loads(Path(sys.argv[5]).read_text(encoding="utf-8"))
doctor_status_validation = json.loads(Path(sys.argv[6]).read_text(encoding="utf-8"))

assert bundle["resolved_status_bundle_path"] == str(Path(sys.argv[1]).resolve()), bundle
assert bundle["status_path"] == str(Path(sys.argv[3]).resolve()), bundle
assert bundle["status_validation_path"] == str(Path(sys.argv[4]).resolve()), bundle
assert bundle["ready"] is True, bundle
assert validation["status_bundle_path"] == str(Path(sys.argv[1]).resolve()), validation
assert validation["verdict"] == "pass", validation
assert doctor_status["verdict"] == "pass", doctor_status
assert doctor_status["bundle_status_output_path"] == str(Path(sys.argv[5]).resolve()), doctor_status
assert doctor_status_validation["verdict"] == "pass", doctor_status_validation
PY

python3 - <<'PY' "${GATE_BUNDLE}" "${BROKEN_BUNDLE}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["status_sidecar_validation_verdict"] = "fail"
doc["next_step"] = "rerun monday projection doctor"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if bash "${ROOT_DIR}/planningops/scripts/gate_monday_agent_harness_projection_status_bundle.sh" \
  --bundle-file "${BROKEN_BUNDLE}" \
  --bundle-validation-output "${GATE_BUNDLE_VALIDATION}" \
  --status-output "${GATE_STATUS}" \
  --status-validation-output "${GATE_STATUS_VALIDATION}" >/dev/null 2>&1; then
  echo "expected monday projection status-bundle gate to fail on broken bundle" >&2
  exit 1
fi

echo "gate monday agent harness projection status bundle ok"
