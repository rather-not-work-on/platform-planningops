#!/usr/bin/env bash
set -euo pipefail

repo_root="$(pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
policy_fixture="$repo_root/planningops/fixtures/external-only-commit-guard-policy.sample.json"

work_repo="$tmp_dir/work-repo"
mkdir -p "$work_repo/planningops/artifacts/loops/demo" "$work_repo/planningops/artifacts/validation"
cd "$work_repo"
git init -q
git config user.name "Codex"
git config user.email "codex@example.com"
cp "$policy_fixture" policy.json

printf '{"tracked":true}\n' > planningops/artifacts/loops/demo/run.json
printf '{"untracked":true}\n' > planningops/artifacts/loops/demo/extra.json
git add policy.json planningops/artifacts/loops/demo/run.json

python3 "$repo_root/planningops/scripts/migrate_external_only_artifacts.py" \
  --policy policy.json \
  --scope tracked \
  --output "$tmp_dir/artifact-migration-tracked-dry-run.test.json" \
  >/dev/null

python3 "$repo_root/planningops/scripts/migrate_external_only_artifacts.py" \
  --policy policy.json \
  --scope tracked \
  --apply \
  --output "$tmp_dir/artifact-migration-tracked-apply.test.json" \
  >/dev/null

cd "$repo_root"

python3 - <<'PY' \
  "$tmp_dir/artifact-migration-tracked-dry-run.test.json" \
  "$tmp_dir/artifact-migration-tracked-apply.test.json" \
  "planningops/artifacts/validation/artifact-migration-tracked-dry-run.test.json" \
  "planningops/artifacts/validation/artifact-migration-tracked-apply.test.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual_dry = normalize(load(sys.argv[1]))
actual_apply = normalize(load(sys.argv[2]))

expected_dry = normalize(load(sys.argv[3]))
expected_apply = normalize(load(sys.argv[4]))

assert actual_dry == expected_dry, (actual_dry, expected_dry)
assert actual_apply == expected_apply, (actual_apply, expected_apply)

print("migrate external-only artifact lanes ok")
PY
