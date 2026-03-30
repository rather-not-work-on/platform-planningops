---
title: plan: DeepAgents, Skillctl, and Sandboxed Apply-Mode Issue Pack
type: plan
date: 2026-03-16
updated: 2026-03-19
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Defines the selected long-term rollout order for planner-engine migration: DeepAgents adapter first, skill supply-chain second, sandboxed apply-mode third, default promotion fourth, and canonical migration last.
tags:
  - uap
  - monday
  - planningops
  - deepagents
  - skills
  - sandbox
  - migration
  - issue-pack
---

# plan: DeepAgents, Skillctl, and Sandboxed Apply-Mode Issue Pack

## Goal

Choose the long-term path explicitly and encode it as one dependency-safe rollout:
- bounded context C becomes vendor-neutral `planner engine`, with `deepagents` as the first implementation target
- `skillctl` becomes the mandatory skill supply-chain layer before external skill expansion
- sandboxed apply-mode becomes the mandatory safety layer before default planner promotion
- `deepagents` default promotion happens only after dual-engine and safety gates pass
- canonical docs/config migration happens last so the source of truth changes only after runtime reality is proven

## Selected Strategy

This issue pack selects `A + B + C + D` in this order:

1. `A1`: DeepAgents adapter skeleton
2. `A2`: planner-aware orchestrator readiness
3. `B`: skillctl and external skill supply chain
4. `C`: sandboxed apply-mode
5. `A3`: DeepAgents default promotion
6. `D`: canonical migration and terminology retirement

## Execution Update (2026-03-19)

- `monday` runtime now runs with `local -> deepagents -> LiteLLM(gemini -> ollama)` as the promoted default planner path.
- `legacy_local` remains the explicit rollback profile inside `monday/config/planner-runtime.json`.
- runtime gate evidence is green:
  - `npm run test:planner-runtime`
  - `bash scripts/test_deepagents_sdk_live_smoke.sh`
  - `bash scripts/test_assess_planner_runtime_readiness.sh`
  - `npm run gate:planner-runtime-ready`
- this means `U60` is implemented in runtime reality.
- `U40` is now implemented in `monday` with:
  - `config/skill-registry.json`
  - `config/skill-lock.json`
  - `scripts/import_pm_skills.py`
  - `scripts/validate_skill_registry.py`
  - `scripts/validate_skill_lock.py`
  - `vendor/skills/pm-skills/...`
  - `65` imported `pm-skills` entries pinned in the lockfile
- `U50` is now implemented in `monday` with:
  - `config/apply-sandbox-policy.json`
  - `config/apply-sandbox-container-profiles.json`
  - `scripts/assess_skill_apply_sandbox.py`
  - `scripts/run_skill_apply_mode.py`
  - `scripts/validate_apply_sandbox_policy.py`
  - `scripts/validate_apply_sandbox_container_profiles.py`
  - `scripts/validate_skill_apply_sandbox_decision.py`
  - `scripts/test_apply_sandbox_suite.sh`
- `U70` is now implemented:
  - canonical architecture and execution-plan docs use vendor-neutral planner-engine language
  - `planningops/config/runtime-profiles.json` retires `nanoclaw_endpoint`
  - `monday` shared runtime reader and planner evidence no longer deserialize `nanoclawEndpoint`
- this issue pack is now a rollout record and should be treated as reference material.

## Why This Order

- doing `A` first addresses the current planner seam weakness without forcing an immediate runtime default change
- doing `B` before `A3` prevents unmanaged external skills from becoming part of the default planner path
- doing `C` before `A3` prevents “default promotion first, safety later” drift
- doing `D` last keeps canonical docs aligned with proven runtime behavior instead of aspirational direction

## Issue Pack Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `U10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_contract` | `docs/workbench/unified-personal-agent-platform/audits/2026-03-16-planner-engine-terminology-and-config-migration-audit.md` |
| `U20` | 20 | `rather-not-work-on/monday` | `agent-kernel` | `ready_implementation` | `DeepAgentsPlanner` skeleton + planner engine selector with `legacy` rollout default |
| `U30` | 30 | `rather-not-work-on/monday` | `orchestrator` | `ready_implementation` | deterministic primary-selection metadata for richer planner output |
| `U40` | 40 | `rather-not-work-on/monday` | `skill-registry` | `ready_implementation` | `skillctl`, lockfile, namespace policy, `pm-skills` importer |
| `U50` | 50 | `rather-not-work-on/monday` | `sandbox` | `ready_implementation` | apply-sandbox policy + isolated subprocess enforcement |
| `U60` | 60 | `rather-not-work-on/monday` | `planner-rollout` | `review_gate` | `deepagents` default promotion with rollback switch intact |
| `U70` | 70 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | canonical architecture/execution-plan update + `nanoclaw_endpoint` retirement |

## Current Status Snapshot

| ID | Runtime Status | Note |
| --- | --- | --- |
| `U10` | `done` | planner-engine terminology and migration boundary audit exists |
| `U20` | `done` | planner selector, async seam, SDK adapter, and runtime config path are implemented |
| `U30` | `done` | orchestrator metadata and config-aware composition are in place without changing run semantics |
| `U40` | `done` | Python-first `skillctl` baseline is implemented with registry, lockfile, importer, validator, runbook, and vendored `pm-skills` mirror |
| `U50` | `done` | apply-sandbox policy, reviewed container profile catalog, decision assessment, isolated subprocess runner, fail-closed regression suite, and optional container-required hardening hooks are implemented |
| `U60` | `done` | runtime default promotion is live with rollback profile intact |
| `U70` | `done` | canonical docs/config migration landed and retired `nanoclaw_endpoint` from active runtime surfaces |

## Decomposition Rules

- `U10` defines language, migration scope, and control-plane hint shape only. It must not introduce repo-local monday paths.
- `U20` adds the adapter seam only. `deepagents` is not yet the default planner.
- `U30` may enrich internal planner metadata, but it must not change `createRun -> RunRef` semantics.
- `U40` must make external skill import reproducible before any default planner promotion.
- `U50` must block unapproved vendor/user skills and capability overreach in apply-mode.
- `U60` may promote `deepagents` only after `U20`, `U30`, `U40`, and `U50` all pass.
- `U70` may update canonical defaults only after `U60` proves runtime reality and rollback readiness.

## Dependencies

- `U20` depends on `U10`
- `U30` depends on `U20`
- `U40` depends on `U20`
- `U50` depends on `U40`
- `U60` depends on `U20`, `U30`, `U40`, `U50`
- `U70` depends on `U10`, `U60`

## Hold Rules

- do not promote `deepagents` to default while `legacy`/`deepagents` comparison corpus is incomplete
- do not allow `vendor` skills to shadow `bundled` skills without explicit activation
- do not add `.deepagents/skills`, `.mcp.json`, or sandbox file paths to `planningops` runtime config
- do not retire `nanoclaw_endpoint` until all readers are moved to `planner_policy`
- do not rewrite canonical docs to claim DeepAgents default before `U60` is complete

## Go / Hold Criteria by Stage

### `U20` Go
- planner adapter compiles
- `legacy` remains rollout default
- no operator-channel boundary regressions

### `U40` Go
- at least one curated `pm-skills` bundle imports successfully
- lockfile is reproducible
- namespace collisions fail closed

Status (2026-03-19):
- satisfied via `monday/config/skill-registry.json`
- satisfied via `monday/config/skill-lock.json`
- satisfied via `monday/scripts/test_skill_registry_suite.sh`

### `U50` Go
- apply-mode rejects unapproved vendor/user skills
- credential and channel-delivery capabilities stay blocked for imported skills

Status (2026-03-19):
- satisfied via `monday/config/apply-sandbox-policy.json`
- satisfied via `monday/scripts/test_apply_sandbox_suite.sh`

### `U60` Go
- dual-engine comparison corpus passes
- rollback switch verified
- runtime evidence semantics unchanged on approved mission set

### `U70` Go
- canonical docs updated to vendor-neutral bounded context language
- `nanoclaw_endpoint` retirement validated
- no default-planner contradictions remain across workbench/canonical/docs/config

## Non-Goals

- no OpenClaw gateway/runtime adoption
- no NanoClaw-first planner continuation
- no direct planner-level channel delivery
- no skill marketplace publication in this wave
- no containerization-first sandbox implementation in the first safety wave

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

## Decision Note

If progress is slow, preserve this order anyway. The whole point of this issue pack is to prefer long-term coherence over short-term shortcutting:
- no default-first rollout
- no marketplace-first rollout
- no doc-first rewrite
- no safety-last sequencing
