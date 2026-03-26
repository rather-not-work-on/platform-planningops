#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
OUTPUT_READY="${TMP_DIR}/projection-ready-validation.json"
OUTPUT_READY_FROM_BUNDLE="${TMP_DIR}/projection-ready-from-bundle-validation.json"
OUTPUT_BLOCKED="${TMP_DIR}/projection-blocked-validation.json"
OUTPUT_BROKEN="${TMP_DIR}/projection-broken-validation.json"
BUNDLE="${TMP_DIR}/projection-bundle.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{
  "schemaVersion": 1,
  "missionId": "mh60-mission",
  "runId": "mh60-run",
  "sessionId": "mh60-session",
  "finalPhase": "publish_evidence",
  "finalStatus": "succeeded",
  "verificationVerdict": "pass",
  "completedAtUtc": "2026-03-23T07:00:00Z",
  "evidenceBundlePath": "${EVIDENCE}"
}
JSON

cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{
  "schemaVersion": 1,
  "missionId": "mh60-mission",
  "runId": "mh60-run",
  "sessionId": "mh60-session",
  "readinessStatus": "ready",
  "reason": "verification_passed",
  "verificationVerdict": "pass",
  "blockingConditions": [],
  "requiredEvidenceRefs": ["${EVIDENCE}"],
  "generatedAtUtc": "2026-03-23T07:00:01Z",
  "evidenceBundlePath": "${EVIDENCE}"
}
JSON

cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{
  "schemaVersion": 1,
  "missionId": "mh60-mission",
  "runId": "mh60-run",
  "sessionId": "mh60-session",
  "verificationVerdict": "pass",
  "verificationReportRefs": ["${EVIDENCE}", "check:contract"],
  "failedChecks": [],
  "repairAttempts": 1,
  "generatedAtUtc": "2026-03-23T07:00:02Z",
  "evidenceBundlePath": "${EVIDENCE}"
}
JSON

cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{
  "schemaVersion": 1,
  "missionId": "mh60-mission",
  "runId": "mh60-run",
  "sessionId": "mh60-session",
  "finalStatus": "succeeded",
  "verificationVerdict": "pass",
  "handoffStatus": "not_required",
  "handoffReason": "none",
  "nextRequiredActor": "none",
  "recommendedNextStep": "none",
  "blockingQuestionSet": [],
  "generatedAtUtc": "2026-03-23T07:00:03Z",
  "evidenceBundlePath": "${EVIDENCE}"
}
JSON

touch "${PROJECTION_ROOT}/._completion-summary.json"
touch "${PROJECTION_ROOT}/._projection-noise.json"

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${OUTPUT_READY}" \
  --strict >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection.py" \
  --bundle-file "${BUNDLE}" \
  --output "${OUTPUT_READY_FROM_BUNDLE}" \
  --strict >/dev/null

python3 - <<'PY' "${OUTPUT_READY}" "${OUTPUT_READY_FROM_BUNDLE}" "${BUNDLE}"
import json
import sys
from pathlib import Path

root_report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
bundle_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert root_report["verdict"] == "pass", root_report
assert root_report["ready"] is True, root_report
assert root_report["readiness_status"] == "ready", root_report
assert root_report["next_step"] == "none", root_report
assert bundle_report["verdict"] == "pass", bundle_report
assert bundle_report["ready"] is True, bundle_report
assert bundle_report["readiness_status"] == "ready", bundle_report
assert Path(bundle_report["bundle_path"]).resolve() == Path(sys.argv[3]).resolve(), bundle_report
assert bundle_report["next_step"] == "none", bundle_report
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
readiness["reason"] = "missing_question_set"
readiness["verificationVerdict"] = "blocked_fail"
readiness["blockingConditions"] = ["missing_question_set"]
verification["verificationVerdict"] = "blocked_fail"
verification["verificationReportRefs"] = [completion["evidenceBundlePath"], "question:owner"]
handoff["finalStatus"] = "blocked"
handoff["verificationVerdict"] = "blocked_fail"
handoff["handoffStatus"] = "required"
handoff["handoffReason"] = "missing_question_set"
handoff["nextRequiredActor"] = "user"
handoff["recommendedNextStep"] = "answer the blocking question set and rerun verification"
handoff["blockingQuestionSet"] = ["question:owner"]

Path(sys.argv[1]).write_text(json.dumps(completion, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[2]).write_text(json.dumps(readiness, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[3]).write_text(json.dumps(verification, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[4]).write_text(json.dumps(handoff, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${OUTPUT_BLOCKED}" \
  --strict >/dev/null

python3 - <<'PY' "${OUTPUT_BLOCKED}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["ready"] is False, report
assert report["readiness_status"] == "blocked", report
assert report["next_required_actor"] == "user", report
assert report["next_step"] == "answer the blocking question set and rerun verification", report
PY

python3 - <<'PY' "${PROJECTION_ROOT}/readiness-projection.json" "${PROJECTION_ROOT}/operator-handoff-summary.json"
import json
import sys
from pathlib import Path

readiness = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
handoff = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
readiness["readinessStatus"] = "ready"
readiness["blockingConditions"] = []
handoff["handoffStatus"] = "required"
handoff["nextRequiredActor"] = "operator"
handoff["recommendedNextStep"] = "force contradiction"
Path(sys.argv[1]).write_text(json.dumps(readiness, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
Path(sys.argv[2]).write_text(json.dumps(handoff, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${OUTPUT_BROKEN}" \
  --strict >/dev/null 2>&1; then
  echo "expected monday projection validator to fail on readiness/handoff contradiction" >&2
  exit 1
fi

python3 - <<'PY' "${OUTPUT_BROKEN}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("readinessStatus=ready requires handoffStatus=not_required" in error for error in report["errors"]), report
PY

echo "validate monday agent harness projection ok"
