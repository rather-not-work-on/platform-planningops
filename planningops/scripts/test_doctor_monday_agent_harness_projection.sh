#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
OUTPUT_READY="${TMP_DIR}/doctor-ready.txt"
OUTPUT_BLOCKED="${TMP_DIR}/doctor-blocked.txt"
REPORT_READY="${TMP_DIR}/doctor-ready-validation.json"
BUNDLE="${TMP_DIR}/projection-bundle.json"
STATUS="${TMP_DIR}/projection-status.json"
STATUS_VALIDATION="${TMP_DIR}/projection-status-validation.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T07:10:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T07:10:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T07:10:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T07:10:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

touch "${PROJECTION_ROOT}/._completion-summary.json"
touch "${PROJECTION_ROOT}/._projection-noise.json"

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BUNDLE}" \
  --output "${REPORT_READY}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --require-pass >"${OUTPUT_READY}"

test -f "${BUNDLE}"
test -f "${STATUS}"
test -f "${STATUS_VALIDATION}"
grep -q "bundle path:" "${OUTPUT_READY}"
grep -q "run id: mh60-run" "${OUTPUT_READY}"
grep -q "readiness status: ready" "${OUTPUT_READY}"
grep -q "ready: True" "${OUTPUT_READY}"
grep -q "handoff status: not_required" "${OUTPUT_READY}"
grep -q "projection status validation verdict: pass" "${OUTPUT_READY}"
grep -q "next step: none" "${OUTPUT_READY}"

python3 - <<'PY' "${REPORT_READY}" "${BUNDLE}" "${STATUS}" "${STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert Path(report["bundle_path"]).resolve() == Path(sys.argv[2]).resolve(), report
status = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
assert Path(status["bundle_path"]).resolve() == Path(sys.argv[2]).resolve(), status
assert status["ready"] is True, status
status_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
assert status_validation["verdict"] == "pass", status_validation
PY

python3 - <<'PY' "${PROJECTION_ROOT}/completion-summary.json" "${PROJECTION_ROOT}/readiness-projection.json" "${PROJECTION_ROOT}/verification-projection.json" "${PROJECTION_ROOT}/operator-handoff-summary.json"
import json
import sys
from pathlib import Path

completion = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
readiness = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
verification = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
handoff = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

completion["finalStatus"] = "blocked"
completion["verificationVerdict"] = "blocked_fail"
readiness["readinessStatus"] = "blocked"
readiness["reason"] = "blocked_dependency"
readiness["verificationVerdict"] = "blocked_fail"
readiness["blockingConditions"] = ["blocked_dependency"]
verification["verificationVerdict"] = "blocked_fail"
verification["verificationReportRefs"] = [completion["evidenceBundlePath"], "failed-check:dependency-health"]
verification["failedChecks"] = ["failed-check:dependency-health"]
handoff["finalStatus"] = "blocked"
handoff["verificationVerdict"] = "blocked_fail"
handoff["handoffStatus"] = "required"
handoff["handoffReason"] = "blocked_dependency"
handoff["nextRequiredActor"] = "operator"
handoff["recommendedNextStep"] = "restore the blocked runtime dependency and rerun verification"
Path(sys.argv[1]).write_text(json.dumps(completion, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[2]).write_text(json.dumps(readiness, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[3]).write_text(json.dumps(verification, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[4]).write_text(json.dumps(handoff, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BUNDLE}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" >"${OUTPUT_BLOCKED}"

grep -q "readiness status: blocked" "${OUTPUT_BLOCKED}"
grep -q "ready: False" "${OUTPUT_BLOCKED}"
grep -q "next required actor: operator" "${OUTPUT_BLOCKED}"
grep -q "projection status validation verdict: pass" "${OUTPUT_BLOCKED}"
grep -q "next step: restore the blocked runtime dependency and rerun verification" "${OUTPUT_BLOCKED}"

if python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${BUNDLE}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --require-pass >/dev/null 2>&1; then
  echo "expected doctor --require-pass to fail when readiness is blocked" >&2
  exit 1
fi

echo "doctor monday agent harness projection ok"
