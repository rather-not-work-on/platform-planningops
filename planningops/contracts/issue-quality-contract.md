# Issue Quality Contract

## Purpose
Prevent low-quality backlog issues by enforcing deterministic structure, metadata, and evidence requirements.

## Scope
- Repository: `rather-not-work-on/platform-planningops`
- Applies to issue bodies containing `plan_item_id:` marker.

## Required Sections
1. `Planning Context`
2. `Problem Statement`
3. `Interfaces & Dependencies`
4. `Evidence`
5. `Acceptance Criteria`
6. `Definition of Done`

## Required Metadata Keys
- `plan_item_id`
- `target_repo`
- `component`
- `workflow_state`
- `loop_profile`
- `execution_order`
- `depends_on`

## Quality Rules
- Acceptance checklist must contain at least 2 items.
- Placeholder evidence markers (`- (none)`, `<TBD>`) are forbidden.
- `execution_kind=inventory` issues must declare `inventory_lifecycle`.
- open inventory issues must use `inventory_lifecycle=active`.
- archived inventory issues must use `workflow_state=done`, `inventory_lifecycle=archived`, and include `archive_ref` + `compacted_into`.
- Labels must satisfy taxonomy contract:
  - include `task`
  - include exactly one of `p1|p2|p3`
  - include at least one `area/` label
  - include at least one `type/` label
- Generated issues from planning scripts must pass this contract before create/update.

## Verification
- Contract rules: `planningops/config/issue-quality-rules.json`
- Label taxonomy: `planningops/contracts/issue-label-taxonomy-contract.md`
- Validator: `planningops/scripts/validate_issue_quality.py`
- Test: `bash planningops/scripts/test_validate_issue_quality_contract.sh`
- Live check: `python3 planningops/scripts/validate_issue_quality.py --strict`
