#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

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
STATUS_SCHEMA="${ROOT_DIR}/planningops/schemas/monday-agent-harness-projection-status-bundle-status.schema.json"

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
  --status-validation-output "${DOCTOR_STATUS_VALIDATION}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${DOCTOR_STATUS}" "${STATUS_SCHEMA}" "${RESOLVED_BUNDLE}" "${RESOLVED_BUNDLE_VALIDATION}" "${DOCTOR_STATUS_VALIDATION}"
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
assert report["bundle_path"] == str(bundle_path.resolve()), report
assert report["resolved_status_bundle_path"] == str(bundle_path.resolve()), report
assert report["bundle_status_output_path"] == str(status_path.resolve()), report
assert report["bundle_status_validation_output_path"] == str(status_validation_path.resolve()), report
assert report["bundle_validation_output_path"] == str(bundle_validation_path.resolve()), report
assert report["verdict"] == "pass", report
assert report["ready"] is True, report
assert report["next_step"] == "none", report
assert report["projection_validation_verdict"] == "pass", report
assert report["projection_validation_state"] == "fresh", report
assert report["status_sidecar_validation_verdict"] == "pass", report
assert report["bundle_validation_verdict"] == "pass", report
PY

python3 - <<'PY' "${DOCTOR_STATUS}" "${TMP_DIR}/invalid-status.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = "yes"
doc["next_step"] = 3
doc["bundle_validation_verdict"] = "maybe"
doc.pop("projection_bundle_path")
doc.pop("bundle_status_output_path")
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "${ROOT_DIR}" "${TMP_DIR}/invalid-status.json" "${STATUS_SCHEMA}"
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
assert any("$.projection_bundle_path is required" in item for item in errors), errors
assert any("$.bundle_status_output_path is required" in item for item in errors), errors
PY

echo "validate monday agent harness projection status bundle status contract ok"
