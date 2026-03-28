#!/usr/bin/env bash
set -euo pipefail
repo_root="$(pwd)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

allowed_files="planningops/fixtures/external-only-commit-guard-allowed-files.sample.txt"
blocked_files="planningops/fixtures/external-only-commit-guard-blocked-files.sample.txt"
tracked_policy="planningops/fixtures/external-only-commit-guard-policy.sample.json"

python3 planningops/scripts/validate_external_only_commit_guard.py \
  --policy planningops/config/artifact-storage-policy.json \
  --files-file "$allowed_files" \
  --output "$tmp_dir/guard-allowed-report.json" \
  --strict

set +e
python3 planningops/scripts/validate_external_only_commit_guard.py \
  --policy planningops/config/artifact-storage-policy.json \
  --files-file "$blocked_files" \
  --output "$tmp_dir/guard-blocked-report.json" \
  --strict
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
cp "$repo_root/$tracked_policy" policy.json
printf '{"ok":true}\n' > planningops/artifacts/validation/report.json
printf '{"bad":true}\n' > planningops/artifacts/loops/demo/run.json
printf 'metadata\n' > planningops/artifacts/loops/demo/._run.json
git add policy.json planningops/artifacts/validation/report.json planningops/artifacts/loops/demo/run.json planningops/artifacts/loops/demo/._run.json

set +e
python3 "$repo_root/planningops/scripts/validate_external_only_commit_guard.py" \
  --policy policy.json \
  --mode tracked \
  --output "$tmp_dir/guard-tracked-report.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for tracked external-only baseline"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/guard-tracked-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["mode"] == "tracked", report
assert report["violation_count"] == 1, report
assert report["violations"] == ["planningops/artifacts/loops/demo/run.json"], report
assert report["metadata_file_count"] == 1, report
PY

echo "external-only commit guard contract test ok"
