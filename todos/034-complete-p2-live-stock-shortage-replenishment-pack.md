---
status: complete
priority: p2
issue_id: "034"
tags: [planningops, backlog, replenishment, kanban]
dependencies: ["031", "028"]
---

# Live Stock Shortage Replenishment Pack

## Problem Statement
Live supervisor pilot (`031`) failed backlog stock gate with deterministic shortages in `next_up` and `quality_hardening` classes.

## Findings
- `next_up` stock: required `2`, actual `0`
- `quality_hardening` stock: required `2`, actual `1`

## Proposed Solution
Generate and register a dependency-scoped replenishment issue pack to satisfy stock floor requirements.

## Acceptance Criteria
- [x] at least 2 `next_up` candidates added with dependencies
- [x] at least 1 additional `quality_hardening` candidate added
- [x] backlog stock report shows no shortage for those classes in live project run

## Work Log

### 2026-03-05 - Replenishment Complete

**By:** Codex

**Actions:**
- Captured live baseline report with shortages:
  - `planningops/artifacts/validation/backlog-stock-live-before-034.json`
- Registered dependency-scoped issue pack:
  - blocker `#86`
  - ready-now/quality-hardening `#87`
  - next-up candidates with dependency `#88`, `#89` (`depends_on: #86`)
- Added project field mapping for each candidate card (`Status=Todo`, `workflow_state=ready-contract`, `component=planningops`, initiative/target_repo, execution order, loop profile).
- Revalidated live stock gate:
  - `planningops/artifacts/validation/backlog-stock-live-after-034.json` (`verdict=pass`, no breaches)
- Added audit:
  - `docs/workbench/unified-personal-agent-platform/audits/2026-03-05-live-stock-replenishment-pack-audit.md`

**Validation:**
- `python3 planningops/scripts/backlog_stock_replenishment_guard.py --owner rather-not-work-on --project-num 2 --initiative unified-personal-agent-platform --output planningops/artifacts/validation/backlog-stock-live-before-034.json`
- `python3 planningops/scripts/backlog_stock_replenishment_guard.py --owner rather-not-work-on --project-num 2 --initiative unified-personal-agent-platform --output planningops/artifacts/validation/backlog-stock-live-after-034.json`
