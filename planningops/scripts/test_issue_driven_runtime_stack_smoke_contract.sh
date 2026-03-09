#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

output_path="$tmp_dir/issue-driven-runtime-stack-smoke.json"

python3 "${ROOT_DIR}/planningops/scripts/federation/run_issue_driven_runtime_stack_smoke.py" \
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
  --run-id "issue-driven-runtime-stack-smoke-contract" \
  --output "$output_path"

python3 - <<'PY' "$output_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["reason_code"] == "issue_runtime_stack_smoke_ok", report
assert report["source_issue"]["number"] == 4242, report
assert report["mission"]["missionId"].startswith("issue-4242-"), report
assert len(report["component_runs"]) == 3, report
components = {row["component"]: row for row in report["component_runs"]}
assert sorted(components) == ["monday_issue_mission", "observability", "provider"], report
assert components["monday_issue_mission"]["report_summary"]["verdict"] == "pass", report
assert components["provider"]["report_summary"]["profile"] == "local", report
assert components["observability"]["report_summary"]["launcher_mode_requested"] == "dry-run", report
PY

echo "issue-driven runtime stack smoke contract ok"
