#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RESOLVER="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ENTRYPOINTS_PATH="${TMP_DIR}/plain-python-compat-entrypoints.json"
SEQUENCE_PATH="${TMP_DIR}/plain-python-compat-sequence.json"
GUARDRAILS_PATH="${TMP_DIR}/plain-python-compat-guardrails.json"

python3 "${RESOLVER}" --mode entrypoints >"${ENTRYPOINTS_PATH}"
python3 "${RESOLVER}" --mode sequence >"${SEQUENCE_PATH}"
python3 "${RESOLVER}" --mode guardrails >"${GUARDRAILS_PATH}"

python3 - <<'PY' "${ENTRYPOINTS_PATH}" "${SEQUENCE_PATH}" "${GUARDRAILS_PATH}"
import json
import sys
from pathlib import Path

entrypoints_report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
sequence_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
guardrails_report = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

assert entrypoints_report["entrypoint_count"] >= 3, entrypoints_report
entrypoints = entrypoints_report["entrypoints"]
ids = {entry["id"] for entry in entrypoints}
assert sequence_report["issue_driven_entrypoint_id"] in ids, sequence_report
assert sequence_report["local_entrypoint_id"] in ids, sequence_report

entrypoints_by_id = {entry["id"]: entry for entry in entrypoints}
assert (
    entrypoints_by_id[sequence_report["issue_driven_entrypoint_id"]]["resolved_path"]
    == sequence_report["issue_driven_resolved_path"]
), sequence_report
assert (
    entrypoints_by_id[sequence_report["local_entrypoint_id"]]["resolved_path"]
    == sequence_report["local_resolved_path"]
), sequence_report

for entry in entrypoints:
    assert Path(entry["resolved_path"]).is_file(), entry

assert len(guardrails_report) >= 2, guardrails_report
guardrail_ids = [step["id"] for step in guardrails_report]
assert len(set(guardrail_ids)) == len(guardrail_ids), guardrails_report
assert guardrails_report[-2]["id"] == "compat-smoke", guardrails_report
assert guardrails_report[-1]["id"] == "runtime-stack-sequence", guardrails_report
assert guardrails_report[-2]["local_matrix_command"].startswith("PLAIN_PYTHON_BIN='${SYSTEM_PYTHON_BIN}' "), guardrails_report
assert guardrails_report[-2]["workflow_command"] == "bash planningops/scripts/test_cross_repo_plain_python_compat.sh", guardrails_report
PY

echo "resolve plain python compat manifest ok"
