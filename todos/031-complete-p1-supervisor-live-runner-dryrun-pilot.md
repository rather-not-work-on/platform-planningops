---
status: complete
priority: p1
issue_id: "031"
tags: [planningops, supervisor, pilot, reliability]
dependencies: ["030", "029", "028"]
---

# Supervisor Live Runner Dry-Run Pilot

## Problem Statement
Current supervisor pilot converges in deterministic sequence mode. We still need a live dry-run pilot that invokes `issue_loop_runner.py` directly (no sequence stub) to validate real selector/project interaction behavior.

## Findings
- Sequence-mode pilot is useful for policy contract checks, but does not exercise live project intake variability.
- Live dry-run is needed before apply-mode rollout.

## Proposed Solution
Run a controlled live dry-run pilot on supervisor loop with strict gates and capture cycle-by-cycle evidence.

## Acceptance Criteria
- [x] Supervisor run executes at least 2 cycles using live `issue_loop_runner.py` (no `--loop-result-sequence-file`).
- [x] Backlog stock/replenishment gates pass (or fail with deterministic reason and recovery plan).
- [x] Pilot summary and cycle reports are archived under `planningops/artifacts/pilot/`.
- [x] Trade-off delta vs sequence-mode pilot is documented in workbench audit.

## Work Log

### 2026-03-05 - Live Pilot Complete

**By:** Codex

**Actions:**
- Created temporary pilot issue/card and executed live supervisor run without sequence stub:
  - run id: `pilot-20260305-live-runner`
  - cycles: `2`
- Captured summary/cycle artifacts under `planningops/artifacts/pilot/pilot-20260305-live-runner/`.
- Published live-vs-sequence delta and deterministic recovery plan:
  - `docs/workbench/unified-personal-agent-platform/audits/2026-03-05-supervisor-live-runner-dryrun-pilot-audit.md`
- Closed and removed temporary pilot issue/card after run.
- Added follow-up backlog for discovered gaps:
  - `033` escalation false-positive on `pass/ok`
  - `034` live backlog stock shortage replenishment

**Validation:**
- `python3 planningops/scripts/autonomous_supervisor_loop.py --mode dry-run --max-cycles 2 --continue-on-experiment --report-only-gates --owner rather-not-work-on --project-num 2 --initiative unified-personal-agent-platform --run-id pilot-20260305-live-runner --artifacts-root planningops/artifacts/pilot --output planningops/artifacts/pilot/pilot-20260305-live-runner-summary.json`
