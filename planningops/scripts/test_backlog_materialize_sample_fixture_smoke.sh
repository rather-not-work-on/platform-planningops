#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

manifest_issues="$tmpdir/program-manifest-issues.json"
label_issues="$tmpdir/issue-label-issues.json"
manifest_output="$tmpdir/program-manifest.json"
manifest_report="$tmpdir/program-manifest-report.json"
label_report="$tmpdir/issue-label-backfill-report.json"

cp planningops/fixtures/program-manifest-sample-issues.json "$manifest_issues"
cp planningops/fixtures/issue-label-backfill-sample-issues.json "$label_issues"

python3 planningops/scripts/build_program_manifest.py \
  --issues-file "$manifest_issues" \
  --output "$manifest_output" \
  --report-output "$manifest_report" \
  --strict

python3 planningops/scripts/backfill_issue_labels.py \
  --repo rather-not-work-on/platform-planningops \
  --issues-file "$label_issues" \
  --write-updated-issues-file "$label_issues" \
  --output "$label_report" \
  --apply

python3 - <<'PY' "$manifest_output" "$manifest_report" "$label_issues" "$label_report"
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
manifest_report = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
label_issues = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
label_report = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))

assert manifest["item_count"] == 3, manifest
assert [row["plan_item_id"] for row in manifest["items"]] == ["A00", "A10", "B10"], manifest
assert manifest_report["verdict"] == "pass", manifest_report
assert manifest_report["duplicate_group_count"] == 0, manifest_report

assert len(label_issues) == 1, label_issues
labels = sorted(label["name"] for label in label_issues[0]["labels"])
assert labels == ["area/planningops", "p2", "task", "type/hardening"], labels
assert label_report["mode"] == "apply", label_report
assert label_report["issues_applied"] == 1, label_report

print("backlog materialize sample fixture smoke ok")
PY
