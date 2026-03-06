# planningops/config

## Purpose
Provide stable configuration sources for project fields, runtime profiles, and contract references.

## Contents
- `project-field-ids.json`: GitHub Project field ids/options catalog
- `project-view-conventions.md`: view/filter/sort contract for project operations
- `runtime-profiles.json`: local/oracle runtime and provider policies
- `contract-ref-map.json`: C1~C8 schema pointer map
- `repository-boundary-map.json`: control-plane vs execution-repo ownership and script layout rules
- `script-role-map.json`: recurring core/federation scripts vs one-off script placement rules
- `issue-quality-rules.json`: backlog issue body quality contract rules
- `ready-implementation-blueprint-defaults.json`: blueprint ref normalization defaults by `target_repo`
- `backlog-stock-policy.json`: queue class stock floors and replenishment candidate requirements
- `supervisor-experiment-validation-pack.json`: command pack for automatic worktree comparative execution
- `refactor-hygiene-policy.json`: single-repo refactor hygiene policy
- `refactor-hygiene-multi-repo.json`: multi-repo hygiene matrix config
- `artifact-storage-policy.json`: artifact tier map, backend selector, and retention policy
- `repository-governance-policy.json`: default-branch protection baseline and required checks policy
- `federated-label-taxonomy.json`: execution-repo label catalog and default backfill mapping

## Change Rules
- Field id updates must be synchronized with validator scripts and CI tests.
- Runtime profile additions must keep existing profile names and task-key fallback behavior.
- Contract map paths must stay repo-root-relative and portable across local/CI.
- Script role map changes must keep root wrapper compatibility for moved entrypoints.
- Issue quality rule changes must align with `planningops/contracts/issue-quality-contract.md`.
