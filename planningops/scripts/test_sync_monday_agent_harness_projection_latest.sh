#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
VALIDATION_DIR="${ROOT_DIR}/planningops/artifacts/validation"
BACKUP_DIR="${TMP_DIR}/validation-backup"
MONDAY_ROOT="${TMP_DIR}/monday"
SUMMARY_FILE="${TMP_DIR}/federated-ci-summary.json"
trap 'find "${VALIDATION_DIR}" -maxdepth 1 -type f -name "monday-agent-harness-projection*.json" -delete; if [[ -d "${BACKUP_DIR}" ]]; then while IFS= read -r backup_file; do cp "${backup_file}" "${VALIDATION_DIR}/$(basename "${backup_file}")"; done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f | sort); fi; rm -rf "${TMP_DIR}"' EXIT

mkdir -p "${BACKUP_DIR}"
while IFS= read -r validation_file; do
  cp "${validation_file}" "${BACKUP_DIR}/$(basename "${validation_file}")"
done < <(find "${VALIDATION_DIR}" -maxdepth 1 -type f -name 'monday-agent-harness-projection*.json' | sort)

mkdir -p "${MONDAY_ROOT}/scripts" "${MONDAY_ROOT}/runtime-artifacts"
cp "${ROOT_DIR}/../monday/scripts/publish_agent_harness_projection_fixture.py" "${MONDAY_ROOT}/scripts/"

cat >"${SUMMARY_FILE}" <<'JSON'
{
  "run_id": "sync-fixture-run",
  "overall_status": "complete",
  "verdict": "pass",
  "check_count": 10
}
JSON

sync_output="$(bash "${ROOT_DIR}/planningops/scripts/sync_monday_agent_harness_projection_latest.sh" \
  --summary-file "${SUMMARY_FILE}" \
  --monday-root "${MONDAY_ROOT}" \
  --mission-id "sync-mission")"

printf '%s\n' "${sync_output}" | grep -q '^summary_run_id=sync-fixture-run$'
printf '%s\n' "${sync_output}" | grep -q '^projection_run_id=sync-fixture-run-monday-harness$'

python3 - <<'PY' "${ROOT_DIR}" "${MONDAY_ROOT}"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
monday_root = Path(sys.argv[2]).resolve()
projection_root = monday_root / "runtime-artifacts" / "agent-harness"

validation = json.loads((root / "planningops/artifacts/validation/monday-agent-harness-projection-validation.json").read_text())
status_validation = json.loads((root / "planningops/artifacts/validation/monday-agent-harness-projection-status-validation.json").read_text())
outer_bundle = json.loads(
    (
        root
        / "planningops/artifacts/validation"
        / "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
    ).read_text()
)

if Path(validation["projection_root"]).resolve() != projection_root:
    raise SystemExit("projection_root mismatch")
if validation.get("run_id") != "sync-fixture-run-monday-harness":
    raise SystemExit("projection run_id mismatch")
if validation.get("ready") is not True or validation.get("next_step") != "none":
    raise SystemExit("projection validation not ready/pass")
if status_validation.get("status_run_id") != "sync-fixture-run-monday-harness":
    raise SystemExit("status validation run_id mismatch")
if status_validation.get("projection_status_verdict") != "pass":
    raise SystemExit("projection_status_verdict mismatch")
if status_validation.get("projection_validation_verdict") != "pass":
    raise SystemExit("projection_validation_verdict mismatch")
if status_validation.get("projection_validation_state") != "fresh":
    raise SystemExit("projection_validation_state mismatch")
if outer_bundle.get("run_id") != "sync-fixture-run-monday-harness":
    raise SystemExit("outer bundle run_id mismatch")
if outer_bundle.get("ready") is not True or outer_bundle.get("next_step") != "none":
    raise SystemExit("outer bundle not ready/pass")
PY

echo "sync monday agent harness projection latest ok"
