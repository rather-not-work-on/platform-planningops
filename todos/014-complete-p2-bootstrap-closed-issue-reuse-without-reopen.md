---
status: complete
priority: p2
issue_id: "014"
tags: [code-review, workflow, github, automation, planningops]
dependencies: []
---

# Bootstrap Can Reuse Closed Issue Without Reopen Workflow

Bootstrap dedup scans all issue states and can bind a plan item to a closed issue, but no reopen logic exists.

## Findings

- `planningops/scripts/bootstrap_two_track_backlog.py:229-231` queries `--state all`.
- `find_issue_for_item` returns the first body-marker match, regardless of open/closed state.
- Subsequent flow reuses that issue URL and edits project fields, but does not reopen the issue.
- Impact: backlog card can map to closed issue unexpectedly, reducing execution visibility and introducing state drift.

## Proposed Solutions

### Option 1: Restrict dedup lookup to open issues only

**Approach:** Use `--state open` for matching and create new issue if no open match exists.

**Pros:**
- Predictable active backlog

**Cons:**
- Legacy closed mapping may be abandoned unless explicitly migrated

**Effort:** Small

**Risk:** Low

---

### Option 2: Reopen matched closed issue

**Approach:** If marker match is closed, call `gh issue reopen` before project sync.

**Pros:**
- Preserves historical continuity

**Cons:**
- Reopening may violate closure intent without operator approval

**Effort:** Small

**Risk:** Medium

---

### Option 3: Add `--allow-reopen-closed` explicit flag

**Approach:** Default to open-only, optional reopen behavior when flag is set.

**Pros:**
- Safe default plus explicit override

**Cons:**
- Slightly more CLI complexity

**Effort:** Small

**Risk:** Low

## Recommended Action

완료. 기본 정책을 open-only로 고정하고 `--allow-reopen-closed` 옵션에서만 closed 재사용(+apply 시 reopen)하도록 분리했다.

## Technical Details

**Affected files:**
- `planningops/scripts/bootstrap_two_track_backlog.py:221-247, 399-458`

## Acceptance Criteria

- [x] Closed issues are not silently reused by default.
- [x] Behavior for closed marker matches is explicit and documented.
- [x] Integration test covers closed-match scenario.

## Work Log

### 2026-03-02 - Review Finding Created

**By:** Codex

**Actions:**
- Reviewed dedup + issue state behavior.
- Identified missing reopen/state policy branch.
- Added remediation options.

**Learnings:**
- State-aware dedup is required to keep backlog semantics stable.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/bootstrap_two_track_backlog.py`에 `--allow-reopen-closed` 플래그를 추가했다.
- 기본 경로는 open 이슈만 매칭하도록 수정하고, 옵션 활성 시에만 closed 매칭을 재사용하도록 구현했다.
- apply 모드에서는 closed 매칭을 재사용할 때 `gh issue reopen`을 실행하도록 명시했다.
- 회귀 테스트에서 기본/옵션 모드의 분기 동작을 검증했다.

**Learnings:**
- backlog bootstrap은 “기본 안전 정책 + 명시적 override” 모델이 운영 실수를 줄인다.

## Notes

- Should be addressed before regular re-bootstrap operations.
