# Control-Tower Ontology Contract

## Purpose
Define the canonical entity model that lets `platform-planningops` operate as the org-level source of truth without absorbing runtime implementation from execution repositories.

This contract fixes:
- the core nouns used across plans, issues, contracts, and evidence
- the allowed relations between those nouns
- the identifier and path rules that keep machine-readable references stable across repositories

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Applies to:
  - backlog/project metadata managed from planningops
  - canonical docs under `docs/initiatives/**`
  - planning contracts/config under `planningops/contracts/**` and `planningops/config/**`
  - cross-repo evidence references imported from `monday` and `platform-*` repositories

## Control-Tower Principles
1. `platform-planningops` owns ontology, policy, sequencing, and gates.
2. Execution repositories own runtime behavior and runtime evidence generation.
3. Ontology links must be explicit enough that an agent can resolve:
   - what an item is
   - which repo owns it
   - which contracts govern it
   - which evidence proves it
4. PlanningOps may index or validate runtime evidence, but it must not become the implementation home for provider, observability, or runtime internals.

## Entity Types
| Entity | Description | Canonical identifier | Minimum required fields | Primary SoT |
|---|---|---|---|---|
| `Initiative` | Top-level strategic scope spanning multiple repos and plans. | `initiative` slug (for example `unified-personal-agent-platform`) | `initiative`, `title`, `status` | `docs/initiatives/**` |
| `PlanItem` | Atomic execution unit tracked as issue/backlog card. | `plan_item_id` (`A10`, `B20`, `C90`) | `plan_item_id`, `target_repo`, `component`, `workflow_state`, `loop_profile`, `depends_on` | GitHub issue body + project fields |
| `Contract` | Normative interface, policy, or behavior boundary. | `contract_id` or canonical contract path | `path`, `owner_repo`, `purpose`, `verification_cmd` | `planningops/contracts/**` or owning repo contract directory |
| `RepositoryRole` | Declared ownership role for a repository or component. | repository coordinate (`owner/repo`) + component | `repo`, `plane`, `component`, `responsibilities` | `docs/initiatives/**`, `planningops/config/**` |
| `RuntimeArtifact` | Evidence emitted by execution or validation runs. | `run_id` + `logical_path` within owning repo | `run_id`, `repo`, `logical_path`, `reason_code`, `contract_refs` | owning execution repo or external artifact sink |
| `MemoryRecord` | Distilled or archived knowledge unit derived from work history. | `memory_id` or canonical path | `memory_tier`, `source_refs`, `summary`, `status` | `planningops/contracts/memory-tier-contract.md` + `planningops/config/memory-tier-rules.json` |

## Canonical Relations
| Relation | Source -> Target | Meaning | Cardinality rule |
|---|---|---|---|
| `contains` | `Initiative -> PlanItem` | initiative owns the execution unit | initiative contains `1..n` plan items |
| `references` | `PlanItem -> Contract` | plan item is governed by the contract | every plan item references `>=1` contract |
| `targets` | `PlanItem -> RepositoryRole` | plan item is delivered in one owning repo/component | every plan item targets exactly `1` repository role |
| `owns` | `RepositoryRole -> Contract` | repo/component is the authoritative owner of a contract | a contract has exactly `1` owner repo |
| `emits` | `RepositoryRole -> RuntimeArtifact` | runtime or validator in that repo emits evidence | runtime artifacts have exactly `1` emitting repo |
| `evidences` | `RuntimeArtifact -> PlanItem` | artifact proves plan-item progress or completion | every done/reviewed plan item should have `>=1` evidence link |
| `validates` | `RuntimeArtifact -> Contract` | artifact was validated against contract(s) | every artifact references `>=1` governing contract when available |
| `compacts` | `MemoryRecord -> PlanItem|RuntimeArtifact` | memory record distills work or evidence history | memory records compact `>=1` source ref |

## Repository Role Classification
### Plane values
- `control-plane`
- `execution-plane`

### Canonical repository roles
| Repo | Plane | Primary component values | Responsibility |
|---|---|---|---|
| `rather-not-work-on/platform-planningops` | `control-plane` | `planningops`, `orchestrator` | ontology, policy, gates, backlog/project orchestration |
| `rather-not-work-on/platform-contracts` | `execution-plane` | `contracts` | shared schema/interface ownership |
| `rather-not-work-on/platform-provider-gateway` | `execution-plane` | `provider-gateway` | provider invocation runtime and smoke evidence |
| `rather-not-work-on/platform-observability-gateway` | `execution-plane` | `observability-gateway` | replay/backfill/ingest runtime and evidence |
| `rather-not-work-on/monday` | `execution-plane` | `runtime` | executor/worker runtime, scheduler, handoff boundary |

## Identifier and Path Rules
### Identifier rules
- `initiative` must use the canonical slug shared by docs and project fields.
- `plan_item_id` must match `^[A-Z][0-9]{2}$`.
- `target_repo` must use full repository coordinates (`owner/repo`), not shorthand.
- `execution_kind` may be used to refine delivery semantics:
  - `executable` (default when omitted)
  - `inventory`
- `inventory_lifecycle` may further classify inventory records:
  - `active`
  - `archived`
- `component` must use the canonical project field vocabulary:
  - `planningops`
  - `contracts`
  - `provider-gateway`
  - `observability-gateway`
  - `runtime`
  - `orchestrator`
- `workflow_state` must follow the project workflow field vocabulary (`backlog`, `ready-contract`, `ready-implementation`, `in-progress`, `review-gate`, `blocked`, `done`).

### Path root rules
- Machine-readable file references must be represented as:
  - `repo`: owning repository coordinate
  - `path`: repo-root-relative path
- `initiative`-relative paths are allowed in prose links, but not as canonical machine-readable ontology references.
- Runtime artifacts stored externally must still preserve:
  - `repo`
  - `logical_path` (repo-root-relative logical destination)
  - backend pointer (`uri`)
- PlanningOps canonical knowledge paths are repo-root-relative under one of:
  - `docs/initiatives/**`
  - `planningops/contracts/**`
  - `planningops/config/**`
  - `planningops/adr/**`

## Ontology Invariants
1. Every `PlanItem` belongs to exactly one `Initiative`.
2. Every `PlanItem` has exactly one `target_repo` and one dominant output artifact.
3. Every `PlanItem` references at least one `Contract` before entering `in-progress`.
4. A `RuntimeArtifact` without `repo`, `logical_path`, or governing refs is invalid for completion evidence.
5. A `MemoryRecord` cannot compact sources from multiple initiatives without an explicit cross-initiative note.
6. `platform-planningops` may validate evidence from execution repos, but runtime ownership remains with the emitting repo.
7. `execution_kind=inventory` items are valid backlog records, but they are not eligible for executable queue stock or loop pull selection.
8. Archived inventory records must move to `workflow_state=done`, carry `archive_ref` + `compacted_into`, and remain traceable through `docs/archive/**` plus `planningops/archive-manifest/**`.

## Verification
- Backlog/project metadata quality: `python3 planningops/scripts/validate_issue_quality.py --strict`
- Ontology contract regression: `bash planningops/scripts/test_control_tower_ontology_contract.sh`
- Boundary consistency: `bash planningops/scripts/test_validate_repo_boundaries_contract.sh`
- Follow-up machine map: `planningops/config/ontology-entity-map.json` (A11)

## Related Contracts
- `planningops/contracts/control-plane-boundary-contract.md`
- `planningops/contracts/issue-quality-contract.md`
- `planningops/contracts/artifact-retention-tier-contract.md`
- `planningops/contracts/memory-tier-contract.md`
- `planningops/contracts/inventory-issue-lifecycle-contract.md`
