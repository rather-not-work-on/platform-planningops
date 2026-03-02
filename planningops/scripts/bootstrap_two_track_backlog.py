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


def list_existing_issues(repo: str):
    rc, out, err = run(
        [
            "gh",
            "issue",
            "list",
            "--repo",
            repo,
            "--state",
            "all",
            "--limit",
            "200",
            "--json",
            "number,title,body,url",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to list issues: {err}")
    return json.loads(out)


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


def normalize_workflow_key(key: str):
    return key.replace("-", "_")


def find_project_item_id(owner: str, project_number: int, issue_number: int, issue_repo: str):
    rc, out, err = run(
        [
            "gh",
            "project",
            "item-list",
            str(project_number),
            "--owner",
            owner,
            "--limit",
            "500",
            "--format",
            "json",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to list project items: {err}")
    doc = json.loads(out)
    for item in doc.get("items", []):
        content = item.get("content") or {}
        if content.get("type") != "Issue":
            continue
        if content.get("number") != issue_number:
            continue
        if content.get("repository") != issue_repo:
            continue
        return item.get("id")
    return None


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


def execute_item(project, item, apply_mode: bool, existing_issues):
    issue = find_issue_for_item(existing_issues, item["plan_item_id"])
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
        existing_issues.append(
            {
                "number": issue_number,
                "url": issue_url,
                "body": issue_body(item),
            }
        )

    status_key = WORKFLOW_TO_STATUS[item["workflow_state"]]

    result = {
        "plan_item_id": item["plan_item_id"],
        "execution_order": item["execution_order"],
        "issue_number": issue_number,
        "issue_url": issue_url,
        "created_issue": created,
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
    args = parser.parse_args()

    project = load_project_config(Path(args.config))
    issues = list_existing_issues(CONTROL_REPO)

    report = {
        "mode": "apply" if args.apply else "dry-run",
        "control_repo": CONTROL_REPO,
        "project_owner": project["owner"],
        "project_number": project["project_number"],
        "items_total": len(BACKLOG_ITEMS),
        "results": [],
    }

    try:
        for item in BACKLOG_ITEMS:
            report["results"].append(execute_item(project, item, args.apply, issues))
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
