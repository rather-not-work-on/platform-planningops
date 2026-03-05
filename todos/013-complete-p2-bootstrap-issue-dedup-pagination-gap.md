---
status: complete
priority: p2
issue_id: "013"
tags: [code-review, reliability, github, automation, planningops]
dependencies: []
---

# Backlog Bootstrap Dedup Uses Fixed 200-Issue Window

Bootstrap dedup logic only scans first 200 issues, so existing plan items can be missed in larger repositories and duplicated.

## Findings

- `planningops/scripts/bootstrap_two_track_backlog.py:231-234` uses `gh issue list --limit 200`.
- Dedup lookup relies on body marker search (`plan_item_id`) against this limited set.
- If historical issues exceed 200 and matching plan item is outside window, script creates duplicate issue.
- Impact: duplicate cards, inconsistent execution_order mapping, manual cleanup overhead.

## Proposed Solutions

### Option 1: Add pagination loop for full issue scan

**Approach:** Iterate through issue pages until exhaustion.

**Pros:**
- Correct dedup behavior at scale

**Cons:**
- More API calls

**Effort:** Medium

**Risk:** Low

---

### Option 2: Use targeted search query by marker

**Approach:** Query specific `plan_item_id` marker per item with `gh search issues`.

**Pros:**
- Lower data transfer
- Scale-friendly

**Cons:**
- Requires robust query escaping and tie-break rules

**Effort:** Medium

**Risk:** Medium

---

### Option 3: Persist local mapping ledger

**Approach:** Maintain plan_item_id -> issue_number mapping artifact and trust it first.

**Pros:**
- Fast repeated runs

**Cons:**
- Requires ledger consistency maintenance

**Effort:** Medium

**Risk:** Medium

## Recommended Action

완료. issue dedup 조회를 REST pagination으로 전환해 고정 200-window 의존을 제거했다.

## Technical Details

**Affected files:**
- `planningops/scripts/bootstrap_two_track_backlog.py:221-247`

## Resources

- `planningops/artifacts/validation/two-track-backlog-bootstrap-report.json`

## Acceptance Criteria

- [x] Dedup logic finds existing plan items regardless of issue volume.
- [x] No duplicate issue created for repeated `--apply` runs in high-volume repo.
- [x] Regression test or simulation covers >200 issues case.

## Work Log

### 2026-03-02 - Review Finding Created

**By:** Codex

**Actions:**
- Audited bootstrap dedup flow.
- Identified fixed-window limit in issue lookup.
- Documented scale-safe alternatives.

**Learnings:**
- Fixed-size issue windows are brittle in long-running planning repos.

### 2026-03-03 - Resolution

**By:** Codex

**Actions:**
- `planningops/scripts/bootstrap_two_track_backlog.py`의 issue 목록 조회를 `gh api /repos/{repo}/issues` pagination 루프로 변경했다.
- dedup 입력을 open/closed 분리 구조로 재정렬했다.
- `planningops/scripts/test_bootstrap_two_track_backlog_contract.sh`에서 300건 샘플로 >200 case를 검증했다.

**Learnings:**
- plan marker dedup은 단순 limit 조회보다 페이지 순회 방식이 장기적으로 안정적이다.

## Notes

- Important but not merge-blocking for current low issue volume.
