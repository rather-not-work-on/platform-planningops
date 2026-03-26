#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
BUNDLE="${TMP_DIR}/projection-bundle.json"
VALIDATION="${TMP_DIR}/projection-validation.json"
STATUS="${TMP_DIR}/projection-status.json"
STATUS_VALIDATION="${TMP_DIR}/projection-status-validation.json"
STATUS_VALIDATION_STALE="${TMP_DIR}/projection-status-validation-stale.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T10:10:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T10:10:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T10:10:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T10:10:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BUNDLE}" \
  --output "${VALIDATION}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --require-pass >/dev/null

python3 - <<'PY' "${STATUS}" "${STATUS_VALIDATION}" "${VALIDATION}" "${BUNDLE}"
import json
import sys
from pathlib import Path

status = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert status["ready"] is True, status
assert status["validation_verdict"] == "pass", status
assert status["validation_state"] == "fresh", status
assert Path(status["bundle_path"]).resolve() == Path(sys.argv[4]).resolve(), status
assert Path(status["validation_report_path"]).resolve() == Path(sys.argv[3]).resolve(), status
assert status_validation["verdict"] == "pass", status_validation
assert status_validation["projection_status_verdict"] == "pass", status_validation
assert status_validation["projection_validation_verdict"] == "pass", status_validation
assert status_validation["projection_validation_state"] == "fresh", status_validation
assert status_validation["status_validation_state"] == "fresh", status_validation
PY

python3 - <<'PY' "${STATUS}"
import json
import sys
from pathlib import Path

status = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
status["next_step"] = "force drift"
Path(sys.argv[1]).write_text(json.dumps(status, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection_status.py" \
  --status-file "${STATUS}" \
  --bundle-file "${BUNDLE}" \
  --validation-report "${VALIDATION}" \
  --output "${STATUS_VALIDATION_STALE}" \
  --strict >/dev/null 2>&1; then
  echo "expected monday agent harness projection status validator to fail on stale next_step" >&2
  exit 1
fi

python3 - <<'PY' "${STATUS_VALIDATION_STALE}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("next_step must match canonical monday harness projection doctor status" in error for error in report["errors"]), report
PY

echo "validate monday agent harness projection status ok"
