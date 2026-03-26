#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
PROJECTION_BUNDLE="${TMP_DIR}/projection-bundle.json"
PROJECTION_VALIDATION="${TMP_DIR}/projection-validation.json"
STATUS="${TMP_DIR}/projection-status.json"
STATUS_VALIDATION="${TMP_DIR}/projection-status-validation.json"
STATUS_BUNDLE="${TMP_DIR}/projection-status-bundle.json"
STATUS_BUNDLE_VALIDATION="${TMP_DIR}/projection-status-bundle-validation.json"
SCHEMA_PATH="${ROOT_DIR}/planningops/schemas/monday-agent-harness-projection-status-bundle-validation.schema.json"
INVALID_BUNDLE="${TMP_DIR}/invalid-status-bundle.json"
INVALID_BUNDLE_VALIDATION="${TMP_DIR}/invalid-status-bundle-validation.json"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T11:00:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T11:00:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T11:00:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T11:00:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${PROJECTION_BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --bundle-output "${PROJECTION_BUNDLE}" \
  --output "${PROJECTION_VALIDATION}" \
  --status-output "${STATUS}" \
  --status-validation-output "${STATUS_VALIDATION}" \
  --require-pass >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection_status.py" \
  --artifact-file "${STATUS}" \
  --output "${STATUS_BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection_status_bundle.py" \
  --bundle-file "${STATUS_BUNDLE}" \
  --output "${STATUS_BUNDLE_VALIDATION}" \
  --strict

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE_VALIDATION}" "${SCHEMA_PATH}" "${STATUS_BUNDLE}" "${PROJECTION_BUNDLE}" "${PROJECTION_VALIDATION}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
report_path = Path(sys.argv[2])
schema_path = Path(sys.argv[3])
bundle_path = Path(sys.argv[4])
projection_bundle_path = Path(sys.argv[5])
projection_validation_path = Path(sys.argv[6])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_monday_agent_harness_projection as mod

report = json.loads(report_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))
errors = mod.validate_schema(report, schema)
assert not errors, errors
assert report["status_bundle_path"] == str(bundle_path.resolve()), report
assert report["projection_bundle_path"] == str(projection_bundle_path.resolve()), report
assert report["projection_validation_report_path"] == str(projection_validation_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["bundle_ready"] is True, report
assert report["bundle_next_step"] == "none", report
assert report["projection_validation_verdict"] == "pass", report
assert report["projection_validation_state"] == "fresh", report
assert report["status_sidecar_validation_verdict"] == "pass", report
assert report["resolved_status_bundle_path"] == str(bundle_path.resolve()), report
PY

python3 - <<'PY' "${STATUS_BUNDLE}" "${INVALID_BUNDLE}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = False
doc["next_step"] = "custom remediation"
doc["resolved_status_bundle_path"] = str(Path(sys.argv[2]).with_name("wrong-status-bundle.json").resolve())
doc["status_validation_report"]["status_output_path"] = str(Path(sys.argv[2]).with_name("wrong-status.json").resolve())
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection_status_bundle.py" \
  --bundle-file "${INVALID_BUNDLE}" \
  --output "${INVALID_BUNDLE_VALIDATION}" \
  --strict
rc=$?
set -e

if [[ "${rc}" -eq 0 ]]; then
  echo "expected strict failure for invalid monday harness projection status bundle"
  exit 1
fi

python3 - <<'PY' "${INVALID_BUNDLE_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("resolved_status_bundle_path must match the validated bundle file path" in item for item in report["errors"]), report
assert any("ready must match status_report.ready" in item for item in report["errors"]), report
assert any("next_step must match status_report.next_step" in item for item in report["errors"]), report
assert any("status_validation_report.status_output_path must match status_path" in item for item in report["errors"]), report
assert any("bundle must match canonical monday harness projection status bundle resolution" in item for item in report["errors"]), report
PY

echo "validate monday agent harness projection status bundle validation contract ok"
