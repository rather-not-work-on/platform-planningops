---
status: ready
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
- [ ] Supervisor run executes at least 2 cycles using live `issue_loop_runner.py` (no `--loop-result-sequence-file`).
- [ ] Backlog stock/replenishment gates pass (or fail with deterministic reason and recovery plan).
- [ ] Pilot summary and cycle reports are archived under `planningops/artifacts/pilot/`.
- [ ] Trade-off delta vs sequence-mode pilot is documented in workbench audit.
