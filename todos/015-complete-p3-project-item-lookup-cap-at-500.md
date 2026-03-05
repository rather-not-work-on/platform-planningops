---
status: complete
priority: p3
issue_id: "015"
tags: [code-review, scalability, github, automation, planningops]
dependencies: []
---

# Project Item Lookup Uses Fixed 500-Item Limit

Project item lookup uses a fixed `--limit 500` call and no pagination, which can fail to resolve existing items in larger projects.

## Findings

- `planningops/scripts/bootstrap_two_track_backlog.py:283` uses `gh project item-list --limit 500`.
- If item is outside first 500, script can fail to resolve `item_id` and raise runtime error.
- This path is fallback-critical when `item-add` returns non-JSON/no id.

## Proposed Solutions

### Option 1: Paginate project item-list

**Approach:** Iterate through all project items with cursor/page strategy.

**Pros:**
- Correct at scale

**Cons:**
- More API calls

**Effort:** Medium

**Risk:** Low

---

### Option 2: Query item by issue node id

**Approach:** Use GraphQL query keyed by issue node id instead of full list scan.

**Pros:**
- Efficient lookup

**Cons:**
- More complex GraphQL query surface

**Effort:** Medium

**Risk:** Medium

## Recommended Action

완료. project item fallback lookup을 GraphQL cursor pagination 인덱스로 전환해 500 cap 의존을 제거했다.

## Technical Details

**Affected files:**
- `planningops/scripts/bootstrap_two_track_backlog.py:273-301`

## Acceptance Criteria

- [x] Item lookup succeeds regardless of project size.
- [x] No runtime failure when project has >500 items.
- [x] Documented operational constraints if hard limit remains.

## Work Log

### 2026-03-02 - Review Finding Created

**By:** Codex

**Actions:**
- Reviewed fallback item lookup path.
- Identified fixed-limit scaling risk.
- Documented mitigation options.

**Learnings:**
- Fallback lookup should not depend on fixed list caps in long-lived projects.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/bootstrap_two_track_backlog.py`에 GraphQL cursor pagination 기반 project item 로더를 추가했다.
- fallback lookup에서 issue `(number, repository)` 인덱스를 구성해 item id를 조회하도록 변경했다.
- 회귀 테스트에 multi-page(2-page) 케이스를 추가해 item id 조회 성공을 검증했다.

**Learnings:**
- fallback 경로일수록 fixed limit보다 cursor pagination이 장애 전파를 줄인다.
