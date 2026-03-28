#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

valid_report="$tmpdir/artifact-storage-policy-valid.test.json"
invalid_report="$tmpdir/artifact-storage-policy-invalid.test.json"

python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy planningops/config/artifact-storage-policy.json \
  --output "$valid_report" \
  --strict \
  >/dev/null

set +e
python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy planningops/fixtures/artifact-storage-policy-invalid.sample.json \
  --output "$invalid_report" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid artifact-storage policy fixture"
  exit 1
fi

python3 - <<'PY' \
  "$valid_report" \
  "$invalid_report" \
  "planningops/artifacts/validation/artifact-storage-policy-valid.test.json" \
  "planningops/artifacts/validation/artifact-storage-policy-invalid.test.json"
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

print("artifact storage policy validation artifact lanes ok")
PY
