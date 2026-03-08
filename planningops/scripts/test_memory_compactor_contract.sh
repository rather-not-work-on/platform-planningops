#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fixture_root="$tmp_dir/repo"
mkdir -p \
  "$fixture_root/docs/workbench/unified-personal-agent-platform/brainstorms" \
  "$fixture_root/docs/workbench/unified-personal-agent-platform/plans" \
  "$fixture_root/docs/workbench/unified-personal-agent-platform/audits" \
  "$fixture_root/docs/initiatives/unified-personal-agent-platform"

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/brainstorms/2026-02-01-alpha-brainstorm.md" <<'EOF'
---
title: Alpha Brainstorm
type: brainstorm
date: 2026-02-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Alpha brainstorming context.
topic: alpha
---
EOF

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/plans/2026-02-02-alpha-plan.md" <<'EOF'
---
title: plan: Alpha
type: plan
date: 2026-02-02
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Alpha planning context.
topic: alpha
---
EOF

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/audits/2026-02-03-alpha-audit.md" <<'EOF'
---
title: Alpha Audit
type: audit
date: 2026-02-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Alpha audit context.
topic: alpha
---
EOF

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/plans/2026-02-01-delta-plan.md" <<'EOF'
---
title: plan: Delta
type: plan
date: 2026-02-01
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Delta plan compacted into canonical memory.
topic: delta
compacted_into: docs/initiatives/unified-personal-agent-platform/10-platform/contracts/memory-summary.md
---
EOF

cat > "$fixture_root/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-fresh-plan.md" <<'EOF'
---
title: plan: Fresh
type: plan
date: 2026-03-07
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Fresh plan should not trip stale detection.
topic: fresh
---
EOF

cat > "$fixture_root/docs/initiatives/unified-personal-agent-platform/memory-summary.md" <<'EOF'
---
title: Memory Summary
type: contract
date: 2026-03-08
initiative: unified-personal-agent-platform
lifecycle: canonical
status: active
summary: Canonical summary placeholder.
memory_tier: L1
---
EOF

touch "$fixture_root/docs/workbench/unified-personal-agent-platform/brainstorms/._ignored.md"

python3 planningops/scripts/memory_compactor.py \
  --mode check \
  --root "$fixture_root" \
  --rules planningops/config/memory-tier-rules.json \
  --as-of 2026-03-08 \
  --output "$tmp_dir/report-dirty.json"

python3 - "$tmp_dir/report-dirty.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert report["trigger_count"] == 4, report
assert len(report["stale_l0_uncompacted"]) == 3, report
assert len(report["topic_compaction_required"]) == 1, report
topic = report["topic_compaction_required"][0]
assert topic["topic"] == "alpha", topic
assert topic["record_count"] == 3, topic
assert report["error_count"] == 0, report
PY

set +e
python3 planningops/scripts/memory_compactor.py \
  --mode check \
  --root "$fixture_root" \
  --rules planningops/config/memory-tier-rules.json \
  --as-of 2026-03-08 \
  --output "$tmp_dir/report-dirty-strict.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for stale or duplicate L0 memory"
  exit 1
fi

clean_root="$tmp_dir/clean-repo"
mkdir -p "$clean_root/docs/workbench/unified-personal-agent-platform/plans"

cat > "$clean_root/docs/workbench/unified-personal-agent-platform/plans/2026-03-07-clean-plan.md" <<'EOF'
---
title: plan: Clean
type: plan
date: 2026-03-07
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Fresh workbench item.
topic: clean
---
EOF

python3 planningops/scripts/memory_compactor.py \
  --mode check \
  --root "$clean_root" \
  --rules planningops/config/memory-tier-rules.json \
  --as-of 2026-03-08 \
  --output "$tmp_dir/report-clean.json" \
  --strict

python3 - "$tmp_dir/report-clean.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["trigger_count"] == 0, report
assert report["error_count"] == 0, report
PY

python3 - <<'PY'
from pathlib import Path

text = Path("planningops/contracts/memory-tier-contract.md").read_text(encoding="utf-8")
required = [
    "stale_l0_uncompacted",
    "topic_compaction_required",
    "planningops/scripts/memory_compactor.py",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("memory tier contract missing compactor references: " + ", ".join(missing))
print("memory compactor contract test ok")
PY
