#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
MONDAY_DIR="${TMP_DIR}/monday"
PROJECTION_ROOT="${MONDAY_DIR}/runtime-artifacts/agent-harness"
BUNDLE="${TMP_DIR}/monday-agent-harness-projection-bundle.json"
trap 'rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${PROJECTION_ROOT}"
EVIDENCE="${PROJECTION_ROOT}/execution-evidence-bundle.json"
printf '{}\n' >"${EVIDENCE}"

cat >"${PROJECTION_ROOT}/completion-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalPhase":"publish_evidence","finalStatus":"succeeded","verificationVerdict":"pass","completedAtUtc":"2026-03-23T07:30:00Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/readiness-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","readinessStatus":"ready","reason":"verification_passed","verificationVerdict":"pass","blockingConditions":[],"requiredEvidenceRefs":["${EVIDENCE}"],"generatedAtUtc":"2026-03-23T07:30:01Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/verification-projection.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","verificationVerdict":"pass","verificationReportRefs":["${EVIDENCE}"],"failedChecks":[],"repairAttempts":0,"generatedAtUtc":"2026-03-23T07:30:02Z","evidenceBundlePath":"${EVIDENCE}"}
JSON
cat >"${PROJECTION_ROOT}/operator-handoff-summary.json" <<JSON
{"missionId":"mh60-mission","runId":"mh60-run","sessionId":"mh60-session","finalStatus":"succeeded","verificationVerdict":"pass","handoffStatus":"not_required","handoffReason":"none","nextRequiredActor":"none","recommendedNextStep":"none","blockingQuestionSet":[],"generatedAtUtc":"2026-03-23T07:30:03Z","evidenceBundlePath":"${EVIDENCE}"}
JSON

python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${BUNDLE}" >/dev/null

python3 - <<'PY' "${BUNDLE}" "${PROJECTION_ROOT}" "${EVIDENCE}"
import json
import sys
from pathlib import Path

bundle = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
projection_root = Path(sys.argv[2]).resolve()
evidence = Path(sys.argv[3]).resolve()
assert Path(bundle["bundle_path"]).resolve() == Path(sys.argv[1]).resolve(), bundle
assert Path(bundle["projection_root"]).resolve() == projection_root, bundle
assert Path(bundle["completion_summary_path"]).resolve() == projection_root / "completion-summary.json", bundle
assert Path(bundle["readiness_projection_path"]).resolve() == projection_root / "readiness-projection.json", bundle
assert Path(bundle["verification_projection_path"]).resolve() == projection_root / "verification-projection.json", bundle
assert Path(bundle["operator_handoff_summary_path"]).resolve() == projection_root / "operator-handoff-summary.json", bundle
assert bundle["completion_summary"]["runId"] == "mh60-run", bundle
assert Path(bundle["completion_summary"]["evidenceBundlePath"]).resolve() == evidence, bundle
assert bundle["readiness_projection"]["readinessStatus"] == "ready", bundle
assert bundle["verification_projection"]["verificationVerdict"] == "pass", bundle
assert bundle["operator_handoff_summary"]["handoffStatus"] == "not_required", bundle
PY

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection.py" \
  --bundle-file "${BUNDLE}" \
  --output "${TMP_DIR}/bundle-validation.json" \
  --strict >/dev/null

rm -f "${PROJECTION_ROOT}/operator-handoff-summary.json"
if python3 "${ROOT_DIR}/planningops/scripts/resolve_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_DIR}" \
  --projection-root "${PROJECTION_ROOT}" \
  --output "${TMP_DIR}/broken-bundle.json" >/dev/null 2>&1; then
  echo "expected resolver to fail when operator handoff summary is missing" >&2
  exit 1
fi

echo "resolve monday agent harness projection ok"
