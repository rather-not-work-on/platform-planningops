---
title: plan: Project Field And Blueprint Latest Refresh Packet
type: plan
date: 2026-03-28
updated: 2026-03-28
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Refreshes the canonical latest project-field schema and ready-implementation blueprint normalization reports after the corresponding sample lanes were promoted.
related_docs:
  - ./2026-03-28-project-field-schema-sample-artifact-lane-packet.md
  - ./2026-03-28-ready-implementation-blueprint-normalize-sample-artifact-lane-packet.md
---

# plan: Project Field And Blueprint Latest Refresh Packet

## Summary
- Re-run the live project-field schema validator and publish an updated latest report.
- Re-run the live ready-implementation blueprint normalizer in dry-run mode and publish an updated latest report.
- Keep these mutable latest artifacts separate from the committed fixture-backed `.sample.json` lanes.

## Scope
- `planningops/artifacts/validation/project-field-schema-report.json`
- `planningops/artifacts/validation/ready-implementation-blueprint-normalize-report.json`

## Acceptance
- `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch --output planningops/artifacts/validation/project-field-schema-report.json` passes
- `python3 planningops/scripts/normalize_ready_implementation_blueprint_refs.py --fail-on-missing --output planningops/artifacts/validation/ready-implementation-blueprint-normalize-report.json` passes
- `uap-docs.sh check --profile workbench` passes
- `uap-docs.sh check --profile all` passes
