#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path


CONTROL_REPO = "rather-not-work-on/platform-planningops"
PLAN_DOC = (
    "docs/workbench/unified-personal-agent-platform/plans/"
    "2026-03-02-plan-two-track-hard-gates-execution-plan.md"
)


BACKLOG_ITEMS = [
    {
        "plan_item_id": "tt-hg-100",
        "execution_order": 100,
        "title": "Gate contract and terminology lock",
        "track": "T1",
        "component": "planningops",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "ready_contract",
        "loop_profile": "l1_contract_clarification",
        "depends_on": [],
        "primary_output": "track1-contract-terminology-lock.md",
    },
    {
        "plan_item_id": "tt-hg-110",
        "execution_order": 110,
        "title": "Validation chain runner and evidence manifest",
        "track": "T1",
        "component": "planningops",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "ready_contract",
        "loop_profile": "l1_contract_clarification",
        "depends_on": [100],
        "primary_output": "track1-validation-chain-report.json",
    },
    {
        "plan_item_id": "tt-hg-120",
        "execution_order": 120,
        "title": "loop_profile drift and state-coverage hardening",
        "track": "T1",
        "component": "planningops",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "ready_contract",
        "loop_profile": "l2_simulation",
        "depends_on": [110],
        "primary_output": "track1-drift-reconcile-policy.md",
    },
    {
        "plan_item_id": "tt-hg-130",
        "execution_order": 130,
        "title": "Transition log schema and trigger evaluator alignment",
        "track": "T1",
        "component": "orchestrator",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "ready_contract",
        "loop_profile": "l2_simulation",
        "depends_on": [120],
        "primary_output": "transition-log-contract-report.md",
    },
    {
        "plan_item_id": "tt-hg-140",
        "execution_order": 140,
        "title": "KPI baseline capture run",
        "track": "T1",
        "component": "planningops",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "ready_implementation",
        "loop_profile": "l3_implementation_tdd",
        "depends_on": [130],
        "primary_output": "track1-kpi-baseline.json",
    },
    {
        "plan_item_id": "tt-hg-150",
        "execution_order": 150,
        "title": "Track 1 Exit Gate dry-run verdict x2",
        "track": "T1",
        "component": "planningops",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "review_gate",
        "loop_profile": "l3_implementation_tdd",
        "depends_on": [140],
        "primary_output": "track1-gate-dryrun-report.json",
    },
    {
        "plan_item_id": "tt-hg-160",
        "execution_order": 160,
        "title": "Monday target UX freeze",
        "track": "T2",
        "component": "runtime",
        "target_repo": "rather-not-work-on/monday",
        "workflow_state": "ready_contract",
        "loop_profile": "l2_simulation",
        "depends_on": [120],
        "primary_output": "monday-target-ux-scenarios.md",
    },
    {
        "plan_item_id": "tt-hg-170",
        "execution_order": 170,
        "title": "Infra local and OCI profile boundary map",
        "track": "T2",
        "component": "provider_gateway",
        "target_repo": "rather-not-work-on/platform-provider-gateway",
        "workflow_state": "ready_contract",
        "loop_profile": "l2_simulation",
        "depends_on": [120],
        "primary_output": "infra-profile-boundary-map.md",
    },
    {
        "plan_item_id": "tt-hg-180",
        "execution_order": 180,
        "title": "LangFuse integration boundary map",
        "track": "T2",
        "component": "observability_gateway",
        "target_repo": "rather-not-work-on/platform-observability-gateway",
        "workflow_state": "ready_contract",
        "loop_profile": "l2_simulation",
        "depends_on": [120],
        "primary_output": "langfuse-boundary-map.md",
    },
    {
        "plan_item_id": "tt-hg-190",
        "execution_order": 190,
        "title": "NanoClaw fit assessment and adapter strategy",
        "track": "T2",
        "component": "orchestrator",
        "target_repo": "rather-not-work-on/monday",
        "workflow_state": "ready_contract",
        "loop_profile": "l2_simulation",
        "depends_on": [160, 170, 180],
        "primary_output": "nanoclaw-fit-assessment.md",
    },
    {
        "plan_item_id": "tt-hg-200",
        "execution_order": 200,
        "title": "Track 2 implementation readiness packet",
        "track": "T2",
        "component": "runtime",
        "target_repo": "rather-not-work-on/monday",
        "workflow_state": "ready_implementation",
        "loop_profile": "l3_implementation_tdd",
        "depends_on": [150, 190],
        "primary_output": "track2-implementation-readiness-packet.md",
    },
    {
        "plan_item_id": "tt-hg-210",
        "execution_order": 210,
        "title": "Recovery and replan policy automation",
        "track": "cross",
        "component": "planningops",
        "target_repo": "rather-not-work-on/platform-planningops",
        "workflow_state": "blocked",
        "loop_profile": "l5_recovery_replan",
        "depends_on": [150],
        "primary_output": "replan-policy-automation-report.md",
    },
]


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


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_project_config(path: Path):
    doc = read_json(path)
    project = {
        "owner": doc["owner"],
        "project_number": doc["project_number"],
        "project_id": doc["project_id"],
        "initiative": doc["initiative"],
        "fields": doc["fields"],
    }
    return project


def issue_body(item):
    depends = ",".join(str(x) for x in item["depends_on"]) if item["depends_on"] else "-"
    return "\n".join(
        [
            "## Planning Context",
            f"- plan_doc: `{PLAN_DOC}`",
            f"- plan_item_id: `{item['plan_item_id']}`",
            f"- execution_order: `{item['execution_order']}`",
            f"- track: `{item['track']}`",
            f"- target_repo: `{item['target_repo']}`",
            f"- component: `{item['component']}`",
            f"- workflow_state: `{item['workflow_state']}`",
            f"- loop_profile: `{item['loop_profile']}`",
            f"- depends_on: `{depends}`",
            f"- primary_output: `{item['primary_output']}`",
            "",
            "## Definition of Done",
            "- [ ] Required artifact created",
            "- [ ] Validation report attached",
            "- [ ] Project fields updated with evidence",
        ]
    )


def list_existing_issues(repo: str, state: str):
    page = 1
    issues = []
    while True:
        rc, out, err = run(
            [
                "gh",
                "api",
                f"repos/{repo}/issues?state={state}&per_page=100&page={page}",
            ]
        )
        if rc != 0:
            raise RuntimeError(f"failed to list issues (state={state}, page={page}): {err}")
        batch = json.loads(out)
        if not batch:
            break
        for issue in batch:
            # REST /issues includes pull requests; skip to keep dedup strictly issue-based.
            if issue.get("pull_request"):
                continue
            issues.append(
                {
                    "number": issue.get("number"),
                    "title": issue.get("title", ""),
                    "body": issue.get("body") or "",
                    "url": issue.get("html_url"),
                    "state": issue.get("state", "").lower(),
                }
            )
        if len(batch) < 100:
            break
        page += 1
    return issues


def find_issue_for_item(issues, plan_item_id: str):
    marker = f"plan_item_id: `{plan_item_id}`"
    for issue in issues:
        if marker in (issue.get("body") or ""):
            return issue
    return None


def create_issue(repo: str, title: str, body: str):
    rc, out, err = run(
        [
            "gh",
            "issue",
            "create",
            "--repo",
            repo,
            "--title",
            title,
            "--body",
            body,
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to create issue: {err}")
    return out.strip()


def reopen_issue(repo: str, issue_number: int):
    rc, _, err = run(
        [
            "gh",
            "issue",
            "reopen",
            str(issue_number),
            "--repo",
            repo,
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to reopen issue #{issue_number}: {err}")


def normalize_workflow_key(key: str):
    return key.replace("-", "_")


def load_project_items_page(owner: str, project_number: int, cursor=None):
    query = (
        "query($owner: String!, $number: Int!, $cursor: String) { "
        "repositoryOwner(login: $owner) { "
        "__typename "
        "... on ProjectV2Owner { "
        "projectV2(number: $number) { "
        "items(first: 100, after: $cursor) { "
        "nodes { "
        "id "
        "content { "
        "__typename "
        "... on Issue { "
        "number "
        "repository { nameWithOwner } "
        "} "
        "} "
        "} "
        "pageInfo { hasNextPage endCursor } "
        "} "
        "} "
        "} "
        "} "
        "}"
    )
    cmd = [
        "gh",
        "api",
        "graphql",
        "-f",
        f"query={query}",
        "-F",
        f"owner={owner}",
        "-F",
        f"number={project_number}",
    ]
    if cursor is not None:
        cmd.extend(["-F", f"cursor={cursor}"])
    rc, out, err = run(cmd)
    if rc != 0:
        raise RuntimeError(f"failed to query project items page: {err}")
    doc = json.loads(out)
    if doc.get("errors"):
        raise RuntimeError(f"project items graphql errors: {doc['errors']}")
    root = (doc.get("data") or {}).get("repositoryOwner") or {}
    project = root.get("projectV2") or {}
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
            repo_doc = content.get("repository") or {}
            repo_name = repo_doc.get("nameWithOwner")
            if number is None or not repo_name:
                continue
            issue_index[(number, repo_name)] = item.get("id")
        if not page_info.get("hasNextPage"):
            break
        cursor = page_info.get("endCursor")
        if not cursor:
            break
    return issue_index


def find_project_item_id(
    owner: str,
    project_number: int,
    issue_number: int,
    issue_repo: str,
    project_item_issue_index: dict,
):
    key = (issue_number, issue_repo)
    item_id = project_item_issue_index.get(key)
    if item_id:
        return item_id
    refreshed = build_project_item_issue_index(owner, project_number)
    project_item_issue_index.clear()
    project_item_issue_index.update(refreshed)
    return project_item_issue_index.get(key)


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
            item_id = doc.get("id")
            if item_id:
                return item_id
        except json.JSONDecodeError:
            pass
    return None


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


def field_option_id(fields, field_key: str, option_key: str):
    field = fields[field_key]
    option_id = (field.get("options") or {}).get(option_key)
    if not option_id:
        raise KeyError(f"missing option id: {field_key}.{option_key}")
    return field["id"], option_id


def execute_item(
    project,
    item,
    apply_mode: bool,
    open_issues,
    closed_issues,
    allow_reopen_closed: bool,
    project_item_issue_index: dict,
):
    issue = find_issue_for_item(open_issues, item["plan_item_id"])
    reused_closed_issue = False
    reopened_closed_issue = False
    dedup_match_state = "open" if issue else None

    if issue is None and allow_reopen_closed:
        closed_issue = find_issue_for_item(closed_issues, item["plan_item_id"])
        if closed_issue:
            issue = dict(closed_issue)
            reused_closed_issue = True
            dedup_match_state = "closed"
            if apply_mode:
                reopen_issue(CONTROL_REPO, issue["number"])
                reopened_closed_issue = True
                issue["state"] = "open"
            open_issues.append(issue)

    created = False

    if issue:
        issue_number = issue["number"]
        issue_url = issue["url"]
    else:
        title = f"plan: [{item['execution_order']}] {item['title']}"
        body = issue_body(item)
        if apply_mode:
            issue_url = create_issue(CONTROL_REPO, title, body)
        else:
            issue_url = f"https://github.com/{CONTROL_REPO}/issues/DRY-RUN-{item['execution_order']}"
        issue_number = None
        created = True

    if apply_mode and issue_number is None:
        issue_number = int(issue_url.rstrip("/").split("/")[-1])
        open_issues.append(
            {
                "number": issue_number,
                "url": issue_url,
                "body": issue_body(item),
                "state": "open",
            }
        )

    status_key = WORKFLOW_TO_STATUS[item["workflow_state"]]

    result = {
        "plan_item_id": item["plan_item_id"],
        "execution_order": item["execution_order"],
        "issue_number": issue_number,
        "issue_url": issue_url,
        "created_issue": created,
        "dedup_match_state": dedup_match_state,
        "reused_closed_issue": reused_closed_issue,
        "reopened_closed_issue": reopened_closed_issue,
        "field_updates": [],
    }

    if not apply_mode:
        result["field_updates"] = [
            "initiative(text)",
            "target_repo(text)",
            "execution_order(number)",
            f"status({status_key})",
            f"component({item['component']})",
            f"workflow_state({item['workflow_state']})",
            f"loop_profile({item['loop_profile']})",
        ]
        return result

    item_id = ensure_project_item(project["owner"], project["project_number"], issue_url)
    if not item_id:
        item_id = find_project_item_id(
            project["owner"],
            project["project_number"],
            issue_number,
            CONTROL_REPO,
            project_item_issue_index,
        )
    if not item_id:
        raise RuntimeError(f"could not resolve project item id for issue #{issue_number}")

    fields = project["fields"]
    set_text_field(project["project_id"], item_id, fields["initiative"]["id"], project["initiative"])
    result["field_updates"].append("initiative")
    set_text_field(project["project_id"], item_id, fields["target_repo"]["id"], item["target_repo"])
    result["field_updates"].append("target_repo")
    set_number_field(project["project_id"], item_id, fields["execution_order"]["id"], item["execution_order"])
    result["field_updates"].append("execution_order")

    status_field_id, status_option_id = field_option_id(fields, "status", status_key)
    set_select_field(project["project_id"], item_id, status_field_id, status_option_id)
    result["field_updates"].append("status")

    comp_field_id, comp_option_id = field_option_id(fields, "component", item["component"])
    set_select_field(project["project_id"], item_id, comp_field_id, comp_option_id)
    result["field_updates"].append("component")

    wf_field_id, wf_option_id = field_option_id(fields, "workflow_state", item["workflow_state"])
    set_select_field(project["project_id"], item_id, wf_field_id, wf_option_id)
    result["field_updates"].append("workflow_state")

    loop_field_id, loop_option_id = field_option_id(fields, "loop_profile", item["loop_profile"])
    set_select_field(project["project_id"], item_id, loop_field_id, loop_option_id)
    result["field_updates"].append("loop_profile")

    if "plan_lane" in fields and (fields["plan_lane"].get("options") or {}).get("m3_guardrails"):
        lane_field_id, lane_option_id = field_option_id(fields, "plan_lane", "m3_guardrails")
        set_select_field(project["project_id"], item_id, lane_field_id, lane_option_id)
        result["field_updates"].append("plan_lane")

    return result


def main():
    parser = argparse.ArgumentParser(description="Bootstrap Two-Track hard-gate backlog issues and project fields")
    parser.add_argument(
        "--config",
        default="planningops/config/project-field-ids.json",
        help="Project field config JSON path",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Apply changes to GitHub (default is dry-run)",
    )
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/two-track-backlog-bootstrap-report.json",
        help="Output report path",
    )
    parser.add_argument(
        "--allow-reopen-closed",
        action="store_true",
        help="Allow closed dedup matches and reopen them in apply mode",
    )
    args = parser.parse_args()

    project = load_project_config(Path(args.config))
    open_issues = list_existing_issues(CONTROL_REPO, "open")
    closed_issues = list_existing_issues(CONTROL_REPO, "closed") if args.allow_reopen_closed else []
    project_item_issue_index = {}

    report = {
        "mode": "apply" if args.apply else "dry-run",
        "control_repo": CONTROL_REPO,
        "project_owner": project["owner"],
        "project_number": project["project_number"],
        "allow_reopen_closed": args.allow_reopen_closed,
        "open_issues_scanned": len(open_issues),
        "closed_issues_scanned": len(closed_issues),
        "items_total": len(BACKLOG_ITEMS),
        "results": [],
    }

    try:
        for item in BACKLOG_ITEMS:
            report["results"].append(
                execute_item(
                    project,
                    item,
                    args.apply,
                    open_issues,
                    closed_issues,
                    args.allow_reopen_closed,
                    project_item_issue_index,
                )
            )
    except Exception as exc:
        report["error"] = str(exc)
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
