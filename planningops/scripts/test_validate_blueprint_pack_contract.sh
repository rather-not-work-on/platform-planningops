#!/usr/bin/env bash
set -euo pipefail

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/good.md" <<'EOF'
## Interface Contract Refs
ok

## Target Package Topology
ok

## Dependency Manifest
ok

## File Plan
ok

## Verification Plan
ok

## Module README Deltas
ok
EOF

cat > "$TMP_DIR/bad.md" <<'EOF'
## Interface Contract Refs
ok
EOF

python3 planningops/scripts/validate_blueprint_pack.py \
  --doc "$TMP_DIR/good.md" \
  --output "$TMP_DIR/good-report.json"

python3 - <<'PY' "$TMP_DIR/good-report.json"
import json
import sys
doc = json.load(open(sys.argv[1], encoding="utf-8"))
assert doc["verdict"] == "pass", doc
assert doc["violation_count"] == 0, doc
PY

if python3 planningops/scripts/validate_blueprint_pack.py \
  --doc "$TMP_DIR/bad.md" \
  --output "$TMP_DIR/bad-report.json"; then
  echo "expected failure for incomplete blueprint pack"
  exit 1
fi

python3 - <<'PY' "$TMP_DIR/bad-report.json"
import json
import sys
doc = json.load(open(sys.argv[1], encoding="utf-8"))
assert doc["verdict"] == "fail", doc
assert doc["violation_count"] == 1, doc
assert "Target Package Topology" in doc["rows"][0]["missing_sections"], doc
PY

echo "validate_blueprint_pack contract ok"
