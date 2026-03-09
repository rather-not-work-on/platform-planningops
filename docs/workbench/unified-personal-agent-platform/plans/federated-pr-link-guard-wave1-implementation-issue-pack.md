---
title: plan: Federated PR Link Guard Wave 1 Implementation Issue Pack
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Rolls out repo-local PR templates and review gates so execution repo PRs must link planningops issues with repo-qualified references.
tags:
  - uap
  - guardrails
  - github
  - pull-request
  - backlog
---

# Federated PR Link Guard Wave 1 Implementation Issue Pack

## Preconditions

This issue pack is valid because:
- wave7 and wave8 both required manual closing of planningops issues after external repo PR merges
- the repeated failure mode was not code behavior but PR metadata behavior
- planningops already enforces PR template structure locally, but sibling execution repos do not

## Goal

Push PR issue-link guardrails into the execution repos so cross-repo work references planningops issues correctly before merge.

The rule for this wave is strict:
- keep the rule lightweight and repo-local
- enforce repo-qualified planningops issue refs in external repo PR bodies
- do not invent a planningops-only workaround when repo-local hygiene can prevent the error

## Wave Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `G10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `.github/workflows/pr-review-gate.yml` |
| `G20` | 20 | `rather-not-work-on/platform-provider-gateway` | `provider_gateway` | `ready_implementation` | `.github/workflows/pr-review-gate.yml` |
| `G30` | 30 | `rather-not-work-on/platform-observability-gateway` | `observability_gateway` | `ready_implementation` | `.github/workflows/pr-review-gate.yml` |
| `G40` | 40 | `rather-not-work-on/platform-contracts` | `contracts` | `ready_implementation` | `.github/workflows/pr-review-gate.yml` |
| `G50` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `backlog` | `planningops/artifacts/validation/federated-pr-link-guard-wave1-review.json` |

## Decomposition Rules

- `G10` adds a monday PR template and review gate that require repo-qualified planningops issue refs.
- `G20` adds the same guard to provider gateway.
- `G30` adds the same guard to observability gateway.
- `G40` adds the same guard to contracts.
- `G50` validates that all four repos now expose repo-local PR hygiene consistent with planningops control-plane policy.

## Dependencies

- `G50` depends on `G10`, `G20`, `G30`, `G40`

## Explicit Non-Goals

- no branch protection changes in this wave
- no change to runtime code behavior
- no GitHub App or webhook automation yet
