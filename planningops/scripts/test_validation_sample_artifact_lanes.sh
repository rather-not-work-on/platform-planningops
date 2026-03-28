#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

compile_output="$tmpdir/plan-compile-report.sample.json"
issue_quality_valid_output="$tmpdir/issue-quality-valid.sample.json"
issue_quality_invalid_output="$tmpdir/issue-quality-invalid.sample.json"

python3 planningops/scripts/compile_plan_to_backlog.py \
  --contract-file planningops/fixtures/plan-execution-contract-sample.json \
  --issues-file planningops/fixtures/plan-compile-sample-issues.json \
  --output "$compile_output"

python3 planningops/scripts/validate_issue_quality.py \
  --issues-file planningops/fixtures/issue-quality/issue-quality-sample-valid.json \
  --output "$issue_quality_valid_output" \
  --strict

set +e
python3 planningops/scripts/validate_issue_quality.py \
  --issues-file planningops/fixtures/issue-quality/issue-quality-sample-invalid.json \
  --output "$issue_quality_invalid_output" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid issue-quality sample artifact"
  exit 1
fi

python3 - <<'PY' \
  "$compile_output" \
  "$issue_quality_valid_output" \
  "$issue_quality_invalid_output" \
  "planningops/artifacts/validation/plan-compile-report.sample.json" \
  "planningops/artifacts/validation/issue-quality-valid.sample.json" \
  "planningops/artifacts/validation/issue-quality-invalid.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize_issue_quality(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual_compile = load(sys.argv[1])
actual_issue_quality_valid = normalize_issue_quality(load(sys.argv[2]))
actual_issue_quality_invalid = normalize_issue_quality(load(sys.argv[3]))

expected_compile = load(sys.argv[4])
expected_issue_quality_valid = normalize_issue_quality(load(sys.argv[5]))
expected_issue_quality_invalid = normalize_issue_quality(load(sys.argv[6]))

assert actual_compile == expected_compile, (actual_compile, expected_compile)
assert actual_issue_quality_valid == expected_issue_quality_valid, (
    actual_issue_quality_valid,
    expected_issue_quality_valid,
)
assert actual_issue_quality_invalid == expected_issue_quality_invalid, (
    actual_issue_quality_invalid,
    expected_issue_quality_invalid,
)

print("validation sample artifact lanes ok")
PY
