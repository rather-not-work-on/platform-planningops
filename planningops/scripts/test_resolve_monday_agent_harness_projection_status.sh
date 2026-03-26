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
STATUS_BUNDLE="${TMP_DIR}/projection-status-bundle.json"
STATUS_BUNDLE_FROM_VALIDATION="${TMP_DIR}/projection-status-bundle-from-validation.json"
STATUS_BUNDLE_SCHEMA="${ROOT_DIR}/planningops/schemas/monday-agent-harness-projection-status-bundle.schema.json"
BROKEN_STATUS="${TMP_DIR}/broken-status.json"
BROKEN_STATUS_VALIDATION="${TMP_DIR}/broken-status-validation.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T10:30:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T10:30:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T10:30:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T10:30:03Z","evidenceBundlePath":"${EVIDENCE}"}
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

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection_status.py" \
  --artifact-file "${STATUS}" \
  --output "${STATUS_BUNDLE}" >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection_status.py" \
  --status-validation-file "${STATUS_VALIDATION}" \
  --output "${STATUS_BUNDLE_FROM_VALIDATION}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${STATUS_BUNDLE}" "${STATUS_BUNDLE_FROM_VALIDATION}" "${STATUS_BUNDLE_SCHEMA}" "${STATUS}" "${STATUS_VALIDATION}" "${BUNDLE}" "${VALIDATION}"
import json
import sys
from pathlib import Path

root_dir = Path(sys.argv[1])
bundle_path = Path(sys.argv[2])
validation_bundle_path = Path(sys.argv[3])
schema_path = Path(sys.argv[4])
status_path = Path(sys.argv[5])
status_validation_path = Path(sys.argv[6])
projection_bundle_path = Path(sys.argv[7])
validation_path = Path(sys.argv[8])

sys.path.insert(0, str(root_dir / "planningops/scripts"))
import validate_monday_agent_harness_projection as mod

bundle = json.loads(bundle_path.read_text(encoding="utf-8"))
validation_bundle = json.loads(validation_bundle_path.read_text(encoding="utf-8"))
schema = json.loads(schema_path.read_text(encoding="utf-8"))

errors = mod.validate_schema(bundle, schema)
assert not errors, errors
errors = mod.validate_schema(validation_bundle, schema)
assert not errors, errors

assert bundle["status_path"] == str(status_path.resolve()), bundle
assert bundle["status_validation_path"] == str(status_validation_path.resolve()), bundle
assert bundle["bundle_path"] == str(projection_bundle_path.resolve()), bundle
assert bundle["validation_report_path"] == str(validation_path.resolve()), bundle
assert bundle["projection_validation_verdict"] == "pass", bundle
assert bundle["projection_validation_state"] == "fresh", bundle
assert bundle["status_sidecar_validation_verdict"] == "pass", bundle
assert bundle["ready"] is True, bundle
assert bundle["next_step"] == "none", bundle
assert bundle["resolved_status_bundle_path"] == str(bundle_path.resolve()), bundle
assert validation_bundle["resolved_status_bundle_path"] == str(validation_bundle_path.resolve()), validation_bundle

bundle_without_output = dict(bundle)
bundle_without_output.pop("resolved_status_bundle_path")
validation_bundle_without_output = dict(validation_bundle)
validation_bundle_without_output.pop("resolved_status_bundle_path")
assert bundle_without_output == validation_bundle_without_output, (bundle_without_output, validation_bundle_without_output)
PY

python3 - <<'PY' "${STATUS}" "${BROKEN_STATUS}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["status_validation_output_path"] = str(Path(sys.argv[2]).with_name("missing-status-validation.json").resolve())
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection_status.py" \
  --artifact-file "${BROKEN_STATUS}" >/dev/null 2>&1; then
  echo "expected monday harness projection status resolver to fail on mismatched status_validation_output_path" >&2
  exit 1
fi

python3 - <<'PY' "${STATUS_VALIDATION}" "${BROKEN_STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["status_output_path"] = str(Path(sys.argv[2]).with_name("missing-status.json").resolve())
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection_status.py" \
  --status-validation-file "${BROKEN_STATUS_VALIDATION}" >/dev/null 2>&1; then
  echo "expected monday harness projection status resolver to fail on mismatched status_output_path" >&2
  exit 1
fi

python3 - <<'PY' "${STATUS_VALIDATION}" "${BROKEN_STATUS_VALIDATION}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["status_next_step"] = "force drift"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection_status.py" \
  --status-validation-file "${BROKEN_STATUS_VALIDATION}" >/dev/null 2>&1; then
  echo "expected monday harness projection status resolver to fail on mismatched status_next_step" >&2
  exit 1
fi

echo "resolve monday agent harness projection status ok"
