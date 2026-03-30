---
title: plan: MONDAY Agent Memory Wave G Reflection Packet
type: plan
date: 2026-03-25
updated: 2026-03-25
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Pins the next monday memory slice after queue completion: exporting completed memory worker outcomes from scheduler evidence into planningops reflection packets and evaluation decisions.
related_docs:
  - ./2026-03-25-monday-agent-memory-wave-f-completion-packet.md
  - ./2026-03-25-monday-agent-memory-wave-e-scheduler-execution-packet.md
---

# plan: MONDAY Agent Memory Wave G Reflection Packet

## Purpose

Turn completed monday memory scheduler evidence into a planningops-ready worker outcome reflection packet without reopening queue store internals by hand.

## Scope

Wave G should add:

- a monday-local helper that resolves `worker_outcome_ref` from scheduler evidence into a reflection packet
- deterministic regression coverage using the real memory queue path
- a planningops evaluation smoke that proves the exported packet yields a valid control-plane decision

Wave G should not yet add:

- automatic planningops apply-side reflection actions for memory jobs
- operator notification routing for memory outcomes
- dead-letter/retry memory policies

## Repo Targets

- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/export_scheduler_worker_outcome_reflection_packet.py`
- `/Volumes/T7 Touch/mini/rather-not-work-on/monday/scripts/test_export_scheduler_worker_outcome_reflection_packet.sh`

## Acceptance Gates

- helper accepts a scheduler report and fails closed when `worker_outcome_ref` is absent
- helper emits the same packet shape as the generic worker-outcome reflection exporter
- the packet preserves the scheduler-owned `worker_outcome_ref` as `source_outcome_ref`
- planningops reflection evaluation passes against a matching active-goal registry fixture

## Codex Prompt

```text
Continue the monday memory-aware agent harness.

Current state:
- successful memory scheduler runs now emit completed worker-outcome evidence
- planningops already has a generic worker-outcome reflection evaluator

Implement Wave G only:
1. add a monday-local helper that exports a reflection packet from scheduler evidence
2. keep it generic for any scheduler report with worker_outcome_ref, but prove it on the memory queue path
3. add a deterministic regression that runs memory queue execution, exports the packet, and evaluates it in planningops
4. do not yet apply reflection decisions automatically
```
