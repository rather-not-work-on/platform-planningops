---
title: plan: Runtime-Profiles Validator Family Backfill Packet
type: plan
date: 2026-03-26
updated: 2026-03-26
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Backfills the runtime-profiles schema, validator, regression, and catalog update so planningops can validate runtime profile semantics from remote main.
related_docs:
  - ./2026-03-26-control-plane-governance-helper-family-backfill-packet.md
  - ./2026-03-26-provider-profile-helper-family-backfill-packet.md
---

# plan: Runtime-Profiles Validator Family Backfill Packet

## Summary
- Backfill the tracked `runtime-profiles` validator family that `planningops/scripts/README.md` already documents.
- Promote the missing schema, validator, regression, and runtime profile catalog changes into git-tracked reality so runtime profile semantics are reproducible from remote `main`.
- Validate the catalog against a strict schema and semantic rule set, including planner policy, provider policy, and worker policy surfaces.

## Scope
- `planningops/config/runtime-profiles.json`
- `planningops/schemas/runtime-profiles.schema.json`
- `planningops/scripts/validate_runtime_profiles.py`
- `planningops/scripts/test_validate_runtime_profiles_contract.sh`
- workbench hub link for this validator-family backfill

## Acceptance
- `test_validate_runtime_profiles_contract.sh` passes
- `validate_runtime_profiles.py --runtime-profile-file planningops/config/runtime-profiles.json --schema-file planningops/schemas/runtime-profiles.schema.json --output planningops/artifacts/validation/runtime-profiles-report.json --strict` succeeds from the repo root
