#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

workspace_root="$tmp_dir/workspace"
mkdir -p \
  "$workspace_root/monday/packages/executor-ralph-loop" \
  "$workspace_root/platform-provider-gateway/services/provider-runtime" \
  "$workspace_root/platform-provider-gateway/adapters/provider-codex" \
  "$workspace_root/platform-observability-gateway/services/telemetry-gateway"

for repo in monday platform-provider-gateway platform-observability-gateway; do
  touch "$workspace_root/$repo/package.json"
  touch "$workspace_root/$repo/pnpm-workspace.yaml"
  touch "$workspace_root/$repo/tsconfig.base.json"
done

touch "$workspace_root/monday/packages/executor-ralph-loop/package.json"
touch "$workspace_root/platform-provider-gateway/services/provider-runtime/package.json"
touch "$workspace_root/platform-provider-gateway/adapters/provider-codex/package.json"
touch "$workspace_root/platform-observability-gateway/services/telemetry-gateway/package.json"

contract_path="$tmp_dir/contract.json"
cat > "$contract_path" <<'JSON'
{
  "execution_contract": {
    "plan_id": "test-runtime-skeleton-wave",
    "plan_revision": 1,
    "source_of_truth": "docs/workbench/example.md",
    "items": [
      {
        "plan_item_id": "S10",
        "execution_order": 10,
        "title": "monday workspace bootstrap",
        "target_repo": "rather-not-work-on/monday",
        "component": "runtime",
        "workflow_state": "ready_implementation",
        "loop_profile": "l3_implementation_tdd",
        "plan_lane": "m2_sync_core",
        "depends_on": [],
        "primary_output": "package.json"
      },
      {
        "plan_item_id": "S11",
        "execution_order": 20,
        "title": "monday core package",
        "target_repo": "rather-not-work-on/monday",
        "component": "runtime",
        "workflow_state": "backlog",
        "loop_profile": "l3_implementation_tdd",
        "plan_lane": "m2_sync_core",
        "depends_on": [10],
        "primary_output": "packages/executor-ralph-loop/package.json"
      },
      {
        "plan_item_id": "S20",
        "execution_order": 40,
        "title": "provider service",
        "target_repo": "rather-not-work-on/platform-provider-gateway",
        "component": "provider_gateway",
        "workflow_state": "ready_implementation",
        "loop_profile": "l3_implementation_tdd",
        "plan_lane": "m2_sync_core",
        "depends_on": [],
        "primary_output": "services/provider-runtime/package.json"
      },
      {
        "plan_item_id": "S21",
        "execution_order": 50,
        "title": "provider adapter",
        "target_repo": "rather-not-work-on/platform-provider-gateway",
        "component": "provider_gateway",
        "workflow_state": "backlog",
        "loop_profile": "l3_implementation_tdd",
        "plan_lane": "m2_sync_core",
        "depends_on": [40],
        "primary_output": "adapters/provider-codex/package.json"
      },
      {
        "plan_item_id": "S30",
        "execution_order": 60,
        "title": "observability runtime",
        "target_repo": "rather-not-work-on/platform-observability-gateway",
        "component": "observability_gateway",
        "workflow_state": "ready_implementation",
        "loop_profile": "l3_implementation_tdd",
        "plan_lane": "m2_sync_core",
        "depends_on": [],
        "primary_output": "services/telemetry-gateway/package.json"
      }
    ]
  }
}
JSON

python3 planningops/scripts/federation/validate_runtime_skeleton_scaffold.py \
  --workspace-root "$workspace_root" \
  --contract "$contract_path" \
  --bootstrap-mode off \
  --skip-command-checks \
  --output "$tmp_dir/pass-report.json"

python3 - <<'PY' "$tmp_dir/pass-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["failure_count"] == 0, report
assert report["output_check_count"] == 5, report
assert report["root_check_count"] == 9, report
assert report["command_check_count"] == 0, report
print("runtime scaffold validator pass case ok")
PY

rm "$workspace_root/platform-provider-gateway/adapters/provider-codex/package.json"

if python3 planningops/scripts/federation/validate_runtime_skeleton_scaffold.py \
  --workspace-root "$workspace_root" \
  --contract "$contract_path" \
  --bootstrap-mode off \
  --skip-command-checks \
  --output "$tmp_dir/fail-report.json"; then
  echo "expected failure for missing provider adapter package"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/fail-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert report["failure_count"] == 1, report
failed = [row for row in report["output_checks"] if row["verdict"] == "fail"]
assert failed and failed[0]["plan_item_id"] == "S21", report
print("runtime scaffold validator failure case ok")
PY

echo "validate_runtime_skeleton_scaffold contract ok"
