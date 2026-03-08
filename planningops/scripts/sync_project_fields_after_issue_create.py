#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from planning_context import parse_execution_order, parse_metadata


DEFAULT_CONFIG = Path("planningops/config/project-field-ids.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/project-field-sync-after-create-report.json")
DEFAULT_REPOS = [
    "rather-not-work-on/platform-planningops",
    "rather-not-work-on/platform-contracts",
    "rather-not-work-on/platform-provider-gateway",
    "rather-not-work-on/platform-observability-gateway",
    "rather-not-work-on/monday",
]
DEFAULT_PLAN_ITEM_REGEX = r"^[A-Z][0-9]{2}$"
WORKFLOW_TO_STATUS = {
    "backlog": "todo",
    "ready_contract": "todo",
    "ready_implementation": "todo",
    "in_progress": "in_progress",
    "review_gate": "in_progress",
    "blocked": "blocked",
    "done": "done",
}


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_config(path: Path):
    doc = load_json(path)
    return {
        "owner": doc["owner"],
        "project_number": int(doc["project_number"]),
        "project_id": doc["project_id"],
        "initiative": doc["initiative"],
        "fields": doc["fields"],
    }


def normalize_option_key(value: str):
    if value is None:
        return ""
    normalized = str(value).strip().strip("`")
    normalized = normalized.replace("-", "_")
    normalized = re.sub(r"\s+", "_", normalized)
    normalized = normalized.lower()
    return normalized

def parse_issue_ref(raw: str):
    value = str(raw).strip()
    match = re.match(r"^([^#\s]+/[^#\s]+)#(\d+)$", value)
    if not match:
        raise ValueError(f"invalid issue ref: {raw} (expected owner/repo#number)")
    return match.group(1), int(match.group(2))


def list_open_issues(repo: str):
    rc, out, err = run(["gh", "issue", "list", "--repo", repo, "--state", "open", "--limit", "200", "--json", "number,title,url,body"])
    if rc != 0:
        raise RuntimeError(f"failed to list issues for {repo}: {err}")
    rows = json.loads(out)
    issues = []
    for row in rows:
        issues.append(
            {
                "repo": repo,
                "number": int(row["number"]),
                "title": row.get("title") or "",
                "url": row.get("url") or "",
                "body": row.get("body") or "",
            }
        )
    return issues


def get_issue(repo: str, number: int):
    rc, out, err = run(["gh", "issue", "view", str(number), "--repo", repo, "--json", "number,title,url,body"])
    if rc != 0:
        raise RuntimeError(f"failed to read issue {repo}#{number}: {err}")
    row = json.loads(out)
    return {
        "repo": repo,
        "number": int(row["number"]),
        "title": row.get("title") or "",
        "url": row.get("url") or "",
        "body": row.get("body") or "",
    }


def load_project_items_page(owner: str, project_number: int, cursor=None):
    query = (
        "query($owner: String!, $number: Int!, $cursor: String) { "
        "repositoryOwner(login: $owner) { "
        "... on ProjectV2Owner { "
        "projectV2(number: $number) { "
        "items(first: 100, after: $cursor) { "
        "nodes { id content { __typename ... on Issue { number repository { nameWithOwner } } } } "
        "pageInfo { hasNextPage endCursor } "
        "} } } } }"
    )
    cmd = ["gh", "api", "graphql", "-f", f"query={query}", "-F", f"owner={owner}", "-F", f"number={project_number}"]
    if cursor is not None:
        cmd.extend(["-F", f"cursor={cursor}"])
    rc, out, err = run(cmd)
    if rc != 0:
        raise RuntimeError(f"failed to query project items page: {err}")
    doc = json.loads(out)
    if doc.get("errors"):
        raise RuntimeError(f"project items graphql errors: {doc['errors']}")
    project = ((doc.get("data") or {}).get("repositoryOwner") or {}).get("projectV2") or {}
    if not project:
        raise RuntimeError("projectV2 not found while listing project items")
    items = (project.get("items") or {}).get("nodes") or []
    page_info = (project.get("items") or {}).get("pageInfo") or {}
    return items, page_info


def build_project_item_issue_index(owner: str, project_number: int):
    issue_index = {}
    cursor = None
    while True:
        items, page_info = load_project_items_page(owner, project_number, cursor=cursor)
        for item in items:
            content = item.get("content") or {}
            if content.get("__typename") != "Issue":
                continue
            number = content.get("number")
            repo_name = (content.get("repository") or {}).get("nameWithOwner")
            if number is None or not repo_name:
                continue
            issue_index[(int(number), repo_name)] = item.get("id")
        if not page_info.get("hasNextPage"):
            break
        cursor = page_info.get("endCursor")
        if not cursor:
            break
    return issue_index


def ensure_project_item(owner: str, project_number: int, issue_url: str):
    rc, out, err = run(
        [
            "gh",
            "project",
            "item-add",
            str(project_number),
            "--owner",
            owner,
            "--url",
            issue_url,
            "--format",
            "json",
        ]
    )
    if rc != 0 and "already exists" not in err.lower():
        raise RuntimeError(f"failed to add issue to project: {err}")
    if out:
        try:
            doc = json.loads(out)
            if doc.get("id"):
                return doc["id"]
        except json.JSONDecodeError:
            pass
    return None


def find_project_item_id(owner: str, project_number: int, issue_number: int, issue_repo: str, issue_index: dict):
    key = (issue_number, issue_repo)
    item_id = issue_index.get(key)
    if item_id:
        return item_id
    refreshed = build_project_item_issue_index(owner, project_number)
    issue_index.clear()
    issue_index.update(refreshed)
    return issue_index.get(key)


def set_text_field(project_id: str, item_id: str, field_id: str, text: str):
    rc, _, err = run(
        [
            "gh",
            "project",
            "item-edit",
            "--id",
            item_id,
            "--project-id",
            project_id,
            "--field-id",
            field_id,
            "--text",
            text,
        ]
    )
    if rc != 0:
        raise RuntimeError(err)


def set_number_field(project_id: str, item_id: str, field_id: str, number_value: int):
    rc, _, err = run(
        [
            "gh",
            "project",
            "item-edit",
            "--id",
            item_id,
            "--project-id",
            project_id,
            "--field-id",
            field_id,
            "--number",
            str(number_value),
        ]
    )
    if rc != 0:
        raise RuntimeError(err)


def set_select_field(project_id: str, item_id: str, field_id: str, option_id: str):
    rc, _, err = run(
        [
            "gh",
            "project",
            "item-edit",
            "--id",
            item_id,
            "--project-id",
            project_id,
            "--field-id",
            field_id,
            "--single-select-option-id",
            option_id,
        ]
    )
    if rc != 0:
        raise RuntimeError(err)


def field_option_id(fields: dict, field_key: str, option_key: str):
    field = fields.get(field_key) or {}
    options = field.get("options") or {}
    option_id = options.get(option_key)
    if not option_id:
        raise KeyError(f"missing option id: {field_key}.{option_key}")
    return field["id"], option_id

def collect_candidates(args):
    plan_item_re = re.compile(args.plan_item_regex)
    if args.issue_ref:
        rows = []
        for raw_ref in args.issue_ref:
            repo, number = parse_issue_ref(raw_ref)
            issue = get_issue(repo, number)
            metadata = parse_metadata(issue["body"])
            issue["metadata"] = metadata
            rows.append(issue)
        return rows

    repos = [x.strip() for x in args.repos.split(",") if x.strip()]
    rows = []
    for repo in repos:
        for issue in list_open_issues(repo):
            metadata = parse_metadata(issue["body"])
            plan_item_id = metadata.get("plan_item_id", "")
            if not plan_item_id:
                continue
            if not plan_item_re.search(plan_item_id):
                continue
            issue["metadata"] = metadata
            rows.append(issue)
    return rows


def sync_one_issue(project: dict, issue: dict, apply_mode: bool, issue_index: dict):
    fields = project["fields"]
    metadata = issue["metadata"]
    plan_item_id = metadata.get("plan_item_id", "")
    raw_component = metadata.get("component", "")
    raw_workflow = metadata.get("workflow_state", "")
    raw_plan_lane = metadata.get("plan_lane", "")

    component = normalize_option_key(raw_component)
    workflow_state = normalize_option_key(raw_workflow)
    plan_lane = normalize_option_key(raw_plan_lane)
    loop_profile = normalize_option_key(metadata.get("loop_profile", ""))
    execution_order = parse_execution_order(metadata.get("execution_order"))
    target_repo = metadata.get("target_repo") or issue["repo"]

    result = {
        "plan_item_id": plan_item_id,
        "issue_repo": issue["repo"],
        "issue_number": issue["number"],
        "issue_url": issue["url"],
        "component": component,
        "workflow_state": workflow_state,
        "plan_lane": plan_lane,
        "field_updates": [],
    }

    missing = []
    if not component:
        missing.append("component")
    if not workflow_state:
        missing.append("workflow_state")
    if not plan_lane:
        missing.append("plan_lane")
    if missing:
        raise RuntimeError(f"missing metadata keys: {','.join(missing)}")

    status_key = WORKFLOW_TO_STATUS.get(workflow_state)
    if not status_key:
        raise RuntimeError(f"unsupported workflow_state: {workflow_state}")

    if not apply_mode:
        result["field_updates"].extend(
            [
                f"component({component})",
                f"workflow_state({workflow_state})",
                f"plan_lane({plan_lane})",
            ]
        )
        return result

    item_id = ensure_project_item(project["owner"], project["project_number"], issue["url"])
    if not item_id:
        item_id = find_project_item_id(
            project["owner"],
            project["project_number"],
            issue["number"],
            issue["repo"],
            issue_index,
        )
    if not item_id:
        raise RuntimeError("could not resolve project item id")

    if "initiative" in fields and fields["initiative"].get("id"):
        set_text_field(project["project_id"], item_id, fields["initiative"]["id"], project["initiative"])
        result["field_updates"].append("initiative")
    if "target_repo" in fields and fields["target_repo"].get("id"):
        set_text_field(project["project_id"], item_id, fields["target_repo"]["id"], target_repo)
        result["field_updates"].append("target_repo")
    if execution_order is not None and "execution_order" in fields and fields["execution_order"].get("id"):
        set_number_field(project["project_id"], item_id, fields["execution_order"]["id"], execution_order)
        result["field_updates"].append("execution_order")

    status_field_id, status_option_id = field_option_id(fields, "status", status_key)
    set_select_field(project["project_id"], item_id, status_field_id, status_option_id)
    result["field_updates"].append("status")

    comp_field_id, comp_option_id = field_option_id(fields, "component", component)
    set_select_field(project["project_id"], item_id, comp_field_id, comp_option_id)
    result["field_updates"].append("component")

    workflow_field_id, workflow_option_id = field_option_id(fields, "workflow_state", workflow_state)
    set_select_field(project["project_id"], item_id, workflow_field_id, workflow_option_id)
    result["field_updates"].append("workflow_state")

    lane_field_id, lane_option_id = field_option_id(fields, "plan_lane", plan_lane)
    set_select_field(project["project_id"], item_id, lane_field_id, lane_option_id)
    result["field_updates"].append("plan_lane")

    if loop_profile and "loop_profile" in fields:
        loop_field_id, loop_option_id = field_option_id(fields, "loop_profile", loop_profile)
        set_select_field(project["project_id"], item_id, loop_field_id, loop_option_id)
        result["field_updates"].append("loop_profile")

    return result


def main():
    parser = argparse.ArgumentParser(
        description="Sync GitHub Project fields (plan_lane/workflow_state/component) from issue metadata after issue creation"
    )
    parser.add_argument("--config", default=str(DEFAULT_CONFIG), help="Project field config JSON path")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Output report path")
    parser.add_argument("--apply", action="store_true", help="Apply GitHub mutations (default dry-run)")
    parser.add_argument(
        "--repos",
        default=",".join(DEFAULT_REPOS),
        help="Comma-separated repo list for candidate scan (ignored when --issue-ref is used)",
    )
    parser.add_argument(
        "--plan-item-regex",
        default=DEFAULT_PLAN_ITEM_REGEX,
        help="Regex to filter plan_item_id (default: ^[A-Z][0-9]{2}$)",
    )
    parser.add_argument(
        "--issue-ref",
        action="append",
        default=[],
        help="Explicit issue refs (owner/repo#number). Can be repeated.",
    )
    args = parser.parse_args()

    project = load_config(Path(args.config))
    report = {
        "mode": "apply" if args.apply else "dry-run",
        "project_owner": project["owner"],
        "project_number": project["project_number"],
        "project_id": project["project_id"],
        "plan_item_regex": args.plan_item_regex,
        "issues_total": 0,
        "updated_count": 0,
        "error_count": 0,
        "results": [],
        "errors": [],
    }

    try:
        issues = collect_candidates(args)
        report["issues_total"] = len(issues)
        issue_index = {}
        for issue in issues:
            try:
                row = sync_one_issue(project, issue, args.apply, issue_index)
                report["results"].append(row)
                report["updated_count"] += 1
            except Exception as exc:  # noqa: BLE001
                report["error_count"] += 1
                report["errors"].append(
                    {
                        "issue_repo": issue["repo"],
                        "issue_number": issue["number"],
                        "issue_url": issue["url"],
                        "error": str(exc),
                    }
                )
    except Exception as exc:  # noqa: BLE001
        report["error_count"] += 1
        report["errors"].append({"error": str(exc)})

    report["verdict"] = "pass" if report["error_count"] == 0 else "fail"
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
