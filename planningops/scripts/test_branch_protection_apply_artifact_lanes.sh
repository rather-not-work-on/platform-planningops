#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

policy="planningops/fixtures/repository-governance-apply-policy.sample.json"
policy_invalid="planningops/fixtures/repository-governance-apply-policy-invalid.sample.json"
snapshot="planningops/fixtures/branch-protection-apply-snapshot.sample.json"

valid_report="$tmpdir/branch-protection-apply-valid.test.json"
invalid_report="$tmpdir/branch-protection-apply-invalid.test.json"

python3 planningops/scripts/apply_branch_protection.py \
  --policy "$policy" \
  --snapshot-file "$snapshot" \
  --output "$valid_report" \
  >/dev/null

set +e
python3 planningops/scripts/apply_branch_protection.py \
  --policy "$policy_invalid" \
  --snapshot-file "$snapshot" \
  --output "$invalid_report" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure when only required_status_checks_any is configured"
  exit 1
fi

python3 - <<'PY' \
  "$valid_report" \
  "$invalid_report" \
  "planningops/artifacts/validation/branch-protection-apply-valid.test.json" \
  "planningops/artifacts/validation/branch-protection-apply-invalid.test.json"
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

print("branch protection apply artifact lanes ok")
PY
