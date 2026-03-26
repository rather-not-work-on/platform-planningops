#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_SUMMARY_FILE="${ROOT_DIR}/planningops/artifacts/ci/federated-ci-summary.json"
DEFAULT_MONDAY_ROOT="${ROOT_DIR}/../monday"
DEFAULT_MISSION_ID="monday-harness-projection"

SUMMARY_FILE="${DEFAULT_SUMMARY_FILE}"
MONDAY_ROOT="${DEFAULT_MONDAY_ROOT}"
MISSION_ID="${DEFAULT_MISSION_ID}"
SUMMARY_RUN_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary-file)
      SUMMARY_FILE="$2"
      shift 2
      ;;
    --monday-root)
      MONDAY_ROOT="$2"
      shift 2
      ;;
    --mission-id)
      MISSION_ID="$2"
      shift 2
      ;;
    --summary-run-id)
      SUMMARY_RUN_ID="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

PUBLISHER="${MONDAY_ROOT}/scripts/publish_agent_harness_projection_fixture.py"
PROJECTION_ROOT="${MONDAY_ROOT}/runtime-artifacts/agent-harness"
MATERIALIZER="${ROOT_DIR}/planningops/scripts/materialize_monday_agent_harness_projection_surfaces.sh"

if [[ ! -f "${PUBLISHER}" ]]; then
  echo "publisher script not found: ${PUBLISHER}" >&2
  exit 1
fi

if [[ -z "${SUMMARY_RUN_ID}" ]]; then
  if [[ ! -f "${SUMMARY_FILE}" ]]; then
    echo "summary file not found: ${SUMMARY_FILE}" >&2
    exit 1
  fi
  SUMMARY_RUN_ID="$(python3 - <<'PY' "${SUMMARY_FILE}"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
run_id = summary.get("run_id")
if not isinstance(run_id, str) or not run_id.strip():
    raise SystemExit("summary run_id missing")
print(run_id)
PY
)"
fi

PROJECTION_RUN_ID="${SUMMARY_RUN_ID}-monday-harness"
PROJECTION_SESSION_ID="${SUMMARY_RUN_ID}-monday-harness-session"

python3 "${PUBLISHER}" \
  --output-root "${PROJECTION_ROOT}" \
  --mission-id "${MISSION_ID}" \
  --run-id "${PROJECTION_RUN_ID}" \
  --session-id "${PROJECTION_SESSION_ID}" \
  --clean \
  >/dev/null

bash "${MATERIALIZER}" --projection-root "${PROJECTION_ROOT}" >/dev/null

printf 'summary_run_id=%s\n' "${SUMMARY_RUN_ID}"
printf 'projection_run_id=%s\n' "${PROJECTION_RUN_ID}"
printf 'projection_root=%s\n' "${PROJECTION_ROOT}"
