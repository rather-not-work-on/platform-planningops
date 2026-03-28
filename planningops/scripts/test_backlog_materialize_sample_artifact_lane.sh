#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

manifest_output="$tmpdir/program-manifest.sample.json"
manifest_report="$tmpdir/program-manifest-report.sample.json"
label_output="$tmpdir/issue-label-backfill-report.sample.json"
updated_issues_output="$tmpdir/issue-label-updated-issues.sample.json"

python3 planningops/scripts/build_program_manifest.py \
  --issues-file planningops/fixtures/program-manifest-sample-issues.json \
  --output "$manifest_output" \
  --report-output "$manifest_report" \
  --strict

python3 planningops/scripts/backfill_issue_labels.py \
  --repo rather-not-work-on/platform-planningops \
  --issues-file planningops/fixtures/issue-label-backfill-sample-issues.json \
  --write-updated-issues-file "$updated_issues_output" \
  --output "$label_output" \
  --apply

python3 - <<'PY' \
  "$manifest_output" \
  "$manifest_report" \
  "$updated_issues_output" \
  "$label_output" \
  "planningops/artifacts/program/program-manifest.sample.json" \
  "planningops/artifacts/validation/program-manifest-report.sample.json" \
  "planningops/artifacts/backlog/issue-label-updated-issues.sample.json" \
  "planningops/artifacts/validation/issue-label-backfill-report.sample.json"
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
    return normalized


def normalize_label_report(doc, updated_issues_path: str):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    normalized["write_updated_issues_file"] = normalized["write_updated_issues_file"].replace(
        updated_issues_path,
        "__UPDATED_ISSUES_FILE__",
    )
    return normalized


actual_manifest = normalize_manifest(load(sys.argv[1]))
actual_manifest_report = normalize_manifest_report(load(sys.argv[2]))
actual_updated_issues = load(sys.argv[3])
actual_label_report = normalize_label_report(load(sys.argv[4]), sys.argv[3])

expected_manifest = normalize_manifest(load(sys.argv[5]))
expected_manifest_report = normalize_manifest_report(load(sys.argv[6]))
expected_updated_issues = load(sys.argv[7])
expected_label_report = normalize_label_report(load(sys.argv[8]), load(sys.argv[8])["write_updated_issues_file"])

assert actual_manifest == expected_manifest, (actual_manifest, expected_manifest)
assert actual_manifest_report == expected_manifest_report, (actual_manifest_report, expected_manifest_report)
assert actual_updated_issues == expected_updated_issues, (actual_updated_issues, expected_updated_issues)
assert actual_label_report == expected_label_report, (actual_label_report, expected_label_report)

print("backlog materialize sample artifact lane ok")
PY
