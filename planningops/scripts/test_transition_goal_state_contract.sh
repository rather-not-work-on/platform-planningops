#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

registry="$tmpdir/active-goal-registry.json"
report="$tmpdir/report.json"

cat >"$registry" <<'JSON'
{
  "registry_version": 1,
  "active_goal_key": "goal-a",
  "goals": [
    {
      "goal_key": "goal-a",
      "title": "Goal A",
      "status": "active",
      "owner_repo": "rather-not-work-on/platform-planningops",
      "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1-goal-brief.md",
      "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1.execution-contract.json",
      "completion_contract_refs": [
        "planningops/contracts/goal-completion-contract.md"
      ],
      "operator_channels": {
        "primary_operator_channel": {
          "kind": "slack_skill_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        },
        "terminal_notification_channel": {
          "kind": "email_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        }
      }
    },
    {
      "goal_key": "goal-b",
      "title": "Goal B",
      "status": "draft",
      "owner_repo": "rather-not-work-on/platform-planningops",
      "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2-goal-brief.md",
      "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave2.execution-contract.json",
      "completion_contract_refs": [
        "planningops/contracts/goal-completion-contract.md",
        "planningops/contracts/active-goal-registry-contract.md"
      ],
      "operator_channels": {
        "primary_operator_channel": {
          "kind": "slack_skill_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        },
        "terminal_notification_channel": {
          "kind": "email_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        }
      }
    }
  ]
}
JSON

python3 planningops/scripts/core/goals/transition_goal_state.py \
  --registry "$registry" \
  --goal-key goal-a \
  --to-status achieved \
  --activate-next-goal-key goal-b \
  --reason "goal_completed" \
  --evidence-ref "planningops/artifacts/validation/goal-driven-autonomy-wave1-review.json" \
  --output "$report" >/dev/null

python3 - <<'PY' "$report" "$registry"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
registry = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["active_goal_key_after"] == "goal-b", report
assert registry["active_goal_key"] == "goal-a", registry
PY

python3 planningops/scripts/core/goals/transition_goal_state.py \
  --registry "$registry" \
  --goal-key goal-a \
  --to-status achieved \
  --activate-next-goal-key goal-b \
  --reason "goal_completed" \
  --evidence-ref "planningops/artifacts/validation/goal-driven-autonomy-wave1-review.json" \
  --mode apply \
  --output "$report" >/dev/null

python3 - <<'PY' "$report" "$registry"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
registry = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert registry["active_goal_key"] == "goal-b", registry
goals = {item["goal_key"]: item for item in registry["goals"]}
assert goals["goal-a"]["status"] == "achieved", goals
assert goals["goal-b"]["status"] == "active", goals
PY

if python3 planningops/scripts/core/goals/transition_goal_state.py \
  --registry "$registry" \
  --goal-key goal-b \
  --to-status blocked \
  --reason "blocked_without_successor" \
  --output "$report" >/dev/null 2>&1; then
  echo "expected active->blocked without successor to fail"
  exit 1
fi

python3 - <<'PY' "$report"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert "activate_next_goal_key required when transitioning the current active goal away from active" in report["errors"], report
PY

echo "goal lifecycle transition contract ok"
