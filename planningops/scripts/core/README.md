# planningops/scripts/core

## Purpose
Hold canonical core loop modules that implement planningops control-plane logic without repo-specific federation mappings.

## Contents
- `loop/`: issue loop runner internals split by responsibility

## Change Rules
- Core modules must not own repo-specific execution mappings.
- Root compatibility wrappers must continue to dispatch to canonical core modules until deprecation gates say otherwise.
- New core modules should expose deterministic functions that remain reusable from wrapper entrypoints and tests.
