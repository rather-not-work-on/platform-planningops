---
title: audit: Track 1 Gate Evidence Manifest
type: audit
date: 2026-03-02
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Manifest template for Track 1 Exit Gate evidence bundle and verdict traceability.
---

# audit: Track 1 Gate Evidence Manifest

## Required Bundle
- [ ] `planningops/artifacts/validation/track1-validation-chain-report.json`
- [ ] `planningops/artifacts/validation/track1-kpi-baseline.json`
- [ ] `planningops/artifacts/validation/project-field-schema-report.json`
- [ ] `planningops/artifacts/validation/transition-log.ndjson`
- [ ] `planningops/artifacts/validation/track1-gate-dryrun-report.json`

## Gate Axes
### Docs and Contract Integrity
- command: `bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all`
- result:

### Project Schema Integrity
- command: `python3 planningops/scripts/validate_project_field_schema.py --fail-on-mismatch`
- result:

### KPI Evidence
- loop_success_rate:
- replan_without_evidence:
- schema_drift_recovery_time_p95:

## Final Verdict
- verdict: pending
- decided_by:
- decided_at_utc:
- notes:
