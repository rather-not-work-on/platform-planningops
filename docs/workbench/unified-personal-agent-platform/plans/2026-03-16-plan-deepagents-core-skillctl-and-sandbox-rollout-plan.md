---
title: plan: DeepAgents Core, Skillctl, and Sandboxed Apply-Mode Rollout
type: plan
date: 2026-03-16
updated: 2026-03-19
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Replaces NanoClaw-first planning assumptions with a vendor-neutral planner-engine strategy that adopts DeepAgents first, adds an OpenClaw-inspired skill manager, and adopts NanoClaw-style sandboxing for apply-mode execution.
---

# plan: DeepAgents Core, Skillctl, and Sandboxed Apply-Mode Rollout

## Overview
This plan defines one operating model for the next planner/runtime wave:

1. bounded context C moves from a NanoClaw-first description to a vendor-neutral `planner engine` abstraction, with `deepagents` as the first preferred implementation candidate inside `monday`.
2. `skillctl` becomes the repo-owned skill supply-chain tool that imports, pins, syncs, and audits repo-local skills.
3. `OpenClaw` is used as a reference for skill registry and precedence design, not as a replacement runtime.
4. `NanoClaw` is used as a reference for isolation and anti-bloat discipline, not as the default planner runtime.
5. existing `nanoclaw` assumptions in canonical docs/config move through an explicit compatibility migration instead of ad hoc replacement.

## Implementation Reality Update (2026-03-19)

- `monday` has now promoted `local` to the gateway-first `deepagents` default planner profile.
- the active live path is:
  - `local runtime profile`
  - `deepagents` planner engine
  - local LiteLLM-compatible endpoint
  - intended routing priority `Gemini free-tier -> Ollama local fallback`
- `legacy_local` is retained as the rollback profile.
- runtime readiness and gate evidence are passing.
- `monday` runtime-operations readiness now aggregates the sibling `platform-provider-gateway` LiteLLM stack as an explicit external surface instead of assuming planner evidence alone is sufficient.
- this plan therefore moves from “future default-promotion design” into “post-promotion governance catch-up” status.
- the governance/documentation gap is now closed:
  - canonical docs describe bounded context C as a vendor-neutral planner engine
  - `planningops/config/runtime-profiles.json` no longer carries `nanoclaw_endpoint`
  - `monday` consumes shared runtime planner hints through `planner_policy` only
- this plan should now be treated as implementation history and reference material.

## Research Consolidation
### Current State (2026-03-16)
- canonical monday architecture still names bounded context C as `Planning & Delegation (nanoclaw core)`.
- canonical foundation planning still assumes `nanoclaw + orchestrator + ralph-loop + codex2message` as the core composition.
- `planningops/config/runtime-profiles.json` still carries `nanoclaw_endpoint` in both `local` and `oracle_cloud` profiles.
- `monday` already has the correct seam for engine replacement:
  - `MissionPlannerPort`
  - `MissionOrchestrator` dependency injection
  - `SubtaskDelegator` / handoff plan scaffolding
- operator-channel delivery is already contract-pinned to `monday`-owned CLI/MCP adapters and must remain a thin wrapper over `packages/messaging-adapter`.
- no checked-in `.mcp.json` exists in the current repo set, so initial deepagents adoption should not depend on MCP-first wiring.
- internal workbench evidence currently includes only a NanoClaw fit assessment, so this migration must preserve explicit compatibility notes until a canonical planner-engine update is approved.

### Existing Internal Inputs
- `docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md`
- `docs/initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md`
- `docs/initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md`
- `planningops/contracts/operator-channel-adapter-contract.md`
- `planningops/contracts/control-plane-boundary-contract.md`
- `planningops/config/runtime-profiles.json`

### External Inputs
- DeepAgents official docs and repo
- OpenClaw gateway and skills docs
- NanoClaw official repo

## Problem Statement
The platform has three mismatches that now need a single corrective plan:

1. `nanoclaw` is still embedded in core architecture language even though the current direction requires a vendor-neutral planner seam with `deepagents` as the leading implementation candidate.
2. the system has no approved skill supply-chain model for importing curated external skills such as `pm-skills` into repo-local deepagents/Codex surfaces.
3. apply-mode execution is transport-gated, but tool execution and external skill ingestion are not yet isolated under a dedicated sandbox contract.

If these remain unresolved:
- canonical docs will diverge from the intended runtime direction,
- `monday` planner evolution will stay stuck on a stub seam,
- external skills will enter by copy/paste instead of an auditable pipeline,
- apply-mode will accumulate unsafe exceptions around tools and imported skills.

## Goals
1. Replace `nanoclaw`-first planning assumptions with a vendor-neutral planner-engine design whose first implementation target is `deepagents`.
2. Keep `platform-planningops` as a thin control plane while `monday` remains the only execution/runtime owner.
3. Introduce a repo-owned `skillctl` workflow with source pinning, namespacing, precedence, and lock evidence.
4. Add a sandbox contract for risky apply-mode tool execution and imported skills.
5. Roll out the migration in waves that preserve documentation, runtime, and contract integrity.

## Non-Goals
- adopting the full OpenClaw gateway/runtime stack
- adopting NanoClaw as the default planner runtime
- replacing `monday` queue, messaging, or delivery-cycle ownership
- building a public skill marketplace in the first rollout wave
- redesigning Slack/email transport semantics in this plan

## Decision Summary
### Chosen Operating Model
- `deepagents` is the first embedded planner-engine implementation inside `monday/packages/agent-kernel`.
- `skillctl` is the repo-owned skill manager for deepagents/Codex-facing skill roots.
- `OpenClaw` contributes skill precedence, registry metadata, and bundle ideas only.
- `NanoClaw` contributes isolation, anti-bloat, and capability discipline only.

### Explicit Rejections
- no OpenClaw gateway process inside `monday`
- no NanoClaw-first planner assumption in new docs
- no direct planner-level Slack/email/provider calls outside existing CLI/MCP and gateway boundaries

## Detailed Architecture
## A. Ownership Model
### `platform-planningops` owns
- canonical planner/runtime contracts
- approved external skill source policy
- compatibility migration plan (`nanoclaw` terminology -> `deepagents` terminology)
- rollout gates and verification commands

### `monday` owns
- embedded `deepagents` planner implementation
- repo-local skill resolution and execution
- `skillctl` implementation and lockfile generation
- apply-mode sandbox enforcement
- CLI/MCP operator channel adapters and transport evidence

### Boundary Rule
`platform-planningops` must not become a runtime host for deepagents, skills, or sandboxes. It governs the contracts; `monday` executes them.

## B. `monday` DeepAgents Core Design
### Package Additions
- `packages/agent-kernel/src/deepagents_planner.ts`
- `packages/agent-kernel/src/planner_engine_selector.ts`
- `packages/agent-kernel/src/skill_manifest_loader.ts`
- `packages/orchestrator/src/planner_run_metadata.ts`

### Planner Port Strategy
Keep the existing planner seam stable:
- `MissionPlannerPort` remains the only planning contract exposed to orchestrator.
- `DeepAgentsPlanner` implements `MissionPlannerPort`.
- legacy `SubtaskDelegator` remains available behind a feature flag for fallback and regression comparison.
- canonical docs should describe bounded context C as `planner engine` first, and list DeepAgents/NanoClaw only as implementation candidates or historical compatibility notes.

### Runtime Selection
Introduce planner engine selection in `monday`:

```text
planner_engine = legacy | deepagents
rollout_default = legacy
target_default_after_gate = deepagents
```

Selection inputs:
- `monday` repo-local planner config
- abstract planner hint from `planningops` runtime profile
- explicit CLI override for local smoke

### DeepAgents Planner Responsibilities
- interpret `MissionInput`
- select approved repo-local skills
- build `TaskPlan`
- emit planner metadata artifact for diagnostics
- never perform operator delivery directly
- never bypass executor or messaging boundaries

### DeepAgents Planner Non-Responsibilities
- queue mutation
- Slack/email delivery
- provider gateway ownership
- run state creation outside orchestrator/executor contracts

## C. Orchestrator and Handoff Evolution
### Current Gap
`MissionOrchestrator` only executes the first generated handoff. That is acceptable for the current stub, but under-utilizes a richer planner.

### Required Change
Extend orchestrator semantics in one controlled step:
- preserve `createRun(mission): RunRef`
- add internal support for ordered handoff candidate metadata
- emit planner diagnostics without changing external run semantics
- keep `ExecutorPort` as the single execution entrypoint
- keep one primary executor invocation per `createRun` until a separate run-lifecycle contract change explicitly allows multi-handoff execution semantics

### Guardrail
Do not let planner richness leak into new cross-package coupling. `orchestrator` still consumes plans and handoffs through typed ports only.

## D. `skillctl` Design
### Goal
Create one deterministic skill supply-chain tool for:
- internal repo-owned skills
- imported external skills such as `pm-skills`
- synchronized deepagents/Codex skill views

### Implementation Reality (2026-03-19)
- phase-1 `skillctl` is now Python-first, not package-first
- landed files in `monday`:
  - `config/skill-registry.json`
  - `config/skill-registry.schema.json`
  - `config/skill-lock.json`
  - `config/skill-lock.schema.json`
  - `scripts/import_pm_skills.py`
  - `scripts/validate_skill_registry.py`
  - `scripts/validate_skill_lock.py`
  - `scripts/test_skill_registry_suite.sh`
  - `vendor/skills/pm-skills/...`
- current baseline imports the full `phuryn/pm-skills` skill tree while ignoring Claude-only slash commands
- future TypeScript/package ergonomics remain optional follow-up work, not a prerequisite for claiming `U40`

### Proposed Files
- `monday/config/skill-registry.json`
- `monday/config/skill-lock.json`
- `monday/config/planner-runtime.json`
- `monday/config/apply-sandbox-policy.json`
- `monday/scripts/skill_registry_contract.py`
- `monday/scripts/validate_skill_registry.py`
- `monday/scripts/import_pm_skills.py`
- `monday/scripts/validate_skill_lock.py`
- `monday/vendor/skills/`
- optional later ergonomics:
  - `monday/packages/skill-registry/README.md`
  - `monday/packages/skill-registry/src/cli.ts`

### Source Classes
1. `bundled`
   - future repo-owned skills committed under a dedicated repo-local skill root
2. `vendor`
   - imported external skills mirrored under `monday/vendor/skills/`
3. `user`
   - local developer-only overlays outside the repo

### Precedence Rules
1. `bundled` is the default CI/apply baseline.
2. `vendor` must not silently override `bundled`; any same-capability replacement must use an explicit namespace and activation profile.
3. `user` is allowed for local interactive exploration only.
4. CI and apply-mode must reject `user` skills.
5. name resolution must fail closed on namespace collisions or ambiguous activation.

### Lockfile Contract
Each locked skill entry must record:
- `source_type`
- `source_repo`
- `source_ref`
- `source_path`
- `license`
- `content_hash`
- `namespace`
- `enabled`
- `sync_targets`

### `pm-skills` Import Strategy
- recursively discover `*/skills/*/SKILL.md`
- ignore Claude-only `commands/` in v1
- namespace imported skills by plugin and skill slug
- record source repo/ref/path/license/hash in the lockfile

### Sync Targets
`skillctl sync` writes deterministic outputs to:
- `monday/vendor/skills/`
- optional local Codex target for operator/dev workflows only

Local Codex sync rules:
- never executed by CI
- never required for apply-mode
- never used as the source of truth for lock verification

## E. Sandboxed Apply-Mode Design
### Goal
Adopt NanoClaw-style isolation without importing NanoClaw runtime ownership.

### Implementation Reality (2026-03-19)
- phase-1 sandboxing is now implemented in `monday` with:
  - `config/apply-sandbox-policy.json`
  - `config/apply-sandbox-policy.schema.json`
  - `contracts/runtime-apply-sandbox-decision.schema.json`
  - `scripts/validate_apply_sandbox_policy.py`
  - `scripts/assess_skill_apply_sandbox.py`
  - `scripts/run_skill_apply_mode.py`
  - `scripts/validate_skill_apply_sandbox_decision.py`
  - `scripts/test_apply_sandbox_suite.sh`
- current enforcement is intentionally process-level, not container-level:
  - source-class policy is fail-closed
  - imported vendor skills are limited to `observe/read_repo`
  - user skills are blocked in `ci` and `apply`
  - subprocess execution strips provider credentials unless `credential_access` is explicitly allowed
- future containerization was not required for the first `U50` claim, and `monday` now includes optional container-required hardening hooks without changing the default subprocess-first posture
- reviewed container runtime profiles are now separated into `monday/config/apply-sandbox-container-profiles.json`, so sandbox policy selection and runtime implementation details no longer drift together

### Policy Levels
1. `observe`
   - read-only inspection, no filesystem mutation
2. `dry-run`
   - patch proposal/evidence only
3. `apply-sandboxed`
   - isolated process or container with explicit capability allowlist
4. `apply-reviewed`
   - reviewed adapters only, used for approved channel/delivery or higher-risk mutations

### Capability Classes
- `read_repo`
- `write_workspace`
- `run_tests`
- `network_fetch`
- `provider_call`
- `credential_access`
- `channel_delivery`

### Sandbox Rules
- imported external skills default to `observe` until approved
- `credential_access` and `channel_delivery` are never granted to vendor/user skills
- apply-mode writes must remain inside repo-owned boundaries
- planner-level tools cannot directly invoke Slack/email/provider gateways outside approved adapters

### Initial Isolation Mechanism
Start with isolated subprocess profiles and workspace allowlists. Containerization is a phase-2 hardening step only for high-risk capability classes.

## F. Config and Contract Migration
### Runtime Profile Migration
Current:
- `nanoclaw_endpoint`

Target:

```json
{
  "planner_policy": {
    "engine_hint": "deepagents",
    "execution_mode": "embedded",
    "capability_profile": "repo_local_skills"
  }
}
```

Concrete repo-local planner settings move to `monday/config/planner-runtime.json`:

```json
{
  "engine": "deepagents",
  "skills_root": ".deepagents/skills",
  "sandbox_policy_ref": "config/apply-sandbox-policy.json",
  "mcp_config": null
}
```

### Compatibility Window
1. add `planner_policy` while keeping `nanoclaw_endpoint`
2. migrate all planningops readers to `planner_policy`
3. add `monday/config/planner-runtime.json` for repo-local paths and sandbox refs
4. migrate monday readers to repo-local planner config
5. freeze new `nanoclaw_*` additions
6. remove `nanoclaw_endpoint` after contract and config consumers are updated

### Canonical Doc Migration Targets
- `20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md`
- `20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md`
- any remaining workbench/canonical references that position NanoClaw as the default planner core

## File Plan
## PlanningOps / Docs
- add workbench plan (this document)
- add a canonical follow-up architecture or execution-plan update once approved
- update planner terminology in canonical monday docs
- update quality/gate docs if migration introduces new contract evidence

## Monday / Runtime
- add planner engine selector and deepagents adapter
- add skill registry package and `skillctl`
- add `packages/skill-registry/README.md` and monday topology/readme updates alongside the new package
- add sandbox policy config
- add repo-local planner config
- add repo-local deepagents skills root
- add optional `.mcp.json` only after CLI-first rollout is green

## Implementation Phases
## Phase 0: Decision Lock and Migration Scope (P0)
### Deliverables
- this workbench plan
- migration scope inventory for `nanoclaw` references
- approval decision on `planner_policy` and repo-local planner config schemas

### Validation
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile workbench`
- `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`

## Phase 1: DeepAgents Adapter Skeleton (P1)
### Deliverables
- `DeepAgentsPlanner` skeleton in `monday/packages/agent-kernel`
- planner engine feature flag / selector
- planner diagnostics artifact format
- legacy planner fallback preserved
- `legacy` remains the rollout default in local and CI paths

### Validation
- `pnpm typecheck` in `monday`
- planner unit tests for `legacy` and `deepagents`
- no contract or messaging boundary regressions

## Phase 2: Orchestrator Multi-Handoff Readiness (P1)
### Deliverables
- orchestrator support for ordered handoff candidate metadata and deterministic primary-selection tracing
- planner metadata surfaced in local runtime evidence
- regression tests proving `createRun` semantics remain stable

### Validation
- `bash scripts/test_runtime_guardrails.sh` in `monday`
- scheduler/queue smoke unchanged
- planner richer output does not change operator delivery path

## Phase 3: `skillctl` and Skill Supply Chain (P1)
### Deliverables
- `monday/config/planner-runtime.json`
- `skill-registry.json`
- `skill-lock.json`
- `skillctl` phase-1 baseline via Python importer/validator/report flow
- `pm-skills` recursive importer
- namespace policy for bundled/vendor/user skills

### Validation
- lockfile reproducibility test
- imported skill hash drift test
- full `pm-skills` skill tree imported successfully without commands
- collision test proves vendor skills cannot shadow bundled skills without explicit activation

## Phase 4: Sandboxed Apply-Mode (P1)
### Deliverables
- `apply-sandbox-policy.json`
- isolated subprocess runner
- capability allowlist enforcement
- CI rejection of unapproved vendor/user skills in apply-mode

### Validation
- sandbox policy contract tests
- apply-mode failure-closed tests
- operator-channel delivery tests still route through reviewed adapters only

Status (2026-03-19):
- all phase-4 deliverables are implemented in `monday`
- validation is covered by `scripts/test_apply_sandbox_suite.sh`

## Phase 5: DeepAgents Default Promotion (P2)
### Deliverables
- promote `deepagents` from gated option to default planner engine in approved runtime paths
- preserve explicit `legacy` fallback path for rollback
- document rollout verdict and rollback trigger

### Validation
- dual-engine comparison corpus passes
- no planner/evidence schema drift between `legacy` and `deepagents` on approved missions
- rollback switch verified in local smoke

## Phase 6: Canonical Migration and Nanoclaw Terminology Retirement (P2)
### Deliverables
- canonical architecture doc update
- canonical execution-plan update
- planningops runtime profile migration off `nanoclaw_endpoint`
- deprecation note in workbench audit and config consumers

### Validation
- `rg -n "nanoclaw core|nanoclaw_endpoint" docs/initiatives docs/workbench planningops/config`
- no unresolved default-planner references remain
- config readers pass against new schema

## Backlog Issue Split
1. `UAP-DA-001` (`platform-planningops`)
- inventory and migrate canonical `nanoclaw` planner references
- depends_on: none

2. `MON-DA-002` (`monday`)
- add `DeepAgentsPlanner` and planner engine selector
- depends_on: `UAP-DA-001`

3. `MON-DA-003` (`monday`)
- extend orchestrator for multi-handoff readiness without changing external run semantics
- depends_on: `MON-DA-002`

4. `MON-DA-004` (`monday`)
- add `skillctl`, registry, lockfile, and sync pipeline
- depends_on: `MON-DA-002`

5. `MON-DA-005` (`monday`)
- import first curated `pm-skills` bundle with namespace + hash pinning
- depends_on: `MON-DA-004`

6. `MON-DA-006` (`monday`)
- add sandbox policy and apply-mode isolation runner
- depends_on: `MON-DA-004`

7. `MON-DA-007` (`monday`)
- promote `deepagents` to default behind rollout gate and preserve rollback switch
- depends_on: `MON-DA-003`, `MON-DA-005`, `MON-DA-006`

8. `PO-DA-008` (`platform-planningops`)
- migrate `runtime-profiles.json` to `planner_policy`
- depends_on: `MON-DA-002`, `MON-DA-006`

## Acceptance Criteria
- [ ] canonical monday architecture no longer presents NanoClaw as the default planner core and instead describes bounded context C in vendor-neutral terms
- [ ] `monday` can select `legacy` or `deepagents` through the same planner port
- [ ] `skillctl` can import at least one curated external skill bundle and emit a reproducible lockfile
- [ ] imported skills are namespaced and hash-pinned
- [ ] vendor skills cannot shadow bundled skills without explicit activation
- [ ] apply-mode rejects unapproved vendor/user skills and capability overreach
- [ ] operator-channel delivery still flows only through `monday`-owned CLI/MCP adapters
- [ ] documentation and contract validation remain green through the migration

## Success Metrics
- `default_planner_reference_nanoclaw_count = 0` outside compatibility notes
- `skill_lock_reproducibility_failures = 0`
- `vendor_skill_shadow_collision_count = 0`
- `apply_mode_unapproved_skill_executions = 0`
- `planner_port_dual_engine_regressions = 0`
- `operator_channel_boundary_regressions = 0`
- `planningops_repo_local_path_leaks = 0`

## Risks and Mitigations
- risk: deepagents introduces planner nondeterminism
  - mitigation: feature flag, planner diagnostics artifact, locked skill set, regression corpus
- risk: skill sprawl from imported packs
  - mitigation: namespace policy, allowlist import, lockfile pinning, no command import in v1
- risk: sandbox cost slows delivery
  - mitigation: start with subprocess isolation, containerize only high-risk paths later
- risk: control-plane config starts owning repo-local runtime paths
  - mitigation: keep `planningops` at planner hints only and move concrete paths into `monday/config/planner-runtime.json`
- risk: canonical docs and runtime config drift during migration
  - mitigation: explicit terminology inventory, compatibility window, doc sweep gate
- risk: deepagents adoption leaks into transport or control-plane ownership
  - mitigation: preserve current CLI/MCP adapter and messaging-adapter boundaries

## Validation Commands
```bash
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile workbench
bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all
```

Expected sibling-repo validation during implementation:

```bash
cd ../monday
pnpm typecheck
bash scripts/test_operator_channel_delivery_cli.sh
bash scripts/test_supervisor_status_update_cli.sh
bash scripts/test_supervisor_goal_completion_cli.sh
bash scripts/test_runtime_guardrails.sh
```

## References
- DeepAgents official docs and repo
- OpenClaw gateway/skills docs
- NanoClaw official repo
- `docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md`
- `docs/initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md`
- `docs/initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md`
