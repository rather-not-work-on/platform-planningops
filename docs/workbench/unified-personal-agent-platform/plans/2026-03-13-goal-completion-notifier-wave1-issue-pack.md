---
title: plan: Goal Completion Notifier Wave 1 Issue Pack
type: plan
date: 2026-03-13
updated: 2026-03-13
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Projects the monday-owned terminal completion notification baseline so achieved goals can emit one idempotent email without putting provider details into PlanningOps.
tags:
  - uap
  - implementation
  - monday
  - email
  - completion
  - backlog
---

# Goal Completion Notifier Wave 1 Issue Pack

## Preconditions

This issue pack is valid because:
- `planningops/contracts/goal-completion-contract.md` now defines achieved-state and terminal notification policy
- `planningops/config/active-goal-registry.json` records `email_cli` as the default terminal notification channel
- the first operator channel pack isolates Slack transport, so completion email can reuse the same monday-owned delivery boundary without coupling it to planningops

## Goal

Give `monday` one deterministic terminal notification path that only fires on goal transition to `achieved`.

The rule for this wave is strict:
- completion policy stays in `planningops`
- terminal delivery logic stays in `monday`
- terminal notifications must be idempotent by `goal_key` + `achieved_at_utc`
- the baseline implementation must be CLI-callable and dry-run capable before any provider-specific MCP layering

## Wave 1 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AH10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/messaging-adapter/src/goal_completion_notifier.ts` |
| `AH20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_goal_completion_notification.py` |
| `AH30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `docs/runbook/goal-completion-notifier.md` |
| `AH40` | 40 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/goal-completion-notifier-wave1-review.json` |

## Decomposition Rules

- `AH10` adds a monday-owned notifier module that turns a typed achieved-goal payload into deterministic delivery evidence without owning goal-state transitions.
- `AH20` exposes a CLI entrypoint that accepts a completion payload file or inline JSON and supports `dry-run` and `apply`.
- `AH30` documents the handoff between active-goal completion evaluation and terminal notification delivery so later Slack/Email skills stay thin.
- `AH40` verifies that achieved-goal evaluation still happens in planningops while email delivery remains monday-owned.

## Dependencies

- `AH20` depends on `AH10`
- `AH30` depends on `AH10`
- `AH40` depends on `AH10`, `AH20`, `AH30`

## Explicit Non-Goals

- no mail provider credentials in `platform-planningops`
- no automatic email resend scheduler yet
- no direct SMTP or vendor API calls embedded in planningops scripts
- no Slack completion summary duplication in this wave
