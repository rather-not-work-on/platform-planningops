#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
RUN_ID="${1:-federated-ci-$(date -u +%Y%m%dT%H%M%SZ)}"
SYSTEM_PYTHON_BIN="$(command -v python3)"
PYTHON_BIN="$(python3 "${ROOT_DIR}/planningops/scripts/federation/federated_python_env.py" --workspace-root "${WORKSPACE_DIR}" --mode auto --print-python-path)"
PYTHON_BIN_DIR="$(cd "$(dirname "${PYTHON_BIN}")" && pwd)"
export PYTHON_BIN
export PATH="${PYTHON_BIN_DIR}:${PATH}"
SUMMARY_RECONCILE_HELPER="${ROOT_DIR}/planningops/scripts/federation/reconcile_federated_ci_summary_tmp.py"

OUT_DIR="${ROOT_DIR}/planningops/artifacts/ci"
mkdir -p "${OUT_DIR}"
VALIDATION_DIR="${ROOT_DIR}/planningops/artifacts/validation"
mkdir -p "${VALIDATION_DIR}"
LATEST_PATH="${OUT_DIR}/federated-ci-summary.json"
STAMPED_PATH="${OUT_DIR}/${RUN_ID}.json"
SUMMARY_TMP_PATH="${OUT_DIR}/${RUN_ID}.tmp.json"
SUMMARY_CHECKPOINT_PATH="${OUT_DIR}/${RUN_ID}.checkpoint.json"
LATEST_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-validation.json"
STAMPED_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-validation.json"
LATEST_READINESS_PATH="${VALIDATION_DIR}/federated-ci-summary-readiness.json"
STAMPED_READINESS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-readiness.json"
LATEST_READINESS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-readiness-validation.json"
STAMPED_READINESS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-readiness-validation.json"
LATEST_RECONCILE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile.json"
STAMPED_RECONCILE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile.json"
LATEST_RECONCILE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-validation.json"
STAMPED_RECONCILE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-validation.json"
LATEST_RECONCILE_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle.json"
STAMPED_RECONCILE_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle.json"
LATEST_RECONCILE_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH="${VALIDATION_DIR}/${RUN_ID}-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json"
SUMMARY_FINALIZED=0
LOCAL_RUNTIME_PROFILE="local"

REQUIRED_CHECKS=(
  "contract-conformance"
  "provider-gateway-ready"
  "runtime-handoff"
  "runtime-operations-ready"
  "monday-harness-projection"
  "o11y-replay"
  "provider-profile"
  "loop-guardrails"
)

INIT_ARGS=(
  --summary "${SUMMARY_TMP_PATH}"
  --run-id "${RUN_ID}"
)
for required_check in "${REQUIRED_CHECKS[@]}"; do
  INIT_ARGS+=(--required-check "${required_check}")
done

python3 "${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py" init "${INIT_ARGS[@]}"
cp "${SUMMARY_TMP_PATH}" "${SUMMARY_CHECKPOINT_PATH}"

restore_summary_from_checkpoint_if_needed() {
  local check_name="$1"
  python3 "${SUMMARY_RECONCILE_HELPER}" \
    --summary "${SUMMARY_TMP_PATH}" \
    --checkpoint "${SUMMARY_CHECKPOINT_PATH}" \
    --output "${STAMPED_RECONCILE_PATH}" \
    --previous-report "${STAMPED_RECONCILE_PATH}" \
    --check-name "${check_name}" \
    --restore-in-place >/dev/null
  cp "${STAMPED_RECONCILE_PATH}" "${LATEST_RECONCILE_PATH}"
  python3 - <<'PY' "${LATEST_RECONCILE_PATH}"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["output_path"] = str(path)
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile.py" \
    --report-file "${STAMPED_RECONCILE_PATH}" \
    --output "${STAMPED_RECONCILE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile.py" \
    --report-file "${LATEST_RECONCILE_PATH}" \
    --output "${LATEST_RECONCILE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \
    --artifact-file "${STAMPED_RECONCILE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \
    --artifact-file "${LATEST_RECONCILE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_PATH}" \
    --validation-report "${STAMPED_RECONCILE_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_PATH}" \
    --validation-report "${LATEST_RECONCILE_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --bundle-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --bundle-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --status-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --status-validation-output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_VALIDATION_PATH}" \
    --require-pass >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py" \
    --artifact-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${STAMPED_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
  python3 "${ROOT_DIR}/planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py" \
    --bundle-file "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_PATH}" \
    --output "${LATEST_RECONCILE_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_STATUS_BUNDLE_VALIDATION_PATH}" \
    --strict >/dev/null
}

finalize_summary() {
  local status="$1"
  local shell_exit_code="$2"
  local readiness_rc=0
  local restore_errexit=0
  case "$-" in
    *e*) restore_errexit=1 ;;
  esac
  set +e
  python3 "${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py" finalize \
    --summary "${SUMMARY_TMP_PATH}" \
    --stamped-path "${STAMPED_PATH}" \
    --latest-path "${LATEST_PATH}" \
    --status "${status}" \
    --stamped-validation-output "${STAMPED_VALIDATION_PATH}" \
    --latest-validation-output "${LATEST_VALIDATION_PATH}" \
    --shell-exit-code "${shell_exit_code}"
  local summary_rc=$?

  if [[ -f "${STAMPED_PATH}" && -f "${STAMPED_VALIDATION_PATH}" ]]; then
    python3 "${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py" write-readiness \
      --summary "${STAMPED_PATH}" \
      --validation-report "${STAMPED_VALIDATION_PATH}" \
      --output "${STAMPED_READINESS_PATH}" \
      --validation-output "${STAMPED_READINESS_VALIDATION_PATH}"
    local stamped_readiness_rc=$?
    if [[ "${stamped_readiness_rc}" -ne 0 ]]; then
      readiness_rc="${stamped_readiness_rc}"
    fi
  fi
  if [[ -f "${LATEST_PATH}" && -f "${LATEST_VALIDATION_PATH}" ]]; then
    python3 "${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py" write-readiness \
      --summary "${LATEST_PATH}" \
      --validation-report "${LATEST_VALIDATION_PATH}" \
      --output "${LATEST_READINESS_PATH}" \
      --validation-output "${LATEST_READINESS_VALIDATION_PATH}"
    local latest_readiness_rc=$?
    if [[ "${latest_readiness_rc}" -ne 0 && "${readiness_rc}" -eq 0 ]]; then
      readiness_rc="${latest_readiness_rc}"
    fi
  fi
  if [[ "${restore_errexit}" -eq 1 ]]; then
    set -e
  else
    set +e
  fi
  if [[ "${summary_rc}" -ne 0 ]]; then
    return "${summary_rc}"
  fi
  return "${readiness_rc}"
}

trap 'shell_rc=$?; if [ "${SUMMARY_FINALIZED}" -eq 0 ]; then finalize_summary interrupted "${shell_rc}" >/dev/null 2>&1 || true; fi' EXIT

run_check() {
  local check_name="$1"
  local domain="$2"
  shift 2
  local cmd=("$@")
  local stdout_file="${OUT_DIR}/${RUN_ID}-${check_name}.stdout.log"
  local stderr_file="${OUT_DIR}/${RUN_ID}-${check_name}.stderr.log"

  cp "${SUMMARY_TMP_PATH}" "${SUMMARY_CHECKPOINT_PATH}"

  set +e
  "${cmd[@]}" >"${stdout_file}" 2>"${stderr_file}"
  local rc=$?
  set -e

  restore_summary_from_checkpoint_if_needed "${check_name}"

  python3 "${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py" append-check \
    --summary "${SUMMARY_TMP_PATH}" \
    --name "${check_name}" \
    --domain "${domain}" \
    --exit-code "${rc}" \
    --stdout-log "${stdout_file}" \
    --stderr-log "${stderr_file}"
}

run_check "contract-conformance" "contract" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/run_contract_conformance_ci_check.sh --run-id ${RUN_ID}-contract --workspace-root .. --bootstrap-mode auto --python-bin \"${PYTHON_BIN}\""

run_check "provider-profile" "infra" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/run_provider_profile_ci_check.sh --run-id ${RUN_ID}-provider --provider-root ../platform-provider-gateway --runtime-profile-file planningops/config/runtime-profiles.json --profiles local,oracle_cloud"

run_check "provider-gateway-ready" "infra" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/run_provider_gateway_ready_ci_check.sh --run-id ${RUN_ID}-provider-gateway-ready --provider-root ../platform-provider-gateway"

run_check "o11y-replay" "infra" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/run_o11y_replay_ci_check.sh --run-id ${RUN_ID}-o11y --o11y-root ../platform-observability-gateway"

run_check "runtime-handoff" "runtime" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/run_runtime_handoff_ci_check.sh --run-id ${RUN_ID}-runtime --monday-root ../monday --python-bin \"${PYTHON_BIN}\""

run_check "runtime-operations-ready" "runtime" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/run_runtime_operations_ready_ci_check.sh --run-id ${RUN_ID}-runtime-operations-ready --provider-root ../platform-provider-gateway --monday-root ../monday --runtime-profile ${LOCAL_RUNTIME_PROFILE}"

run_check "monday-harness-projection" "runtime" \
  bash -c "
    set -euo pipefail
    cd '${ROOT_DIR}'
    bash planningops/scripts/run_monday_agent_harness_projection_ci_check.sh --summary-run-id ${RUN_ID} --monday-root ../monday --mission-id monday-harness-projection
  "
run_check "loop-guardrails" "policy" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/test_federated_python_env_contract.sh && bash planningops/scripts/test_federated_ci_workflow_summary_contract.sh && bash planningops/scripts/test_federated_ci_local_matrix_mode_contract.sh && bash planningops/scripts/test_reconcile_federated_ci_summary_tmp.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_contract.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile.sh && bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile.sh && bash planningops/scripts/test_validate_federated_ci_summary_contract.sh && bash planningops/scripts/test_federated_ci_summary_contract_doc.sh && bash planningops/scripts/test_plain_python_compat_manifest_contract_doc.sh && bash planningops/scripts/test_uap_automation_operations_summary_contract.sh && bash planningops/scripts/test_validate_supervisor_operator_handoff_contract.sh && bash planningops/scripts/test_resolve_supervisor_operator_handoff_validation.sh && bash planningops/scripts/test_resolve_supervisor_operator_handoff_bundle.sh && bash planningops/scripts/test_validate_supervisor_operator_handoff_bundle.sh && bash planningops/scripts/test_assess_supervisor_operator_handoff_bundle_readiness.sh && bash planningops/scripts/test_validate_supervisor_operator_handoff_bundle_readiness.sh && bash planningops/scripts/test_doctor_supervisor_operator_handoff_bundle.sh && bash planningops/scripts/test_gate_supervisor_operator_handoff_bundle.sh && bash planningops/scripts/test_supervisor_handoff_bridge_wiring.sh && bash planningops/scripts/test_assess_federated_ci_summary_readiness.sh && bash planningops/scripts/test_validate_federated_ci_summary_readiness_contract.sh && bash planningops/scripts/test_doctor_federated_ci_summary.sh && bash planningops/scripts/test_gate_federated_ci_summary.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_validation_contract.sh && bash planningops/scripts/test_gate_plain_python_compat_manifest.sh && bash planningops/scripts/gate_plain_python_compat_manifest.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh && bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh && bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh && bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json && bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json && bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json && bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh && bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json && bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle.sh && bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status.json && bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle.sh && bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json && bash planningops/scripts/test_resolve_plain_python_compat_manifest.sh && bash planningops/scripts/test_cross_repo_plain_python_annotation_contract.sh && bash planningops/scripts/test_plain_python_compat_manifest_wiring.sh && bash planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh && PLAIN_PYTHON_BIN='${SYSTEM_PYTHON_BIN}' bash planningops/scripts/test_cross_repo_plain_python_compat.sh && PLAIN_PYTHON_BIN='${SYSTEM_PYTHON_BIN}' bash planningops/scripts/test_runtime_stack_smoke_sequence_contract.sh && PLANNINGOPS_ALLOW_SCHEMA_FETCH_FAILURE=1 \"${PYTHON_BIN}\" planningops/scripts/run_track1_gate_dryrun.py --kpi-path planningops/fixtures/track1-kpi-baseline-ci.json --strict && bash planningops/scripts/test_track1_gate_dryrun_contract.sh && bash planningops/scripts/test_bootstrap_two_track_backlog_contract.sh && bash planningops/scripts/test_compile_plan_to_backlog_contract.sh && bash planningops/scripts/test_verify_plan_projection_contract.sh && bash planningops/scripts/test_planning_context_contract.sh && bash planningops/scripts/test_inventory_issue_lifecycle_contract.sh && bash planningops/scripts/test_inventory_issue_lifecycle_audit_snapshot.sh && \"${PYTHON_BIN}\" planningops/scripts/compile_plan_to_backlog.py --contract-file planningops/fixtures/plan-execution-contract-sample.json --output planningops/artifacts/validation/plan-compile-report.json && \"${PYTHON_BIN}\" planningops/scripts/verify_plan_projection.py --contract-file planningops/fixtures/plan-execution-contract-sample.json --snapshot-file planningops/fixtures/plan-projection-snapshot-sample.json --strict --output planningops/artifacts/validation/plan-projection-report.json && \"${PYTHON_BIN}\" planningops/scripts/validate_runtime_profiles.py --strict && bash planningops/scripts/test_meta_plan_graph_schema_contract.sh && bash planningops/scripts/test_build_meta_plan_graph_contract.sh && bash planningops/scripts/test_meta_plan_orchestrator_contract.sh && \"${PYTHON_BIN}\" planningops/scripts/build_meta_plan_graph.py --contract-file planningops/fixtures/meta-plan-graph-sample.json --strict --output planningops/artifacts/meta-plan/meta-graph.json && \"${PYTHON_BIN}\" planningops/scripts/meta_plan_orchestrator.py --meta-graph-contract planningops/fixtures/meta-plan-graph-sample.json --mode dry-run --strict --meta-graph-output planningops/artifacts/meta-plan/meta-graph.json --output planningops/artifacts/meta-plan/meta-execution-report.json && bash planningops/scripts/test_validate_project_field_schema_matrix.sh && bash planningops/scripts/test_module_readme_contract.sh && bash planningops/scripts/test_validate_repo_boundaries_contract.sh && bash planningops/scripts/test_validate_script_roles_contract.sh && bash planningops/scripts/test_cross_repo_conformance_run_root_reuse_contract.sh && bash planningops/scripts/test_validate_issue_quality_contract.sh && \"${PYTHON_BIN}\" planningops/scripts/validate_issue_quality.py --strict && bash planningops/scripts/test_normalize_ready_implementation_blueprint_refs.sh && bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh && bash planningops/scripts/test_ralph_loop_local_worker_policy.sh && bash planningops/scripts/test_validate_worker_task_pack_contract.sh && bash planningops/scripts/test_validate_runtime_profiles_contract.sh && bash planningops/scripts/test_issue_driven_mission_smoke_contract.sh && bash planningops/scripts/test_issue_driven_runtime_stack_smoke_contract.sh && bash planningops/scripts/test_local_runtime_stack_smoke_contract.sh && bash planningops/scripts/test_wave14_oracle_rehearsal_contract.sh && bash planningops/scripts/test_loop_checkpoint_resume.sh && bash planningops/scripts/test_lease_lock_watchdog.sh && bash planningops/scripts/test_escalation_gate.sh"

run_check "loop-guardrails-outer-status-resolve" "policy" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh"

run_check "loop-guardrails-outer-status-bundle-validation" "policy" \
  bash -c "cd '${ROOT_DIR}' && bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh"

set +e
finalize_summary complete 0
finalize_rc=$?
set -e
SUMMARY_FINALIZED=1
exit "${finalize_rc}"
