# Loop Verification Checklist and Result Format

## Checklist
- [ ] intake-check generated
- [ ] simulation report generated
- [ ] verification report generated
- [ ] transition log entry appended
- [ ] required contracts referenced
- [ ] dependency checks passed (or blocked reason recorded)
- [ ] feedback update attempted
- [ ] `loop_profile` selected and recorded
- [ ] project payload includes `last_verdict`, `last_reason`, `loop_profile`
- [ ] replanning trigger evaluated (`inconclusive x2` or same `reason_code x3`)
- [ ] adapter pre-hook artifact generated
- [ ] adapter post-hook artifact generated
- [ ] escalation gate evaluated (`same_reason x3` / `inconclusive x2`)
- [ ] auto-pause transition and replan decision artifact generated when escalation triggers

## Loop-Specific Required Artifacts
- `L1 Contract-Clarification`: `contract-gap-report.md`
- `L2 Simulation`: `scenario-matrix.json`
- `L3 Implementation-TDD`: `test-report.json`
- `L4 Integration-Reconcile`: `sync-summary.json`, `drift-report.json`
- `L5 Recovery-Replan`: `replan-decision.md`

## Result Format (JSON)
```json
{
  "issue_number": 0,
  "loop_id": "loop-<timestamp>-<issue>",
  "verdict": "pass|fail|inconclusive",
  "loop_profile": "L1|L2|L3|L4|L5",
  "reason_code": "ok|missing_input|missing_artifact|dependency_blocked|verification_failed|feedback_failed|permission_denied",
  "artifacts": {
    "patch_summary": "<path>",
    "simulation_report": "<path>",
    "verification_report": "<path>",
    "transition_log": "<path>"
  },
  "metrics": {
    "duration_ms": 0,
    "retry_count": 0
  },
  "trigger_detection": {
    "repeated_reason_trigger": false,
    "inconclusive_trigger": false,
    "replanning_triggered": false
  },
  "executed_at_utc": "<ISO-8601>"
}
```
