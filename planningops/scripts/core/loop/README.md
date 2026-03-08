# planningops/scripts/core/loop

## Purpose
Keep the issue loop runner split into reusable core modules with explicit ownership boundaries.

## Contents
- `checkpoint_lock.py`: checkpoint persistence, lease lock, and runtime heartbeat helpers
- `selection.py`: issue selection, selector hints, blueprint refs, and loop-profile helpers
- `runner.py`: canonical issue loop runner module assembled from core helpers

## Change Rules
- Shared loop behavior should move here instead of growing the root wrapper entrypoint.
- Core loop modules must remain free of repo-specific adapter mappings; those belong under `planningops/scripts/federation/`.
- Compatibility for `planningops/scripts/issue_loop_runner.py` must be preserved until wrapper deprecation gates allow removal.
