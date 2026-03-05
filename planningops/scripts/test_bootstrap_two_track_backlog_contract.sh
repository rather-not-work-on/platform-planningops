#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
from urllib.parse import parse_qs, urlsplit
from pathlib import Path

module_path = Path("planningops/scripts/bootstrap_two_track_backlog.py")
spec = importlib.util.spec_from_file_location("bootstrap_two_track_backlog", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# 1) Issue pagination dedup (>200) should still find marker.
pages = {}
for page in range(1, 4):
    rows = []
    for i in range(100):
        issue_no = (page - 1) * 100 + i + 1
        body = "no marker"
        if issue_no == 250:
            body = "plan_item_id: `tt-hg-190`"
        rows.append(
            {
                "number": issue_no,
                "title": f"Issue {issue_no}",
                "body": body,
                "html_url": f"https://github.com/rather-not-work-on/platform-planningops/issues/{issue_no}",
                "state": "open",
            }
        )
    pages[page] = rows
pages[4] = []


def run_for_issue_pagination(cmd):
    if cmd[:2] != ["gh", "api"]:
        raise AssertionError(f"unexpected command: {cmd}")
    endpoint = cmd[2]
    page_values = parse_qs(urlsplit(f"https://api.github.local/{endpoint}").query).get("page", [])
    if not page_values:
        raise AssertionError(f"page missing: {endpoint}")
    page = int(page_values[0])
    return 0, json.dumps(pages[page]), ""


mod.run = run_for_issue_pagination
all_open = mod.list_existing_issues("rather-not-work-on/platform-planningops", "open")
match = mod.find_issue_for_item(all_open, "tt-hg-190")
assert len(all_open) == 300, len(all_open)
assert match and match["number"] == 250, match

# 2) Default open-only policy should not reuse closed matches.
plan_item = dict(mod.BACKLOG_ITEMS[0])
open_issues = []
closed_issues = [
    {
        "number": 900,
        "url": "https://github.com/rather-not-work-on/platform-planningops/issues/900",
        "body": f"plan_item_id: `{plan_item['plan_item_id']}`",
        "state": "closed",
    }
]
result_default = mod.execute_item(
    project={},
    item=plan_item,
    apply_mode=False,
    open_issues=open_issues,
    closed_issues=closed_issues,
    allow_reopen_closed=False,
    project_item_issue_index={},
)
assert result_default["created_issue"] is True, result_default
assert result_default["reused_closed_issue"] is False, result_default
assert result_default["reopened_closed_issue"] is False, result_default

# 3) Explicit allow flag should reuse closed issue and mark intent.
open_issues = []
closed_issues = [
    {
        "number": 901,
        "url": "https://github.com/rather-not-work-on/platform-planningops/issues/901",
        "body": f"plan_item_id: `{plan_item['plan_item_id']}`",
        "state": "closed",
    }
]
result_allow = mod.execute_item(
    project={},
    item=plan_item,
    apply_mode=False,
    open_issues=open_issues,
    closed_issues=closed_issues,
    allow_reopen_closed=True,
    project_item_issue_index={},
)
assert result_allow["created_issue"] is False, result_allow
assert result_allow["reused_closed_issue"] is True, result_allow
assert result_allow["reopened_closed_issue"] is False, result_allow
assert result_allow["issue_number"] == 901, result_allow

# 4) Project item index must span multiple pages (>500 style growth path).
responses = {
    None: (
        [
            {
                "id": "PVTI_first",
                "content": {
                    "__typename": "Issue",
                    "number": 10,
                    "repository": {"nameWithOwner": "rather-not-work-on/platform-planningops"},
                },
            }
        ],
        {"hasNextPage": True, "endCursor": "CURSOR_1"},
    ),
    "CURSOR_1": (
        [
            {
                "id": "PVTI_target",
                "content": {
                    "__typename": "Issue",
                    "number": 777,
                    "repository": {"nameWithOwner": "rather-not-work-on/platform-planningops"},
                },
            }
        ],
        {"hasNextPage": False, "endCursor": None},
    ),
}


mod.load_project_items_page = lambda owner, project_number, cursor=None: responses[cursor]
index = mod.build_project_item_issue_index("rather-not-work-on", 2)
assert index[(777, "rather-not-work-on/platform-planningops")] == "PVTI_target", index
item_id = mod.find_project_item_id(
    owner="rather-not-work-on",
    project_number=2,
    issue_number=777,
    issue_repo="rather-not-work-on/platform-planningops",
    project_item_issue_index={},
)
assert item_id == "PVTI_target", item_id

print("bootstrap two-track backlog contract tests ok")
PY
