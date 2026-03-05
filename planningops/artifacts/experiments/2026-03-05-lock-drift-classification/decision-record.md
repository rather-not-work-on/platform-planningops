# Decision Record: exp-20260305-lock-drift-classification

- selected_option: A
- rejected_options: B
- generated_at_utc: 2026-03-05T11:23:59.716539+00:00

## Score Table
| Option | correctness/safety | complexity | maintainability | rollback | total |
|---|---:|---:|---:|---:|---:|
| A | 5 | 4 | 4 | 4 | 4.4 |
| B | 1 | 5 | 2 | 3 | 2.4 |

## Safety Gate Notes
- Option A rc=0: watchdog regression passed.
- Option B rc=1: watchdog regression failed (no runtime drift classification).

## Rollback Plan
- If Option A introduces unexpected noise, revert lock-drift classification changes and re-run reliability pack before reapply.

## Follow-up Tasks
- Keep runtime heartbeat + drift classification covered by required CI reliability pack (issue 025).