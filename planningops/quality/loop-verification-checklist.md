# Loop Verification Checklist and Result Format

## Checklist
- [ ] intake-check generated
- [ ] simulation report generated
- [ ] verification report generated
- [ ] transition log entry appended
- [ ] required contracts referenced
- [ ] dependency checks passed (or blocked reason recorded)
- [ ] feedback update attempted

## Result Format (JSON)
```json
{
  "issue_number": 0,
  "loop_id": "loop-<timestamp>-<issue>",
  "verdict": "pass|fail|inconclusive",
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
  "executed_at_utc": "<ISO-8601>"
}
```
