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

python3 - <<'PY' \
  "$manifest_output" \
  "$manifest_report" \
  "$label_issues" \
  "$label_report" \
  "planningops/fixtures/program-manifest-sample.expected.json" \
  "planningops/fixtures/program-manifest-report-sample.expected.json" \
  "planningops/fixtures/issue-label-backfill-sample-updated-issues.expected.json" \
  "planningops/fixtures/issue-label-backfill-report-sample.expected.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize_manifest(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


def normalize_manifest_report(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    normalized["issues_file"] = "__ISSUES_FILE__"
    return normalized


def normalize_label_report(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    normalized["issues_file"] = "__ISSUES_FILE__"
    normalized["write_updated_issues_file"] = "__UPDATED_ISSUES_FILE__"
    return normalized


actual_manifest = normalize_manifest(load(sys.argv[1]))
actual_manifest_report = normalize_manifest_report(load(sys.argv[2]))
actual_label_issues = load(sys.argv[3])
actual_label_report = normalize_label_report(load(sys.argv[4]))

expected_manifest = load(sys.argv[5])
expected_manifest_report = load(sys.argv[6])
expected_label_issues = load(sys.argv[7])
expected_label_report = load(sys.argv[8])

assert actual_manifest == expected_manifest, (actual_manifest, expected_manifest)
assert actual_manifest_report == expected_manifest_report, (actual_manifest_report, expected_manifest_report)
assert actual_label_issues == expected_label_issues, (actual_label_issues, expected_label_issues)
assert actual_label_report == expected_label_report, (actual_label_report, expected_label_report)

print("backlog materialize sample snapshot contract ok")
PY
