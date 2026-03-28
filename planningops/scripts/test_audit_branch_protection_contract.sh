#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

policy="planningops/fixtures/repository-governance-policy.sample.json"
snapshot_valid="planningops/fixtures/branch-protection-snapshot-valid.sample.json"
snapshot_invalid="planningops/fixtures/branch-protection-snapshot-invalid.sample.json"

python3 planningops/scripts/audit_branch_protection.py \
  --policy "$policy" \
  --snapshot-file "$snapshot_valid" \
  --output "$tmp_dir/branch-protection-valid.test.json" \
  --strict

set +e
python3 planningops/scripts/audit_branch_protection.py \
  --policy "$policy" \
  --snapshot-file "$snapshot_invalid" \
  --output "$tmp_dir/branch-protection-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid branch protection snapshot"
  exit 1
fi

echo "branch protection audit contract test ok"
