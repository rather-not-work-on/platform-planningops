# planningops/scripts/core/backlog

## Purpose
Hold recurring control-plane backlog materialization logic.

## Contents
- `materialize.py`
  - Canonical steady-state entrypoint for `execution contract -> issue materialization -> label backfill -> manifest refresh -> issue quality validation`.
  - Dry-run uses projected local issues so backlog regeneration stays deterministic before GitHub mutations are applied.

## Rules
- Keep backlog creation deterministic and contract-driven.
- Prefer composing existing backlog helpers over re-implementing GitHub mutation logic here.
- Write a regression test whenever the orchestration sequence or failure handling changes.
