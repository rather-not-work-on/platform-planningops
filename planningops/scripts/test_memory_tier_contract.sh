#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

python3 planningops/scripts/validate_memory_tier_rules.py \
  --rules planningops/config/memory-tier-rules.json \
  --output "$tmp_dir/memory-tier-rules-valid.json" \
  --strict

python3 - "$tmp_dir/memory-tier-rules-valid.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
PY

cat > "$tmp_dir/invalid-rules.json" <<'JSON'
{
  "policy_version": 0,
  "memory_tiers": {
    "L0": {
      "default_roots": [],
      "ttl_days": {"min": 14, "max": 7, "default": 30},
      "required_frontmatter": [],
      "allowed_next_tiers": []
    },
    "L1": {
      "default_roots": [],
      "review_cycle_days": 0,
      "required_frontmatter": [],
      "allowed_next_tiers": []
    }
  },
  "frontmatter_keys": {
    "memory_tier": {"allowed_values": ["L0", "L1"]}
  },
  "compaction_triggers": [],
  "promotion_rules": {},
  "rehydrate_rules": {
    "required_inputs": [],
    "path_root": "absolute"
  },
  "storage_interop": {
    "artifact_storage_contract": "invalid",
    "memory_tier_overrides_storage_tier": true
  }
}
JSON

set +e
python3 planningops/scripts/validate_memory_tier_rules.py \
  --rules "$tmp_dir/invalid-rules.json" \
  --output "$tmp_dir/memory-tier-rules-invalid.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid memory tier rules"
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

text = Path("planningops/contracts/memory-tier-contract.md").read_text(encoding="utf-8")
required = [
    "`L0`",
    "`L1`",
    "`L2`",
    "`memory_tier`",
    "`expires_on`",
    "`compacted_into`",
    "`archive_ref`",
    "stale_l0_uncompacted",
    "topic_compaction_required",
    "closed_issue_memory_summary_missing",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("memory tier contract missing required content: " + ", ".join(missing))
print("memory tier contract test ok")
PY
