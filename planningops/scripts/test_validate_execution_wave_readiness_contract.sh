#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

workspace_root="$tmp_dir/workspace"
mkdir -p "$workspace_root/platform-planningops/docs" "$workspace_root/monday/packages/contract-bindings"

touch "$workspace_root/platform-planningops/docs/meta.md"
touch "$workspace_root/monday/packages/contract-bindings/runtime_ports.ts"

contract_path="$tmp_dir/contract.json"
cat > "$contract_path" <<'JSON'
{
  "execution_contract": {
    "plan_id": "test-wave",
    "plan_revision": 1,
    "source_of_truth": "docs/workbench/test.md",
    "items": [
      {
        "plan_item_id": "W10",
        "execution_order": 10,
        "title": "monday ports",
        "target_repo": "rather-not-work-on/monday",
        "component": "runtime",
        "workflow_state": "ready_implementation",
        "loop_profile": "l3_implementation_tdd",
        "plan_lane": "m2_sync_core",
        "depends_on": [],
        "primary_output": "packages/contract-bindings/runtime_ports.ts"
      },
      {
        "plan_item_id": "W60",
        "execution_order": 60,
        "title": "wave readiness",
        "target_repo": "rather-not-work-on/platform-planningops",
        "component": "planningops",
        "workflow_state": "backlog",
        "loop_profile": "l4_integration_reconcile",
        "plan_lane": "m2_sync_core",
        "depends_on": [10],
        "primary_output": "planningops/artifacts/validation/test-readiness.json"
      }
    ]
  }
}
JSON

report_pass="$tmp_dir/blueprint-report.json"
cat > "$report_pass" <<'JSON'
{"verdict":"pass"}
JSON

open_issues_pass="$tmp_dir/open-issues-pass.json"
cat > "$open_issues_pass" <<'JSON'
[
  {
    "number": 60,
    "title": "wave readiness",
    "url": "https://example.test/issues/60",
    "body": "## Planning Context\n- plan_id: `test-wave`\n- plan_item_id: `W60`\n"
  }
]
JSON

python3 planningops/scripts/federation/validate_execution_wave_readiness.py \
  --contract "$contract_path" \
  --ready-order 60 \
  --workspace-root "$workspace_root" \
  --blueprint-report "$report_pass" \
  --open-issues-file "$open_issues_pass" \
  --output "$tmp_dir/pass.json"

python3 - <<'PY' "$tmp_dir/pass.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["prerequisite_item_count"] == 1, report
assert report["failure_count"] == 0, report
print("validate_execution_wave_readiness pass case ok")
PY

rm "$workspace_root/monday/packages/contract-bindings/runtime_ports.ts"

open_issues_fail="$tmp_dir/open-issues-fail.json"
cat > "$open_issues_fail" <<'JSON'
[
  {
    "number": 10,
    "title": "monday ports",
    "url": "https://example.test/issues/10",
    "body": "## Planning Context\n- plan_id: `test-wave`\n- plan_item_id: `W10`\n"
  }
]
JSON

if python3 planningops/scripts/federation/validate_execution_wave_readiness.py \
  --contract "$contract_path" \
  --ready-order 60 \
  --workspace-root "$workspace_root" \
  --blueprint-report "$report_pass" \
  --open-issues-file "$open_issues_fail" \
  --output "$tmp_dir/fail.json"; then
  echo "expected readiness validation to fail"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/fail.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert report["failure_count"] >= 2, report
print("validate_execution_wave_readiness fail case ok")
PY

echo "validate_execution_wave_readiness contract ok"
