# MONDAY Agent Harness Projection Contract

## Purpose
Freeze the first `planningops` control-plane boundary over monday-owned agent-harness projection surfaces.

This contract exists so:
- `monday` keeps ownership of runtime-private phase, replay, worker, and repair state
- `planningops` validates only the monday-published projection layer
- readiness promotion stays projection-only and fail-closed

## Scope
- monday projection producer surface:
  - `runtime-artifacts/agent-harness/completion-summary.json`
  - `runtime-artifacts/agent-harness/readiness-projection.json`
  - `runtime-artifacts/agent-harness/verification-projection.json`
  - `runtime-artifacts/agent-harness/operator-handoff-summary.json`
- planningops schema:
  - `planningops/schemas/monday-agent-harness-projection-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
  - `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- planningops resolver:
  - `planningops/scripts/resolve_monday_agent_harness_projection.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
  - `planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
- planningops validator:
  - `planningops/scripts/validate_monday_agent_harness_projection.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
  - `planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
- planningops doctor:
  - `planningops/scripts/doctor_monday_agent_harness_projection.py`
  - `planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py`
  - `planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py`
  - `planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
  - `planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
- planningops gate:
  - `planningops/scripts/gate_monday_agent_harness_projection.sh`
  - `planningops/scripts/gate_monday_agent_harness_projection_status_bundle.sh`
  - `planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle.sh`
  - `planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh`
  - `planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh`
  - `planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`
  - `planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`

## Boundary Rule

PlanningOps may consume only the four monday projection files above.

PlanningOps must not directly consume:
- `runtime-artifacts/agent-harness/session-state.json`
- `runtime-artifacts/agent-harness/worker-snapshot.json`
- `runtime-artifacts/agent-harness/replay-log.jsonl`
- `runtime-artifacts/agent-harness/verification-verdict.json`
- `runtime-artifacts/agent-harness/repair-loop-state.json`

Filesystem sidecars such as `runtime-artifacts/agent-harness/._*` may exist on external drives. They are non-canonical and must be ignored; projection consumers resolve only the explicit four projection filenames above.

## Canonical Validation Output
- after monday publishes a canonical local projection root, `planningops/scripts/materialize_monday_agent_harness_projection_surfaces.sh` is the canonical refresh step for rewriting the full latest projection cascade before doctor/gate surfaces are consumed
- `planningops/scripts/sync_monday_agent_harness_projection_latest.sh` is the canonical local/workflow sync step when the monday projection root should inherit the latest federated summary run lineage before rematerialization
- `planningops/scripts/run_monday_agent_harness_projection_ci_suite.sh` is the canonical suite helper for the full monday projection regression chain plus final sync/rematerialization
  - `--print-tests` emits the canonical ordered regression inventory for contract and wiring consumers
  - `--help` documents the supported suite options and public inventory surface
- `planningops/scripts/run_monday_agent_harness_projection_ci_check.sh` is the canonical local/workflow entrypoint
  - `--print-steps` emits the canonical ordered wrapper step inventory for contract and wiring consumers
  - `--print-local-invocation` and `--print-workflow-invocation` emit the canonical local/workflow wrapper call shapes for contract and wiring consumers
  - `--help` documents the supported wrapper options and suite passthrough boundary
  - it runs its own wrapper-contract regression, helper-wiring regression, suite-helper contract, then the suite helper
  - local matrix and GitHub workflow must invoke this wrapper only rather than inlining monday projection regressions or calling wrapper internals directly
- `planningops/scripts/test_run_monday_agent_harness_projection_ci_check_contract.sh` is the canonical regression that proves the ci-check wrapper still owns its contract, helper-wiring regression, suite-helper contract, and suite-helper handoff in that order
- `planningops/scripts/test_monday_agent_harness_projection_helper_wiring.sh` is the canonical regression that proves the wrapper owns helper-wiring checks and that local matrix and GitHub workflow still call only the wrapper surface
- latest resolved bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-bundle.json`
- latest validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-validation.json`
- latest doctor status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status.json`
- latest doctor status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-validation.json`
- latest resolved doctor status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle.json`
- latest resolved doctor status bundle validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-validation.json`
- latest resolved doctor status bundle status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status.json`
- latest resolved doctor status bundle status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-validation.json`
- latest resolved doctor status bundle status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle.json`
- latest resolved doctor status bundle status bundle validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-validation.json`
- latest resolved doctor status bundle status bundle status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status.json`
- latest resolved doctor status bundle status bundle status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-validation.json`
- latest resolved doctor status bundle status bundle status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle.json`
- latest resolved doctor status bundle status bundle status bundle validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-validation.json`
- latest resolved doctor status bundle status bundle status bundle status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.json`
- latest resolved doctor status bundle status bundle status bundle status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest resolved doctor status bundle status bundle status bundle status bundle validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status bundle status:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status bundle status validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status bundle status bundle:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest resolved doctor status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation report:
  - `planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`

## Required Cross-Projection Invariants
- all four projections must agree on `missionId`
- all four projections must agree on `runId`
- all four projections must agree on `sessionId`
- all four projections must agree on `evidenceBundlePath`
- `completion-summary.finalStatus=succeeded` requires `verificationVerdict=pass`
- `readinessStatus=ready` requires `handoffStatus=not_required`
- `readinessStatus=blocked` requires `handoffStatus=required`
- `handoffReason=missing_question_set` requires non-empty `blockingQuestionSet`

## Validation Rules
`planningops/scripts/resolve_monday_agent_harness_projection.py` must:
- resolve exactly the four monday-published projection files into one canonical bundle
- validate the emitted bundle against `planningops/schemas/monday-agent-harness-projection-bundle.schema.json`
- fail closed when any required projection file is missing or malformed

`planningops/scripts/validate_monday_agent_harness_projection.py` must:
- accept either `--projection-root` inputs or one canonical `--bundle-file`
- validate the loaded projection bundle against `planningops/schemas/monday-agent-harness-projection-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-validation.schema.json`
- fail closed when run/session/evidence lineage diverges across projections
- fail closed when ready semantics contradict handoff semantics
- fail closed when the sealed evidence path is missing or points outside the expected evidence filename
- stay projection-only and not reopen monday runtime-private artifacts

The validation report must expose at least:
- `run_id`
- `session_id`
- `evidence_bundle_path`
- `final_status`
- `readiness_status`
- `ready`
- `verification_verdict`
- `handoff_status`
- `next_required_actor`
- `next_step`
- `error_count`
- `warning_count`
- `verdict`

`planningops/scripts/validate_monday_agent_harness_projection_status.py` must:
- validate the doctor-owned status sidecar against `planningops/schemas/monday-agent-harness-projection-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-validation.schema.json`
- fail closed when the stored status payload drifts from the canonical doctor status derived from the referenced projection validation report

`planningops/scripts/resolve_monday_agent_harness_projection_status.py` must:
- accept either a status report, a status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor `status/status-validation` pair
- fail closed when the embedded bundle path, validation report path, or propagated run/session/readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle.py` must:
- validate the resolved doctor status bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status.py` output

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status.py` must:
- validate the doctor-owned resolved status-bundle status sidecar against `planningops/schemas/monday-agent-harness-projection-status-bundle-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-validation.schema.json`
- fail closed when the stored status sidecar drifts from the canonical resolved bundle, its validation report, or the propagated monday projection readiness fields

`planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status.py` must:
- accept either a status-bundle-status report, a status-bundle-status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor-owned `status-bundle-status/status-bundle-status-validation` pair
- fail closed when the embedded bundle path, validation report path, or propagated monday projection readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle.py` must:
- validate the resolved doctor-owned `status-bundle-status/status-bundle-status-validation` bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status_bundle_status.py` output

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status.py` must:
- validate the doctor-owned resolved status-bundle-status-bundle status sidecar against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-validation.schema.json`
- fail closed when the stored status sidecar drifts from the canonical resolved bundle, its validation report, or the propagated monday projection readiness fields

`planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py` must:
- accept either a status-bundle-status-bundle-status report, a status-bundle-status-bundle-status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor-owned `status-bundle-status-bundle-status/status-bundle-status-bundle-status-validation` pair
- fail closed when the embedded bundle path, validation report path, or propagated monday projection readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py` must:
- validate the resolved doctor-owned `status-bundle-status-bundle-status/status-bundle-status-bundle-status-validation` bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py` output

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py` must:
- validate the doctor-owned resolved status-bundle-status-bundle-status-bundle status sidecar against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- fail closed when the stored status sidecar drifts from the canonical resolved bundle, its validation report, or the propagated monday projection readiness fields

`planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py` must:
- accept either a status-bundle-status-bundle-status-bundle-status report, a status-bundle-status-bundle-status-bundle-status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor-owned `status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-validation` pair
- fail closed when the embedded outer bundle path, validation report path, or propagated monday projection readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- validate the resolved doctor-owned `status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-validation` bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py` output

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py` must:
- validate the doctor-owned resolved status-bundle-status-bundle-status-bundle-status-bundle status sidecar against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- fail closed when the stored status sidecar drifts from the canonical resolved bundle, its validation report, or the propagated monday projection readiness fields

`planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py` must:
- accept either a status-bundle-status-bundle-status-bundle-status-bundle-status report, a status-bundle-status-bundle-status-bundle-status-bundle-status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-validation` pair
- validate the emitted bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- fail closed when the embedded outermost bundle path, validation report path, or propagated monday projection readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- validate the resolved doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-validation` bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py` output

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` must:
- validate the doctor-owned resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle status sidecar against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- fail closed when the stored status sidecar drifts from the canonical resolved bundle, its validation report, or the propagated monday projection readiness fields

`planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` must:
- accept either a status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status report, a status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation` pair
- validate the emitted bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- fail closed when the embedded outermost bundle path, validation report path, or propagated monday projection readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- validate the resolved doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle` against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` output

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` must:
- validate the doctor-owned resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle status sidecar against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- fail closed when the stored status sidecar drifts from the canonical resolved bundle, its validation report, or the propagated monday projection readiness fields

`planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` must:
- accept either a status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status report, a status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation report, or one `--artifact-file` pointing at either surface
- emit one canonical bundle artifact for the doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation` pair
- validate the emitted bundle against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- fail closed when the embedded outermost bundle path, validation report path, or propagated monday projection readiness fields drift between the two sidecars

`planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- validate the resolved doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle` against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- validate its emitted report against `planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- fail closed when the stored bundle drifts from fresh canonical `resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` output

## Doctor and Gate Rules
`planningops/scripts/doctor_monday_agent_harness_projection.py` must:
- refresh the canonical resolved bundle and validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the validation report verdict is not `pass`
  - or the status-validation report verdict is not `pass`
  - or the projection surface is not `ready`

`planningops/scripts/gate_monday_agent_harness_projection.sh` must:
- be a thin fail-closed wrapper around the doctor `--require-pass` path

`planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py` must:
- accept either one canonical resolved bundle or one doctor-owned status / status-validation artifact and resolve the canonical bundle when needed
- refresh the canonical status-bundle validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the status-bundle validation report verdict is not `pass`
  - or the resolved status-bundle status-validation report verdict is not `pass`
  - or the resolved bundle `ready` field is not `true`
  - or the propagated monday projection validation verdict/state is not `pass/fresh`
  - or the doctor status sidecar validation verdict is not `pass`

`planningops/scripts/gate_monday_agent_harness_projection_status_bundle.sh` must:
- be a thin fail-closed wrapper around the resolved status-bundle doctor `--require-pass` path

`planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py` must:
- accept either one canonical resolved status-bundle-status-bundle artifact or one doctor-owned input sidecar and resolve the canonical bundle when needed
- refresh the canonical status-bundle-status-bundle validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the status-bundle-status-bundle validation report verdict is not `pass`
  - or the resolved bundle `ready` field is not `true`
  - or the propagated bundle status / bundle status validation verdict is not `pass`
  - or the propagated monday projection validation verdict/state is not `pass/fresh`
  - or the propagated status sidecar validation verdict is not `pass`
  - or the doctor status sidecar validation verdict is not `pass`

`planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle.sh` must:
- be a thin fail-closed wrapper around the resolved status-bundle-status-bundle doctor `--require-pass` path

`planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py` must:
- accept either one canonical resolved status-bundle-status-bundle-status-bundle artifact or one doctor-owned input sidecar and resolve the canonical bundle when needed
- refresh the canonical status-bundle-status-bundle-status-bundle validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the status-bundle-status-bundle-status-bundle validation report verdict is not `pass`
  - or the resolved bundle `ready` field is not `true`
  - or the propagated status verdict is not `pass`
  - or the propagated status-validation verdict is not `pass`
  - or the propagated bundle-status verdict is not `pass`
  - or the propagated bundle-status-validation verdict is not `pass`
  - or the propagated monday projection validation verdict/state is not `pass/fresh`
  - or the propagated status sidecar validation verdict is not `pass`
  - or the propagated bundle validation verdict is not `pass`
  - or the doctor status sidecar validation verdict is not `pass`

`planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh` must:
- be a thin fail-closed wrapper around the resolved status-bundle-status-bundle-status-bundle doctor `--require-pass` path

`planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- accept either one canonical resolved status-bundle-status-bundle-status-bundle-status-bundle artifact or one doctor-owned input sidecar and resolve the canonical bundle when needed
- refresh the canonical status-bundle-status-bundle-status-bundle-status-bundle validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the status-bundle-status-bundle-status-bundle-status-bundle validation report verdict is not `pass`
  - or the resolved bundle `ready` field is not `true`
  - or the propagated status verdict is not `pass`
  - or the propagated status-validation verdict is not `pass`
  - or the propagated bundle-status verdict is not `pass`
  - or the propagated bundle-status-validation verdict is not `pass`
  - or the propagated monday projection validation verdict/state is not `pass/fresh`
  - or the propagated status sidecar validation verdict is not `pass`
  - or the propagated bundle validation verdict is not `pass`
  - or the doctor status sidecar validation verdict is not `pass`

`planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh` must:
- be a thin fail-closed wrapper around the resolved status-bundle-status-bundle-status-bundle-status-bundle doctor `--require-pass` path

`planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- accept either one canonical resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle artifact or one doctor-owned input sidecar and resolve the canonical bundle when needed
- refresh the canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the status-bundle-status-bundle-status-bundle-status-bundle-status-bundle validation report verdict is not `pass`
  - or the resolved bundle `ready` field is not `true`
  - or the propagated status verdict is not `pass`
  - or the propagated status-validation verdict is not `pass`
  - or the propagated bundle-status verdict is not `pass`
  - or the propagated bundle-status-validation verdict is not `pass`
  - or the propagated monday projection validation verdict/state is not `pass/fresh`
  - or the propagated status sidecar validation verdict is not `pass`
  - or the propagated bundle validation verdict is not `pass`
  - or the doctor status sidecar validation verdict is not `pass`

`planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh` must:
- be a thin fail-closed wrapper around the resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle doctor `--require-pass` path

`planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` must:
- accept either one canonical resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle artifact or one doctor-owned input sidecar and resolve the canonical bundle when needed
- refresh the canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle validation report before printing operator-facing status
- write a fresh machine-readable status sidecar and status-validation sidecar by default
- print one deterministic `next step`
- return non-zero under `--require-pass` when:
  - the status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle validation report verdict is not `pass`
  - or the resolved bundle `ready` field is not `true`
  - or the propagated status verdict is not `pass`
  - or the propagated status-validation verdict is not `pass`
  - or the propagated bundle-status verdict is not `pass`
  - or the propagated bundle-status-validation verdict is not `pass`
  - or the propagated monday projection validation verdict/state is not `pass/fresh`
  - or the propagated status sidecar validation verdict is not `pass`
  - or the propagated bundle validation verdict is not `pass`
  - or the doctor status sidecar validation verdict is not `pass`

`planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh` must:
- be a thin fail-closed wrapper around the resolved status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle doctor `--require-pass` path

## Consumer Rule
Downstream `planningops` promotion or readiness gates must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection.sh`

Downstream consumers that need the doctor-owned `status/status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status.py --artifact-file <status-or-status-validation>`

Downstream consumers that need one operator-facing pass/fail verdict over the resolved doctor bundle must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection_status_bundle.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection_status_bundle.sh`

Downstream consumers that need the resolved doctor-owned `status-bundle-status/status-bundle-status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status.py --artifact-file <status-or-status-validation>`

Downstream consumers that need one operator-facing pass/fail verdict over the resolved doctor-owned status-bundle-status bundle must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle.sh`

Downstream consumers that need the doctor-owned `status-bundle-status-bundle-status/status-bundle-status-bundle-status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`

Downstream consumers that need one operator-facing pass/fail verdict over the resolved doctor-owned status-bundle-status-bundle-status-bundle must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh`

Downstream consumers that need the doctor-owned `status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`

Downstream consumers that need a validator-backed artifact over that resolved doctor-owned bundle must prefer:
- `python3 planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file <resolved-bundle> --strict`

Downstream consumers that need one operator-facing pass/fail verdict over that resolved doctor-owned bundle must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh`

Downstream consumers that need the doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`

Downstream consumers that need the doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`
- `python3 planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file <resolved-bundle> --strict`

Downstream consumers that need one operator-facing pass/fail verdict over that next outer resolved doctor-owned bundle must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`

Downstream consumers that need one operator-facing pass/fail verdict over the next outer resolved doctor-owned status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle must prefer:
- `python3 planningops/scripts/doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`
- `bash planningops/scripts/gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`

Downstream consumers that need the doctor-owned `status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status/status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation` pair as one artifact must prefer:
- `python3 planningops/scripts/resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`
- `python3 planningops/scripts/validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file <resolved-bundle> --strict`

They must not reconstruct readiness by reading monday runtime-private artifacts.

## Regression Surface
- contract doc regression:
  - `planningops/scripts/test_monday_agent_harness_projection_contract_doc.sh`
- resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection.sh`
- validator regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection.sh`
- status validator regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status.sh`
- status resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status.sh`
- status bundle validator regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_validation_contract.sh`
- status bundle status regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_contract.sh`
- status bundle status validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_validation_contract.sh`
- status bundle status resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status.sh`
- status bundle status bundle validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_validation_contract.sh`
- status bundle status bundle status regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_contract.sh`
- status bundle status bundle status validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_validation_contract.sh`
- status bundle status bundle status resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status.sh`
- status bundle status bundle status bundle validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_validation_contract.sh`
- status bundle status bundle status bundle status regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_contract.sh`
- status bundle status bundle status bundle status validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_validation_contract.sh`
- status bundle status bundle status bundle status resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status.sh`
- status bundle status bundle status bundle status bundle validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh`
- status bundle status bundle status bundle status bundle status regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh`
- status bundle status bundle status bundle status bundle status validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh`
- status bundle status bundle status bundle status bundle status resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status.sh`
- status bundle status bundle status bundle status bundle status bundle validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh`
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh`
- status bundle status bundle status bundle status bundle status bundle status regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh`
- status bundle status bundle status bundle status bundle status bundle status validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh`
- status bundle status bundle status bundle status bundle status bundle status regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh`
- status bundle status bundle status bundle status bundle status bundle status validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh`
- status bundle status bundle status bundle status bundle status bundle doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle status bundle status bundle gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle status bundle status bundle status bundle doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle status bundle status bundle status bundle gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle status bundle status bundle status resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh`
- status bundle status bundle status bundle status bundle status bundle status bundle resolver regression:
  - `planningops/scripts/test_resolve_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh`
- status bundle status bundle status bundle status bundle status bundle status bundle validation regression:
  - `planningops/scripts/test_validate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh`
- status bundle status bundle status bundle status bundle doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle status bundle gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection.sh`
- status bundle doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle.sh`
- status bundle status bundle doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle doctor regression:
  - `planningops/scripts/test_doctor_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh`
- gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection.sh`
- status bundle gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle.sh`
- status bundle status bundle gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle gate regression:
  - `planningops/scripts/test_gate_monday_agent_harness_projection_status_bundle_status_bundle_status_bundle.sh`
- cross-repo bridge regression:
  - `planningops/scripts/test_monday_agent_harness_projection_bridge.sh`
