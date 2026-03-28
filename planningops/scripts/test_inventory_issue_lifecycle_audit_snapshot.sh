#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

"${PYTHON_BIN}" "$ROOT_DIR/scripts/inventory_issue_lifecycle.py" audit \
  --root "$ROOT_DIR/.." \
  --issues-file "$ROOT_DIR/fixtures/inventory-issue-lifecycle-audit-snapshot.json" \
  --repo rather-not-work-on/platform-planningops \
  --output "$ROOT_DIR/artifacts/validation/inventory-issue-lifecycle-report.json" \
  --strict

echo "inventory issue lifecycle snapshot audit ok"
