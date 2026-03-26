#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_REF=""
HEAD_REF="HEAD"
PYTHON_BIN="python3"
PRINT_STEPS=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_external_artifact_residency_ci_check.sh [options]

options:
  --base-ref <ref>            diff base ref for the external-only commit guard
  --head-ref <ref>            diff head ref for the external-only commit guard
  --python-bin <path>         python interpreter for the live guard checks
  --print-steps               print the legacy workflow step inventory replaced by this helper
  --print-workflow-invocation print the canonical GitHub workflow invocation
  --help                      show this help text
EOF
}

print_steps() {
  cat <<'EOF'
bash planningops/scripts/test_validate_external_only_commit_guard.sh
bash planningops/scripts/test_migrate_external_only_artifacts_contract.sh
bash planningops/scripts/test_artifact_sink_e2e.sh
BASE_REF="${{ github.event.pull_request.base.sha }}"
if [[ -z "$BASE_REF" || "$BASE_REF" == "null" ]]; then BASE_REF="origin/main"; fi
python3 planningops/scripts/validate_external_only_commit_guard.py --base-ref "$BASE_REF" --head-ref "${{ github.sha }}" --strict
python3 planningops/scripts/validate_external_only_commit_guard.py --mode tracked --strict
EOF
}

resolve_base_ref() {
  local candidate="$1"
  if [[ -z "${candidate}" || "${candidate}" == "null" ]]; then
    printf '%s\n' "origin/main"
    return 0
  fi
  printf '%s\n' "${candidate}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-ref)
      BASE_REF="$2"
      shift 2
      ;;
    --head-ref)
      HEAD_REF="$2"
      shift 2
      ;;
    --python-bin)
      PYTHON_BIN="$2"
      shift 2
      ;;
    --print-steps)
      PRINT_STEPS=1
      shift
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

if [[ "${PRINT_STEPS}" -eq 1 ]]; then
  print_steps
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' 'bash planningops/scripts/run_external_artifact_residency_ci_check.sh --base-ref "${{ github.event.pull_request.base.sha }}" --head-ref "${{ github.sha }}" --python-bin python3'
  exit 0
fi

RESOLVED_BASE_REF="$(resolve_base_ref "${BASE_REF}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_external_artifact_residency_ci_check_contract.sh"

cd "${ROOT_DIR}"
bash planningops/scripts/test_validate_external_only_commit_guard.sh
bash planningops/scripts/test_migrate_external_only_artifacts_contract.sh
bash planningops/scripts/test_artifact_sink_e2e.sh
"${PYTHON_BIN}" planningops/scripts/validate_external_only_commit_guard.py \
  --base-ref "${RESOLVED_BASE_REF}" \
  --head-ref "${HEAD_REF}" \
  --strict
"${PYTHON_BIN}" planningops/scripts/validate_external_only_commit_guard.py \
  --mode tracked \
  --strict
