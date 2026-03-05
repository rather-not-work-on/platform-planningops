# Supervisor Experiment Decision Record

- generated_at_utc: 2026-03-05T12:05:57.956096+00:00
- selected_option: option-a
- rejected_options: option-b

## Score Table
| option | rc | correctness/safety | implementation complexity | maintainability/drift risk | rollback cost | weighted_total |
|---|---:|---:|---:|---:|---:|---:|
| option-a | 0 | 5 | 4 | 4 | 4 | 4.400 |
| option-b | 0 | 5 | 4 | 4 | 4 | 4.400 |

## Safety Gate Notes
- Safety threshold: correctness/safety >= 3 required.

## Rollback Plan
- Remove option branch/worktree artifacts and keep only selected option decision record.

## Follow-Up Tasks
- If selected option is `none`, create recovery backlog item with failing command evidence.