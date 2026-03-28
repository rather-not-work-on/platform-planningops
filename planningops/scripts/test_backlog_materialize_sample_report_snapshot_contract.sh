#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

contract_file="planningops/fixtures/backlog-materialization-sample-contract.json"
compile_output="$tmpdir/plan-compile-report.json"
label_output="$tmpdir/issue-label-backfill-report.json"
manifest_output="$tmpdir/program-manifest.json"
manifest_report="$tmpdir/program-manifest-report.json"
quality_output="$tmpdir/issue-quality-report.json"
projected_issues_output="$tmpdir/projected-issues.json"
materialize_output="$tmpdir/materialize-report.json"

python3 planningops/scripts/core/backlog/materialize.py \
  --contract-file "$contract_file" \
  --repo rather-not-work-on/platform-planningops \
  --initiative unified-personal-agent-platform \
  --compile-output "$compile_output" \
  --label-output "$label_output" \
  --manifest-output "$manifest_output" \
  --manifest-report "$manifest_report" \
  --quality-output "$quality_output" \
  --projected-issues-output "$projected_issues_output" \
  --output "$materialize_output" \
  >/dev/null

python3 - <<'PY' \
  "$materialize_output" \
  "$compile_output" \
  "$quality_output" \
  "$projected_issues_output" \
  "planningops/fixtures/backlog-materialize-report-sample.expected.json" \
  "planningops/fixtures/backlog-materialize-plan-compile-report-sample.expected.json" \
  "planningops/fixtures/backlog-materialize-issue-quality-report-sample.expected.json" \
  "planningops/fixtures/backlog-materialize-projected-issues-sample.expected.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def replace_strings(value, mapping):
    if isinstance(value, dict):
        return {key: replace_strings(item, mapping) for key, item in value.items()}
    if isinstance(value, list):
        return [replace_strings(item, mapping) for item in value]
    if isinstance(value, str):
        replaced = value
        for source, target in mapping.items():
            replaced = replaced.replace(source, target)
        return replaced
    return value


def normalize_materialize_report(doc, path_mapping):
    normalized = replace_strings(json.loads(json.dumps(doc)), path_mapping)
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    for step in normalized["steps"]:
        step["stdout"] = "__STDOUT__"
    return normalized


def normalize_quality_report(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


def normalize_projected_issues(doc):
    normalized = json.loads(json.dumps(doc))
    for issue in normalized:
        issue["updated_at"] = "__UPDATED_AT__"
    return normalized


path_mapping = {
    sys.argv[2]: "__COMPILE_OUTPUT__",
    sys.argv[3]: "__QUALITY_OUTPUT__",
    sys.argv[4]: "__PROJECTED_ISSUES_FILE__",
    str(Path(sys.argv[2]).with_name("issue-label-backfill-report.json")): "__LABEL_OUTPUT__",
    str(Path(sys.argv[2]).with_name("program-manifest.json")): "__MANIFEST_OUTPUT__",
    str(Path(sys.argv[2]).with_name("program-manifest-report.json")): "__MANIFEST_REPORT__",
}

actual_materialize_report = normalize_materialize_report(load(sys.argv[1]), path_mapping)
actual_compile_report = replace_strings(load(sys.argv[2]), path_mapping)
actual_quality_report = normalize_quality_report(load(sys.argv[3]))
actual_projected_issues = normalize_projected_issues(load(sys.argv[4]))

expected_materialize_report = load(sys.argv[5])
expected_compile_report = load(sys.argv[6])
expected_quality_report = load(sys.argv[7])
expected_projected_issues = load(sys.argv[8])

assert actual_materialize_report == expected_materialize_report, (
    actual_materialize_report,
    expected_materialize_report,
)
assert actual_compile_report == expected_compile_report, (actual_compile_report, expected_compile_report)
assert actual_quality_report == expected_quality_report, (actual_quality_report, expected_quality_report)
assert actual_projected_issues == expected_projected_issues, (actual_projected_issues, expected_projected_issues)

print("backlog materialize sample report snapshot contract ok")
PY
