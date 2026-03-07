# Federated Artifact Storage Contract

## Purpose
Keep runtime-generated evidence out of tracked repository paths across execution repos while preserving deterministic operator access.

## Scope
- `rather-not-work-on/platform-provider-gateway`
- `rather-not-work-on/platform-observability-gateway`
- `rather-not-work-on/monday`
- validator: `planningops/scripts/rollout_external_artifact_policy.py`

## Rules
1. Execution repos must default runtime outputs to repo-local `runtime-artifacts/**`.
2. `runtime-artifacts/` must be gitignored in every execution repo.
3. CI and regression tests must prefer explicit temporary output paths (`/tmp` or `mktemp`) over tracked repo paths.
4. Legacy repo-local paths under `artifacts/**` are forbidden for execution-repo runtime outputs.
5. References to `planningops/artifacts/**` are allowed only when pointing to control-plane evidence consumed by `monday`.

## Required Default Roots
- `platform-provider-gateway`
  - `runtime-artifacts/smoke`
  - `runtime-artifacts/validation`
  - `runtime-artifacts/launcher`
- `platform-observability-gateway`
  - `runtime-artifacts/ingest`
  - `runtime-artifacts/validation`
  - `runtime-artifacts/launcher`
- `monday`
  - `runtime-artifacts/interface`
  - `runtime-artifacts/scheduler`
  - `runtime-artifacts/transition-log`
  - `runtime-artifacts/integration`
  - `runtime-artifacts/validation`

## Verification
```bash
python3 planningops/scripts/rollout_external_artifact_policy.py \
  --workspace-root .. \
  --strict \
  --output planningops/artifacts/validation/federated-artifact-policy-rollout-report.json
```

## Failure Handling
1. Move default output paths from `artifacts/**` to `runtime-artifacts/**`.
2. Update README/runbook examples to match new defaults.
3. Re-run repo-local smoke tests and federated conformance.
