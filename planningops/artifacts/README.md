# planningops/artifacts

## Purpose
Persist loop execution outputs, validation reports, and CI evidence bundles.

## Contents
- `validation/`: gate and schema validation outputs
- `meta-plan/`: meta graph build outputs and orchestration reports
- `loop-runner/`: last run snapshot and idempotency ledger
- `loops/`: per-loop run artifacts (`intake`, `simulation`, `verification`, `patch-summary`)
- `sync-summary/`: GitHub/project sync outputs
- `ci/`: federated CI local/summary outputs
- `conformance/`: cross-repo contract conformance reports
- `refactor-hygiene/`: periodic refactor hygiene run reports
- `adapter-hooks/`, `verification/`, `drift/`, `transition-log/`, `pilot/`, `idempotency/`: supporting evidence

## Change Rules
- Artifacts are evidence outputs; do not treat them as source configuration.
- New artifact roots require README update and deterministic naming policy.
- Generated paths should be stable and include run ids where replay matters.
