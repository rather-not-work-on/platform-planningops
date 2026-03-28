#!/usr/bin/env bash
set -euo pipefail

repo_root="$(pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

allowed_report="$tmp_dir/external-only-commit-guard-allowed.test.json"
blocked_report="$tmp_dir/external-only-commit-guard-blocked.test.json"
tracked_report="$tmp_dir/external-only-commit-guard-tracked.test.json"

python3 planningops/scripts/validate_external_only_commit_guard.py \
  --policy planningops/config/artifact-storage-policy.json \
  --files-file planningops/fixtures/external-only-commit-guard-allowed-files.sample.txt \
  --output "$allowed_report" \
  --strict \
  >/dev/null

set +e
python3 planningops/scripts/validate_external_only_commit_guard.py \
  --policy planningops/config/artifact-storage-policy.json \
  --files-file planningops/fixtures/external-only-commit-guard-blocked-files.sample.txt \
  --output "$blocked_report" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for external-only commit guard sample"
  exit 1
fi

tracked_repo="$tmp_dir/tracked-repo"
mkdir -p "$tracked_repo/planningops/artifacts/loops/demo" "$tracked_repo/planningops/artifacts/validation"
cd "$tracked_repo"
git init -q
git config user.name "Codex"
git config user.email "codex@example.com"
cp "$repo_root/planningops/fixtures/external-only-commit-guard-policy.sample.json" policy.json
printf '{"ok":true}\n' > planningops/artifacts/validation/report.json
printf '{"bad":true}\n' > planningops/artifacts/loops/demo/run.json
printf 'metadata\n' > planningops/artifacts/loops/demo/._run.json
git add policy.json planningops/artifacts/validation/report.json planningops/artifacts/loops/demo/run.json planningops/artifacts/loops/demo/._run.json

set +e
python3 "$repo_root/planningops/scripts/validate_external_only_commit_guard.py" \
  --policy policy.json \
  --mode tracked \
  --output "$tracked_report" \
  --strict \
  >/dev/null 2>&1
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for tracked external-only baseline"
  exit 1
fi

cd "$repo_root"

python3 - <<'PY' \
  "$allowed_report" \
  "$blocked_report" \
  "$tracked_report" \
  "planningops/artifacts/validation/external-only-commit-guard-allowed.test.json" \
  "planningops/artifacts/validation/external-only-commit-guard-blocked.test.json" \
  "planningops/artifacts/validation/external-only-commit-guard-tracked.test.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual_allowed = normalize(load(sys.argv[1]))
actual_blocked = normalize(load(sys.argv[2]))
actual_tracked = normalize(load(sys.argv[3]))

expected_allowed = normalize(load(sys.argv[4]))
expected_blocked = normalize(load(sys.argv[5]))
expected_tracked = normalize(load(sys.argv[6]))

assert actual_allowed == expected_allowed, (actual_allowed, expected_allowed)
assert actual_blocked == expected_blocked, (actual_blocked, expected_blocked)
assert actual_tracked == expected_tracked, (actual_tracked, expected_tracked)

print("external-only commit guard artifact lanes ok")
PY
