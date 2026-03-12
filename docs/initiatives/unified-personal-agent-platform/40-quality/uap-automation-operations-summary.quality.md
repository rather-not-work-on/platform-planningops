---
doc_id: uap-automation-operations-summary
title: UAP Automation Operations Summary
doc_type: quality
domain: quality
status: active
date: 2026-03-11
updated: 2026-03-13
initiative: unified-personal-agent-platform
memory_tier: L1
tags:
  - uap
  - automation
  - planningops
  - supervisor
  - standup
summary: Canonical operating summary for active Codex automations, their role boundaries, the resolved local-only failure mode, and current execution rules.
related_docs:
  - ../README.md
  - ./uap-planningops-tradeoff-decision-framework.quality.md
  - ../../../workbench/unified-personal-agent-platform/audits/federated-reconciliation-report-20260311.md
  - ../../../archive/README.md
---

# UAP Automation Operations Summary

## Purpose
Keep active automation behavior compact and current so long-running loops do not keep acting on stale blocker memory.

## Active Automations
### Overnight UAP
- role: execution automation for `platform-planningops`, `monday`, `platform-provider-gateway`, `platform-observability-gateway`, and `platform-contracts`
- authority:
  - branch create/switch
  - commit/push
  - PR create/edit
  - PR body repair for `template-and-link-check`
  - check monitoring
  - merge and post-merge sync
  - issue/project field sync
- boundary:
  - keep `planningops` as control tower only
  - move execution logic into owning repos
  - stop only for irreversible decisions, missing credentials, or manual external actions

### Standup Summary
- role: observational automation only
- authority:
  - read git history
  - summarize prior-day activity
- boundary:
  - no repo mutation
  - no issue/project mutation
  - no PR/merge activity

## Current State
Last manually re-verified on `2026-03-11` KST.

- GitHub auth is healthy for the operator account.
- GitHub API rate limit is healthy.
- `git ls-remote` to `origin` succeeds.
- all five managed repos currently report `0` open issues.
- automation worktree roots use the space-free symlink `/Users/minijb/rather-not-work-on`.

## Resolved Failure Mode
The earlier local-only behavior was not caused by git permissions.

- failure source: worktree execution rooted under `/Volumes/T7 Touch/...`
- failure symptom: cwd truncation at the first space
- observed error: `fatal: cannot change to '/Volumes/T7'`
- mitigation:
  - automation `cwds` moved to `/Users/minijb/rather-not-work-on`
  - execution prompt now requires remote reconciliation when auth/network are healthy
  - automation memory must treat auth/network blockers as stale unless re-verified in the current run

## Operating Rules
1. Re-check GitHub auth, connectivity, and rate limits at the start of every run.
2. If remote operations are healthy, do not stop at local validation or local commits.
3. Finish the full remote lifecycle in the same run whenever work is mergeable:
   - push
   - PR create or update
   - template/link repair
   - check monitoring
   - merge
   - local main sync
   - feature branch cleanup
   - issue/project field sync
4. If all repos are clean and no open issue is ready, regenerate or re-triage backlog from `planningops` instead of inventing repo-local work.
   - canonical command: `python3 planningops/scripts/core/backlog/materialize.py --contract-file <execution-contract.json>`
   - dry-run expectation: the command must project local issues first, then run label backfill / manifest / issue-quality against that projected issue set instead of depending on pre-existing live GitHub issues
5. Supervisor runs may opt into automatic backlog regeneration on replanning paths.
   - canonical command: `python3 planningops/scripts/autonomous_supervisor_loop.py --mode apply --auto-materialize-backlog --backlog-materialization-contract-file <execution-contract.json>`
   - dry-run expectation: materialization reports should be attached to the supervisor cycle and surfaced as review guidance rather than being treated as a quality failure
6. Keep durable conclusions in canonical docs or workbench audits; keep automation memory short and current.

## Reflected Outcomes
- execution-repo remote reconciliation completed for:
  - `platform-contracts` PR `#13`
  - `platform-provider-gateway` PR `#22`
  - `platform-observability-gateway` PR `#22`
  - `monday` PR `#24`
- PlanningOps reconciliation follow-up completed through PR `#272`.
- The remaining automation memory should therefore describe current operating truth, not archived blocker logs.

## Verification
- `gh auth status`
- `gh api rate_limit`
- `git ls-remote --heads origin`
- `gh issue list --state open` across the five managed repos
- `python3 planningops/scripts/core/backlog/materialize.py --contract-file <execution-contract.json>`
- `python3 planningops/scripts/autonomous_supervisor_loop.py --mode apply --auto-materialize-backlog --backlog-materialization-contract-file <execution-contract.json>`
- `python3 planningops/scripts/backfill_issue_labels.py --repo rather-not-work-on/platform-planningops --issues-file /tmp/projected-issues.json --write-updated-issues-file /tmp/projected-issues.json --output /tmp/issue-label-backfill-report.json --apply`
