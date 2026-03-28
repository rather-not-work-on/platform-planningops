#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

output="$tmpdir/blueprint-pack-report.sample.json"

python3 planningops/scripts/validate_blueprint_pack.py \
  --doc planningops/fixtures/blueprint-pack-valid.sample.md \
  --output "$output"

python3 - <<'PY' "$output" "planningops/artifacts/validation/blueprint-pack-report.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


actual = load(sys.argv[1])
expected = load(sys.argv[2])

assert actual == expected, (actual, expected)
print("validate blueprint pack artifact lane ok")
PY
