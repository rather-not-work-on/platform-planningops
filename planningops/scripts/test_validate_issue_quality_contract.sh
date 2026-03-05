#!/usr/bin/env bash
set -euo pipefail

python3 planningops/scripts/validate_issue_quality.py \
  --issues-file planningops/fixtures/issue-quality/issue-quality-sample-valid.json \
  --output planningops/artifacts/validation/issue-quality-valid.test.json \
  --strict

set +e
python3 planningops/scripts/validate_issue_quality.py \
  --issues-file planningops/fixtures/issue-quality/issue-quality-sample-invalid.json \
  --output planningops/artifacts/validation/issue-quality-invalid.test.json \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid issue-quality fixture"
  exit 1
fi

echo "issue quality contract test ok"
