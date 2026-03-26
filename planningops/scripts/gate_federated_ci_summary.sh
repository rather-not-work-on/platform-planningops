#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assess_args=()
doctor_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary|--validation-report|--output|--readiness-report|--validation-output|--readiness-validation-report)
      assess_args+=("$1" "$2")
      doctor_args+=("$1" "$2")
      shift 2
      ;;
    --reconcile-report|--reconcile-validation-report)
      doctor_args+=("$1" "$2")
      shift 2
      ;;
    *)
      doctor_args+=("$1")
      shift
      ;;
  esac
done

assess_cmd=(python3 "$ROOT_DIR/scripts/assess_federated_ci_summary_readiness.py")
if [[ ${#assess_args[@]} -gt 0 ]]; then
  assess_cmd+=("${assess_args[@]}")
fi

doctor_cmd=(python3 "$ROOT_DIR/scripts/doctor_federated_ci_summary.py" --require-pass)
if [[ ${#doctor_args[@]} -gt 0 ]]; then
  doctor_cmd+=("${doctor_args[@]}")
fi

"${assess_cmd[@]}" >/dev/null
"${doctor_cmd[@]}"
