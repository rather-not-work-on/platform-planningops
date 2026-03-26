# Plain Python Compat Manifest Contract

## Purpose
Keep one canonical, fail-closed compatibility chain for cross-repo shell `python3` entrypoints so local guardrails, GitHub workflow parity, and operator diagnosis all read the same manifest, validation, resolution, and gate surface.

## Scope
- canonical manifest: `planningops/config/plain-python-compat-manifest.json`
- manifest schema: `planningops/schemas/plain-python-compat-manifest.schema.json`
- validation report schema: `planningops/schemas/plain-python-compat-manifest-validation.schema.json`
- status report schema: `planningops/schemas/plain-python-compat-manifest-status.schema.json`
- status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-validation.schema.json`
- status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle.schema.json`
- status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-validation.schema.json`
- status bundle status report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status.schema.json`
- status bundle status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle.schema.json`
- status bundle status bundle status report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status.schema.json`
- status bundle status bundle status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-validation.schema.json`
- status bundle status bundle status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle.schema.json`
- status bundle status bundle status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-validation.schema.json`
- status bundle status bundle status bundle status report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.schema.json`
- status bundle status bundle status bundle status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- status bundle status bundle status bundle status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- status bundle status bundle status bundle status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- status bundle status bundle status bundle status bundle status report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
- status bundle status bundle status bundle status bundle status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- status bundle status bundle status bundle status bundle status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- status bundle status bundle status bundle status bundle status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- status bundle status bundle status bundle status bundle status bundle status report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
- status bundle status bundle status bundle status bundle status bundle status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- status bundle status bundle status bundle status bundle status bundle status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- status bundle status bundle status bundle status bundle status bundle status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- status bundle status bundle status bundle status bundle status bundle status bundle status report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json`
- status bundle status bundle status bundle status bundle status bundle status bundle status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json`
- status bundle status bundle status bundle status bundle status bundle status bundle status bundle schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json`
- status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.schema.json`
- status bundle status validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-validation.schema.json`
- status bundle status bundle validation report schema: `planningops/schemas/plain-python-compat-manifest-status-bundle-status-bundle-validation.schema.json`
- canonical resolver: `planningops/scripts/resolve_plain_python_compat_manifest.py`
- canonical status sidecar resolver: `planningops/scripts/resolve_plain_python_compat_manifest_status.py`
- canonical status-bundle-status sidecar resolver: `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py`
- canonical status-bundle-status-bundle-status sidecar resolver: `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.py`
- canonical status-bundle-status-bundle-status-bundle-status sidecar resolver: `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status sidecar resolver: `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status sidecar resolver: `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
- machine validator: `planningops/scripts/validate_plain_python_compat_manifest.py`
- status validator: `planningops/scripts/validate_plain_python_compat_manifest_status.py`
- status bundle validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle.py`
- status bundle status bundle validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle.py`
- status bundle status bundle status validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status.py`
- status bundle status bundle status bundle validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle status validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py`
- status bundle status bundle status bundle status bundle validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle status bundle status validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
- status bundle status bundle status bundle status bundle status bundle validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle status bundle status bundle status validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
- status bundle status bundle status bundle status bundle status bundle status bundle validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle status bundle status bundle status bundle status validator: `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py`
- status bundle status bundle status bundle status bundle status bundle doctor: `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle status bundle status bundle gate: `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle doctor: `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle.py`
- status bundle status bundle gate: `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle doctor: `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle gate: `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh`
- status bundle status bundle status bundle status bundle doctor: `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py`
- status bundle status bundle status bundle status bundle gate: `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh`
- status bundle doctor: `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py`
- status bundle gate: `planningops/scripts/gate_plain_python_compat_manifest_status_bundle.sh`
- operator diagnosis: `planningops/scripts/doctor_plain_python_compat_manifest.py`
- fail-closed gate: `planningops/scripts/gate_plain_python_compat_manifest.sh`
- plain interpreter smoke: `planningops/scripts/test_cross_repo_plain_python_compat.sh`
- runtime sequence smoke: `planningops/scripts/test_runtime_stack_smoke_sequence_contract.sh`
- recursive surface inventory regression: `planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh`
  - must consume the validator-owned `resolved_guardrail_script_paths` inventory instead of re-parsing manifest guardrail commands independently

## Canonical Artifacts
- canonical manifest: `planningops/config/plain-python-compat-manifest.json`
- latest validation report: `planningops/artifacts/validation/plain-python-compat-manifest-validation.json`
- latest status report: `planningops/artifacts/validation/plain-python-compat-manifest-status.json`
- latest status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-validation.json`
- latest status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle.json`
- latest status bundle validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-validation.json`
- latest status bundle status report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json`
- latest status bundle status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle.json`
- latest status bundle status bundle status report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json`
- latest status bundle status bundle status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-validation.json`
- latest status bundle status bundle status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle.json`
- latest status bundle status bundle status bundle status report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json`
- latest status bundle status bundle status bundle status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest status bundle status bundle status bundle status bundle validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest status bundle status bundle status bundle status bundle status report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest status bundle status bundle status bundle status bundle status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest status bundle status bundle status bundle status bundle status bundle validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest status bundle status bundle status bundle status bundle status bundle status report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest status bundle status bundle status bundle status bundle status bundle status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest status bundle status bundle status bundle status bundle status bundle status bundle validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest status bundle status bundle status bundle status bundle status bundle status bundle status report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- latest status bundle status bundle status bundle status bundle status bundle status bundle status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`
- latest status bundle status bundle status bundle status bundle status bundle status bundle status bundle: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json`
- latest status bundle status bundle status bundle status bundle status bundle status bundle status bundle validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json`
- latest status bundle status validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-validation.json`
- latest status bundle status bundle validation report: `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-validation.json`
- canonical resolved consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest.py --mode entrypoints`
- canonical sequence consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest.py --mode sequence`
- canonical loop-guardrails consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest.py --mode guardrails`
- canonical status sidecar consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status.json`
- canonical status-bundle-status consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json`
- canonical status-bundle-status-bundle-status consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json`
- canonical status-bundle-status-bundle-status-bundle-status consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle consumer path: `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle validation path: `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict`
- canonical status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle validation path: `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict`

## Producer Rules
1. The curated entrypoint set must live only in `planningops/config/plain-python-compat-manifest.json`.
2. Dynamic compat smoke and runtime-stack sequence smoke must resolve entrypoints through `planningops/scripts/resolve_plain_python_compat_manifest.py`.
3. The canonical plain-python `loop-guardrails` order must live only in `planningops/config/plain-python-compat-manifest.json` as `loop_guardrails_chain`.
4. The validator must write `planningops/artifacts/validation/plain-python-compat-manifest-validation.json` by default.
5. The validator must fail closed when schema shape, canonical resolution, runtime-stack sequence semantics, `loop_guardrails_chain` semantics, or manifest-backed guardrail script references drift.
6. The validator report must expose the resolved manifest-backed guardrail script inventory so downstream contract checks can reuse one machine-readable source of truth.
7. The doctor must write a fresh validation report, a fresh status report, a fresh status-validation report, a fresh status bundle, and a fresh status-bundle validation report before printing status.
8. The status validator must write `planningops/artifacts/validation/plain-python-compat-manifest-status-validation.json` by default.
9. The status bundle validator must write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-validation.json` by default.
10. The status bundle doctor must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status.py` plus `planningops/scripts/validate_plain_python_compat_manifest_status_bundle.py` over ad hoc status/status-validation joins, and must emit a machine-readable status report plus a status-validation report alongside its bundle-validation sidecar.
11. The gate must prefer `python3 planningops/scripts/doctor_plain_python_compat_manifest.py --require-pass` and `python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py --require-pass` over ad hoc validation calls, and both `--require-pass` surfaces must fail closed when the fresh status-validation or status-bundle-validation report drifts.
12. Every manifest-backed entrypoint must keep `from __future__ import annotations` in its top-of-file header so shell `python3` parity does not drift back into PEP 604 failures.
13. The doctor output must surface the canonical `loop_guardrails_chain` ids so operator-facing diagnosis does not have to reopen the manifest to inspect replay order.
14. The doctor output must surface the fresh validation report path so operators can dereference the exact report that gate consumed.
15. The doctor output must also surface the fresh status-validation report path and verdict so operators can inspect the exact status-validation sidecar that gate consumed.
16. The doctor output must surface the fresh status-bundle path so operators can inspect the canonical status/status-validation consumer bundle that gate consumed.
17. The doctor output must surface the fresh status-bundle-validation path and verdict so operators can inspect the exact bundle-validation sidecar that gate consumed.
18. Status-sidecar consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status.py` over ad hoc status/status-validation path joins.
19. Status-bundle doctor consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json` when they need one machine-readable go/no-go summary for the canonical status bundle.
20. Status-bundle doctor validation consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-validation.json` when they need the fresh machine validation verdict for that status sidecar.
20. Status-bundle-status consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py` over ad hoc joins between `plain-python-compat-manifest-status-bundle-status.json` and `plain-python-compat-manifest-status-bundle-status-validation.json`.
21. Status-bundle-status-bundle consumers must prefer `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle.py` when they need a fail-closed machine verdict for the resolved status-bundle-status pair.
22. Operator-facing status-bundle-status-bundle consumers must prefer `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle.py` or `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh` over ad hoc validation invocations.
23. The status-bundle-status-bundle doctor must write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json` by default so downstream operators can inspect one machine-readable status artifact before the outer-bundle gate runs.
24. The status-bundle-status-bundle doctor must also write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-validation.json` by default, and that validation report must fail closed if the emitted outer status artifact, propagated bundle lineage, or embedded validation output path drifts.
25. Outer status-sidecar consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.py` over ad hoc joins between `plain-python-compat-manifest-status-bundle-status-bundle-status.json` and `plain-python-compat-manifest-status-bundle-status-bundle-status-validation.json`.
26. Outermost status-sidecar consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py` over ad hoc joins between `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json` and `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-validation.json`.
27. Outermost bundle validators must prefer `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py` over ad hoc joins between the resolved outermost bundle and its upstream sidecars.
28. Outermost bundle doctor consumers must prefer `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py` or `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh` over ad hoc validation invocations.
29. The outermost bundle doctor must write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json` by default so downstream operators can inspect one machine-readable status artifact before the outermost-bundle gate runs.
30. The outermost bundle doctor must also write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json` by default, and that validation report must fail closed if the emitted status artifact, propagated bundle lineage, or embedded validation output path drifts.
31. Outermost-doctor status-sidecar consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py` over ad hoc joins between `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json` and `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`.
32. Outermost-doctor status-bundle validators must prefer `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` over ad hoc joins between the resolved outermost-doctor status bundle and its upstream sidecars.
33. Resolved outermost-doctor status-bundle operators must prefer `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` or `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh` over ad hoc validation invocations.
34. The resolved outermost-doctor status-bundle doctor must write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` by default so downstream operators can inspect one machine-readable status artifact before the outermost-doctor bundle gate runs.
35. The resolved outermost-doctor status-bundle doctor must also write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json` by default, and that validation report must fail closed if the emitted status artifact, propagated bundle lineage, or embedded validation output path drifts.
36. Outermost-doctor status-bundle-status consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` over ad hoc joins between `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` and `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`.
37. Outermost-doctor status-bundle-status-bundle validators must prefer `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` over ad hoc joins between the resolved outermost-doctor status-bundle doctor bundle and its upstream sidecars.
38. Resolved outermost-doctor status-bundle doctor bundle operators must prefer `planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` or `planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh` over ad hoc validation invocations.
39. The resolved outermost-doctor status-bundle doctor bundle doctor must write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` by default so downstream operators can inspect one machine-readable status artifact before the next resolver layer runs.
40. The resolved outermost-doctor status-bundle doctor bundle doctor must also write `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json` by default, and that validation report must fail closed if the emitted status artifact, propagated bundle lineage, or embedded validation output path drifts.
41. Resolved outermost-doctor status-bundle doctor bundle status-sidecar consumers must prefer `planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` over ad hoc joins between `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` and `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json`.
42. Resolved outermost-doctor status-bundle doctor bundle status-bundle validators must prefer `planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py` over ad hoc joins between the resolved bundle and its upstream status sidecars.

## Consumer Rules
1. Local and GitHub `loop-guardrails` must validate the manifest contract before replaying cross-repo plain-`python3` smoke.
2. Local and GitHub `loop-guardrails` must use `bash planningops/scripts/gate_plain_python_compat_manifest.sh` as the canonical go/no-go surface.
3. Local and GitHub `loop-guardrails` must replay the canonical `loop_guardrails_chain` in manifest order instead of maintaining ad hoc local/workflow copies.
4. Downstream consumers must not reconstruct the runtime-stack sequence from hard-coded script paths when `resolve_plain_python_compat_manifest.py` is available.
5. `planningops/scripts/test_cross_repo_plain_python_annotation_contract.sh` must derive its required file set from the resolver output, not an ad hoc hard-coded list.
6. Downstream consumers must not hand-join `plain-python-compat-manifest-status.json` with `plain-python-compat-manifest-status-validation.json` when `resolve_plain_python_compat_manifest_status.py` is available.
7. Canonical latest consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle.json` when they need the validated pair as one artifact.
8. Status-validation reports and status bundles must preserve the validator-owned `resolved_guardrail_script_paths` inventory as a top-level field so downstream consumers do not need to reopen nested reports to recover manifest-backed guardrail refs.
8. Downstream consumers must not hand-join `plain-python-compat-manifest-status-bundle-status.json` with `plain-python-compat-manifest-status-bundle-status-validation.json` when `resolve_plain_python_compat_manifest_status_bundle_status.py` is available.
9. Downstream consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-validation.json` when they need the latest machine validation verdict for the resolved status-bundle-status bundle.
10. Local and GitHub `loop-guardrails` should prefer `bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json` when they need the operator-facing go/no-go surface for the resolved status-bundle-status bundle.
11. Downstream consumers must not hand-join `plain-python-compat-manifest-status-bundle-status-bundle-status.json` with `plain-python-compat-manifest-status-bundle-status-bundle-status-validation.json` when `resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.py` is available.
12. Downstream consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-validation.json` when they need the latest machine validation verdict for the resolved outer status-bundle-status-bundle-status bundle.
13. Local and GitHub `loop-guardrails` should prefer `bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json` when they need the operator-facing go/no-go surface for the resolved outer status-bundle-status-bundle-status bundle.
14. Downstream consumers must not hand-join `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json` with `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-validation.json` when `resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py` is available.
15. Canonical latest consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle.json` when they need the resolved outermost status/status-validation pair as one artifact.
16. Downstream consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-validation.json` when they need the latest machine validation verdict for the resolved outermost bundle.
17. Local and GitHub `loop-guardrails` should prefer `bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json` when they need the operator-facing go/no-go surface for the resolved outermost bundle.
18. Downstream consumers must not hand-join `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json` with `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json` when `resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py` is available.
19. Canonical latest consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json` when they need the resolved outermost-doctor status/status-validation pair as one artifact.
20. Downstream consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json` when they need the latest machine validation verdict for the resolved outermost-doctor status bundle.
21. Local and GitHub `loop-guardrails` should prefer `bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json` when they need the operator-facing go/no-go surface for the resolved outermost-doctor status bundle.
22. Downstream consumers must not hand-join `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` with `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json` when `resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` is available.
23. Canonical latest consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json` when they need the resolved outermost-doctor-status-bundle doctor `status/status-validation` pair as one artifact.
24. Downstream consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json` when they need the latest machine validation verdict for the resolved outermost-doctor-status-bundle doctor bundle.
25. Local and GitHub `loop-guardrails` should prefer `bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` when they need the operator-facing go/no-go surface for the resolved outermost-doctor-status-bundle doctor bundle.
26. Downstream consumers must not hand-join `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` with `plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json` when `resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py` is available.
27. Canonical latest consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json` when they need the resolved outermost-doctor-status-bundle doctor bundle `status/status-validation` pair as one artifact.
28. Downstream consumers should prefer `planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-validation.json` when they need the latest machine validation verdict for the resolved outermost-doctor-status-bundle doctor bundle status bundle.

## Verification
```bash
bash planningops/scripts/test_validate_plain_python_compat_manifest.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_validation_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_validation_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_validation_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_contract.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_validation_contract.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.sh
bash planningops/scripts/test_validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_validation_contract.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle_status_bundle.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest_status_bundle.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest_status_bundle.sh
bash planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest_status.sh
bash planningops/scripts/test_resolve_plain_python_compat_manifest.sh
bash planningops/scripts/test_doctor_plain_python_compat_manifest.sh
bash planningops/scripts/test_gate_plain_python_compat_manifest.sh
bash planningops/scripts/test_run_plain_python_compat_workflow_chain_contract.sh
bash planningops/scripts/run_plain_python_compat_workflow_chain.sh
bash planningops/scripts/test_cross_repo_plain_python_annotation_contract.sh
PLAIN_PYTHON_BIN="$(command -v python3)" bash planningops/scripts/test_cross_repo_plain_python_compat.sh
PLAIN_PYTHON_BIN="$(command -v python3)" bash planningops/scripts/test_runtime_stack_smoke_sequence_contract.sh
python3 planningops/scripts/resolve_plain_python_compat_manifest.py --mode entrypoints
python3 planningops/scripts/resolve_plain_python_compat_manifest.py --mode guardrails
python3 planningops/scripts/resolve_plain_python_compat_manifest_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status.json
python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json
python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json
python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --strict
python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json --require-pass
python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json --require-pass
python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json --require-pass
python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json --require-pass
python3 planningops/scripts/doctor_plain_python_compat_manifest.py --require-pass
python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status.json --require-pass
bash planningops/scripts/gate_plain_python_compat_manifest.sh
bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status.json
bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json
bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json
bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json
bash planningops/scripts/gate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.sh --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json
```

## Failure Handling
1. If manifest validation fails, rerun `python3 planningops/scripts/validate_plain_python_compat_manifest.py --strict` to capture the latest validation report.
2. If doctor or gate fails, use `python3 planningops/scripts/doctor_plain_python_compat_manifest.py --require-pass` to inspect the canonical reason instead of reopening the manifest manually.
3. If status-sidecar resolution fails, inspect the canonical pair with `python3 planningops/scripts/resolve_plain_python_compat_manifest_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status.json` before hand-editing paths.
4. If status-bundle-status resolution fails, inspect the canonical pair with `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json` before hand-editing paths.
5. If status-bundle-status-bundle validation fails, inspect `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle.py --strict` before hand-editing stored bundle artifacts.
6. If the status-bundle-status-bundle doctor or gate fails, inspect `python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status.json --require-pass` before bypassing the consumer surface.
7. If the outer status-bundle-status-bundle-status-bundle doctor or gate fails, inspect `python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status.json --require-pass` before bypassing the consumer surface.
8. If the outermost status-sidecar pair fails to resolve, inspect `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json` before hand-editing the latest outermost status sidecars.
9. If the outermost-doctor status-sidecar pair fails to resolve, inspect `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before hand-editing the latest outermost-doctor status sidecars.
10. If the resolved outermost-doctor status bundle fails validation, inspect `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict` before hand-editing the latest outermost-doctor status bundle artifact.
11. If the resolved outermost-doctor status-bundle doctor or gate fails, inspect `python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status.json --require-pass` before bypassing the consumer surface.
12. If the resolved outermost-doctor status-bundle doctor status pair fails to resolve, inspect `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before hand-editing the latest outermost-doctor status-bundle doctor status sidecars.
13. If the resolved outermost-doctor status-bundle doctor bundle fails validation, inspect `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict` before hand-editing the latest outermost-doctor status-bundle doctor bundle artifact.
14. If the resolved outermost bundle fails validation, inspect `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py --strict` before hand-editing the latest outermost bundle artifact.
15. If the outermost bundle doctor or gate fails, inspect `python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status.json --require-pass` before bypassing the consumer surface.
16. If the resolved outermost-doctor status-bundle doctor bundle doctor or gate fails, inspect `python3 planningops/scripts/doctor_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json --require-pass` before bypassing the consumer surface.
17. If the resolved outermost-doctor status-bundle doctor bundle status pair fails to resolve, inspect `python3 planningops/scripts/resolve_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status.py --artifact-file planningops/artifacts/validation/plain-python-compat-manifest-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle-status.json` before hand-editing the latest resolved outermost-doctor status-bundle doctor bundle status sidecars.
18. If the resolved outermost-doctor status-bundle doctor bundle status bundle fails validation, inspect `python3 planningops/scripts/validate_plain_python_compat_manifest_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle.py --strict` before hand-editing the latest resolved outermost-doctor status-bundle doctor bundle status bundle artifact.
19. If the sequence smoke fails after the manifest passes, treat that as runtime drift in one resolved entrypoint, not as permission to bypass the manifest gate.
20. If recursive plain-python compat files exist outside the documented surface, rerun `bash planningops/scripts/test_plain_python_compat_manifest_surface_inventory.sh` before wiring a new layer into local or GitHub guardrails.
21. If GitHub `loop-guardrails` wiring drifts, inspect `bash planningops/scripts/run_plain_python_compat_workflow_chain.sh --print-steps` and `bash planningops/scripts/run_plain_python_compat_workflow_chain.sh --print-workflow-invocation` before re-inlining manifest commands in the workflow.
