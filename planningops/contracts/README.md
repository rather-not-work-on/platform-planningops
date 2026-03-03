# planningops/contracts

## Purpose
Define runtime behavior contracts used by the issue-resolution loop and quality gates.

## Contents
- `problem-contract.md`: required inputs/outputs and success/failure boundaries
- `requirements-contract.md`: functional and non-functional requirements
- `failure-taxonomy-and-retry-policy.md`: reason codes and retry/escalation policy
- `implementation-readiness-gate-contract.md`: design-first gate and redefine loop
- `execution-adapter-interface-contract.md`: adapter hook interface
- `attempt-budget-contract.md`: per-task loop budget
- `checkpoint-resume-contract.md`: checkpoint and resume behavior
- `lease-lock-watchdog-contract.md`: concurrency and stale-lock recovery
- `escalation-gate-contract.md`: automatic replan escalation conditions
- `module-refactor-hygiene-loop-contract.md`: periodic refactor hygiene policy
- `cross-repo-contract-version-pin-policy.md`: external contract version pinning
- `compatibility-report.md`: compatibility tracking summary

## Change Rules
- Behavior changes must update the relevant contract first, then scripts.
- New failure reasons must be added to taxonomy and mapped consistently.
- Contract edits must keep command paths and artifact paths repo-root relative.

