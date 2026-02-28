#!/usr/bin/env bash
set -euo pipefail

python3 planningops/scripts/parser_diff_dry_run.py \
  --plan-file planningops/fixtures/plan-items/multi-repo-sample.json \
  --state-file planningops/fixtures/plan-items/actual-state-empty.json \
  --run-id multi-repo-a \
  --mode dry-run

python3 planningops/scripts/parser_diff_dry_run.py \
  --plan-file planningops/fixtures/plan-items/multi-repo-sample.json \
  --state-file planningops/fixtures/plan-items/actual-state-empty.json \
  --run-id multi-repo-b \
  --mode dry-run

python3 planningops/scripts/multi_repo_projection_report.py \
  --summary planningops/artifacts/sync-summary/multi-repo-a.json \
  --output planningops/artifacts/drift/multi-repo-a-drift-report.json

# deterministic convergence check (same actions for same inputs)
python3 - <<'PY'
import json
from pathlib import Path

a = json.loads(Path('planningops/artifacts/sync-summary/multi-repo-a.json').read_text())
b = json.loads(Path('planningops/artifacts/sync-summary/multi-repo-b.json').read_text())

if a['actions'] != b['actions']:
    raise SystemExit('actions mismatch across deterministic runs')

keys = [x['key'] for x in a['actions']]
if len(keys) != len(set(keys)):
    raise SystemExit('projection key collision detected')

repos = sorted(set(x['item']['target_repo'] for x in a['actions']))
if len(repos) < 2:
    raise SystemExit('expected at least 2 target repos')

print('deterministic convergence ok')
print('target repos:', repos)
PY
