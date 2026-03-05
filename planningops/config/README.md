# planningops/config

## Purpose
Provide stable configuration sources for project fields, runtime profiles, and contract references.

## Contents
- `project-field-ids.json`: GitHub Project field ids/options catalog
- `project-view-conventions.md`: view/filter/sort contract for project operations
- `runtime-profiles.json`: local/oracle runtime and provider policies
- `contract-ref-map.json`: C1~C8 schema pointer map
- `ready-implementation-blueprint-defaults.json`: blueprint ref normalization defaults by `target_repo`
- `backlog-stock-policy.json`: queue class stock floors and replenishment candidate requirements
- `refactor-hygiene-policy.json`: single-repo refactor hygiene policy
- `refactor-hygiene-multi-repo.json`: multi-repo hygiene matrix config

## Change Rules
- Field id updates must be synchronized with validator scripts and CI tests.
- Runtime profile additions must keep existing profile names and task-key fallback behavior.
- Contract map paths must stay repo-root-relative and portable across local/CI.
