#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_root="$tmp_dir/repo"
mkdir -p "$fixture_root/docs/workbench/unified-personal-agent-platform/plans"

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/plans/2026-03-24-clean-plan.md" <<'EOF_PLAN'
---
title: plan: Clean Governance Smoke
type: plan
date: 2026-03-24
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Clean governance smoke fixture.
topic: governance-smoke
---
EOF_PLAN

cat > "$tmp_dir/inventory-issues.json" <<'EOF_JSON'
[
  {
    "repo": "rather-not-work-on/platform-planningops",
    "number": 901,
    "title": "[stock-901] governance smoke inventory",
    "url": "https://example.local/issues/901",
    "state": "OPEN",
    "createdAt": "2026-03-24T00:00:00Z",
    "body": "## Planning Context\n- plan_item_id: `stock-901-9001`\n- target_repo: `rather-not-work-on/platform-planningops`\n- component: `planningops`\n- execution_kind: `inventory`\n- inventory_lifecycle: `active`\n- workflow_state: `backlog`\n- loop_profile: `l1_contract_clarification`\n- execution_order: `9001`\n- plan_lane: `M3 Guardrails`\n- depends_on: `-`\n\n## Problem Statement\n- Preserve governance smoke issue.\n\n## Interfaces & Dependencies\n- depends_on: `-`\n\n## Evidence\n- `docs/workbench/example.md`\n\n## Acceptance Criteria\n- [ ] remains inventory only\n\n## Definition of Done\n- [ ] validation report attached\n"
  }
]
EOF_JSON

memory_output="$tmp_dir/memory-gate-report.json"
inventory_output="$tmp_dir/inventory-issue-lifecycle-report.json"

bash "$ROOT_DIR/planningops/scripts/run_control_plane_governance_ci_check.sh" \
  --python-bin python3 \
  --root "$fixture_root" \
  --memory-output "$memory_output" \
  --inventory-output "$inventory_output" \
  --inventory-issues-file "$tmp_dir/inventory-issues.json"

python3 - <<'PY' "$memory_output" "$inventory_output"
import json
import sys
from pathlib import Path

memory_report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
inventory_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert memory_report["verdict"] == "pass", memory_report
assert memory_report["trigger_count"] == 0, memory_report
assert inventory_report["verdict"] == "pass", inventory_report
assert inventory_report["violation_count"] == 0, inventory_report
PY

echo "control plane governance ci check smoke ok"
