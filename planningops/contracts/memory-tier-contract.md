# Memory Tier Contract

## Purpose
Define the 3-tier memory lifecycle that keeps `platform-planningops` compact, searchable, and reusable without turning the repository into an unbounded log sink.

This contract makes memory behavior explicit for:
- where new planning knowledge lands first
- when it must be distilled, promoted, or archived
- which metadata fields make compaction and rehydrate deterministic

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Applies to:
  - planning documents under `docs/workbench/**`, `docs/initiatives/**`, `docs/archive/**`
  - planning-derived evidence records referenced from `planningops/artifacts/**`
  - future memory tooling (`memory_compactor.py`, `memory_archive.py`, `memory_rehydrate.py`)

## Memory Model
Memory tier describes knowledge lifecycle.
Artifact storage tier describes storage backend and Git retention.

These are related, but not the same:
- memory tier answers `how fresh/reusable is this knowledge?`
- artifact storage tier answers `where and how is the artifact stored?`

When both apply, memory tier must not override the artifact backend policy from `planningops/contracts/artifact-retention-tier-contract.md`.

## Tier Definitions
| Tier | Name | Purpose | Default locations | Retention/SLA | Exit rule |
|---|---|---|---|---|---|
| `L0` | short / active working memory | mutable execution context and unresolved working notes | `docs/workbench/**`, open initiative issues, non-promoted planning evidence | TTL `7-14` days | must be promoted to `L1` or archived to `L2` before expiry |
| `L1` | mid / operational canonical memory | stable reusable operating knowledge | `docs/initiatives/**`, `planningops/contracts/**`, `planningops/config/**`, `planningops/adr/**` | quarterly review cadence | superseded or low-signal records move to `L2` with archive pointer |
| `L2` | long / institutional archive | historical record kept for future retrieval, not active editing | `docs/archive/**`, `planningops/archive-manifest/**` | long-term retention | rehydrate only through pointer/index or explicit restore flow |

## Frontmatter and Metadata Contract
### Required keys
- `memory_tier`
- `expires_on`
- `compacted_into`
- `archive_ref`

### Key rules
1. `memory_tier`
   - required for memory-managed planning documents
   - allowed values: `L0`, `L1`, `L2`
2. `expires_on`
   - required for `L0`
   - optional for `L1`
   - forbidden for immutable `L2` archive summaries unless used as review date
3. `compacted_into`
   - required when an `L0` item has been promoted or archived
   - points to the repo-root-relative target summary/index path
4. `archive_ref`
   - required for `L2`
   - may be empty for `L0`/`L1`

## Compaction Loop Contract
1. `capture`
   - new or volatile knowledge enters `L0`
2. `validate`
   - supporting tests/contracts/gates must pass before promotion
3. `distill`
   - create a concise summary or canonical contract entry
4. `promote`
   - move reusable knowledge to `L1`
5. `archive`
   - move historical detail to `L2` with pointer/index
6. `rehydrate`
   - reconstruct detail from `archive_ref` or pointer manifest on demand

## Promotion and Archive Rules
### `L0 -> L1`
Allowed only when all are true:
- authoritative source has been chosen
- validation evidence exists
- distilled summary exists
- target canonical path is known

### `L0 -> L2`
Allowed only when all are true:
- content has historical value but low active reuse
- distilled summary exists or an authoritative replacement exists
- `archive_ref` is assigned
- `compacted_into` points to the retained summary or replacement path

### `L1 -> L2`
Allowed when:
- record is superseded by a newer canonical version
- historical trace is still useful
- index/pointer allows deterministic rehydrate

## Trigger Rules
1. `stale_l0_uncompacted`
   - fire when an `L0` record exceeds `14` days and has no `compacted_into`
2. `topic_compaction_required`
   - fire when `3+` `L0` records share the same topic without a summary
3. `closed_issue_memory_summary_missing`
   - fire when a plan item closes without summary/evidence refs that identify the retained memory target

## Path Policy
- Canonical machine-readable paths must be repo-root-relative.
- Archive references must resolve through repo-root-relative path or pointer manifest logical path.
- Human prose may use relative links, but automation must resolve `repo + path`.

## Verification
- Rules config: `planningops/config/memory-tier-rules.json`
- Validator: `planningops/scripts/validate_memory_tier_rules.py`
- Check mode: `python3 planningops/scripts/memory_compactor.py --mode check`
- CI gate: `python3 planningops/scripts/memory_compactor.py --mode check --root . --rules planningops/config/memory-tier-rules.json --output planningops/artifacts/validation/memory-gate-report.json --strict`
- Archive command: `python3 planningops/scripts/memory_archive.py --source <repo-relative-source> --compacted-into <repo-relative-target>`
- Rehydrate command: `python3 planningops/scripts/memory_rehydrate.py --manifest <archive-ref-or-manifest-path>`
- Manifest schema: `planningops/schemas/memory-archive-manifest.schema.json`
- Contract test: `bash planningops/scripts/test_memory_tier_contract.sh`
- Future runtime tooling:
  - `planningops/scripts/memory_compactor.py`
  - `planningops/scripts/memory_archive.py`
  - `planningops/scripts/memory_rehydrate.py`

## Related Contracts
- `planningops/contracts/control-tower-ontology-contract.md`
- `planningops/contracts/artifact-retention-tier-contract.md`
- `planningops/contracts/artifact-sink-contract.md`
