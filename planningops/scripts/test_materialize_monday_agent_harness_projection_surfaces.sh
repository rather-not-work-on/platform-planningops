#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MONDAY_ROOT="$(cd "${ROOT_DIR}/../monday" && pwd)"
TMP_DIR="$(mktemp -d)"
VALIDATION_DIR="${ROOT_DIR}/planningops/artifacts/validation"
BACKUP_DIR="${TMP_DIR}/validation-backup"

restore_validation_artifacts() {
  find "${VALIDATION_DIR}" -maxdepth 1 -type f -name 'monday-agent-harness-projection*.json' -delete
  if [[ -d "${BACKUP_DIR}" ]]; then
    while IFS= read -r backup_file; do
      cp "${backup_file}" "${VALIDATION_DIR}/$(basename "${backup_file}")"
    done < <(find "${BACKUP_DIR}" -maxdepth 1 -type f | sort)
  fi
  rm -rf "${TMP_DIR}"
}

mkdir -p "${BACKUP_DIR}"
while IFS= read -r validation_file; do
  cp "${validation_file}" "${BACKUP_DIR}/$(basename "${validation_file}")"
done < <(find "${VALIDATION_DIR}" -maxdepth 1 -type f -name 'monday-agent-harness-projection*.json' | sort)

trap 'restore_validation_artifacts' EXIT

PROJECTION_ROOT="${TMP_DIR}/agent-harness"

python3 "${MONDAY_ROOT}/scripts/publish_agent_harness_projection_fixture.py" \
  --output-root "${PROJECTION_ROOT}" \
  --mission-id "planningops-materialize-projection" \
  --run-id "planningops-materialize-projection:run:test" \
  --session-id "planningops-materialize-projection:session:test" \
  --clean \
  >/dev/null

touch "${PROJECTION_ROOT}/._completion-summary.json"
touch "${PROJECTION_ROOT}/._projection-noise.json"

bash "${ROOT_DIR}/planningops/scripts/materialize_monday_agent_harness_projection_surfaces.sh" \
  --projection-root "${PROJECTION_ROOT}" \
  >/dev/null

python3 - <<'PY' "${ROOT_DIR}" "${PROJECTION_ROOT}"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
projection_root = Path(sys.argv[2]).resolve()

validation = json.loads((root / "planningops/artifacts/validation/monday-agent-harness-projection-validation.json").read_text())
status = json.loads((root / "planningops/artifacts/validation/monday-agent-harness-projection-status.json").read_text())
outer_bundle = json.loads(
    (
        root
        / "planningops/artifacts/validation/"
        / "monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
    ).read_text()
)

if Path(validation["projection_root"]).resolve() != projection_root:
    raise SystemExit("base validation projection_root mismatch")
if validation.get("ready") is not True or validation.get("next_step") != "none":
    raise SystemExit("base validation not ready/pass")
if Path(status["projection_root"]).resolve() != projection_root:
    raise SystemExit("base status projection_root mismatch")
if status.get("ready") is not True or status.get("validation_verdict") != "pass":
    raise SystemExit("base status not refreshed")
if outer_bundle.get("ready") is not True:
    raise SystemExit("outer bundle not ready")
if outer_bundle.get("status_verdict") != "pass":
    raise SystemExit("outer bundle status_verdict not pass")
if outer_bundle.get("projection_validation_verdict") != "pass":
    raise SystemExit("outer bundle projection_validation_verdict not pass")
if outer_bundle.get("bundle_validation_verdict") != "pass":
    raise SystemExit("outer bundle bundle_validation_verdict not pass")
if outer_bundle.get("next_step") != "none":
    raise SystemExit("outer bundle next_step not none")
PY

echo "materialize monday agent harness projection surfaces ok"
