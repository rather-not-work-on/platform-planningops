#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

valid_registry="$tmpdir/active-goal-registry.json"
invalid_registry="$tmpdir/invalid-active-goal-registry.json"
report_path="$tmpdir/report.json"

cp planningops/config/active-goal-registry.json "$valid_registry"

python3 planningops/scripts/validate_active_goal_registry.py \
  --registry "$valid_registry" \
  --output "$report_path" \
  --strict >/dev/null

resolved_contract="$(python3 planningops/scripts/core/goals/resolve_active_goal.py --registry "$valid_registry" --field execution_contract_file)"
[ "$resolved_contract" = "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1.execution-contract.json" ]

cat >"$invalid_registry" <<'JSON'
{
  "registry_version": 1,
  "active_goal_key": "missing",
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
    }
  ]
}
JSON

if python3 planningops/scripts/validate_active_goal_registry.py --registry "$invalid_registry" --output "$report_path" --strict >/dev/null 2>&1; then
  echo "expected invalid registry validation to fail"
  exit 1
fi

echo "active goal registry contract ok"
