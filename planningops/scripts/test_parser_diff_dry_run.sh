#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

python3 planningops/scripts/parser_diff_dry_run.py --run-id test-pass --mode dry-run >/tmp/test-pass.log

set +e
python3 planningops/scripts/parser_diff_dry_run.py \
  --plan-file planningops/fixtures/plan-items/invalid-missing-field.json \
  --run-id test-missing >/tmp/test-missing.log 2>&1
rc_missing=$?

python3 planningops/scripts/parser_diff_dry_run.py \
  --plan-file planningops/fixtures/plan-items/invalid-enum.json \
  --run-id test-enum >/tmp/test-enum.log 2>&1
rc_enum=$?
set -e

if [[ "$rc_missing" -eq 0 ]]; then
  echo "expected missing-field case to fail"
  exit 1
fi
if [[ "$rc_enum" -eq 0 ]]; then
  echo "expected invalid-enum case to fail"
  exit 1
fi

echo "parser-diff-dry-run tests passed"
