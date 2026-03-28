#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

output="$tmpdir/plan-projection-report.sample.json"

python3 planningops/scripts/verify_plan_projection.py \
  --contract-file planningops/fixtures/plan-execution-contract-sample.json \
  --snapshot-file planningops/fixtures/plan-projection-snapshot-sample.json \
  --strict \
  --output "$output"

python3 - <<'PY' "$output" "planningops/artifacts/validation/plan-projection-report.sample.json"
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
print("verify plan projection artifact lane ok")
PY
