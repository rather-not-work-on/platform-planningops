---
title: plan: Artifact Sink Helper Link Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Captures the artifact sink contract hardening that links the external artifact residency helper as a canonical workflow surface.
related_docs:
  - ./2026-03-26-external-artifact-residency-helper-family-backfill-packet.md
---

# plan: Artifact Sink Helper Link Packet

## Summary
- Backfill the tiny artifact sink contract/doc hardening unit.
- Record the external artifact residency helper as a canonical workflow surface on the artifact sink contract.
- Keep scope limited to the contract note, Python compatibility import, and workbench references.

## Scope
- `planningops/contracts/artifact-sink-contract.md`
- `planningops/scripts/artifact_sink.py`
- workbench hub link for this helper-link packet

## Acceptance
- `test_artifact_sink_e2e.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
