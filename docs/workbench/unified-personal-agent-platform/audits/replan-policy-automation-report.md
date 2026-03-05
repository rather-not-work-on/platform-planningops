---
title: audit: Recovery and Replan Policy Automation
type: audit
date: 2026-03-03
initiative: unified-personal-agent-platform
lifecycle: workbench
status: active
summary: Verifies auto-pause and replan trigger automation contract for repeated failures and inconclusive verdict streaks.
---

# audit: Recovery and Replan Policy Automation

## Objective
반복 실패 시 자동 차단과 재계획 경로가 계약대로 동작하는지 검증한다.

## Contract Basis
- `planningops/contracts/escalation-gate-contract.md`
- `planningops/contracts/requirements-contract.md` (FR 19~20)

## Trigger Rules
1. `same_reason_x3`
2. `inconclusive_x2`

## Expected Automation Actions
1. `Status=Blocked`로 전환
2. `replanning_triggered=true` 기록
3. `transition-log.ndjson`에 auto-pause 전이 이벤트 저장
4. `planningops/artifacts/replan/issue-<n>-<timestamp>.md` 생성

## Implementation References
- escalation evaluator: `planningops/scripts/issue_loop_runner.py` (`evaluate_escalation`)
- verification path: `planningops/scripts/verify_loop_run.py`
- contract test: `planningops/scripts/test_escalation_gate.sh`

## Validation Run
```bash
bash planningops/scripts/test_escalation_gate.sh
```

Expected output:
- `same_reason_x3` trigger pass
- `inconclusive_x2` trigger pass
- contract smoke result pass

## Operating Notes
- 초기 상태가 `blocked`인 카드도 L5 루프로 evidence 재생성이 가능해야 한다.
- trigger 조건 미충족이면 상태 전환 없이 기존 workflow를 유지한다.
- 재계획 verdict(`resume|split|stop`)는 후속 triage 결정으로 분리한다.

## Verdict
- status: pass
- reviewer: codex
- reviewed_at_utc: 2026-03-03T16:11:40+09:00
