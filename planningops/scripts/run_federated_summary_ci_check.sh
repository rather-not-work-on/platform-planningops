#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SUMMARY_HELPER="${ROOT_DIR}/planningops/scripts/federation/federated_ci_summary.py"

RUN_ID=""
CONTRACT_CONFORMANCE_RESULT=""
RUNTIME_HANDOFF_RESULT=""
MONDAY_HARNESS_PROJECTION_RESULT=""
O11Y_REPLAY_RESULT=""
PROVIDER_PROFILE_RESULT=""
FEDERATED_CONFORMANCE_RESULT=""
LOOP_GUARDRAILS_RESULT=""
SUMMARY_TMP=""
STAMPED_PATH=""
LATEST_PATH=""
STAMPED_VALIDATION_PATH=""
LATEST_VALIDATION_PATH=""
STAMPED_READINESS_PATH=""
LATEST_READINESS_PATH=""
STAMPED_READINESS_VALIDATION_PATH=""
LATEST_READINESS_VALIDATION_PATH=""
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_federated_summary_ci_check.sh [options]

options:
  --run-id <id>                               federated summary run id
  --contract-conformance-result <result>      GitHub needs result for contract-conformance
  --runtime-handoff-result <result>           GitHub needs result for runtime-handoff
  --monday-harness-projection-result <result> GitHub needs result for monday-harness-projection
  --o11y-replay-result <result>               GitHub needs result for o11y-replay
  --provider-profile-result <result>          GitHub needs result for provider-profile
  --federated-conformance-result <result>     GitHub needs result for federated-conformance
  --loop-guardrails-result <result>           GitHub needs result for loop-guardrails
  --summary-tmp <path>                        tmp summary artifact path
  --stamped-path <path>                       stamped summary artifact path
  --latest-path <path>                        latest summary artifact path
  --stamped-validation-path <path>            stamped summary validation artifact path
  --latest-validation-path <path>             latest summary validation artifact path
  --stamped-readiness-path <path>             stamped readiness artifact path
  --latest-readiness-path <path>              latest readiness artifact path
  --stamped-readiness-validation-path <path>  stamped readiness validation artifact path
  --latest-readiness-validation-path <path>   latest readiness validation artifact path
  --print-workflow-invocation                 print the canonical GitHub workflow invocation
  --help                                      show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --contract-conformance-result)
      CONTRACT_CONFORMANCE_RESULT="$2"
      shift 2
      ;;
    --runtime-handoff-result)
      RUNTIME_HANDOFF_RESULT="$2"
      shift 2
      ;;
    --monday-harness-projection-result)
      MONDAY_HARNESS_PROJECTION_RESULT="$2"
      shift 2
      ;;
    --o11y-replay-result)
      O11Y_REPLAY_RESULT="$2"
      shift 2
      ;;
    --provider-profile-result)
      PROVIDER_PROFILE_RESULT="$2"
      shift 2
      ;;
    --federated-conformance-result)
      FEDERATED_CONFORMANCE_RESULT="$2"
      shift 2
      ;;
    --loop-guardrails-result)
      LOOP_GUARDRAILS_RESULT="$2"
      shift 2
      ;;
    --summary-tmp)
      SUMMARY_TMP="$2"
      shift 2
      ;;
    --stamped-path)
      STAMPED_PATH="$2"
      shift 2
      ;;
    --latest-path)
      LATEST_PATH="$2"
      shift 2
      ;;
    --stamped-validation-path)
      STAMPED_VALIDATION_PATH="$2"
      shift 2
      ;;
    --latest-validation-path)
      LATEST_VALIDATION_PATH="$2"
      shift 2
      ;;
    --stamped-readiness-path)
      STAMPED_READINESS_PATH="$2"
      shift 2
      ;;
    --latest-readiness-path)
      LATEST_READINESS_PATH="$2"
      shift 2
      ;;
    --stamped-readiness-validation-path)
      STAMPED_READINESS_VALIDATION_PATH="$2"
      shift 2
      ;;
    --latest-readiness-validation-path)
      LATEST_READINESS_VALIDATION_PATH="$2"
      shift 2
      ;;
    --print-workflow-invocation)
      PRINT_WORKFLOW_INVOCATION=1
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_federated_summary_ci_check.sh --run-id ci-\${{ github.run_id }} --contract-conformance-result \${{ needs.contract-conformance.result }} --runtime-handoff-result \${{ needs.runtime-handoff.result }} --monday-harness-projection-result \${{ needs.monday-harness-projection.result }} --o11y-replay-result \${{ needs.o11y-replay.result }} --provider-profile-result \${{ needs.provider-profile.result }} --federated-conformance-result \${{ needs.federated-conformance.result }} --loop-guardrails-result \${{ needs.loop-guardrails.result }}"
  exit 0
fi

required_flags=(
  RUN_ID
  CONTRACT_CONFORMANCE_RESULT
  RUNTIME_HANDOFF_RESULT
  MONDAY_HARNESS_PROJECTION_RESULT
  O11Y_REPLAY_RESULT
  PROVIDER_PROFILE_RESULT
  FEDERATED_CONFORMANCE_RESULT
  LOOP_GUARDRAILS_RESULT
)

for flag in "${required_flags[@]}"; do
  if [[ -z "${!flag}" ]]; then
    echo "missing required argument for ${flag}" >&2
    usage >&2
    exit 1
  fi
done

resolve_from_root() {
  if [[ "$1" = /* ]]; then
    printf '%s\n' "$1"
  else
    printf '%s/%s\n' "${ROOT_DIR}" "$1"
  fi
}

SUMMARY_TMP="${SUMMARY_TMP:-planningops/artifacts/ci/${RUN_ID}.tmp.json}"
STAMPED_PATH="${STAMPED_PATH:-planningops/artifacts/ci/${RUN_ID}.json}"
LATEST_PATH="${LATEST_PATH:-planningops/artifacts/ci/federated-ci-summary.json}"
STAMPED_VALIDATION_PATH="${STAMPED_VALIDATION_PATH:-planningops/artifacts/validation/${RUN_ID}-summary-validation.json}"
LATEST_VALIDATION_PATH="${LATEST_VALIDATION_PATH:-planningops/artifacts/validation/federated-ci-summary-validation.json}"
STAMPED_READINESS_PATH="${STAMPED_READINESS_PATH:-planningops/artifacts/validation/${RUN_ID}-summary-readiness.json}"
LATEST_READINESS_PATH="${LATEST_READINESS_PATH:-planningops/artifacts/validation/federated-ci-summary-readiness.json}"
STAMPED_READINESS_VALIDATION_PATH="${STAMPED_READINESS_VALIDATION_PATH:-planningops/artifacts/validation/${RUN_ID}-summary-readiness-validation.json}"
LATEST_READINESS_VALIDATION_PATH="${LATEST_READINESS_VALIDATION_PATH:-planningops/artifacts/validation/federated-ci-summary-readiness-validation.json}"

SUMMARY_TMP="$(resolve_from_root "${SUMMARY_TMP}")"
STAMPED_PATH="$(resolve_from_root "${STAMPED_PATH}")"
LATEST_PATH="$(resolve_from_root "${LATEST_PATH}")"
STAMPED_VALIDATION_PATH="$(resolve_from_root "${STAMPED_VALIDATION_PATH}")"
LATEST_VALIDATION_PATH="$(resolve_from_root "${LATEST_VALIDATION_PATH}")"
STAMPED_READINESS_PATH="$(resolve_from_root "${STAMPED_READINESS_PATH}")"
LATEST_READINESS_PATH="$(resolve_from_root "${LATEST_READINESS_PATH}")"
STAMPED_READINESS_VALIDATION_PATH="$(resolve_from_root "${STAMPED_READINESS_VALIDATION_PATH}")"
LATEST_READINESS_VALIDATION_PATH="$(resolve_from_root "${LATEST_READINESS_VALIDATION_PATH}")"

mkdir -p "$(dirname "${SUMMARY_TMP}")" "$(dirname "${STAMPED_PATH}")" "$(dirname "${LATEST_PATH}")" "$(dirname "${STAMPED_VALIDATION_PATH}")" "$(dirname "${LATEST_VALIDATION_PATH}")" "$(dirname "${STAMPED_READINESS_PATH}")" "$(dirname "${LATEST_READINESS_PATH}")" "$(dirname "${STAMPED_READINESS_VALIDATION_PATH}")" "$(dirname "${LATEST_READINESS_VALIDATION_PATH}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_federated_summary_ci_check_contract.sh"

python3 "${SUMMARY_HELPER}" init \
  --summary "${SUMMARY_TMP}" \
  --run-id "${RUN_ID}" \
  --required-check contract-conformance \
  --required-check runtime-handoff \
  --required-check monday-harness-projection \
  --required-check o11y-replay \
  --required-check provider-profile \
  --required-check federated-conformance \
  --required-check loop-guardrails

append_job_result() {
  local name="$1"
  local domain="$2"
  local result="$3"
  local exit_code=1
  local stdout_log="${ROOT_DIR}/planningops/artifacts/ci/${name}.stdout.log"
  local stderr_log="${ROOT_DIR}/planningops/artifacts/ci/${name}.stderr.log"

  mkdir -p "$(dirname "${stdout_log}")"
  if [[ "${result}" == "success" ]]; then
    exit_code=0
  fi
  printf 'job=%s\nresult=%s\n' "${name}" "${result}" >"${stdout_log}"
  : >"${stderr_log}"

  python3 "${SUMMARY_HELPER}" append-check \
    --summary "${SUMMARY_TMP}" \
    --name "${name}" \
    --domain "${domain}" \
    --exit-code "${exit_code}" \
    --result "${result}" \
    --stdout-log "${stdout_log}" \
    --stderr-log "${stderr_log}"
}

append_job_result "contract-conformance" "contract" "${CONTRACT_CONFORMANCE_RESULT}"
append_job_result "runtime-handoff" "runtime" "${RUNTIME_HANDOFF_RESULT}"
append_job_result "monday-harness-projection" "runtime" "${MONDAY_HARNESS_PROJECTION_RESULT}"
append_job_result "o11y-replay" "infra" "${O11Y_REPLAY_RESULT}"
append_job_result "provider-profile" "infra" "${PROVIDER_PROFILE_RESULT}"
append_job_result "federated-conformance" "federation" "${FEDERATED_CONFORMANCE_RESULT}"
append_job_result "loop-guardrails" "policy" "${LOOP_GUARDRAILS_RESULT}"

set +e
python3 "${SUMMARY_HELPER}" finalize \
  --summary "${SUMMARY_TMP}" \
  --stamped-path "${STAMPED_PATH}" \
  --latest-path "${LATEST_PATH}" \
  --status complete \
  --stamped-validation-output "${STAMPED_VALIDATION_PATH}" \
  --latest-validation-output "${LATEST_VALIDATION_PATH}" \
  --shell-exit-code 0
summary_rc=$?
set -e

write_readiness_artifact() {
  local summary_path="$1"
  local validation_path="$2"
  local output_path="$3"
  local validation_output_path="$4"

  if [[ -f "${summary_path}" && -f "${validation_path}" ]]; then
    python3 "${SUMMARY_HELPER}" write-readiness \
      --summary "${summary_path}" \
      --validation-report "${validation_path}" \
      --output "${output_path}" \
      --validation-output "${validation_output_path}"
  fi
}

write_readiness_artifact \
  "${STAMPED_PATH}" \
  "${STAMPED_VALIDATION_PATH}" \
  "${STAMPED_READINESS_PATH}" \
  "${STAMPED_READINESS_VALIDATION_PATH}"

write_readiness_artifact \
  "${LATEST_PATH}" \
  "${LATEST_VALIDATION_PATH}" \
  "${LATEST_READINESS_PATH}" \
  "${LATEST_READINESS_VALIDATION_PATH}"

exit "${summary_rc}"
