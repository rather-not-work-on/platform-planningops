#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/issue_loop_runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

items = [
    {
        "status": "Todo",
        "workflow_state": "ready-contract",
        "execution_order": 20,
        "target_repo": "rather-not-work-on/platform-planningops",
        "content": {"type": "Issue", "number": 77, "repository": "rather-not-work-on/platform-planningops"},
    },
    {
        "status": "Todo",
        "workflow_state": "ready-contract",
        "execution_order": 10,
        "target_repo": "rather-not-work-on/monday",
        "content": {"type": "Issue", "number": 42, "repository": "rather-not-work-on/monday"},
    },
    {
        "status": "In Progress",
        "workflow_state": "in-progress",
        "execution_order": 30,
        "content": {"type": "Issue", "number": 100, "repository": "rather-not-work-on/platform-contracts"},
    },
    {
        "status": "Todo",
        "workflow_state": "backlog",
        "execution_order": 5,
        "content": {"type": "Issue", "number": 101, "repository": "rather-not-work-on/platform-provider-gateway"},
    },
]

allowed = {"ready-contract", "ready-implementation"}
candidates = mod.normalize_candidates(items, allowed)

assert [c["number"] for c in candidates] == [42, 77], candidates
assert candidates[0]["issue_repo"] == "rather-not-work-on/monday", candidates[0]
assert candidates[1]["issue_repo"] == "rather-not-work-on/platform-planningops", candidates[1]

selected = dict(candidates[1])
selected["deps"] = [41]
attempts = [
    {"number": 42, "issue_repo": "rather-not-work-on/monday", "result": "dependency_blocked"},
    {"number": 77, "issue_repo": "rather-not-work-on/platform-planningops", "result": "selected"},
]
trace = mod.build_selection_trace(candidates, selected, attempts, allowed)

assert trace["candidate_count"] == 2, trace
assert trace["selected"]["number"] == 77, trace
assert trace["selected"]["target_repo"] == "rather-not-work-on/platform-planningops", trace

event = {
    "transition_id": "loop-test-issue-77-intake-selection",
    "run_id": "loop-test-issue-77",
    "card_id": 77,
    "from_state": "Todo",
    "to_state": "ready-contract",
    "transition_reason": "intake.selection.target_repo",
    "actor_type": "agent",
    "actor_id": "issue-loop-runner",
    "decided_at_utc": "2026-02-28T00:00:00+00:00",
    "replanning_flag": False,
    "selection_trace": trace,
}

with tempfile.TemporaryDirectory() as td:
    log_path = Path(td) / "trace.ndjson"
    mod.append_ndjson(log_path, event)
    rows = [json.loads(line) for line in log_path.read_text(encoding="utf-8").splitlines() if line.strip()]
    assert len(rows) == 1, rows
    row = rows[0]
    for key in [
        "transition_id",
        "run_id",
        "card_id",
        "from_state",
        "to_state",
        "transition_reason",
        "actor_type",
        "actor_id",
        "decided_at_utc",
        "replanning_flag",
    ]:
        assert key in row, key
    assert row["selection_trace"]["selected"]["number"] == 77, row

print("issue_loop_runner multi-repo intake trace ok")
PY
