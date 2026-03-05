# ADR-0004: Control Plane Thin-Core Boundary

## Status
Accepted

## Context
PlanningOps accumulated mixed responsibilities in `planningops/scripts` and started to resemble a god-repository.
That increases coupling and weakens long-term multi-repo scalability.

## Decision
- Declare planningops as control-plane only.
- Isolate cross-repo execution entrypoints under `planningops/scripts/federation/`.
- Keep root-path compatibility wrappers to avoid breaking existing commands/contracts.
- Add machine-checkable boundary validation in CI.

## Consequences
### Positive
- Clearer ownership boundary between planning/control and execution/runtime repositories.
- Lower risk of accidental domain-runtime logic accumulation in planningops.
- Refactor path becomes incremental and non-breaking.

### Negative
- Transitional duplication (wrapper + canonical entrypoint) until all call-sites migrate.
- One additional guardrail test in CI.

## Follow-up
1. Migrate remaining cross-repo command references to canonical federation paths.
2. Keep wrappers only as compatibility layer; remove after deprecation window.
3. Extend boundary map when new execution repositories are added.
