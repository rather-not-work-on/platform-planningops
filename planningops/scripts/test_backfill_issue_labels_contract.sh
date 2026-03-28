#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

issues_file="$tmpdir/issues.json"
report_file="$tmpdir/report.json"

cp planningops/fixtures/issue-label-backfill-sample-issues.json "$issues_file"

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
