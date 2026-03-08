---
title: plan: Runtime Skeleton Wave 3 Build Baseline Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the next executable issue pack that turns wave 2 runtime skeletons into locally installable and typecheckable workspaces without assuming a globally installed pnpm.
tags:
  - uap
  - implementation
  - runtime-skeleton
  - build
  - backlog
---

# Runtime Skeleton Wave 3 Build Baseline Issue Pack

## Preconditions

This issue pack is valid because:
- wave 2 runtime scaffolds are merged in `monday`, `platform-provider-gateway`, and `platform-observability-gateway`
- wave 2 scaffold review recorded `verdict=pass`
- the next blocked gate is workspace bootstrap, not package topology

## Goal

Freeze and execute the minimum work required so the new TypeScript workspaces can be installed and typechecked locally in a deterministic way.

The rule for this wave is strict:
- do not assume `pnpm` is globally installed
- prefer local-first bootstrap via `npm exec pnpm@<pinned-version>`
- keep Python harnesses as harnesses; do not rewrite them into runtime code
- commit reproducible lockfiles only after the local bootstrap path is fixed

## Wave 3 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `B10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `ready_implementation` | `planningops/contracts/node-workspace-bootstrap-contract.md` |
| `B11` | 20 | `rather-not-work-on/monday` | `runtime` | `backlog` | `pnpm-lock.yaml` |
| `B20` | 30 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `backlog` | `pnpm-lock.yaml` |
| `B30` | 40 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `backlog` | `pnpm-lock.yaml` |
| `B40` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-skeleton-wave3-build-review.json` |

## Decomposition Rules

- `B10` defines the canonical local-first Node workspace bootstrap contract:
  - pinned `pnpm` invocation path
  - lockfile policy
  - required root scripts
  - allowed CI invocation pattern
- `B11` makes `monday` installable and typecheckable with the pinned local bootstrap path.
- `B20` makes `platform-provider-gateway` installable and typecheckable with the pinned local bootstrap path.
- `B30` makes `platform-observability-gateway` installable and typecheckable with the pinned local bootstrap path.
- `B40` verifies that all three repos satisfy the build baseline and records any new contract gaps or structural blockers.

## Dependencies

- `B11` depends on `B10`
- `B20` depends on `B10`
- `B30` depends on `B10`
- `B40` depends on `B11`, `B20`, `B30`

## Explicit Non-Goals

- no real provider or observability SDK integration yet
- no monday execution logic expansion beyond what is required to compile
- no shared-contract expansion unless `B40` produces explicit gap evidence
