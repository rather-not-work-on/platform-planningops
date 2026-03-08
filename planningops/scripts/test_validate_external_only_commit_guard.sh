#!/usr/bin/env bash
set -euo pipefail
repo_root="$(pwd)"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

allowed_files="$tmp_dir/allowed.txt"
blocked_files="$tmp_dir/blocked.txt"

cat > "$allowed_files" <<'EOF'
planningops/artifacts/validation/report.json
planningops/contracts/issue-quality-contract.md
EOF

cat > "$blocked_files" <<'EOF'
planningops/artifacts/loops/2026-03-06/loop-001/verification-report.json
planningops/artifacts/transition-log/2026-03-06.ndjson
EOF

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
cat > policy.json <<'JSON'
{
  "policy_version": 1,
  "default_external_backend": "local",
  "pointer_manifest_root": "planningops/artifacts/pointers",
  "tiers": {
    "git_canonical": ["planningops/artifacts/validation/**"],
    "git_optional": [],
    "external_only": ["planningops/artifacts/loops/**"]
  },
  "backends": {
    "local": {"kind": "local", "base_path": "planningops/runtime-artifacts/local"},
    "s3": {"kind": "s3_mock", "bucket": "demo", "prefix": "planningops", "mock_base_path": "planningops/runtime-artifacts/s3"},
    "oci": {"kind": "oci_mock", "namespace": "demo", "bucket": "demo", "prefix": "planningops", "mock_base_path": "planningops/runtime-artifacts/oci"}
  },
  "retention": {
    "git_canonical_days": 3650,
    "git_optional_days": 180,
    "external_only_days": 30
  },
  "commit_guard": {
    "forbidden_external_only_in_git": true
  }
}
JSON
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
