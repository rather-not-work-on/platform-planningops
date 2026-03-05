# Escalation Gate and Auto-Pause Contract

## Trigger Rules
- `same_reason_x3`: same non-`ok` `reason_code` appears 3 consecutive times for the same issue on non-`pass` verdict rows
- `inconclusive_x2`: `verdict=inconclusive` appears 2 consecutive times for the same issue

## Action on Trigger
1. set `auto_paused=true`
2. force `status_update=Blocked`
3. set `replanning_triggered=true`
4. append transition log event `escalation.auto_pause`
5. emit replan decision artifact:
   - `planningops/artifacts/replan/issue-<issue>-<timestamp>.md`

## State Record
- history ledger:
  - `planningops/artifacts/loop-runner/escalation-history.json`
- each run appends current `(verdict, reason_code)` for issue.
