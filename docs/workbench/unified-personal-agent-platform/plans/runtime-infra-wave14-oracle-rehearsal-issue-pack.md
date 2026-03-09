---
title: plan: Runtime Infra Wave 14 Oracle Rehearsal Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines the follow-up issue pack that reuses the wave13 federated smoke runner to validate local-to-OCI profile portability without promoting Oracle execution to the default path.
tags:
  - uap
  - implementation
  - runtime
  - oracle
  - rehearsal
  - backlog
---

# Runtime Infra Wave 14 Oracle Rehearsal Issue Pack

## Preconditions

This issue pack is valid because:
- wave13 is the immediate predecessor and must produce a planningops-owned federated local smoke runner
- `planningops/scripts/federation/run_local_oracle_rehearsal.py` already exists as a rehearsal boundary candidate
- the next missing evidence after federated local smoke is profile portability from local to OCI-shaped targets

## Goal

Reuse the planningops-owned federated smoke path to classify whether runtime profiles remain portable when rehearsed against the oracle_cloud profile.

The rule for this wave is strict:
- local remains the default execution profile
- Oracle remains rehearsal-only until explicit user approval
- planningops owns portability evidence, not runtime service code

## Wave 14 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AF10` | 10 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/scripts/federation/run_wave14_oracle_rehearsal.py` |
| `AF20` | 20 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/runtime-infra-wave14-review.json` |

## Decomposition Rules

- `AF10` wraps the existing local/oracle rehearsal boundary into a wave-owned entrypoint that consumes the wave13 federated smoke runner outputs and classifies portability gaps.
- `AF20` validates that rehearsal stays non-destructive, local remains default, and OCI profile drift is surfaced as evidence instead of silently changing runtime defaults.

## Dependencies

- `AF20` depends on `AF10`

## Explicit Non-Goals

- no Oracle production cutover
- no default profile switch away from local
- no secrets bootstrap or infrastructure provisioning

