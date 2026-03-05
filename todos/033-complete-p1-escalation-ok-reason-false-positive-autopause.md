---
status: complete
priority: p1
issue_id: "033"
tags: [planningops, escalation, reliability, supervisor]
dependencies: ["031", "029"]
---

# Escalation Gate False Positive on pass/ok Repetition

## Problem Statement
Live supervisor pilot (`031`) auto-paused on `same_reason_x3` even though loop verdicts were `pass` and `reason_code=ok`.

## Findings
- Current escalation counting appears to trigger purely by reason-code repetition.
- Repeated successful passes should not auto-pause the run.

## Proposed Solution
Constrain escalation rule to failure/inconclusive paths or non-`ok` reasons, then add regression tests.

## Acceptance Criteria
- [x] repeated `pass + ok` cycles do not trigger `same_reason_x3`
- [x] `fail`/`inconclusive` repeated reason patterns still trigger auto-pause
- [x] regression test added to escalation contract pack

## Work Log

### 2026-03-05 - Fix Complete

**By:** Codex

**Actions:**
- Updated escalation eligibility so `same_reason_x3` only counts non-`pass` / non-`ok` reason streaks:
  - `planningops/scripts/issue_loop_runner.py`
- Updated contract wording:
  - `planningops/contracts/escalation-gate-contract.md`
- Added regression for repeated `pass + ok` no-autopause behavior:
  - `planningops/scripts/test_escalation_gate.sh`
- Added audit:
  - `docs/workbench/unified-personal-agent-platform/audits/2026-03-05-escalation-pass-ok-guard-audit.md`

**Validation:**
- `python3 -m py_compile planningops/scripts/issue_loop_runner.py`
- `bash planningops/scripts/test_escalation_gate.sh`
- `bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh`
