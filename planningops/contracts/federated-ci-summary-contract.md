# Federated CI Summary Contract

## Purpose
Keep one canonical, fail-closed evidence chain for federated CI so local automation, GitHub workflow consumers, and operator diagnosis read the same summary, validation, and readiness state.

## Scope
- local producer: `planningops/scripts/federation/federated_ci_matrix_local.sh`
- GitHub producer: `.github/workflows/federated-ci-matrix.yml`
- summary helper: `planningops/scripts/federation/federated_ci_summary.py`
- tmp-summary reconcile helper: `planningops/scripts/federation/reconcile_federated_ci_summary_tmp.py`
- tmp-summary reconcile validator: `planningops/scripts/validate_federated_ci_summary_tmp_reconcile.py`
- tmp-summary reconcile resolver: `planningops/scripts/resolve_federated_ci_summary_tmp_reconcile.py`
- tmp-summary reconcile bundle validator: `planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py`
- tmp-summary reconcile bundle diagnosis: `planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py`
- tmp-summary reconcile bundle gate: `planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle.sh`
- tmp-summary reconcile bundle status validator: `planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py`
- tmp-summary reconcile bundle status resolver: `planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py`
- tmp-summary reconcile bundle status-bundle validator: `planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py`
- tmp-summary reconcile bundle status-bundle diagnosis: `planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py`
- tmp-summary reconcile bundle status-bundle gate: `planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh`
- tmp-summary reconcile bundle status-bundle status resolver: `planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py`
- tmp-summary reconcile bundle status-bundle status-bundle validator: `planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py`
- tmp-summary reconcile bundle status-bundle-status bundle diagnosis: `planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py`
- tmp-summary reconcile bundle status-bundle-status bundle gate: `planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh`
- tmp-summary reconcile bundle status-bundle-status bundle status validator: `planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py`
- tmp-summary reconcile diagnosis: `planningops/scripts/doctor_federated_ci_summary_tmp_reconcile.py`
- tmp-summary reconcile gate: `planningops/scripts/gate_federated_ci_summary_tmp_reconcile.sh`
- summary validator: `planningops/scripts/validate_federated_ci_summary.py`
- readiness assessor: `planningops/scripts/assess_federated_ci_summary_readiness.py`
- readiness validator: `planningops/scripts/validate_federated_ci_summary_readiness.py`
- operator diagnosis: `planningops/scripts/doctor_federated_ci_summary.py`
- fail-closed gate: `planningops/scripts/gate_federated_ci_summary.sh`

## Canonical Artifacts
- latest summary: `planningops/artifacts/ci/federated-ci-summary.json`
- stamped summary: `planningops/artifacts/ci/<run-id>.json`
- latest summary validation: `planningops/artifacts/validation/federated-ci-summary-validation.json`
- stamped summary validation: `planningops/artifacts/validation/<run-id>-summary-validation.json`
- latest readiness: `planningops/artifacts/validation/federated-ci-summary-readiness.json`
- stamped readiness: `planningops/artifacts/validation/<run-id>-summary-readiness.json`
- latest readiness validation: `planningops/artifacts/validation/federated-ci-summary-readiness-validation.json`
- stamped readiness validation: `planningops/artifacts/validation/<run-id>-summary-readiness-validation.json`
- latest tmp-summary reconcile report: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile.json`
- stamped tmp-summary reconcile report: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile.json`
- latest tmp-summary reconcile validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-validation.json`
- stamped tmp-summary reconcile validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-validation.json`
- latest tmp-summary reconcile bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle.json`
- stamped tmp-summary reconcile bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle.json`
- latest tmp-summary reconcile bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-validation.json`
- stamped tmp-summary reconcile bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-validation.json`
- latest tmp-summary reconcile bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status.json`
- stamped tmp-summary reconcile bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status.json`
- latest tmp-summary reconcile bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- stamped tmp-summary reconcile bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation: `planningops/artifacts/validation/<run-id>-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`

## Producer Rules
1. Local and GitHub producers must initialize, append, and finalize summary state through `planningops/scripts/federation/federated_ci_summary.py`.
2. Inline summary generation inside `.github/workflows/federated-ci-matrix.yml` is forbidden.
3. Summary finalization must self-validate against `planningops/schemas/federated-ci-summary.schema.json` before stamped/latest summary artifacts are published.
4. Summary finalization must emit stamped/latest summary validation artifacts alongside stamped/latest summary artifacts.
5. Readiness assessment must consume summary plus its validation report, then emit stamped/latest readiness artifacts and stamped/latest readiness validation artifacts.
6. Artifact upload and finalization steps in the GitHub federated summary lane must run under `if: always()` so interrupted runs still publish fail-closed evidence.
7. Missing required checks, interrupted runs, or non-zero shell exit codes must resolve to a failing summary verdict instead of an absent artifact.
8. The local matrix runner must snapshot the tmp summary before each federated check and restore that checkpoint before append/finalize if the check command clobbers `run_id`, `started_at_utc`, `required_checks`, or previously appended checks.
9. The local matrix runner must emit stamped/latest tmp-summary reconcile reports plus stamped/latest tmp-summary reconcile validation reports each time it repairs or verifies the checkpoint lineage.
10. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundles plus stamped/latest tmp-summary reconcile bundle-validation reports from the canonical resolver/validator pair each time it refreshes checkpoint-lineage evidence.
11. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle doctor status plus stamped/latest tmp-summary reconcile bundle status-validation reports from the canonical bundle doctor/validator pair each time it refreshes checkpoint-lineage evidence.
12. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status bundles plus stamped/latest tmp-summary reconcile bundle status-bundle validation reports from the canonical resolver/validator pair each time it refreshes checkpoint-lineage evidence.
13. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle doctor status plus stamped/latest tmp-summary reconcile bundle status-bundle status-validation reports from the canonical doctor/validator pair each time it refreshes checkpoint-lineage evidence.
14. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundles from the canonical resolver each time it refreshes checkpoint-lineage evidence.
15. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle-validation reports from the canonical validator each time it refreshes checkpoint-lineage evidence.
16. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle doctor status plus stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status-validation reports from the canonical doctor/validator pair each time it refreshes checkpoint-lineage evidence.
17. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundles from the canonical resolver each time it refreshes checkpoint-lineage evidence.
18. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle-validation reports from the canonical validator each time it refreshes checkpoint-lineage evidence.
19. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle doctor status plus stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation reports from the canonical doctor/validator pair each time it refreshes checkpoint-lineage evidence.
20. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundles from the canonical resolver each time it refreshes checkpoint-lineage evidence.
21. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundles from the canonical resolver each time it refreshes checkpoint-lineage evidence.
22. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle-validation reports from the canonical validator each time it refreshes checkpoint-lineage evidence.
22. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle-validation reports from the canonical validator each time it refreshes checkpoint-lineage evidence.
23. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundles from the canonical resolver each time it refreshes checkpoint-lineage evidence.
24. The local matrix runner must also emit stamped/latest tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle-validation reports from the canonical validator each time it refreshes checkpoint-lineage evidence.

## Freshness Rules
1. A summary validation artifact is fresh only when its fingerprint matches the target summary artifact:
   - `summary_run_id`
   - `summary_generated_at_utc`
   - `summary_verdict`
2. A readiness artifact is fresh only when it reflects the current latest summary plus the current latest summary validation verdict.
3. A readiness validation artifact is fresh only when its fingerprint matches the target readiness artifact:
   - `readiness_generated_at_utc`
   - `readiness_summary_run_id`
   - `readiness_status`
   - `readiness_ready`
4. A tmp-summary reconcile validation artifact is fresh only when its fingerprint matches the target tmp-summary reconcile artifact:
   - `reconcile_generated_at_utc`
   - `reconcile_run_id`
   - `reconcile_status`
   - `reconcile_restored`
   - `reconcile_count`
5. A tmp-summary reconcile bundle-validation artifact is fresh only when it points at the current tmp-summary reconcile bundle and preserves the bundle fingerprint:
   - `bundle_generated_at_utc`
   - `run_id`
   - `reconcile_status`
   - `reconcile_count`
   - `reconcile_validation_verdict`
6. A tmp-summary reconcile bundle status-validation artifact is fresh only when it points at the current tmp-summary reconcile bundle status artifact and preserves the doctor fingerprint:
   - `status_generated_at_utc`
   - `status_run_id`
   - `status_reconcile_status`
   - `status_reconcile_count`
   - `status_bundle_validation_verdict`
   - `status_bundle_validation_state`
7. A tmp-summary reconcile bundle status-bundle validation artifact is fresh only when it points at the current resolved tmp-summary reconcile bundle status bundle and preserves the resolved bundle fingerprint:
   - `bundle_generated_at_utc`
   - `run_id`
   - `reconcile_status`
   - `reconcile_count`
   - `bundle_validation_verdict`
   - `bundle_validation_state`
8. A tmp-summary reconcile bundle status-bundle status-validation artifact is fresh only when it points at the current tmp-summary reconcile bundle status-bundle status artifact and preserves the doctor fingerprint:
   - `status_generated_at_utc`
   - `status_run_id`
   - `status_reconcile_status`
   - `status_reconcile_count`
   - `status_bundle_validation_verdict`
   - `status_bundle_validation_state`
9. A tmp-summary reconcile bundle status-bundle-status bundle-validation artifact is fresh only when it points at the current resolved tmp-summary reconcile bundle status-bundle-status bundle and preserves the resolved doctor-sidecar fingerprint:
   - `bundle_generated_at_utc`
   - `run_id`
   - `reconcile_status`
   - `reconcile_count`
   - `bundle_validation_verdict`
   - `bundle_validation_state`
10. A tmp-summary reconcile bundle status-bundle-status bundle status-validation artifact is fresh only when it points at the current tmp-summary reconcile bundle status-bundle-status bundle status artifact and preserves the doctor fingerprint:
   - `status_generated_at_utc`
   - `status_run_id`
   - `status_reconcile_status`
   - `status_reconcile_count`
   - `status_bundle_validation_verdict`
   - `status_bundle_validation_state`
11. `planningops/scripts/doctor_federated_ci_summary.py` must fail closed when validation, readiness, readiness validation, tmp-summary reconcile, or tmp-summary reconcile validation is stale or missing.
12. `planningops/scripts/gate_federated_ci_summary.sh` must refresh readiness before evaluating pass/fail so downstream automation never infers readiness from raw summary files.

## Consumer Rules
1. Operator-facing diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`.
2. Automated go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary.sh`.
3. Downstream consumers must treat `planningops/artifacts/validation/federated-ci-summary-readiness.json` as the canonical ready-or-blocked decision surface.
4. Downstream consumers must not reconstruct readiness by reading only `planningops/artifacts/ci/federated-ci-summary.json`.
5. `planningops/scripts/autonomous_supervisor_loop.py` must embed federated runtime evidence from the canonical readiness artifact when it emits operator handoff artifacts.
6. If the supervisor would otherwise emit `status=ok` while federated readiness is blocked, the handoff must be downgraded to `status=degraded` and point operators to the federated gate inspection path defined by `planningops/contracts/supervisor-operator-handoff-contract.md`.
7. Checkpoint-lineage inspection must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile.py --require-pass` before reading tmp-summary reconcile artifacts ad hoc.
8. Automated checkpoint-lineage go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile.sh`.
9. Canonical tmp-summary reconcile bundle resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile.py --artifact-file <report-or-validation>`.
10. Canonical tmp-summary reconcile bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle.json --strict`.
11. Operator-facing tmp-summary reconcile bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py --require-pass`.
12. Automated tmp-summary reconcile bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle.sh`.
13. Machine-readable tmp-summary reconcile bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py --strict` after running the bundle doctor.
14. Downstream consumers must treat `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-validation.json` as the canonical machine-readable freshness check for the doctor-owned bundle status sidecar.
15. Canonical tmp-summary reconcile bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py --artifact-file <status-or-status-validation>`.
16. Canonical tmp-summary reconcile bundle status-bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json --strict`.
17. Operator-facing tmp-summary reconcile bundle status-bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py --require-pass`.
18. Automated tmp-summary reconcile bundle status-bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh`.
19. Machine-readable tmp-summary reconcile bundle status-bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py --strict` after running the status-bundle doctor.
20. Downstream consumers must treat `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-validation.json` as the canonical machine-readable freshness check for the status-bundle doctor-owned sidecar.
21. Canonical tmp-summary reconcile bundle status-bundle-status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
22. Canonical tmp-summary reconcile bundle status-bundle-status bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json --strict`.
23. Operator-facing tmp-summary reconcile bundle status-bundle-status bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py --require-pass`.
24. Automated tmp-summary reconcile bundle status-bundle-status bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh`.
25. Machine-readable tmp-summary reconcile bundle status-bundle-status bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py --strict` after running the bundle doctor.
26. Downstream consumers must treat `planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-validation.json` as the canonical machine-readable freshness check for the status-bundle-status bundle doctor-owned sidecar.
27. Canonical tmp-summary reconcile bundle status-bundle-status bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
28. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json --strict`.
29. Operator-facing tmp-summary reconcile bundle status-bundle-status bundle status bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`.
30. Machine-readable tmp-summary reconcile bundle status-bundle-status bundle status bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` after running the bundle doctor.
31. Automated tmp-summary reconcile bundle status-bundle-status bundle status bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh`.
32. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
33. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict`.
34. Operator-facing tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`.
35. Machine-readable tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` after running the bundle doctor.
36. Automated tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`.
37. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
38. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict`.
39. Operator-facing tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`.
40. Machine-readable tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` after running the bundle doctor.
41. Automated tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`.
42. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
43. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle-validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file <resolved-bundle> --strict`.
44. Operator-facing tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`.
45. Machine-readable tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` after running the bundle doctor.
46. Automated tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`.
47. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
48. Operator-facing tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass`.
49. Machine-readable tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle diagnosis must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` after running the bundle doctor.
50. Automated tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle go/no-go checks must prefer `bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`.
51. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle status resolution must prefer `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file <status-or-status-validation>`.
52. Canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation must prefer `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict`.

## Verification
```bash
bash planningops/scripts/test_federated_ci_summary_contract.sh
bash planningops/scripts/test_reconcile_federated_ci_summary_tmp.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_contract.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_doctor_federated_ci_summary_tmp_reconcile.sh
bash planningops/scripts/test_gate_federated_ci_summary_tmp_reconcile.sh
bash planningops/scripts/test_validate_federated_ci_summary_contract.sh
bash planningops/scripts/test_validate_federated_ci_summary_readiness_contract.sh
bash planningops/scripts/test_assess_federated_ci_summary_readiness.sh
bash planningops/scripts/test_doctor_federated_ci_summary.sh
bash planningops/scripts/test_gate_federated_ci_summary.sh
bash planningops/scripts/test_federated_ci_workflow_summary_contract.sh
bash planningops/scripts/test_cross_repo_conformance_run_root_reuse_contract.sh
bash planningops/scripts/test_federated_ci_summary_contract_doc.sh
bash planningops/scripts/test_supervisor_operator_handoff_contract.sh
bash planningops/scripts/test_autonomous_supervisor_loop_contract.sh
python3 planningops/scripts/assess_federated_ci_summary_readiness.py --strict
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py --strict
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py --strict
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py --strict
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.sh
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.sh
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile_bundle.sh
python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile.py --require-pass
bash planningops/scripts/gate_federated_ci_summary_tmp_reconcile.sh
python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass
bash planningops/scripts/gate_federated_ci_summary.sh
```

## Failure Handling
1. If summary validation is stale or missing, regenerate validation through `federated_ci_summary.py finalize` or by rerunning the local matrix or GitHub `federated-summary` job.
2. If readiness is stale or missing, rerun `python3 planningops/scripts/assess_federated_ci_summary_readiness.py --strict` before trusting the latest summary.
3. If tmp-summary reconcile validation is stale or missing, use `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile.py --require-pass` to inspect checkpoint-lineage drift before rerunning the matrix.
4. If tmp-summary reconcile bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status.py --strict` before trusting the doctor-owned sidecar.
5. If tmp-summary reconcile bundle status-bundle validation is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status.json` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle.json --strict` before trusting the resolved bundle surface.
6. If tmp-summary reconcile bundle status-bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py --strict` before trusting the status-bundle doctor-owned sidecar.
7. If tmp-summary reconcile bundle status-bundle-status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status.json` before trusting the resolved doctor-sidecar bundle surface.
8. If tmp-summary reconcile bundle status-bundle-status bundle validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle.json --strict` before trusting the resolved doctor-sidecar bundle surface.
9. If tmp-summary reconcile bundle status-bundle-status bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py --strict` before trusting the doctor-owned sidecar.
10. If tmp-summary reconcile bundle status-bundle-status bundle status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status.json` before trusting the resolved status-bundle-status doctor-sidecar bundle surface.
11. If tmp-summary reconcile bundle status-bundle-status bundle status bundle validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle.json --strict` before trusting that resolved status-bundle-status doctor-sidecar bundle surface.
12. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` before trusting that bundle doctor-owned sidecar.
13. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.json` before trusting that resolved bundle doctor-sidecar surface.
14. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict` before trusting that resolved bundle surface.
15. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` before trusting that doctor-owned sidecar.
16. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before trusting that resolved doctor-owned sidecar bundle surface.
17. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict` before trusting that resolved bundle-validation surface.
18. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` before trusting that outer bundle doctor-owned sidecar.
19. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before trusting that resolved outer doctor-owned bundle surface.
20. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle-validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict` before trusting that resolved outer doctor-owned bundle-validation surface.
21. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` before trusting that next outer bundle doctor-owned sidecar.
22. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before trusting that next outer doctor-owned bundle surface.
23. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict` before trusting that next outer resolved bundle-validation surface.
24. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle status validation is stale or missing, rerun `python3 planningops/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --require-pass` followed by `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict` before trusting that next outer resolved bundle doctor-owned sidecar.
25. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle status resolution is stale or missing, rerun `python3 planningops/scripts/resolve_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before trusting that next outer resolved bundle surface.
26. If tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation is stale or missing, rerun `python3 planningops/scripts/validate_federated_ci_summary_tmp_reconcile_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --bundle-file planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json --strict` before trusting that next outer resolved bundle-validation surface.
27. If the gate blocks, use `python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass` to inspect the canonical reason instead of reading stamped artifacts ad hoc.
