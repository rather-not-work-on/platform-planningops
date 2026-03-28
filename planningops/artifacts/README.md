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
  - deterministic sample backlog outputs also live here with `.sample.json` suffixes when a fixture-backed artifact lane is promoted
- `program/`: canonical program-manifest outputs, including fixture-backed `.sample.json` lanes
- `validation/`: gate/schema reports, including fixture-backed `.sample.json` lanes that stay separate from live latest artifacts
  - canonical sample validation lanes currently include `blueprint-pack-report.sample.json`, `federated-artifact-policy-rollout-report.sample.json`, `plan-compile-report.sample.json`, `plan-projection-report.sample.json`, `project-field-schema-report.sample.json`, `ready-implementation-blueprint-normalize-report.sample.json`, `runtime-profiles-report.sample.json`, `worker-task-pack-report.sample.json`, and `issue-quality-*.sample.json`
  - canonical issue-quality validator lanes also include `issue-quality-valid.test.json` and `issue-quality-invalid.test.json`
  - canonical federated issue-quality lanes also include `federated-issue-quality-valid.test.json`, `federated-issue-quality-invalid.test.json`, and `federated-issue-quality-auto-fix.test.json`
  - canonical governance validator lanes also include `repo-boundary-report.test.json`, `script-role-report.test.json`, `artifact-storage-policy-valid.test.json`, and `artifact-storage-policy-invalid.test.json`
  - canonical external-only guard lanes also include `external-only-commit-guard-allowed.test.json`, `external-only-commit-guard-blocked.test.json`, and `external-only-commit-guard-tracked.test.json`
  - canonical external-only migration lanes also include `artifact-migration-tracked-dry-run.test.json` and `artifact-migration-tracked-apply.test.json`
  - canonical artifact sink verification lane also includes `artifact-sink-e2e.test.json`
  - canonical repository-governance validator lanes also include `branch-protection-audit-valid.test.json` and `branch-protection-audit-invalid.test.json`
  - canonical repository-governance apply lanes also include `branch-protection-apply-valid.test.json` and `branch-protection-apply-invalid.test.json`
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
