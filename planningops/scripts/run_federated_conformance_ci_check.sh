#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_WORKSPACE_ROOT="${ROOT_DIR}/.."
DEFAULT_PYTHON_BIN="python3"
DEFAULT_POLICY_OUTPUT="planningops/artifacts/validation/federated-artifact-policy-rollout-report.json"
DEFAULT_BOOTSTRAP_MODE="auto"
RUN_ID=""
WORKSPACE_ROOT="${DEFAULT_WORKSPACE_ROOT}"
PYTHON_BIN="${DEFAULT_PYTHON_BIN}"
POLICY_OUTPUT="${DEFAULT_POLICY_OUTPUT}"
BOOTSTRAP_MODE="${DEFAULT_BOOTSTRAP_MODE}"
OUTPUT=""
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_federated_conformance_ci_check.sh [options]

options:
  --run-id <id>                 federated-conformance run id passed to the cross-repo checker
  --workspace-root <path>       federated workspace root
  --python-bin <path>           python executable used for both planningops entrypoints
  --policy-output <path>        output path for rollout_external_artifact_policy.py
  --bootstrap-mode <mode>       bootstrap mode passed to cross_repo_conformance_check.py
  --output <path>               output path for cross_repo_conformance_check.py
  --print-workflow-invocation   print the canonical GitHub workflow invocation
  --help                        show this help text
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --workspace-root)
      WORKSPACE_ROOT="$2"
      shift 2
      ;;
    --python-bin)
      PYTHON_BIN="$2"
      shift 2
      ;;
    --policy-output)
      POLICY_OUTPUT="$2"
      shift 2
      ;;
    --bootstrap-mode)
      BOOTSTRAP_MODE="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
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
  printf '%s\n' "bash planningops/scripts/run_federated_conformance_ci_check.sh --run-id ci-federated-\${{ github.run_id }} --workspace-root . --python-bin python3 --policy-output planningops/artifacts/validation/federated-artifact-policy-rollout-report.json --bootstrap-mode require --output planningops/artifacts/conformance/ci-federated-\${{ github.run_id }}.json"
  exit 0
fi

if [[ -z "${RUN_ID}" ]]; then
  echo "--run-id is required" >&2
  usage >&2
  exit 1
fi

if [[ -z "${OUTPUT}" ]]; then
  echo "--output is required" >&2
  usage >&2
  exit 1
fi

resolve_from_root() {
  if [[ "$1" = /* ]]; then
    printf '%s\n' "$1"
  else
    printf '%s/%s\n' "${ROOT_DIR}" "$1"
  fi
}

WORKSPACE_ROOT="$(resolve_from_root "${WORKSPACE_ROOT}")"
POLICY_OUTPUT="$(resolve_from_root "${POLICY_OUTPUT}")"
OUTPUT="$(resolve_from_root "${OUTPUT}")"

bash "${ROOT_DIR}/planningops/scripts/test_run_federated_conformance_ci_check_contract.sh"

"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/rollout_external_artifact_policy.py" \
  --workspace-root "${WORKSPACE_ROOT}" \
  --strict \
  --output "${POLICY_OUTPUT}"

"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/federation/cross_repo_conformance_check.py" \
  --workspace-root "${WORKSPACE_ROOT}" \
  --bootstrap-mode "${BOOTSTRAP_MODE}" \
  --run-id "${RUN_ID}" \
  --output "${OUTPUT}"
