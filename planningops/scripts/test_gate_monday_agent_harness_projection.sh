#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
REPORT="${TMP_DIR}/gate-validation.json"
BUNDLE="${TMP_DIR}/projection-bundle.json"
STATUS="${TMP_DIR}/gate-status.json"
STATUS_VALIDATION="${TMP_DIR}/gate-status-validation.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T07:20:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T07:20:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T07:20:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T07:20:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

bash "${ROOT_DIR}/planningops/scripts/gate_monday_agent_harness_projection.sh" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BUNDLE}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --output "${REPORT}" >/dev/null

python3 - <<'PY' "${REPORT}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["ready"] is True, report
PY
test -f "${BUNDLE}"
test -f "${STATUS}"
test -f "${STATUS_VALIDATION}"

python3 - <<'PY' "${STATUS}" "${STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

status = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert status["ready"] is True, status
assert status["validation_verdict"] == "pass", status
assert status_validation["verdict"] == "pass", status_validation
PY

python3 - <<'PY' "${PROJECTION_ROOT}/readiness-projection.json" "${PROJECTION_ROOT}/operator-handoff-summary.json"
import json
import sys
from pathlib import Path

readiness = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
handoff = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
readiness["readinessStatus"] = "ready"
handoff["handoffStatus"] = "required"
handoff["nextRequiredActor"] = "operator"
handoff["recommendedNextStep"] = "force contradiction"
Path(sys.argv[1]).write_text(json.dumps(readiness, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[2]).write_text(json.dumps(handoff, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if bash "${ROOT_DIR}/planningops/scripts/gate_monday_agent_harness_projection.sh" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BUNDLE}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" >/dev/null 2>&1; then
  echo "expected monday agent harness projection gate to fail on contradictory readiness state" >&2
  exit 1
fi

echo "gate monday agent harness projection ok"
