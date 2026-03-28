#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

valid_report="$tmpdir/issue-quality-valid.test.json"
invalid_report="$tmpdir/issue-quality-invalid.test.json"

python3 planningops/scripts/validate_issue_quality.py \
  --issues-file planningops/fixtures/issue-quality/issue-quality-sample-valid.json \
  --output "$valid_report" \
  --strict \
  >/dev/null

set +e
python3 planningops/scripts/validate_issue_quality.py \
  --issues-file planningops/fixtures/issue-quality/issue-quality-sample-invalid.json \
  --output "$invalid_report" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid issue-quality fixture"
  exit 1
fi

python3 - <<'PY' \
  "$valid_report" \
  "$invalid_report" \
  "planningops/artifacts/validation/issue-quality-valid.test.json" \
  "planningops/artifacts/validation/issue-quality-invalid.test.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual_valid = normalize(load(sys.argv[1]))
actual_invalid = normalize(load(sys.argv[2]))

expected_valid = normalize(load(sys.argv[3]))
expected_invalid = normalize(load(sys.argv[4]))

assert actual_valid == expected_valid, (actual_valid, expected_valid)
assert actual_invalid == expected_invalid, (actual_invalid, expected_invalid)

print("issue quality validation artifact lanes ok")
PY
