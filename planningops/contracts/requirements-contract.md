# Ralph Loop Requirements Contract

## Functional Requirements
1. Intake must select only issues where `Status=Todo`, `workflow_state in {ready-contract, ready-implementation}`, and `execution_kind=executable` (default when omitted), then enforce `execution_order` ascending.
2. Intake must block issues with unsatisfied `depends_on`.
3. Selector must deterministically assign `loop_profile` from issue context and transition history (`L1|L2|L3|L4|L5`), including explicit contract-stage simulation signals (`simulation_required`, `uncertainty_level`).
4. Each loop must produce deterministic artifacts for the same input and commit.
5. Verification must emit one verdict from `pass|fail|inconclusive`.
6. Feedback must post result comments to issue and update project fields (`Status`, `workflow_state`, `loop_profile`, `last_verdict`, `last_reason`).
7. Feedback field/schema drift errors must not crash runner; they must be normalized to `reason_code=feedback_failed` with evidence and `last-run.json` persisted.
8. Runtime and provider policy must be resolvable by task key (`issue-<number>` with `default` fallback).
9. Replanning trigger must be raised when `inconclusive` repeats twice or same `reason_code` repeats three times for the same issue.
10. Runner must resolve a repo execution adapter by `target_repo` and invoke `before_loop` and `after_loop` hooks.
11. Adapter hook result payload must satisfy required fields (`status`, `phase`, `adapter`, `target_repo`, `reason_code`, `message`).
12. Adapter reason taxonomy must be constrained to `contract|permission|context|runtime|feedback_failed`.
13. Attempt budget must be derivable from issue body with defaults (`max_attempts`, `max_duration_minutes`, `max_token_budget`).
14. Invalid attempt budget values must be treated as non-selectable input until corrected.
15. Runner must persist checkpoint stages (`pre_hook`, `loop_executed`, `verified`, `feedback_applied`) per issue.
16. Runner must support resume mode that reuses valid checkpoint artifacts.
17. Runner must enforce per-issue lease lock and reject concurrent duplicate execution.
18. Runner must emit watchdog report for lock lifecycle and stale lock recovery.
19. Escalation gate must trigger auto-pause on `same_reason_x3` or `inconclusive_x2`.
20. Auto-pause trigger must emit replan decision artifact and transition-log event.
21. Issues entering `ready-implementation` must include blueprint refs (`interface_contract_refs`, `package_topology_ref`, `dependency_manifest_ref`, `file_plan_ref`).
22. When implementation uncovers contract/topology/dependency/file-plan mismatch, execution must transition back to redefine (`ready-contract`) before resuming implementation.
23. Re-entry to `ready-implementation` requires updated blueprint refs and refreshed verification evidence.
24. Touched planningops modules must have up-to-date module `README.md` files and pass module README contract checks.
25. Before loop execution, runner must validate a deterministic worker task pack (`worker_policy_kind`, rendered `command`, retry/timeout policy, idempotency key).
26. Worker task pack validation failure must block execution start with explicit preflight failure result.
27. Verification hard gate must require schema-valid `execution-attempts` evidence (`execution-attempts.json`) and reject `pass` when evidence is missing/invalid.
28. Verification output (`verdict`, `reason_code`) must be consistency-checked against loop report evidence and written identically into project payload.
29. Autonomous run control must be convergence/risk bounded; wall-clock duration is metadata and cannot override safety or quality stop conditions.
30. Autonomous stop conditions must explicitly include quality failure, escalation trigger, and runtime safety conflict with deterministic evidence output.
31. High-uncertainty or architecture-tradeoff changes must use branch/worktree comparative experiment protocol with artifact-backed selection record.
32. Backlog operation must define queue classes (`ready_now`, `next_up`, `quality_hardening`) with explicit minimum stock targets for executable work only.
33. Intake selection must enforce `high_value_ready_first` so non-ready cards cannot preempt a ready-now candidate.
34. Replenishment candidates must be evidence-backed and rejected when artifact references are missing.
35. Replenishment candidate normalization must preserve `execution_kind`, dependency baseline (`depends_on`), and checklist acceptance criteria.
36. Inventory-only backlog cards must remain distinguishable via issue metadata and must never satisfy executable stock floors or live pull selection.
37. Supervisor loop must orchestrate multi-cycle `plan -> work -> review -> replan` with deterministic per-cycle records.
38. Supervisor must evaluate experiment triggers from uncertainty/simulation signals and emit explicit experiment trigger artifacts.
39. Supervisor decisions must treat replan and replenishment outputs as first-class cycle outputs.
40. Supervisor summary must publish final stop reason and contract references for each run.
41. Supervisor experiment trigger must be able to invoke an automatic comparative executor that creates deterministic option worktrees.
42. Automatic comparative executor must emit per-option reports and weighted decision record artifacts.
43. Automatic comparative executor failure must map to supervisor stop reason `experiment_auto_executor_failed`.

## Non-Functional Requirements
1. Idempotency: repeated execution for same issue+commit must not duplicate updates.
2. Time bounds: loop timeout and retry limit must be configurable.
3. Traceability: every state transition must be recorded in `transition-log.ndjson`.
4. Reproducibility: dry-run mode must simulate updates without remote writes.
5. Portability: local-first runtime must be migratable to Oracle Cloud by profile switch without contract shape change.
6. Kanban operation model: execution cadence is non-periodic pull-based; readiness and evidence gates, not sprint windows, determine progression.
7. Schema mismatch policy: dry-run may emit report-only verdicts for migration visibility; apply mode must fail fast on required field mismatch.
8. Autonomous operation policy: prioritize quality and convergence over throughput or fixed runtime windows.

## Naming Contract
- External contract term is fixed to `Executor`.
- Internal implementation unit term is fixed to `Worker`.

## Definition of Ready (DoR)
- issue has execution metadata (`execution_order`, `depends_on`),
- ECP reference exists,
- required contracts are resolvable,
- runtime permissions are valid,
- implementation blueprint refs are complete for `ready-implementation`,
- `loop_profile` is either present on the card or derivable by selector rules.

## Definition of Done (DoD)
- code/doc patch created,
- verification verdict generated,
- issue comment posted,
- project feedback update attempted and result logged,
- transition log appended,
- touched module README documents updated if module boundaries/outputs changed,
- `loop_profile` and reason fields synchronized to project card.

## Contract Boundary Mapping (`loop_profile`)
- C1 (run lifecycle): `loop_profile`, `selection_reason`, `selected_at_utc` must be recorded in run context.
- C2 (subtask handoff): child runs inherit `loop_profile` unless explicit override policy is declared.
- C8 (plan-to-github projection): `loop_profile` must map to project single-select field and remain consistent with `last_verdict`/`last_reason`.
- Adapter contract: see `planningops/contracts/execution-adapter-interface-contract.md`.
- Attempt budget contract: see `planningops/contracts/attempt-budget-contract.md`.
- Checkpoint resume contract: see `planningops/contracts/checkpoint-resume-contract.md`.
- Lease lock contract: see `planningops/contracts/lease-lock-watchdog-contract.md`.
- Escalation contract: see `planningops/contracts/escalation-gate-contract.md`.
- Autonomous run policy contract: see `planningops/contracts/autonomous-run-policy-contract.md`.
- Worktree comparative experiment protocol: see `planningops/contracts/worktree-comparative-experiment-protocol.md`.
- Backlog stock/replenishment contract: see `planningops/contracts/backlog-stock-replenishment-contract.md`.
- Autonomous supervisor loop contract: see `planningops/contracts/autonomous-supervisor-loop-contract.md`.
- Supervisor experiment auto-executor contract: see `planningops/contracts/supervisor-experiment-auto-executor-contract.md`.
- Implementation readiness contract: see `planningops/contracts/implementation-readiness-gate-contract.md`.
- Worker task pack contract: see `planningops/contracts/worker-task-pack-contract.md`.
