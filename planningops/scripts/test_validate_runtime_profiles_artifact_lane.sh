#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

output="$tmpdir/runtime-profiles-report.sample.json"

python3 planningops/scripts/validate_runtime_profiles.py \
  --runtime-profile-file planningops/config/runtime-profiles.json \
  --schema-file planningops/schemas/runtime-profiles.schema.json \
  --output "$output" \
  --strict

python3 - <<'PY' "$output" "planningops/artifacts/validation/runtime-profiles-report.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual = normalize(load(sys.argv[1]))
expected = normalize(load(sys.argv[2]))

assert actual == expected, (actual, expected)
print("validate runtime profiles artifact lane ok")
PY
