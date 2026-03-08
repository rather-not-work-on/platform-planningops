#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_root="$tmp_dir/repo"
mkdir -p \
  "$fixture_root/docs/workbench/unified-personal-agent-platform/plans" \
  "$fixture_root/docs/initiatives/unified-personal-agent-platform/contracts"

source_rel="docs/workbench/unified-personal-agent-platform/plans/2026-03-07-roundtrip-plan.md"
compacted_rel="docs/initiatives/unified-personal-agent-platform/contracts/roundtrip-contract.md"

cat > "$fixture_root/$source_rel" <<'EOF'
---
title: plan: Roundtrip
type: plan
date: 2026-03-07
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Roundtrip fixture for archive and rehydrate.
topic: roundtrip
memory_tier: L0
compacted_into: docs/initiatives/unified-personal-agent-platform/contracts/roundtrip-contract.md
---

# Roundtrip Plan
EOF

cat > "$fixture_root/$compacted_rel" <<'EOF'
---
title: Roundtrip Contract
type: contract
date: 2026-03-08
initiative: unified-personal-agent-platform
lifecycle: canonical
status: active
summary: Canonical target for roundtrip fixture.
memory_tier: L1
---
EOF

python3 planningops/scripts/memory_archive.py \
  --root "$fixture_root" \
  --source "$source_rel" \
  --compacted-into "$compacted_rel" \
  --archived-at 2026-03-08T00:00:00Z \
  --output "$tmp_dir/archive-report.json" \
  --strict

manifest_rel="planningops/archive-manifest/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-roundtrip-plan.json"
rehydrated_rel="planningops/artifacts/rehydrate/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-roundtrip-plan.md"

python3 planningops/scripts/memory_rehydrate.py \
  --root "$fixture_root" \
  --manifest "$manifest_rel" \
  --output-path "$rehydrated_rel" \
  --output "$tmp_dir/rehydrate-report.json" \
  --strict

test -f "$fixture_root/$rehydrated_rel"

python3 - "$fixture_root/$source_rel" "$fixture_root/$rehydrated_rel" "$tmp_dir/rehydrate-report.json" <<'PY'
import json
import sys
from pathlib import Path

source_text = Path(sys.argv[1]).read_text(encoding="utf-8")
rehydrated_text = Path(sys.argv[2]).read_text(encoding="utf-8")
report = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
assert source_text == rehydrated_text, report
assert report["checksum_match"] is True, report
assert report["verdict"] == "pass", report
PY

set +e
python3 planningops/scripts/memory_rehydrate.py \
  --root "$fixture_root" \
  --manifest missing-manifest.json \
  --output "$tmp_dir/rehydrate-missing-report.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for missing manifest"
  exit 1
fi

echo "memory rehydrate contract test ok"
