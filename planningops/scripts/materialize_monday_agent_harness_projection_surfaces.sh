#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULT_PROJECTION_ROOT="${ROOT_DIR}/../monday/runtime-artifacts/agent-harness"

PROJECTION_ROOT="${DEFAULT_PROJECTION_ROOT}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --projection-root)
      PROJECTION_ROOT="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

cd "${ROOT_DIR}"

run_python() {
  python3 "$@"
}

materialize_level() {
  local resolve_script="$1"
  local artifact_file="$2"
  local bundle_file="$3"
  local validate_script="$4"
  local validation_file="$5"
  local doctor_script="${6:-}"

  run_python "planningops/scripts/${resolve_script}" \
    --artifact-file "${artifact_file}" \
    --output "${bundle_file}" \
    >/dev/null
  run_python "planningops/scripts/${validate_script}" \
    --bundle-file "${bundle_file}" \
    --output "${validation_file}" \
    --strict \
    >/dev/null
  if [[ -n "${doctor_script}" ]]; then
    run_python "planningops/scripts/${doctor_script}" >/dev/null
  fi
}

run_python planningops/scripts/doctor_monday_agent_harness_projection.py \
  --projection-root "${PROJECTION_ROOT}" \
  --require-pass \
  >/dev/null

materialize_level \
  resolve_monday_agent_harness_projection_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-validation.json \
  doctor_monday_agent_harness_projection_status_bundle.py

materialize_level \
  resolve_monday_agent_harness_projection_status_bundle_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-validation.json \
  doctor_monday_agent_harness_projection_status_bundle_status_bundle.py

materialize_level \
  resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-validation.json \
  doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py

materialize_level \
  resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.json \
  doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py

materialize_level \
  resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json \
  doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py

materialize_level \
  resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json \
  doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py

materialize_level \
  resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json \
  validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py \
  planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json

echo "monday agent harness projection surfaces materialized"
