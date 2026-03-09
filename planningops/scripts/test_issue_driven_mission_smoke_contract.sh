#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

output_path="$tmp_dir/issue-driven-mission-smoke.json"

python3 "${ROOT_DIR}/planningops/scripts/federation/run_issue_driven_mission_smoke.py" \
  --workspace-root "${ROOT_DIR}" \
  --issue-file "planningops/fixtures/issue-driven-mission-smoke/issue-sample.json" \
  --monday-repo-dir "${ROOT_DIR}/planningops/fixtures/issue-driven-mission-smoke" \
  --monday-script "monday_smoke_stub.py" \
  --run-id "issue-driven-mission-smoke-contract" \
  --output "$output_path"

python3 - <<'PY' "$output_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["reason_code"] == "issue_mission_smoke_ok", report
assert report["issue_source"]["kind"] == "fixture", report
assert report["source_issue"]["number"] == 4242, report
assert report["mission"]["missionId"].startswith("issue-4242-"), report
assert report["mission"]["objective"] == "Verify that a planningops issue can be normalized into a monday mission input.", report
assert report["monday_report_exists"] is True, report
summary = report["monday_report_summary"]
assert summary["verdict"] == "pass", report
assert summary["mission_source"] == "mission_file", report
assert summary["requested_mission"]["missionId"] == report["mission"]["missionId"], report
assert summary["requested_mission"]["objective"] == report["mission"]["objective"], report
PY

echo "issue-driven mission smoke contract ok"
