---
status: ready
priority: p2
issue_id: "032"
tags: [planningops, supervisor, experiment, worktree]
dependencies: ["030", "027", "029"]
---

# Supervisor Experiment Auto Executor

## Problem Statement
Supervisor currently emits experiment trigger artifacts, but does not yet execute comparative worktree branches automatically from that trigger.

## Findings
- Trigger detection is integrated, yet follow-through still depends on manual operator action.
- Converting trigger -> controlled experiment execution would reduce orchestration gaps.

## Proposed Solution
Implement an experiment auto-executor path that creates option worktrees, runs a fixed validation pack, and writes rubric-based decision artifacts.

## Acceptance Criteria
- [ ] Supervisor trigger can invoke worktree option scaffolding with deterministic naming.
- [ ] Validation pack runs for each option and captures per-option report JSON.
- [ ] Decision record includes selected/rejected options with weighted rubric scores.
- [ ] Failure mode and cleanup behavior are documented and contract-tested.
