---
title: plan: Monday Channel Adapter Wave 1 Issue Pack
type: plan
date: 2026-03-13
updated: 2026-03-13
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Projects the first monday-owned operator channel implementation wave so Slack communication flows through a skill over a repo-owned CLI or MCP adapter instead of prompt-authored HTTP calls.
tags:
  - uap
  - implementation
  - monday
  - slack
  - messaging
  - backlog
---

# Monday Channel Adapter Wave 1 Issue Pack

## Preconditions

This issue pack is valid because:
- `planningops/contracts/operator-channel-adapter-contract.md` freezes the boundary between control-plane policy and monday-owned delivery adapters
- `planningops/config/active-goal-registry.json` records `slack_skill_cli` as the primary operator channel kind
- `monday/packages/messaging-adapter` currently provides only acknowledgement behavior, so structured operator communication is still missing

## Goal

Give `monday` one deterministic operator-message path:
- `Slack skill -> repo-owned CLI or MCP adapter -> Slack API`

The rule for this wave is strict:
- `planningops` owns goal state and delivery evidence expectations only
- `monday` owns payload typing, adapter composition, CLI/MCP surface, and runbook
- the first implementation baseline must be CLI-callable even if MCP support is added in parallel
- no raw Slack HTTP call may be embedded in `planningops` prompts or scripts

## Wave 1 Items

| ID | Order | Target | Component | Initial State | Output |
| --- | --- | --- | --- | --- | --- |
| `AG10` | 10 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/contract-bindings/src/operator_channels.ts` |
| `AG20` | 20 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `packages/messaging-adapter/src/operator_channel_adapter.ts` |
| `AG30` | 30 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `scripts/send_operator_message.py` |
| `AG40` | 40 | `rather-not-work-on/monday` | `runtime` | `ready_implementation` | `docs/runbook/operator-channel-adapter.md` |
| `AG50` | 50 | `rather-not-work-on/platform-planningops` | `planningops` | `review_gate` | `planningops/artifacts/validation/monday-channel-adapter-wave1-review.json` |

## Decomposition Rules

- `AG10` introduces a typed operator-message payload and delivery-evidence surface in monday contract bindings without changing provider or telemetry contracts.
- `AG20` adds a repo-owned messaging adapter that can invoke either a CLI transport or MCP transport while keeping the public payload deterministic.
- `AG30` exposes a CLI entrypoint that accepts a message payload file or inline JSON and supports `dry-run` and `apply`.
- `AG40` documents how the external Slack skill must call the monday-owned CLI/MCP surface instead of re-implementing transport logic itself.
- `AG50` verifies that the first operator channel path stays monday-owned and that planningops still only points to the contract, not the vendor transport.

## Dependencies

- `AG20` depends on `AG10`
- `AG30` depends on `AG20`
- `AG40` depends on `AG20`
- `AG50` depends on `AG10`, `AG20`, `AG30`, `AG40`

## Explicit Non-Goals

- no Slack credentials stored in `platform-planningops`
- no direct Slack app provisioning yet
- no terminal email completion yet
- no human-facing skill body committed into the monday repo
