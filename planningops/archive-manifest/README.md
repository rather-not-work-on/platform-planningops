# planningops/archive-manifest

## Purpose
Store deterministic pointer manifests for archived memory records so future rehydrate commands can restore or inspect long-term context without searching raw history.

## Contract
- one manifest per archived source document
- manifest path is the canonical `archive_ref`
- manifest must validate against `planningops/schemas/memory-archive-manifest.schema.json`
- manifest fields stay repo-root-relative so local and CI paths resolve the same way
