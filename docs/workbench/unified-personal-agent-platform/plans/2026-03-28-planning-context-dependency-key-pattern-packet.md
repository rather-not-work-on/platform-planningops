---
title: plan: Planning Context Dependency Key Pattern Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Hardens planning context dependency parsing so wider plan-item key prefixes are preserved while related governance contracts expose their canonical helper lanes.
related_docs:
  - ./2026-03-26-control-plane-governance-helper-family-backfill-packet.md
---

# plan: Planning Context Dependency Key Pattern Packet

## Summary
- Expand `planning_context` dependency-key parsing to accept wider uppercase key prefixes.
- Backfill the contract regression that proves mixed dependency strings preserve the broader key surface.
- Record the corresponding governance helper lanes on the affected contracts.

## Scope
- `planningops/scripts/planning_context.py`
- `planningops/scripts/test_planning_context_contract.sh`
- `planningops/contracts/control-tower-ontology-contract.md`
- `planningops/contracts/issue-quality-contract.md`
- workbench hub link for this parsing hardening packet

## Acceptance
- `test_planning_context_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
