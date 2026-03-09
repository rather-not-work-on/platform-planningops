---
title: plan: Agent Autonomous Scope Split
type: plan
date: 2026-03-09
updated: 2026-03-09
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Defines what the autonomous PlanningOps loop may continue to do without user input and what remains gated behind explicit user decisions.
tags:
  - uap
  - autonomy
  - scope
  - guardrails
---

# Agent Autonomous Scope Split

## Agent-Owned Work

The autonomous loop may continue without asking the user when the work is reversible and contract-driven.

Allowed:
- backlog generation from validated execution contracts
- issue/project field synchronization
- repo-local scaffolding and build hygiene
- contract and validator creation
- CI trigger hardening
- README and topology updates
- replayable review artifact generation
- PR creation, validation, and merge when checks pass

## User-Gated Work

The autonomous loop must stop for explicit user input when the work changes product behavior or commits to hard-to-reverse operating assumptions.

Stop for:
- first UX/product success definition
- provider precedence policy
- local infra topology choice with long-lived consequences
- secrets loading model
- irreversible storage/vendor commitments
- naming changes that affect public external identity

## Practical Rule

If a task can be justified by:
- existing contracts
- existing topology
- existing validation gates
- and a reversible technical change

then the agent may proceed.

If a task requires:
- choosing a product default
- choosing a human-facing policy
- or committing to a durable external dependency model

then the agent must pause.
