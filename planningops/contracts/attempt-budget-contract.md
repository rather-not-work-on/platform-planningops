# Attempt Budget Contract

## Goal
Bound loop retries per issue so repeated failures do not run indefinitely.

## Budget Fields
Issue body may define:
- `max_attempts`
- `max_duration_minutes`
- `max_token_budget`

## Defaults
If omitted, defaults are used:
- `max_attempts: 3`
- `max_duration_minutes: 30`
- `max_token_budget: 120000`

## Validation Rules
- values must be positive integers
- malformed or negative values are invalid
- invalid budget makes the card non-selectable until corrected

## Override Rule
- per-issue explicit fields override defaults
- missing fields keep default values

## Reference
- parser/validator implementation: `planningops/scripts/issue_loop_runner.py` (`parse_attempt_budget`)
