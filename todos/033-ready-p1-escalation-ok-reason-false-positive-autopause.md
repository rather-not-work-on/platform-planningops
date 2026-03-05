---
status: ready
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
- [ ] repeated `pass + ok` cycles do not trigger `same_reason_x3`
- [ ] `fail`/`inconclusive` repeated reason patterns still trigger auto-pause
- [ ] regression test added to escalation contract pack
