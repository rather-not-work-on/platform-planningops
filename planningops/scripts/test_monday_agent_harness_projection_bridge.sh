#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
MONDAY_ROOT="${WORKSPACE_DIR}/monday"

if [[ ! -d "${MONDAY_ROOT}" ]]; then
  echo "missing sibling monday workspace: ${MONDAY_ROOT}" >&2
  exit 1
fi

TMP_PARENT="${MONDAY_ROOT}/runtime-artifacts/tmp"
mkdir -p "${TMP_PARENT}"
TMP_DIR="$(mktemp -d "${TMP_PARENT}/planningops-projection-bridge.XXXXXX")"
VALIDATION_OUTPUT="${TMP_DIR}/monday-agent-harness-projection-validation.json"
STATUS_OUTPUT="${TMP_DIR}/monday-agent-harness-projection-status.json"
STATUS_VALIDATION_OUTPUT="${TMP_DIR}/monday-agent-harness-projection-status-validation.json"

trap 'rm -rf "${TMP_DIR}"' EXIT

python3 "${MONDAY_ROOT}/scripts/publish_agent_harness_projection_fixture.py" \
  --output-root "${TMP_DIR}" \
  --mission-id "planningops-projection-bridge" \
  --run-id "planningops-projection-bridge:run:test" \
  --session-id "planningops-projection-bridge:session:test" \
  --clean >/dev/null

python3 "${ROOT_DIR}/planningops/scripts/validate_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_ROOT}" \
  --projection-root "${TMP_DIR}" \
  --output "${VALIDATION_OUTPUT}" \
  --strict >/dev/null

python3 - <<'PY' "${VALIDATION_OUTPUT}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["ready"] is True, report
assert report["final_status"] == "succeeded", report
assert report["readiness_status"] == "ready", report
assert report["verification_verdict"] == "pass", report
assert report["handoff_status"] == "not_required", report
assert report["next_step"] == "none", report
PY

doctor_output="$(python3 "${ROOT_DIR}/planningops/scripts/doctor_monday_agent_harness_projection.py" \
  --monday-root "${MONDAY_ROOT}" \
  --projection-root "${TMP_DIR}" \
  --output "${VALIDATION_OUTPUT}" \
  --status-output "${STATUS_OUTPUT}" \
  --status-validation-output "${STATUS_VALIDATION_OUTPUT}" \
  --require-pass)"

printf '%s\n' "${doctor_output}" | grep -q "ready: True"
printf '%s\n' "${doctor_output}" | grep -q "projection status validation verdict: pass"
printf '%s\n' "${doctor_output}" | grep -q "next step: none"

gate_output="$(bash "${ROOT_DIR}/planningops/scripts/gate_monday_agent_harness_projection.sh" \
  --monday-root "${MONDAY_ROOT}" \
  --projection-root "${TMP_DIR}" \
  --output "${VALIDATION_OUTPUT}" \
  --status-output "${STATUS_OUTPUT}" \
  --status-validation-output "${STATUS_VALIDATION_OUTPUT}")"

printf '%s\n' "${gate_output}" | grep -q "next step: none"

python3 - <<'PY' "${STATUS_OUTPUT}" "${STATUS_VALIDATION_OUTPUT}"
import json
import sys
from pathlib import Path

status = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
status_validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert status["ready"] is True, status
assert status["validation_verdict"] == "pass", status
assert status_validation["verdict"] == "pass", status_validation
PY

echo "monday agent harness projection bridge ok"
