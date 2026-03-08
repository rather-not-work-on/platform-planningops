---
title: Archive Root
type: hub
date: 2026-03-08
initiative: unified-personal-agent-platform
lifecycle: canonical
status: active
summary: Long-term archive root for memory records compacted out of active workbench usage.
---

# Archive Root

`docs/archive` stores archived markdown copies that have been compacted out of active working memory.

## Contract
- archive documents are immutable `L2` records
- archive copies must include `memory_tier: L2`
- archive copies must include `archive_ref` pointing at `planningops/archive-manifest/**`
- archive copies must include `compacted_into` pointing at the retained canonical summary or replacement

## Validation
```bash
python3 planningops/scripts/memory_archive.py --source <repo-relative-source> --compacted-into <repo-relative-target>
python3 planningops/scripts/validate_memory_archive_manifest.py --manifest <manifest-path> --schema planningops/schemas/memory-archive-manifest.schema.json --strict
```
