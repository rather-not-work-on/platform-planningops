#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOCAL_MATRIX_PATH="${ROOT_DIR}/planningops/scripts/federation/federated_ci_matrix_local.sh"
WORKFLOW_PATH="${ROOT_DIR}/.github/workflows/federated-ci-matrix.yml"
RESOLVER_PATH="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"
HELPER_PATH="${ROOT_DIR}/planningops/scripts/run_plain_python_compat_workflow_chain.sh"
COMPAT_TEST_PATH="${ROOT_DIR}/planningops/scripts/test_cross_repo_plain_python_compat.sh"
SEQUENCE_TEST_PATH="${ROOT_DIR}/planningops/scripts/test_runtime_stack_smoke_sequence_contract.sh"
ANNOTATION_TEST_PATH="${ROOT_DIR}/planningops/scripts/test_cross_repo_plain_python_annotation_contract.sh"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
GUARDRAILS_PATH="${TMP_DIR}/plain-python-compat-guardrails.json"

python3 "${RESOLVER_PATH}" --mode guardrails >"${GUARDRAILS_PATH}"

python3 - <<'PY' \
  "$LOCAL_MATRIX_PATH" \
  "$WORKFLOW_PATH" \
  "$HELPER_PATH" \
  "$COMPAT_TEST_PATH" \
  "$SEQUENCE_TEST_PATH" \
  "$ANNOTATION_TEST_PATH" \
  "$GUARDRAILS_PATH"
import json
import subprocess
import sys
from pathlib import Path

local_matrix = Path(sys.argv[1]).read_text(encoding="utf-8")
workflow = Path(sys.argv[2]).read_text(encoding="utf-8")
helper_path = Path(sys.argv[3])
compat_test = Path(sys.argv[4]).read_text(encoding="utf-8")
sequence_test = Path(sys.argv[5]).read_text(encoding="utf-8")
annotation_test = Path(sys.argv[6]).read_text(encoding="utf-8")
guardrails = json.loads(Path(sys.argv[7]).read_text(encoding="utf-8"))

workflow_loop_guardrails = workflow.split("  loop-guardrails:", 1)[1].split("  federated-summary:", 1)[0]
workflow_invocation = subprocess.check_output(
    ["bash", str(helper_path), "--print-workflow-invocation"],
    text=True,
).strip()
workflow_steps = subprocess.check_output(
    ["bash", str(helper_path), "--print-steps"],
    text=True,
).splitlines()

guardrail_ids = [step["id"] for step in guardrails]
assert len(set(guardrail_ids)) == len(guardrail_ids), "guardrail ids must be unique"

required_local_snippets = [step["local_matrix_command"] for step in guardrails]
required_workflow_snippets = [step["workflow_command"] for step in guardrails]

for snippet in required_local_snippets:
    assert snippet in local_matrix, f"missing local plain-python wiring snippet: {snippet}"
    assert local_matrix.count(snippet) == 1, f"local plain-python wiring snippet should appear exactly once: {snippet}"

assert workflow_invocation in workflow_loop_guardrails, "workflow loop-guardrails missing plain-python compat helper invocation"
assert workflow_loop_guardrails.count(workflow_invocation) == 1, "workflow loop-guardrails helper invocation should appear exactly once"
assert workflow_steps == required_workflow_snippets, "plain-python compat workflow helper steps drifted from the manifest"
for snippet in required_workflow_snippets:
    assert snippet not in workflow_loop_guardrails, f"workflow loop-guardrails should delegate raw plain-python snippet to helper: {snippet}"

local_order = required_local_snippets

local_positions = [local_matrix.index(snippet) for snippet in local_order]
assert local_positions == sorted(local_positions), "local plain-python wiring order drifted"

resolver_name = "resolve_plain_python_compat_manifest.py"
manifest_name = "plain-python-compat-manifest.json"

for label, content in (
    ("compat", compat_test),
    ("sequence", sequence_test),
    ("annotation", annotation_test),
):
    assert resolver_name in content, f"{label} test must use the canonical resolver"

for label, content in (
    ("compat", compat_test),
    ("sequence", sequence_test),
):
    assert manifest_name not in content, f"{label} test should not hardcode the manifest path"
PY

echo "plain python compat manifest wiring ok"
