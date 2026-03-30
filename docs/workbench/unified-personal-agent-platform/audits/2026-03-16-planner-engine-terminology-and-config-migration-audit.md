---
title: audit: Planner Engine Terminology and Config Migration Scope
type: audit
date: 2026-03-16
initiative: unified-personal-agent-platform
lifecycle: workbench
status: reference
summary: Freezes which NanoClaw references must migrate, which remain as historical context, and how `nanoclaw_endpoint` moves to a vendor-neutral planner policy plus repo-local monday config.
---

# audit: Planner Engine Terminology and Config Migration Scope

## Objective

Define the exact `U10` migration boundary for moving from NanoClaw-first planner terminology to a vendor-neutral planner-engine model with DeepAgents as the first implementation candidate.

This audit exists to prevent three failure modes:
- deleting historically meaningful discovery records
- leaving current-default architecture/config files on outdated terminology
- moving repo-local monday runtime paths into `planningops` config

## Closure Update (2026-03-19)

- canonical monday architecture and execution-plan docs now use vendor-neutral planner-engine language
- `planningops/config/runtime-profiles.json` has retired `nanoclaw_endpoint`
- `monday/packages/orchestrator/src/default_local_runtime.ts` no longer deserializes `nanoclaw_endpoint`
- this audit is now reference material for the completed migration boundary

## Scope

### Included
- canonical architecture and execution-plan docs that currently encode present-tense planner defaults
- workbench plans/issue packs that define the new rollout
- `planningops/config/runtime-profiles.json`
- `monday` runtime config readers that currently deserialize `nanoclaw_endpoint`

### Excluded
- historical runtime artifacts under `planningops/runtime-artifacts/**`
- historical migration evidence under `planningops/artifacts/**`
- frozen discovery documents unless annotated as superseded context

## Migration Principles

1. current-state architecture and execution plans must become vendor-neutral.
2. historical discovery documents may keep NanoClaw references as historical decisions if they are clearly treated as context, not active defaults.
3. `planningops` may carry planner hints only; concrete repo-local planner paths belong in `monday`.
4. config migration must use additive dual-read before field retirement.
5. runtime evidence history is immutable; do not rewrite past artifacts to match the new terminology.

## Inventory Matrix

| Path | Class | Current Role | Action | Migration Rule |
| --- | --- | --- | --- | --- |
| `docs/initiatives/unified-personal-agent-platform/20-repos/monday/20-architecture/2026-02-27-uap-contract-first-requirements.architecture.md` | canonical architecture | active default terminology | update | rename bounded context C to vendor-neutral `planner engine`; mention DeepAgents as current implementation target |
| `docs/initiatives/unified-personal-agent-platform/20-repos/monday/30-execution-plan/2026-02-27-uap-contract-first-foundation.execution-plan.md` | canonical execution plan | active default composition | update | remove NanoClaw-first wording from default composition; preserve anti-bloat principle without vendor lock |
| `planningops/config/runtime-profiles.json` | control-plane config | active runtime profile hints | update | replace `nanoclaw_endpoint` with additive `planner_policy` migration path; keep repo-local details out |
| `/Volumes/T7 Touch/mini/rather-not-work-on/monday/packages/orchestrator/src/default_local_runtime.ts` | runtime reader | active config consumer | update | dual-read old/new fields during compatibility window, then retire `nanoclawEndpoint` |
| `docs/workbench/unified-personal-agent-platform/plans/2026-03-16-plan-deepagents-core-skillctl-and-sandbox-rollout-plan.md` | workbench active plan | new selected strategy | keep active | use as implementation baseline |
| `docs/workbench/unified-personal-agent-platform/plans/2026-03-16-deepagents-skillctl-sandbox-issue-pack.md` | workbench active issue pack | selected rollout order | keep active | use as execution baseline |
| `docs/workbench/unified-personal-agent-platform/audits/nanoclaw-fit-assessment.md` | workbench audit | historical fit evidence | keep with note | retain as historical input; do not treat as current default decision |
| `docs/initiatives/unified-personal-agent-platform/20-repos/monday/10-discovery/2026-02-27-uap-core.brainstorm.md` | canonical discovery | historical decision context | retain | preserve as historical context; add supersession note only if later needed |
| `docs/initiatives/unified-personal-agent-platform/20-repos/monday/10-discovery/2026-02-27-uap-approach-options.strategy.md` | canonical discovery | historical option analysis | retain | preserve NanoClaw references as historical comparison inputs |
| `planningops/runtime-artifacts/**` | generated evidence | immutable past runs | ignore | never rewrite historical evidence |

## Terminology Lock

### New Default Language
- bounded context C: `Planning & Delegation (planner engine)`
- implementation target: `DeepAgents` (first candidate, not eternal contract term)
- control-plane config: `planner_policy`
- monday repo-local config: `planner-runtime.json`

### Historical Language That May Remain
- `nanoclaw core`
- `nanoclaw + orchestrator + ralph-loop + codex2message`
- approach-option language in discovery docs

Historical language may remain only in:
- discovery docs
- historical audits
- immutable runtime evidence

Historical language must not remain as the present-tense default in:
- canonical architecture docs
- canonical execution plans
- active runtime config keys once migration completes

## Config Migration Contract

### `planningops` Target Shape

```json
{
  "planner_policy": {
    "engine_hint": "deepagents",
    "execution_mode": "embedded",
    "capability_profile": "repo_local_skills"
  }
}
```

### `monday` Repo-Local Target Shape

```json
{
  "engine": "deepagents",
  "skills_root": ".deepagents/skills",
  "sandbox_policy_ref": "config/apply-sandbox-policy.json",
  "mcp_config": null
}
```

### Dual-Read Compatibility Rule
1. `planningops` adds `planner_policy` first.
2. `monday` adds repo-local planner config second.
3. `monday` readers support both old and new fields during the compatibility window.
4. `nanoclaw_endpoint` is retired only after all readers are moved.

## Hold Rules

- do not add `.deepagents/skills`, `.mcp.json`, or sandbox policy paths to `planningops/config/runtime-profiles.json`
- do not rewrite discovery docs into present-tense DeepAgents defaults
- do not remove `nanoclaw_endpoint` from config until monday readers support the new planner config
- do not treat the NanoClaw fit audit as the current default architecture source after canonical migration begins

## Recommended Execution Order

1. freeze this audit as the `U10` migration boundary
2. update monday runtime reader to dual-read
3. add `planner_policy` and `monday/config/planner-runtime.json`
4. update canonical architecture/execution-plan defaults
5. retire `nanoclaw_endpoint`

## Validation Queries

```bash
rg -n "nanoclaw core|nanoclaw_endpoint" \
  docs/initiatives \
  docs/workbench \
  planningops/config \
  /Volumes/T7\ Touch/mini/rather-not-work-on/monday
```

Expected outcome after full migration:
- only historical discovery/audit context remains for NanoClaw wording
- no active default architecture/config file keeps NanoClaw-first language

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-16T10:45:00+09:00
