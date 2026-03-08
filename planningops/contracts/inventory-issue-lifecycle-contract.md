# Inventory Issue Lifecycle Contract

## Purpose
Keep `execution_kind=inventory` backlog records useful without letting them accumulate indefinitely as pseudo-work.

This contract defines:
- when an inventory issue may remain open
- when it must be compacted and closed
- which archive pointers make the history deterministic and recoverable

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Applies to:
  - GitHub issues with `execution_kind=inventory`
  - archive copies under `docs/archive/github-issues/**`
  - issue archive manifests under `planningops/archive-manifest/github-issues/**`

## Lifecycle States
### `active`
An open inventory issue is allowed only while it preserves currently useful queue memory.

Required properties:
- issue state: `OPEN`
- `workflow_state: backlog`
- `inventory_lifecycle: active`
- `archive_ref` absent
- `compacted_into` absent

Open inventory issues are temporary support records. They are not executable work and they must not satisfy queue stock floors or live pull selection.

### `archived`
An inventory issue must move to archived state once it is superseded, reduced to history/audit value, or exceeds the active retention window.

Required properties:
- issue state: `CLOSED`
- `workflow_state: done`
- `inventory_lifecycle: archived`
- `archive_ref` points to `planningops/archive-manifest/github-issues/**`
- `compacted_into` points to the retained canonical summary or replacement path

## Close / Compaction Rule
Inventory issue closure is valid only when all are true:
1. An archive markdown copy exists under `docs/archive/github-issues/**`.
2. A deterministic manifest exists under `planningops/archive-manifest/github-issues/**`.
3. The issue body includes `archive_ref` and `compacted_into`.
4. Project card is synchronized to `Status=Done` and `workflow_state=done`.
5. The GitHub issue is closed.

## Retention Rule
- Active inventory records use the same short-memory expectation as `L0` planning memory.
- Inventory issues older than `14` days must be compacted and closed unless an explicit operator exception exists.

## Archive and Rehydrate Contract
- Archive command:
  - `python3 planningops/scripts/inventory_issue_lifecycle.py archive --issue-ref rather-not-work-on/platform-planningops#<n> --compacted-into <repo-relative-summary-path>`
- Rehydrate command:
  - `python3 planningops/scripts/inventory_issue_lifecycle.py rehydrate --manifest planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-<n>.json`
- Audit command:
  - `python3 planningops/scripts/inventory_issue_lifecycle.py audit --repo rather-not-work-on/platform-planningops --strict`

## View Semantics
- Queue and Kanban pull views must exclude archived inventory history by filtering to active queue states (`Status=Todo`, `workflow_state in ready-*|backlog` as appropriate).
- Archived inventory remains discoverable through:
  - closed issue history on GitHub
  - `docs/archive/github-issues/**`
  - `planningops/archive-manifest/github-issues/**`
  - retained summary path referenced by `compacted_into`

## Policy Source
- `planningops/config/inventory-issue-lifecycle-policy.json`

## Related Contracts
- `planningops/contracts/backlog-stock-replenishment-contract.md`
- `planningops/contracts/memory-tier-contract.md`
- `planningops/contracts/control-tower-ontology-contract.md`
