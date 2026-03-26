#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

PLAIN_PYTHON_BIN="${PLAIN_PYTHON_BIN:-python3}"
RESOLVER="${ROOT_DIR}/planningops/scripts/resolve_plain_python_compat_manifest.py"
ISSUE_REPORT_PATH="$TMP_DIR/issue-driven-runtime-stack-smoke.json"
LOCAL_REPORT_PATH="$TMP_DIR/local-runtime-stack-smoke.json"

SEQUENCE_JSON="$("${PLAIN_PYTHON_BIN}" "${RESOLVER}" --mode sequence)"
ISSUE_STACK_SCRIPT="$(python3 - <<'PY' "$SEQUENCE_JSON"
import json
import sys

print(json.loads(sys.argv[1])["issue_driven_resolved_path"])
PY
)"
LOCAL_STACK_SCRIPT="$(python3 - <<'PY' "$SEQUENCE_JSON"
import json
import sys

print(json.loads(sys.argv[1])["local_resolved_path"])
PY
)"

"${PLAIN_PYTHON_BIN}" "${ISSUE_STACK_SCRIPT}" \
  --workspace-root "${ROOT_DIR}" \
  --issue-file "planningops/fixtures/issue-driven-mission-smoke/issue-sample.json" \
  --issue-mission-runner "planningops/scripts/federation/run_issue_driven_mission_smoke.py" \
  --monday-repo-dir "${ROOT_DIR}/planningops/fixtures/issue-driven-mission-smoke" \
  --monday-script "monday_smoke_stub.py" \
  --provider-repo-dir "${ROOT_DIR}/planningops/fixtures/issue-driven-runtime-stack-smoke" \
  --provider-script "provider_live_smoke_stub.py" \
  --provider-launcher-mode "dry-run" \
  --observability-repo-dir "${ROOT_DIR}/planningops/fixtures/issue-driven-runtime-stack-smoke" \
  --observability-script "o11y_live_smoke_stub.py" \
  --observability-launcher-mode "dry-run" \
  --run-id "issue-driven-runtime-stack-smoke-sequence-contract" \
  --output "$ISSUE_REPORT_PATH"

"${PLAIN_PYTHON_BIN}" "${LOCAL_STACK_SCRIPT}" \
  --workspace-root "${WORKSPACE_DIR}" \
  --bootstrap-mode auto \
  --run-id "local-runtime-stack-smoke-sequence-contract" \
  --simulate-deepagents-task "triage the operator request" \
  --simulate-deepagents-task "summarize the runtime handoff" \
  --output "$LOCAL_REPORT_PATH"

python3 - <<'PY' "$ISSUE_REPORT_PATH" "$LOCAL_REPORT_PATH"
import json
import sys
from pathlib import Path

issue_report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
local_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert issue_report["verdict"] == "pass", issue_report
assert issue_report["reason_code"] == "issue_runtime_stack_smoke_ok", issue_report

assert local_report["verdict"] == "pass", local_report
assert local_report["failure_count"] == 0, local_report
assert local_report["requested_profile"] == "local", local_report
assert local_report["bootstrap"]["managed_python"], local_report
components = {row["component"]: row for row in local_report["component_runs"]}
assert sorted(components) == ["monday", "observability", "provider"], local_report
for row in components.values():
    assert row["exit_code"] == 0, row
    assert row["report_exists"] is True, row
PY

echo "runtime stack smoke sequence contract ok"
