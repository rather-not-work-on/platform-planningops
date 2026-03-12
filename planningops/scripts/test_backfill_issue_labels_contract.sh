#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

issues_file="$tmpdir/issues.json"
report_file="$tmpdir/report.json"

cat >"$issues_file" <<'JSON'
[
  {
    "repo": "rather-not-work-on/platform-planningops",
    "number": 60,
    "state": "open",
    "updated_at": "2026-03-12T00:00:00+00:00",
    "title": "plan: [60] Add recurring backlog materialization runner",
    "url": "https://github.com/rather-not-work-on/platform-planningops/issues/60",
    "body": "## Planning Context\n- plan_doc: `docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md`\n- plan_id: `uap-backlog-wave26`\n- plan_revision: `1`\n- plan_item_id: `A60`\n- execution_order: `60`\n- target_repo: `rather-not-work-on/platform-planningops`\n- component: `planningops`\n- workflow_state: `ready_implementation`\n- loop_profile: `l4_integration_reconcile`\n- plan_lane: `m3_guardrails`\n- depends_on: `-`\n- primary_output: `planningops/scripts/core/backlog/materialize.py`\n\n## Problem Statement\n- Resolve this plan item with deterministic artifacts and contract-aligned updates.\n\n## Interfaces & Dependencies\n- target_repo: `rather-not-work-on/platform-planningops`\n- depends_on: `-`\n\n## Evidence\n- `docs/workbench/unified-personal-agent-platform/plans/runtime-mission-wave26-issue-pack.md`\n- `planningops/scripts/core/backlog/materialize.py`\n\n## Acceptance Criteria\n- [ ] Required artifact created and linked under Evidence.\n- [ ] Contract/path references are updated and validated.\n\n## Definition of Done\n- [ ] Required artifact created\n- [ ] Validation report attached\n- [ ] Project fields updated with evidence",
    "labels": []
  }
]
JSON

python3 planningops/scripts/backfill_issue_labels.py \
  --repo rather-not-work-on/platform-planningops \
  --issues-file "$issues_file" \
  --write-updated-issues-file "$issues_file" \
  --output "$report_file" \
  --apply

python3 - <<'PY' "$issues_file" "$report_file"
import json
import sys
from pathlib import Path

issues = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))

assert len(issues) == 1, issues
labels = sorted(label["name"] for label in issues[0]["labels"])
assert labels == ["area/planningops", "p2", "task", "type/hardening"], labels

assert report["mode"] == "apply", report
assert report["issues_in_scope"] == 1, report
assert report["issues_applied"] == 1, report
assert report["rows"][0]["apply_status"] == "applied_local", report["rows"][0]

print("backfill_issue_labels offline contract ok")
PY
