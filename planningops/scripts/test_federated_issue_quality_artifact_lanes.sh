#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

config_fixture="planningops/fixtures/federated-issue-quality-config.sample.json"
valid_fixture="planningops/fixtures/federated-issue-quality-valid.sample.json"
invalid_fixture="planningops/fixtures/federated-issue-quality-invalid.sample.json"

valid_report="$tmp_dir/federated-issue-quality-valid.test.json"
invalid_report="$tmp_dir/federated-issue-quality-invalid.test.json"
auto_fix_report="$tmp_dir/federated-issue-quality-auto-fix.test.json"

python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$config_fixture" \
  --issues-file "$valid_fixture" \
  --output "$valid_report" \
  --strict \
  >/dev/null

set +e
python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$config_fixture" \
  --issues-file "$invalid_fixture" \
  --output "$invalid_report" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid federated issue quality sample"
  exit 1
fi

python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$config_fixture" \
  --issues-file "$invalid_fixture" \
  --output "$auto_fix_report" \
  --apply-default-labels \
  --strict \
  >/dev/null

python3 - <<'PY' \
  "$valid_report" \
  "$invalid_report" \
  "$auto_fix_report" \
  "planningops/artifacts/validation/federated-issue-quality-valid.test.json" \
  "planningops/artifacts/validation/federated-issue-quality-invalid.test.json" \
  "planningops/artifacts/validation/federated-issue-quality-auto-fix.test.json"
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
actual_auto_fix = normalize(load(sys.argv[3]))

expected_valid = normalize(load(sys.argv[4]))
expected_invalid = normalize(load(sys.argv[5]))
expected_auto_fix = normalize(load(sys.argv[6]))

assert actual_valid == expected_valid, (actual_valid, expected_valid)
assert actual_invalid == expected_invalid, (actual_invalid, expected_invalid)
assert actual_auto_fix == expected_auto_fix, (actual_auto_fix, expected_auto_fix)

print("federated issue quality artifact lanes ok")
PY
