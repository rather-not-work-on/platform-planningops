---
title: plan: Project Field Schema Artifact Refresh Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the committed project-field-schema validation artifact so canonical validation evidence matches the current schema contract.
related_docs:
  - ./2026-03-28-track1-gate-artifact-refresh-packet.md
---

# plan: Project Field Schema Artifact Refresh Packet

## Summary
- Re-run the project field schema validator against the current PlanningOps project schema.
- Refresh the committed schema validation report without changing validator behavior.
- Keep the unit artifact-only: no helper, workflow, or contract logic changes.

## Scope
- `planningops/artifacts/validation/project-field-schema-report.json`
- workbench hub link for this packet

## Acceptance
- `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
