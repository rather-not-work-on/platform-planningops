#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

config_fixture="planningops/fixtures/federated-issue-quality-config.sample.json"
valid_fixture="planningops/fixtures/federated-issue-quality-valid.sample.json"
invalid_fixture="planningops/fixtures/federated-issue-quality-invalid.sample.json"

python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$config_fixture" \
  --issues-file "$valid_fixture" \
  --output "$tmp_dir/federated-issue-quality-valid.test.json" \
  --strict

set +e
python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$config_fixture" \
  --issues-file "$invalid_fixture" \
  --output "$tmp_dir/federated-issue-quality-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid federated issue quality sample"
  exit 1
fi

python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$config_fixture" \
  --issues-file "$invalid_fixture" \
  --output "$tmp_dir/federated-issue-quality-auto-fix.test.json" \
  --apply-default-labels \
  --strict

echo "federated issue quality contract test ok"
