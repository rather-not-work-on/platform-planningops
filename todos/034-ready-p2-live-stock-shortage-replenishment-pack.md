---
status: ready
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
- [ ] at least 2 `next_up` candidates added with dependencies
- [ ] at least 1 additional `quality_hardening` candidate added
- [ ] backlog stock report shows no shortage for those classes in live project run
