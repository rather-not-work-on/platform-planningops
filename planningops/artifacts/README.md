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
- `experiments/`: comparative worktree/branch experiment manifests, option reports, and decision records
- `conformance/`: cross-repo contract conformance reports
- `refactor-hygiene/`: periodic refactor hygiene run reports
- `supervisor/`: autonomous supervisor loop cycle reports and run summaries
- `backlog/`: evidence-backed replenishment candidate artifacts per issue
- `adapter-hooks/`, `verification/`, `drift/`, `transition-log/`, `pilot/`, `idempotency/`: supporting evidence

## Change Rules
- Artifacts are evidence outputs; do not treat them as source configuration.
- New artifact roots require README update and deterministic naming policy.
- Generated paths should be stable and include run ids where replay matters.

## Retention Tiers
- `git-canonical`
  - Keep in Git as normative evidence.
  - Examples: `validation/`, `program/`, `meta-plan/`.
- `git-optional`
  - Keep only for milestones/audits.
  - Examples: selected `conformance/`, `pilot/`, `refactor-hygiene/latest.json`.
- `external-only`
  - Store outside Git via artifact sink backend.
  - Examples: `loops/`, `sync-summary/`, `transition-log/`, `adapter-hooks/`, `supervisor/`, `experiments/`.

Policy references:
- contract: `planningops/contracts/artifact-retention-tier-contract.md`
- sink contract: `planningops/contracts/artifact-sink-contract.md`
- config: `planningops/config/artifact-storage-policy.json`
- ADR: `planningops/adr/adr-0005-artifact-retention-and-external-storage-policy.md`
- rollout checklist: `planningops/quality/artifact-storage-rollout-checklist.md`
