---
title: plan: Ralph Loop Full Automation Delivery
type: plan
date: 2026-03-04
updated: 2026-03-04
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the concrete path from current loop MVP to full autonomous issue-resolution automation with hard gates and rollback-safe rollout.
---

# plan: Ralph Loop Full Automation Delivery

## Objective
Move from "deterministic loop control-plane + simulated worker execution" to "fully automated issue resolution loop with real worker execution, verification, and safe feedback updates".

## Current State (2026-03-04)
Implemented:
1. deterministic intake/selection, dependency gating, loop-profile selection
2. checkpoint/resume, lease lock/watchdog, escalation auto-pause
3. PEC compile/projection and meta-plan graph orchestration
4. local harness execution (`issue_loop_runner` -> `ralph_loop_local`)

Gap to full automation:
1. worker execution core still mostly simulation baseline
2. no standardized worker task-pack contract per loop profile
3. no PR-based apply boundary for non-trivial code changes
4. no multi-repo execution matrix with deterministic rollback policy

## Full Automation Definition
A run is "full automation" only when all conditions hold:
1. selected issue is solved by real worker execution against target repo
2. verification returns `pass` with complete evidence artifacts
3. patch is persisted through approved Git workflow boundary (branch/PR/merge policy)
4. issue/project feedback is updated idempotently
5. replay of same input does not create divergent side effects

## Hard Gates
### G1: Execution Contract Gate
- each loop run must resolve a concrete worker policy and command plan
- command plan is recorded in evidence before execution

### G2: Verification Gate
- required artifacts must exist and match loop profile contract
- verification verdict must be deterministic for same inputs

### G3: Apply Safety Gate
- apply mode must enforce policy-driven write boundary (direct push disabled by default)
- fallback path on failure is `blocked + replan_required` with evidence

### G4: Multi-Repo Gate
- cross-repo tasks must use adapter hooks and preserve dependency order
- failure in one repo must not corrupt other repo feedback state

## Delivery Phases
### Phase A (Completed in this turn): Worker Policy Dispatch Foundation
1. add `worker_policy` resolution to runtime context
2. add command resolver in `ralph_loop_local` (`parser_diff_dry_run|python_script|shell`)
3. add contract smoke test for worker policy resolution

Acceptance:
- `ralph_loop_local` can execute task-specific worker policy without code edits
- invalid worker policy fails fast with evidence

### Phase B: Worker Task-Pack Contract
1. define `worker-task-pack` contract (input/output/retry/timeout/idempotency)
2. add per-loop default task pack (`L1~L5`)
3. add validator + contract tests for task-pack schema and runtime rendering

Acceptance:
- every selected issue resolves to exactly one validated task pack
- no run starts with unresolved/malformed worker task pack

### Phase C: Git Boundary Automation
1. add execution mode matrix: `dry-run`, `apply-local`, `apply-pr`
2. implement branch/PR handoff artifact contract
3. enforce required checks before feedback marks as `done`

Acceptance:
- `apply-pr` produces deterministic branch and PR payload artifacts
- failed apply cannot produce `done` feedback

### Phase D: Multi-Repo Autonomous Execution
1. connect task pack + adapter hooks for cross-repo execution
2. add ordered fanout executor with partial-failure containment
3. add reconciliation report linking per-repo verdicts

Acceptance:
- cross-repo run preserves dependency topology and rollback semantics
- reconciliation report is required for final verdict

### Phase E: Pilot and Stabilization
1. run 7-day local pilot with tracked KPIs
2. tune retry/escalation thresholds from observed data
3. lock default profile for production-like local operation

Acceptance:
- no duplicate feedback writes
- no unbounded retries
- stale-lock recovery and checkpoint resume observed in pilot logs

## Work Items for Immediate Next Cycle
1. create `planningops/contracts/worker-task-pack-contract.md`
2. add `planningops/schemas/worker-task-pack.schema.json`
3. add `planningops/fixtures/worker-task-pack-sample.json`
4. implement `planningops/scripts/validate_worker_task_pack.py`
5. wire validator into `issue_loop_runner` preflight
6. add `test_worker_task_pack_contract.sh`

## Replan Triggers
1. repeated `runtime.execute_error` with same reason >= 3
2. inconclusive verdict >= 2 on same issue
3. task-pack render failure in apply mode
4. feedback/apply drift between artifacts and GitHub state

## Rollback Policy
1. force `--mode dry-run --no-feedback`
2. preserve checkpoint and watchdog artifacts
3. mark selected card `blocked` with `reason_code=automation_rollback`
4. require manual recovery plan before re-enabling apply
