#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

REPORT_PATH="$TMP_DIR/local-runtime-stack-smoke.json"
PYTHON_BIN="${PYTHON_BIN:-python3}"

"${PYTHON_BIN}" "${ROOT_DIR}/planningops/scripts/federation/run_local_runtime_stack_smoke.py" \
  --workspace-root "${ROOT_DIR}/.." \
  --bootstrap-mode auto \
  --run-id "contract-local-runtime-stack-smoke" \
  --simulate-deepagents-task "triage the operator request" \
  --simulate-deepagents-task "summarize the runtime handoff" \
  --output "${REPORT_PATH}"

python3 - <<'PY' "${REPORT_PATH}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

assert report["verdict"] == "pass", report
assert report["failure_count"] == 0, report
assert report["requested_profile"] == "local", report
assert report["bootstrap"]["managed_python"], report

launcher_runs = report["launcher_runs"]
assert len(launcher_runs) == 4, launcher_runs
launcher_names = [row["name"] for row in launcher_runs]
assert launcher_names == [
    "provider_gateway",
    "observability_gateway",
    "provider_gateway_stop",
    "observability_gateway_stop",
], launcher_runs
for row in launcher_runs:
    assert row["exit_code"] == 0, row

component_runs = report["component_runs"]
assert len(component_runs) == 3, component_runs
names = {row["component"] for row in component_runs}
assert names == {"monday", "provider", "observability"}, component_runs

for row in component_runs:
    assert row["exit_code"] == 0, row
    assert row["report_exists"] is True, row
    assert row["attempt_count"] >= 1, row
    assert isinstance(row["recovered_after_retry"], bool), row
    assert len(row["attempts"]) == row["attempt_count"], row
    verdict = row["report_summary"]["verdict"]
    assert verdict in {"pass", "skip"}, row
    if verdict == "skip":
        assert row["report_summary"]["reason_code"] == "tsx_fetch_unavailable_offline", row

print("local runtime stack smoke contract ok")
PY
