#!/usr/bin/env bash
set -euo pipefail

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

echo "external-only commit guard contract test ok"
