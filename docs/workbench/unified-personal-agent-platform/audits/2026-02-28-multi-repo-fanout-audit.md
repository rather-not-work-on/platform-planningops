---
title: audit: Multi-Repo Parser and Sync Fan-out
type: audit
date: 2026-02-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures issue #22 evidence for multi-repo parser/sync fan-out, projection key collision checks, repo-level drift reporting, and deterministic convergence.
---

# audit: Multi-Repo Parser and Sync Fan-out

## Scope
- Issue #22: Expand PlanningOps parser/sync for multi-repo target_repo fan-out

## Implemented
- `planningops/fixtures/plan-items/multi-repo-sample.json`
- `planningops/scripts/multi_repo_projection_report.py`
- `planningops/scripts/test_multi_repo_fanout.sh`
- generated artifacts:
  - `planningops/artifacts/sync-summary/multi-repo-a.json`
  - `planningops/artifacts/sync-summary/multi-repo-b.json`
  - `planningops/artifacts/drift/multi-repo-a-drift-report.json`

## Validation
Commands:
```bash
python3 planningops/scripts/parser_diff_dry_run.py \
  --plan-file planningops/fixtures/plan-items/multi-repo-sample.json \
  --state-file planningops/fixtures/plan-items/actual-state-empty.json \
  --run-id multi-repo-a \
  --mode dry-run

python3 planningops/scripts/multi_repo_projection_report.py \
  --summary planningops/artifacts/sync-summary/multi-repo-a.json \
  --output planningops/artifacts/drift/multi-repo-a-drift-report.json

bash planningops/scripts/test_multi_repo_fanout.sh
```

Observed:
```text
repo_count=4 key_collisions=0
deterministic convergence ok
target repos:
- rather-not-work-on/platform-contracts
- rather-not-work-on/platform-provider-gateway
- rather-not-work-on/platform-observability-gateway
- rather-not-work-on/monday
```

## Acceptance Mapping
- at least 2 target repos fan-out: pass (`repo_count=4`)
- projection key collisions: pass (`0`)
- repo-level drift report generated: pass
- deterministic convergence across repeated runs: pass
