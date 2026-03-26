#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOLVER_PATH="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"
MANIFEST_FILE="${ROOT_DIR}/planningops/config/plain-python-compat-manifest.json"
PRINT_STEPS=0
PRINT_WORKFLOW_INVOCATION=0

usage() {
  cat <<EOF
usage: run_plain_python_compat_workflow_chain.sh [options]

options:
  --manifest-file <path>       plain-python compat manifest to resolve
  --print-steps                print the canonical workflow command chain
  --print-workflow-invocation  print the canonical GitHub workflow invocation
  --help                       show this help text
EOF
}

resolve_from_root() {
  if [[ "$1" = /* ]]; then
    printf '%s\n' "$1"
  else
    printf '%s/%s\n' "${ROOT_DIR}" "$1"
  fi
}

resolve_guardrail_commands() {
  python3 - <<'PY' "${RESOLVER_PATH}" "${MANIFEST_FILE}"
import json
import subprocess
import sys

resolver_path = sys.argv[1]
manifest_file = sys.argv[2]
guardrails = json.loads(
    subprocess.check_output(
        ["python3", resolver_path, "--manifest-file", manifest_file, "--mode", "guardrails"],
        text=True,
    )
)
for step in guardrails:
    print(step["workflow_command"])
PY
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --manifest-file)
      MANIFEST_FILE="$2"
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

MANIFEST_FILE="$(resolve_from_root "${MANIFEST_FILE}")"

if [[ "${PRINT_STEPS}" -eq 1 ]]; then
  resolve_guardrail_commands
  exit 0
fi

if [[ "${PRINT_WORKFLOW_INVOCATION}" -eq 1 ]]; then
  printf '%s\n' "bash planningops/scripts/run_plain_python_compat_workflow_chain.sh"
  exit 0
fi

bash "${ROOT_DIR}/planningops/scripts/test_run_plain_python_compat_workflow_chain_contract.sh"

cd "${ROOT_DIR}"
while IFS= read -r step; do
  [[ -z "${step}" ]] && continue
  bash -lc "${step}"
done < <(resolve_guardrail_commands)
