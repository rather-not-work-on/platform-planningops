#!/usr/bin/env bash
set -euo pipefail

python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy planningops/config/artifact-storage-policy.json \
  --output planningops/artifacts/validation/artifact-storage-policy-valid.test.json \
  --strict

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

set +e
python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy planningops/fixtures/artifact-storage-policy-invalid.sample.json \
  --output "$tmp_dir/artifact-storage-policy-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid artifact-storage policy fixture"
  exit 1
fi

echo "artifact storage policy contract test ok"
