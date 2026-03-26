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
STATUS_BUNDLE="${TMP_DIR}/projection-status-bundle.json"
STATUS_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-validation.json"
STATUS_BUNDLE_STATUS="${TMP_DIR}/projection-status-bundle-status.json"
STATUS_BUNDLE_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-validation.json"
RESOLVED_BUNDLE="${TMP_DIR}/projection-status-bundle-status-bundle.json"
RESOLVED_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-validation.json"
RESOLVED_BUNDLE_STATUS="${TMP_DIR}/projection-status-bundle-status-bundle-status.json"
RESOLVED_BUNDLE_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-validation.json"
NEXT_BUNDLE="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle.json"
NEXT_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-validation.json"
NEXT_STATUS="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status.json"
NEXT_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-validation.json"
OUTER_BUNDLE="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle.json"
OUTER_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
OUTER_STATUS="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
OUTER_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
NEW_BUNDLE="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
NEW_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
NEW_STATUS="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
NEW_STATUS_VALIDATION="${TMP_DIR}/projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
INVALID_STATUS="${TMP_DIR}/invalid-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
INVALID_STATUS_VALIDATION="${TMP_DIR}/invalid-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T15:10:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T15:10:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T15:10:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T15:10:03Z","evidenceBundlePath":"${EVIDENCE}"}
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
  --bundle-output "${STATUS_BUNDLE}" \
  --bundle-validation-output "${STATUS_BUNDLE_VALIDATION}" \
  --status-output "${STATUS_BUNDLE_STATUS}" \
  --status-validation-output "${STATUS_BUNDLE_STATUS_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py" \
  --artifact-file "${STATUS_BUNDLE_STATUS}" \
  --bundle-output "${RESOLVED_BUNDLE}" \
  --bundle-validation-output "${RESOLVED_BUNDLE_VALIDATION}" \
  --status-output "${RESOLVED_BUNDLE_STATUS}" \
  --status-validation-output "${RESOLVED_BUNDLE_STATUS_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${RESOLVED_BUNDLE_STATUS}" \
  --bundle-output "${NEXT_BUNDLE}" \
  --bundle-validation-output "${NEXT_BUNDLE_VALIDATION}" \
  --status-output "${NEXT_STATUS}" \
  --status-validation-output "${NEXT_STATUS_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${NEXT_STATUS}" \
  --bundle-output "${OUTER_BUNDLE}" \
  --bundle-validation-output "${OUTER_BUNDLE_VALIDATION}" \
  --status-output "${OUTER_STATUS}" \
  --status-validation-output "${OUTER_STATUS_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
  --artifact-file "${OUTER_STATUS}" \
  --bundle-output "${NEW_BUNDLE}" \
  --bundle-validation-output "${NEW_BUNDLE_VALIDATION}" \
  --status-output "${NEW_STATUS}" \
  --status-validation-output "${NEW_STATUS_VALIDATION}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "${NEW_STATUS}" \
  --output "${NEW_STATUS_VALIDATION}" \
  --schema-file "${SCHEMA_PATH}" \
  --strict >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${NEW_STATUS}" "${NEW_STATUS_VALIDATION}" "${SCHEMA_PATH}" "${NEW_BUNDLE}" "${NEW_BUNDLE_VALIDATION}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
status_path = Path(sys.argv[2])
report_path = Path(sys.argv[3])
schema_path = Path(sys.argv[4])
bundle_path = Path(sys.argv[5])
bundle_validation_path = Path(sys.argv[6])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_monday_agent_harness_projection as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(json.loads(status_path.read_text(encoding="utf-8")), schema)
assert not errors, errors
assert report["bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_path"] == str(status_path.resolve()), report
assert report["bundle_path"] == str(bundle_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["status_ready"] is True, report
assert report["status_next_step"] == "none", report
assert report["status_verdict"] == "pass", report
assert report["status_validation_verdict"] == "pass", report
assert report["bundle_status_verdict"] == "pass", report
assert report["bundle_status_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
assert report["bundle_validation_output_path"] == str(bundle_validation_path.resolve()), report
PY

python3 - <<'PY' "${NEW_STATUS}" "${INVALID_STATUS}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "custom remediation"
doc["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] = str(
    Path(sys.argv[2]).with_name("wrong-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json").resolve()
)
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
  --status-file "${INVALID_STATUS}" \
  --output "${INVALID_STATUS_VALIDATION}" \
  --schema-file "${SCHEMA_PATH}" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid monday harness projection status bundle status bundle status bundle status bundle status bundle status" >&2
  exit 1
fi

python3 - <<'PY' "${INVALID_STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path must match bundle_path" in item for item in report["errors"]), report
assert any("ready must be false when verdict=fail" in item or "verdict must match propagated monday projection status-bundle-status-bundle-status-bundle-status-bundle-status-bundle aggregation" in item for item in report["errors"]), report
PY

echo "validate monday agent harness projection status bundle status bundle status bundle status bundle status bundle status contract ok"
