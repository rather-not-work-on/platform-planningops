# planningops/scripts/oneoff

## Purpose
Store non-recurring bootstrap/migration scripts that are intentionally not part of the steady-state loop runtime.

## Contents
- `bootstrap_two_track_backlog.py`: one-time backlog seeding utility used for initial track bootstrap.

## Change Rules
- One-off scripts must not be called from recurring CI/runtime loops.
- Root compatibility wrapper may exist under `planningops/scripts/` with identical filename.
- Promote to core/federation only when reused as recurring operation.
