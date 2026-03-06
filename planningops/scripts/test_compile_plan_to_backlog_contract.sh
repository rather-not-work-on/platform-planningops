#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path
from urllib.parse import parse_qs, urlsplit


module_path = Path("planningops/scripts/compile_plan_to_backlog.py")
spec = importlib.util.spec_from_file_location("compile_plan_to_backlog", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

fixture_doc = json.loads(Path("planningops/fixtures/plan-execution-contract-sample.json").read_text(encoding="utf-8"))
item = fixture_doc["execution_contract"]["items"][0]
item_with_lane = json.loads(json.dumps(item))
item_with_lane["plan_lane"] = "m1_contract_freeze"

# 1) Base fixture contract must validate.
assert mod.validate_contract(fixture_doc) == []

# 2) Unknown dependency order must fail validation.
bad_doc = json.loads(json.dumps(fixture_doc))
bad_doc["execution_contract"]["items"][0]["depends_on"] = [999]
errors = mod.validate_contract(bad_doc)
assert any("references unknown execution_order: 999" in e for e in errors), errors

# 3) Issue body must carry canonical planning metadata.
issue_body = mod.issue_body(
    fixture_doc["execution_contract"]["source_of_truth"],
    fixture_doc["execution_contract"]["plan_id"],
    fixture_doc["execution_contract"]["plan_revision"],
    item,
)
for token in [
    "plan_doc:",
    "plan_id:",
    "plan_revision:",
    "plan_item_id:",
    "execution_order:",
    "workflow_state:",
    "loop_profile:",
    "primary_output:",
]:
    assert token in issue_body, issue_body

# 4) Issue list pagination should aggregate every page and keep marker search stable.
pages = {1: [], 2: []}
for i in range(1, 101):
    body = "no marker"
    if i == 2:
        body = "\n".join(
            [
                "- plan_id: `plan-a`",
                "- plan_item_id: `sample-001`",
                "- target_repo: `rather-not-work-on/platform-planningops`",
            ]
        )
    pages[1].append(
        {
            "number": i,
            "title": f"issue-{i}",
            "body": body,
            "html_url": f"https://github.com/rather-not-work-on/platform-planningops/issues/{i}",
            "state": "open",
        }
    )
pages[2].append(
    {
        "number": 101,
        "title": "issue-101",
        "body": "no marker",
        "html_url": "https://github.com/rather-not-work-on/platform-planningops/issues/101",
        "state": "open",
    }
)
pages[3] = []


def fake_run_for_issue_pages(cmd, input_text=None):
    if cmd[:2] != ["gh", "api"]:
        raise AssertionError(f"unexpected command: {cmd}")
    endpoint = cmd[2]
    page = int(parse_qs(urlsplit(f"https://api.github.local/{endpoint}").query)["page"][0])
    return 0, json.dumps(pages[page]), ""


mod.run = fake_run_for_issue_pages
open_issues = mod.list_existing_issues("rather-not-work-on/platform-planningops", "open")
assert len(open_issues) == 101, len(open_issues)
match, strategy = mod.find_issue_for_item(
    open_issues,
    "plan-a",
    "sample-001",
    "rather-not-work-on/platform-planningops",
)
assert match and match["number"] == 2, match
assert strategy == "identity_exact", strategy

# 4-1) Cross-plan collision must resolve by plan_id scope.
colliding_issues = [
    {
        "number": 710,
        "title": "plan-a issue",
        "body": "\n".join(
            [
                "- plan_id: `plan-a`",
                "- plan_item_id: `sample-001`",
                "- target_repo: `rather-not-work-on/platform-planningops`",
            ]
        ),
        "url": "https://github.com/rather-not-work-on/platform-planningops/issues/710",
        "state": "open",
    },
    {
        "number": 711,
        "title": "plan-b issue",
        "body": "\n".join(
            [
                "- plan_id: `plan-b`",
                "- plan_item_id: `sample-001`",
                "- target_repo: `rather-not-work-on/platform-planningops`",
            ]
        ),
        "url": "https://github.com/rather-not-work-on/platform-planningops/issues/711",
        "state": "open",
    },
]
match_b, strategy_b = mod.find_issue_for_item(
    colliding_issues,
    "plan-b",
    "sample-001",
    "rather-not-work-on/platform-planningops",
)
assert match_b["number"] == 711, match_b
assert strategy_b == "identity_exact", strategy_b

# 4-2) Duplicate identity rows must fail fast.
duplicate_identity = colliding_issues + [
    {
        "number": 712,
        "title": "plan-b duplicate",
        "body": "\n".join(
            [
                "- plan_id: `plan-b`",
                "- plan_item_id: `sample-001`",
                "- target_repo: `rather-not-work-on/platform-planningops`",
            ]
        ),
        "url": "https://github.com/rather-not-work-on/platform-planningops/issues/712",
        "state": "open",
    }
]
try:
    mod.find_issue_for_item(
        duplicate_identity,
        "plan-b",
        "sample-001",
        "rather-not-work-on/platform-planningops",
    )
    raise AssertionError("expected duplicate identity RuntimeError")
except RuntimeError as exc:
    assert "multiple open issues matched identity" in str(exc), exc

# 5) Dry-run compile should create deterministic DRY-RUN issue projection when unmatched.
dry_result = mod.compile_item(
    project={},
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item,
    apply_mode=False,
    open_issues=[],
    closed_issues=[],
    allow_reopen_closed=False,
    project_item_issue_index={},
)
assert dry_result["created_issue"] is True, dry_result
assert dry_result["issue_number"] is None, dry_result
assert dry_result["issue_url"].endswith("/DRY-RUN-1"), dry_result
assert "status(todo)" in dry_result["field_updates"], dry_result

dry_with_lane = mod.compile_item(
    project={},
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item_with_lane,
    apply_mode=False,
    open_issues=[],
    closed_issues=[],
    allow_reopen_closed=False,
    project_item_issue_index={},
)
assert "plan_lane(m1_contract_freeze)" in dry_with_lane["field_updates"], dry_with_lane

# 6) Closed-match default must not reuse; allow flag must reuse.
closed_issue = {
    "number": 901,
    "url": "https://github.com/rather-not-work-on/platform-planningops/issues/901",
    "body": "\n".join(
        [
            "- plan_id: `sample-pec-plan`",
            "- plan_item_id: `sample-001`",
            "- target_repo: `rather-not-work-on/platform-planningops`",
        ]
    ),
    "state": "closed",
}
default_dry = mod.compile_item(
    project={},
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item,
    apply_mode=False,
    open_issues=[],
    closed_issues=[closed_issue],
    allow_reopen_closed=False,
    project_item_issue_index={},
)
assert default_dry["created_issue"] is True, default_dry
assert default_dry["reused_closed_issue"] is False, default_dry

allow_dry = mod.compile_item(
    project={},
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item,
    apply_mode=False,
    open_issues=[],
    closed_issues=[closed_issue],
    allow_reopen_closed=True,
    project_item_issue_index={},
)
assert allow_dry["created_issue"] is False, allow_dry
assert allow_dry["reused_closed_issue"] is True, allow_dry
assert allow_dry["reopened_closed_issue"] is False, allow_dry
assert allow_dry["issue_number"] == 901, allow_dry

# 7) Apply-mode closed reuse must reopen issue and project mapped fields.
reopen_calls = []
edit_calls = []


def fake_reopen_issue(repo, issue_number):
    reopen_calls.append((repo, issue_number))


def fake_edit_issue(repo, issue_number, title, body):
    edit_calls.append((repo, issue_number, title, body))


mod.reopen_issue = fake_reopen_issue
mod.edit_issue = fake_edit_issue
mod.ensure_project_item = lambda owner, project_number, issue_url: "PVTI_TEST_1"
mod.set_text_field = lambda *args, **kwargs: None
mod.set_number_field = lambda *args, **kwargs: None
mod.set_select_field = lambda *args, **kwargs: None

project = {
    "owner": "rather-not-work-on",
    "project_number": 2,
    "project_id": "PVT_TEST",
    "initiative": "unified-personal-agent-platform",
    "fields": {
        "initiative": {"id": "F_INIT"},
        "target_repo": {"id": "F_REPO"},
        "execution_order": {"id": "F_ORDER"},
        "status": {"id": "F_STATUS", "options": {"todo": "O_TODO", "in_progress": "O_IP", "blocked": "O_BLOCK", "done": "O_DONE"}},
        "component": {"id": "F_COMPONENT", "options": {"planningops": "O_COMPONENT_PLAN"}},
        "workflow_state": {"id": "F_WF", "options": {"ready_contract": "O_WF_READY_CONTRACT"}},
        "loop_profile": {"id": "F_LOOP", "options": {"l1_contract_clarification": "O_LOOP_L1"}},
        "plan_lane": {"id": "F_LANE", "options": {"m1_contract_freeze": "O_LANE_M1"}},
    },
}

apply_result = mod.compile_item(
    project=project,
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item_with_lane,
    apply_mode=True,
    open_issues=[],
    closed_issues=[closed_issue],
    allow_reopen_closed=True,
    project_item_issue_index={},
)
assert reopen_calls == [(mod.CONTROL_REPO, 901)], reopen_calls
assert apply_result["created_issue"] is False, apply_result
assert apply_result["reused_closed_issue"] is True, apply_result
assert apply_result["reopened_closed_issue"] is True, apply_result
assert apply_result["issue_number"] == 901, apply_result
assert apply_result["metadata_sync_required"] is True, apply_result
assert apply_result["metadata_sync_action"] == "applied", apply_result
assert len(edit_calls) == 1, edit_calls
assert set(["initiative", "target_repo", "execution_order", "status", "component", "workflow_state", "loop_profile"]).issubset(
    set(apply_result["field_updates"])
), apply_result
assert "plan_lane" in apply_result["field_updates"], apply_result

# 8) Existing open issue drift should request/perform metadata sync.
stale_open_issue = {
    "number": 902,
    "title": "stale title",
    "url": "https://github.com/rather-not-work-on/platform-planningops/issues/902",
    "body": "\n".join(
        [
            "- plan_id: `sample-pec-plan`",
            "- plan_item_id: `sample-001`",
            "- target_repo: `rather-not-work-on/platform-planningops`",
            "- execution_order: `999`",
        ]
    ),
    "state": "open",
}
dry_sync = mod.compile_item(
    project={},
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item,
    apply_mode=False,
    open_issues=[dict(stale_open_issue)],
    closed_issues=[],
    allow_reopen_closed=False,
    project_item_issue_index={},
)
assert dry_sync["created_issue"] is False, dry_sync
assert dry_sync["metadata_sync_required"] is True, dry_sync
assert dry_sync["metadata_sync_action"] == "planned", dry_sync

edit_calls.clear()
apply_sync = mod.compile_item(
    project=project,
    source_of_truth=fixture_doc["execution_contract"]["source_of_truth"],
    plan_id=fixture_doc["execution_contract"]["plan_id"],
    plan_revision=fixture_doc["execution_contract"]["plan_revision"],
    item=item_with_lane,
    apply_mode=True,
    open_issues=[dict(stale_open_issue)],
    closed_issues=[],
    allow_reopen_closed=False,
    project_item_issue_index={},
)
assert apply_sync["created_issue"] is False, apply_sync
assert apply_sync["metadata_sync_required"] is True, apply_sync
assert apply_sync["metadata_sync_action"] == "applied", apply_sync
assert len(edit_calls) == 1, edit_calls

# 9) create_issue must pass issue body via --body.
captured = {}


def fake_run_for_create(cmd, input_text=None):
    captured["cmd"] = cmd
    captured["input_text"] = input_text
    return 0, "https://github.com/rather-not-work-on/platform-planningops/issues/999", ""


mod.run = fake_run_for_create
created_url = mod.create_issue("rather-not-work-on/platform-planningops", "title", "line1\nline2")
assert created_url.endswith("/999"), created_url
assert "--body" in captured["cmd"], captured
assert captured["cmd"][-1] == "line1\nline2", captured
assert captured["input_text"] is None, captured

# 10) main() must sort by execution_order and keep dry-run deterministic.
mod.list_existing_issues = lambda repo, state: []
with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    contract_path = td_path / "contract.json"
    config_path = td_path / "project-config.json"
    out_path = td_path / "report.json"

    unsorted_doc = {
        "execution_contract": {
            "plan_id": "pec-main-order-test",
            "plan_revision": 2,
            "source_of_truth": "docs/workbench/unified-personal-agent-platform/plans/example.md",
            "items": [
                {
                    "plan_item_id": "late",
                    "execution_order": 20,
                    "title": "later",
                    "target_repo": "rather-not-work-on/platform-planningops",
                    "component": "planningops",
                    "workflow_state": "ready_contract",
                    "loop_profile": "l1_contract_clarification",
                    "depends_on": [10],
                    "primary_output": "planningops/contracts/later.md",
                },
                {
                    "plan_item_id": "early",
                    "execution_order": 10,
                    "title": "earlier",
                    "target_repo": "rather-not-work-on/platform-planningops",
                    "component": "planningops",
                    "workflow_state": "ready_contract",
                    "loop_profile": "l1_contract_clarification",
                    "depends_on": [],
                    "primary_output": "planningops/contracts/early.md",
                },
            ],
        }
    }

    config_doc = {
        "owner": "rather-not-work-on",
        "project_number": 2,
        "project_id": "PVT_TEST",
        "initiative": "unified-personal-agent-platform",
        "fields": {},
    }

    contract_path.write_text(json.dumps(unsorted_doc, ensure_ascii=True), encoding="utf-8")
    config_path.write_text(json.dumps(config_doc, ensure_ascii=True), encoding="utf-8")

    argv_before = list(sys.argv)
    sys.argv = [
        "compile_plan_to_backlog.py",
        "--contract-file",
        str(contract_path),
        "--config",
        str(config_path),
        "--output",
        str(out_path),
    ]
    rc = mod.main()
    sys.argv = argv_before
    assert rc == 0, rc

    report = json.loads(out_path.read_text(encoding="utf-8"))
    assert report["verdict"] == "pass", report
    assert [row["execution_order"] for row in report["results"]] == [10, 20], report

print("compile_plan_to_backlog contract tests ok")
PY
