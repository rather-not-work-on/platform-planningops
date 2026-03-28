#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

output="$tmpdir/worker-task-pack-report.sample.json"

python3 planningops/scripts/validate_worker_task_pack.py \
  --runtime-profile-file planningops/config/runtime-profiles.json \
  --task-key reflection_action \
  --issue-number 95 \
  --mode dry-run \
  --loop-profile "L3 Implementation-TDD" \
  --target-repo rather-not-work-on/platform-planningops \
  --output "$output" \
  --strict

python3 - <<'PY' "$output" "planningops/artifacts/validation/worker-task-pack-report.sample.json"
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
print("validate worker task pack artifact lane ok")
PY
