#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_root="$tmp_dir/repo"
mkdir -p \
  "$fixture_root/docs/workbench/unified-personal-agent-platform/plans" \
  "$fixture_root/docs/initiatives/unified-personal-agent-platform/contracts"

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-sample-plan.md" <<'EOF'
---
title: plan: Sample
type: plan
date: 2026-03-07
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Sample workbench plan ready for archive.
topic: sample
memory_tier: L0
compacted_into: docs/initiatives/unified-personal-agent-platform/contracts/sample-contract.md
---

# Sample Plan
EOF

cat > "$fixture_root/docs/initiatives/unified-personal-agent-platform/contracts/sample-contract.md" <<'EOF'
---
title: Sample Contract
type: contract
date: 2026-03-08
initiative: unified-personal-agent-platform
lifecycle: canonical
status: active
summary: Canonical target for sample.
memory_tier: L1
---
EOF

python3 planningops/scripts/memory_archive.py \
  --root "$fixture_root" \
  --source docs/workbench/unified-personal-agent-platform/plans/2026-03-07-sample-plan.md \
  --compacted-into docs/initiatives/unified-personal-agent-platform/contracts/sample-contract.md \
  --archived-at 2026-03-08T00:00:00Z \
  --output "$tmp_dir/archive-report.json" \
  --strict

archive_path="$fixture_root/docs/archive/workbench/unified-personal-agent-platform/plans/2026-03-07-sample-plan.md"
manifest_path="$fixture_root/planningops/archive-manifest/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-sample-plan.json"

test -f "$archive_path"
test -f "$manifest_path"

python3 planningops/scripts/validate_memory_archive_manifest.py \
  --manifest "$manifest_path" \
  --schema planningops/schemas/memory-archive-manifest.schema.json \
  --output "$tmp_dir/archive-manifest-validation.json" \
  --strict

python3 - "$manifest_path" "$tmp_dir/invalid-manifest.json" <<'PY'
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
manifest.pop("archive_ref")
Path(sys.argv[2]).write_text(json.dumps(manifest, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 planningops/scripts/validate_memory_archive_manifest.py \
  --manifest "$tmp_dir/invalid-manifest.json" \
  --schema planningops/schemas/memory-archive-manifest.schema.json \
  --output "$tmp_dir/archive-manifest-invalid-validation.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid manifest schema"
  exit 1
fi

python3 - "$manifest_path" <<'PY'
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert manifest["manifest_version"] == 1, manifest
assert manifest["archive_ref"] == manifest["manifest_path"], manifest
assert manifest["memory_tier"] == "L2", manifest
assert manifest["compacted_into"] == "docs/initiatives/unified-personal-agent-platform/contracts/sample-contract.md", manifest
assert manifest["source_frontmatter"]["title"] == "plan: Sample", manifest
assert "title" in manifest["source_frontmatter_order"], manifest
PY

python3 - "$archive_path" <<'PY'
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
required = [
    "memory_tier: L2",
    "archive_ref: planningops/archive-manifest/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-sample-plan.json",
    "compacted_into: docs/initiatives/unified-personal-agent-platform/contracts/sample-contract.md",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("archived markdown missing fields: " + ", ".join(missing))
PY

set +e
python3 planningops/scripts/memory_archive.py \
  --root "$fixture_root" \
  --source docs/workbench/unified-personal-agent-platform/plans/2026-03-07-sample-plan.md \
  --compacted-into missing/target.md \
  --output "$tmp_dir/archive-report-invalid.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for missing compacted target"
  exit 1
fi

echo "memory archive contract test ok"
