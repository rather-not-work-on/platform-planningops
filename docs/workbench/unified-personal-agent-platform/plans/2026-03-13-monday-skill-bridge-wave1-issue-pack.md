---
title: plan: Monday Skill Bridge Wave 1 Issue Pack
type: plan
date: 2026-03-13
updated: 2026-03-14
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Projects the first monday-owned skill bridge wave so external Slack/email skills call deterministic repo-owned CLI surfaces and emit contract-grade delivery evidence.
tags:
  - uap
  - autonomy
  - monday
  - skills
  - operator-channel
  - backlog
---

# Monday Skill Bridge Wave 1 Issue Pack

## Preconditions

This issue pack is valid because:
- `planningops/contracts/operator-channel-adapter-contract.md` freezes the boundary that monday owns skill/transport adapters while planningops owns policy and evidence requirements.
- `docs/workbench/unified-personal-agent-platform/plans/2026-03-13-monday-channel-adapter-wave1-issue-pack.md` delivered deterministic CLI entrypoints (`send_operator_message.py`, `send_goal_completion_notification.py`) and runbooks.
- `planningops/config/active-goal-registry.json` keeps `slack_skill_cli` and `email_cli` as canonical channel kinds for active goals.

## Goal

Bridge external operator skills to monday-owned delivery surfaces with no prompt-authored transport logic:
- `Skill wrapper -> monday CLI/MCP boundary -> typed adapter -> delivery evidence artifact`

Wave 1 rule:
- skill prompts must not construct vendor HTTP requests directly
- skill wrappers may normalize user intent, but payload schema and idempotency stay monday-owned
- both operator updates and terminal goal-completion notifications must stay contract-compatible

## Wave 1 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AG10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_operator_message.py` |
| `AG20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_goal_completion_notification.py` |
| `AG30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `docs/runbook/operator-channel-adapter.md` |
| `AG40` | 40 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `docs/runbook/goal-completion-notifier.md` |
| `AG50` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/monday-skill-bridge-wave1-review.json` |

## Decomposition Rules

- `AG10` hardens the operator-channel CLI contract for skill invocation by enforcing file-or-inline payload modes, deterministic validation errors, and delivery evidence shape stability.
- `AG20` hardens goal-completion notification invocation with explicit idempotency constraints keyed by `goal_key` and `achieved_at_utc`.
- `AG30` documents the Slack skill bridge integration path, including required payload contract fields, dry-run expectations, and failure escalation behavior.
- `AG40` documents the terminal notification skill bridge integration path and completion-policy coupling, including when notification should be skipped.
- `AG50` verifies planningops remains a control tower: it references monday contracts and evidence only, without embedding channel vendor logic.

## Dependencies

- `AG20` depends on `AG10`
- `AG30` depends on `AG10`
- `AG40` depends on `AG20`
- `AG50` depends on `AG10`, `AG20`, `AG30`, `AG40`

## Explicit Non-Goals

- no Slack or email credential material in `platform-planningops`
- no skill prompt templates committed as transport authority
- no provider-specific SDK coupling inside planningops scripts
- no direct notification send from planningops without monday adapter evidence
