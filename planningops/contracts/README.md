# planningops/contracts

## Purpose
Define runtime behavior contracts used by the issue-resolution loop and quality gates.

## Contents
- `problem-contract.md`: required inputs/outputs and success/failure boundaries
- `requirements-contract.md`: functional and non-functional requirements
- `failure-taxonomy-and-retry-policy.md`: reason codes and retry/escalation policy
- `plan-execution-contract-v1.md`: machine-executable plan metadata contract (PEC v1)
- `meta-plan-graph-contract.md`: plan-of-plans graph contract (MPG v1)
- `meta-plan-orchestration-runbook.md`: operational runbook for MPG execution flow
- `implementation-readiness-gate-contract.md`: design-first gate and redefine loop
- `execution-adapter-interface-contract.md`: adapter hook interface
- `attempt-budget-contract.md`: per-task loop budget
- `autonomous-run-policy-contract.md`: convergence/risk-based autonomous run control and stop criteria
- `worktree-comparative-experiment-protocol.md`: A/B branch-worktree experiment trigger, artifact, and scoring protocol
- `backlog-stock-replenishment-contract.md`: queue stock floor + evidence-backed replenishment gate
- `autonomous-supervisor-loop-contract.md`: multi-cycle plan-work-review-replan orchestration contract
- `supervisor-experiment-auto-executor-contract.md`: trigger-to-worktree comparative execution and decision contract
- `worker-task-pack-contract.md`: worker execution bundle and render safety contract
- `checkpoint-resume-contract.md`: checkpoint and resume behavior
- `lease-lock-watchdog-contract.md`: concurrency and stale-lock recovery
- `escalation-gate-contract.md`: automatic replan escalation conditions
- `module-refactor-hygiene-loop-contract.md`: periodic refactor hygiene policy
- `control-plane-boundary-contract.md`: thin-core ownership boundary and federation script placement rules
- `script-role-separation-contract.md`: recurring core scripts vs one-off script separation rules
- `issue-quality-contract.md`: backlog issue body quality baseline and verification rules
- `issue-label-taxonomy-contract.md`: required label taxonomy (`task`/priority/area/type) and gates
- `artifact-retention-tier-contract.md`: Git vs external artifact storage tier policy
- `artifact-sink-contract.md`: backend selector abstraction + pointer/rehydrate behavior
- `repository-governance-contract.md`: default-branch protection baseline and required-check governance
- `control-tower-ontology-contract.md`: canonical entity/relation/path model for planningops as control tower
- `memory-tier-contract.md`: 3-tier memory lifecycle, frontmatter keys, and compaction trigger contract
- `federated-label-taxonomy-contract.md`: federated required labels and in-scope issue label quality rules
- `cross-repo-contract-version-pin-policy.md`: external contract version pinning
- `compatibility-report.md`: compatibility tracking summary

## Change Rules
- Behavior changes must update the relevant contract first, then scripts.
- New failure reasons must be added to taxonomy and mapped consistently.
- Contract edits must keep command paths and artifact paths repo-root relative.
