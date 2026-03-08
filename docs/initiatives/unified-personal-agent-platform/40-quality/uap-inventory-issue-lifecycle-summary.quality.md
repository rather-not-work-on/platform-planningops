---
doc_id: uap-inventory-issue-lifecycle-summary
title: UAP Inventory Issue Lifecycle Summary
doc_type: quality
domain: quality
status: active
date: 2026-03-08
updated: 2026-03-08
initiative: unified-personal-agent-platform
memory_tier: L1
tags:
  - uap
  - planningops
  - backlog
  - inventory
  - archive
summary: Canonical retained summary for inventory-only backlog records after compaction out of active queue views.
related_docs:
  - ../README.md
  - ../../../archive/README.md
---

# UAP Inventory Issue Lifecycle Summary

## Purpose
Inventory-only issues remain useful only while they hold active queue memory. After that they should become archived history, not open pseudo-work.

## Active Rule
- open inventory issues must stay `workflow_state=backlog`
- open inventory issues must declare `inventory_lifecycle=active`
- open inventory issues must not carry `archive_ref` or `compacted_into`

## Archived Rule
- archived inventory issues move to `workflow_state=done`
- archived inventory issues must be closed on GitHub
- archived inventory issues must declare `inventory_lifecycle=archived`
- archived inventory issues must point to:
  - `archive_ref` -> `planningops/archive-manifest/github-issues/**`
  - `compacted_into` -> this retained summary or another canonical replacement

## Stock-034 Compaction
- historical stock inventory issues `#86`, `#87`, `#88`, `#89` are compacted into this summary
- their detailed bodies remain recoverable through archive markdown copies and manifest-driven rehydrate
- archive manifests:
  - `planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-86.json`
  - `planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-87.json`
  - `planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-88.json`
  - `planningops/archive-manifest/github-issues/rather-not-work-on/platform-planningops/issue-89.json`

## Verification
- contract: `planningops/contracts/inventory-issue-lifecycle-contract.md`
- policy: `planningops/config/inventory-issue-lifecycle-policy.json`
- archive/audit tool: `planningops/scripts/inventory_issue_lifecycle.py`
