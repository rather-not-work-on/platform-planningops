#!/usr/bin/env bash
set -euo pipefail

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p \
  "$tmpdir/docs/initiatives/unified-personal-agent-platform/40-quality" \
  "$tmpdir/planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops" \
  "$tmpdir/docs/archive/github-issues/rather-not-work-on/platform-planningops"

cat > "$tmpdir/docs/initiatives/unified-personal-agent-platform/40-quality/uap-inventory-issue-lifecycle-summary.quality.md" <<'EOF_DOC'
---
title: Inventory Summary
memory_tier: L1
---

# Inventory Summary
EOF_DOC

now_utc=$(python3 - <<'PY'
from datetime import datetime, timezone
print(datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"))
PY
)

cat > "$tmpdir/open-inventory-issue.json" <<EOF_JSON
{
  "repo": "rather-not-work-on/platform-planningops",
  "number": 86,
  "title": "[stock-034] dependency blocker seed",
  "url": "https://example.local/issues/86",
  "state": "OPEN",
  "createdAt": "${now_utc}",
  "body": "## Planning Context\n- plan_item_id: \`stock-034-9599\`\n- target_repo: \`rather-not-work-on/platform-planningops\`\n- component: \`planningops\`\n- execution_kind: \`inventory\`\n- inventory_lifecycle: \`active\`\n- workflow_state: \`backlog\`\n- loop_profile: \`l1_contract_clarification\`\n- execution_order: \`9599\`\n- plan_lane: \`M3 Guardrails\`\n- depends_on: \`-\`\n\n## Problem Statement\n- Preserve stock history.\n\n## Interfaces & Dependencies\n- depends_on: \`-\`\n\n## Evidence\n- \`docs/workbench/example.md\`\n\n## Acceptance Criteria\n- [ ] remains inventory only\n- [ ] not selected for execution\n\n## Definition of Done\n- [ ] validation report attached\n- [ ] project fields synced with evidence\n"
}
EOF_JSON

python3 planningops/scripts/inventory_issue_lifecycle.py archive \
  --root "$tmpdir" \
  --issue-json "$tmpdir/open-inventory-issue.json" \
  --compacted-into docs/initiatives/unified-personal-agent-platform/40-quality/uap-inventory-issue-lifecycle-summary.quality.md \
  --output "$tmpdir/archive-report.json" \
  --strict

python3 - <<'PY' "$tmpdir/archive-report.json" "$tmpdir"
import json
import pathlib
import sys

report = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert report["verdict"] == "pass", report
manifest = report["manifest"]
assert manifest["source_issue_ref"] == "rather-not-work-on/platform-planningops#86", manifest
assert manifest["archive_ref"] == manifest["manifest_path"], manifest
assert "inventory_lifecycle: `archived`" in manifest["archived_issue_body"], manifest["archived_issue_body"]
root = pathlib.Path(sys.argv[2])
assert (root / manifest["archive_path"]).exists(), manifest["archive_path"]
assert (root / manifest["manifest_path"]).exists(), manifest["manifest_path"]
PY

python3 planningops/scripts/inventory_issue_lifecycle.py rehydrate \
  --root "$tmpdir" \
  --manifest planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-86.json \
  --output "$tmpdir/rehydrate-report.json" \
  --strict

python3 - <<'PY' "$tmpdir/rehydrate-report.json"
import json
import pathlib
import sys

report = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert report["verdict"] == "pass", report
assert report["checksum_match"] is True, report
PY

python3 planningops/scripts/inventory_issue_lifecycle.py audit \
  --root "$tmpdir" \
  --issues-file "$tmpdir/open-inventory-issue.json" \
  --repo rather-not-work-on/platform-planningops \
  --output "$tmpdir/audit-open-report.json" \
  --strict

python3 - <<'PY' "$tmpdir/open-inventory-issue.json" "$tmpdir/archived-issues.json" "$tmpdir/planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-86.json"
import json
import pathlib
import sys

issue = json.loads(pathlib.Path(sys.argv[1]).read_text())
manifest = json.loads(pathlib.Path(sys.argv[3]).read_text())
issue["state"] = "CLOSED"
issue["body"] = manifest["archived_issue_body"]
pathlib.Path(sys.argv[2]).write_text(json.dumps([issue], ensure_ascii=True, indent=2) + "\n")
PY

python3 planningops/scripts/inventory_issue_lifecycle.py audit \
  --root "$tmpdir" \
  --issues-file "$tmpdir/archived-issues.json" \
  --repo rather-not-work-on/platform-planningops \
  --output "$tmpdir/audit-archived-report.json" \
  --strict

python3 - <<'PY' "$tmpdir/open-inventory-issue.json" "$tmpdir/invalid-open-inventory-issue.json"
import json
import pathlib
import sys

issue = json.loads(pathlib.Path(sys.argv[1]).read_text())
issue["body"] = issue["body"].replace("- inventory_lifecycle: `active`\n", "")
pathlib.Path(sys.argv[2]).write_text(json.dumps(issue, ensure_ascii=True, indent=2) + "\n")
PY

set +e
python3 planningops/scripts/inventory_issue_lifecycle.py audit \
  --root "$tmpdir" \
  --issues-file "$tmpdir/invalid-open-inventory-issue.json" \
  --repo rather-not-work-on/platform-planningops \
  --output "$tmpdir/audit-invalid-report.json" \
  --strict >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid lifecycle fixture"
  exit 1
fi

echo "inventory issue lifecycle contract test ok"
