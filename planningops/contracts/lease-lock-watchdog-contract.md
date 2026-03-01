# Lease Lock and Watchdog Contract

## Goal
Prevent duplicate issue execution and detect stale/zombie lock state.

## Lock Path
- `planningops/artifacts/loop-runner/locks/issue-<issue_number>.lock.json`

## Lock Fields
- `issue_number`
- `owner_id`
- `acquired_at_utc`
- `last_heartbeat_utc`
- `expires_at_utc`

## Rules
- Only one active lock per issue is allowed.
- If active lock is not expired, new run must fail with lock conflict.
- Expired lock may be reclaimed as stale recovery.
- Owner must refresh heartbeat at stage boundaries.
- Owner must release lock on completion or controlled interruption.

## Watchdog Report
- `planningops/artifacts/loop-runner/watchdog/issue-<issue_number>.json`
- Must include:
  - `verdict` (`pass|interrupted|fail|lock_conflict`)
  - `events` timeline
  - `release_ok`
  - stale lock recovery signal when applicable
