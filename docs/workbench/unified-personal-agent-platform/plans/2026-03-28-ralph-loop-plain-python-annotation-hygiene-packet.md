---
title: plan: Ralph Loop Plain-Python Annotation Hygiene Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Aligns `ralph_loop_local.py` with the plain-python annotation contract so the local Ralph Loop entrypoint matches the rest of the tracked cross-repo manifest surface.
related_docs:
  - ./2026-03-28-loop-runner-snapshot-intake-normalization-packet.md
---

# plan: Ralph Loop Plain-Python Annotation Hygiene Packet

## Summary
- Add the plain-python annotation header to `ralph_loop_local.py`.
- Keep the unit narrowly scoped to entrypoint hygiene: no runtime behavior changes.
- Preserve workbench traceability for the compatibility hardening.

## Scope
- `planningops/scripts/ralph_loop_local.py`
- workbench hub link for this packet

## Acceptance
- `test_ralph_loop_local_worker_policy.sh` passes
- `test_cross_repo_plain_python_annotation_contract.sh` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
