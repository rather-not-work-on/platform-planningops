#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path


CONTROL_REPO = "rather-not-work-on/platform-planningops"

COMPONENT_ENUM = {
    "planningops",
    "contracts",
    "provider_gateway",
    "observability_gateway",
    "runtime",
    "orchestrator",
}
WORKFLOW_ENUM = {
    "backlog",
    "ready_contract",
    "ready_implementation",
    "in_progress",
    "review_gate",
    "blocked",
    "done",
}
LOOP_ENUM = {
    "l1_contract_clarification",
    "l2_simulation",
    "l3_implementation_tdd",
    "l4_integration_reconcile",
    "l5_recovery_replan",
}
WORKFLOW_LOOP_PROFILE_MATRIX = {
    "backlog": {"l1_contract_clarification", "l2_simulation"},
    "ready_contract": {"l1_contract_clarification", "l2_simulation"},
    "ready_implementation": {"l3_implementation_tdd", "l4_integration_reconcile"},
    "in_progress": set(LOOP_ENUM),
    "review_gate": {"l3_implementation_tdd", "l4_integration_reconcile", "l5_recovery_replan"},
    "blocked": {"l5_recovery_replan"},
    "done": set(LOOP_ENUM),
}
PLAN_LANE_ENUM = {
    "m0_bootstrap",
    "m1_contract_freeze",
    "m2_sync_core",
    "m3_guardrails",
}
WORKFLOW_TO_STATUS = {
    "backlog": "todo",
    "ready_contract": "todo",
    "ready_implementation": "todo",
    "in_progress": "in_progress",
    "review_gate": "in_progress",
    "blocked": "blocked",
    "done": "done",
}
REQUIRED_ITEM_KEYS = [
    "plan_item_id",
    "execution_order",
    "title",
    "target_repo",
    "component",
    "workflow_state",
    "loop_profile",
    "depends_on",
    "primary_output",
]


def run(cmd, input_text=None):
    cp = subprocess.run(cmd, input=input_text, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_project_config(path: Path):
    doc = read_json(path)
    return {
        "owner": doc["owner"],
        "project_number": doc["project_number"],
        "project_id": doc["project_id"],
        "initiative": doc["initiative"],
        "fields": doc["fields"],
    }


def validate_contract(contract_doc):
    errors = []
    ec = contract_doc.get("execution_contract")
    if not isinstance(ec, dict):
        return ["execution_contract object is required"]

    for key in ["plan_id", "plan_revision", "source_of_truth", "items"]:
        if key not in ec:
            errors.append(f"execution_contract.{key} is required")
    if errors:
        return errors

    if not isinstance(ec["plan_revision"], int) or ec["plan_revision"] <= 0:
        errors.append("execution_contract.plan_revision must be integer >= 1")
    if not isinstance(ec["items"], list) or not ec["items"]:
        errors.append("execution_contract.items must be non-empty list")
        return errors

    seen_item_ids = set()
    seen_orders = set()
    all_orders = set()
    for idx, item in enumerate(ec["items"]):
        path = f"execution_contract.items[{idx}]"
        if not isinstance(item, dict):
            errors.append(f"{path} must be object")
            continue

        for key in REQUIRED_ITEM_KEYS:
            if key not in item:
                errors.append(f"{path}.{key} is required")

        if "plan_item_id" in item:
            pid = item["plan_item_id"]
            if not isinstance(pid, str) or not pid.strip():
                errors.append(f"{path}.plan_item_id must be non-empty string")
            elif pid in seen_item_ids:
                errors.append(f"duplicate plan_item_id: {pid}")
            else:
                seen_item_ids.add(pid)

        if "execution_order" in item:
            eo = item["execution_order"]
            if not isinstance(eo, int) or eo <= 0:
                errors.append(f"{path}.execution_order must be integer >= 1")
            elif eo in seen_orders:
                errors.append(f"duplicate execution_order: {eo}")
            else:
                seen_orders.add(eo)
                all_orders.add(eo)

        if "component" in item and item["component"] not in COMPONENT_ENUM:
            errors.append(f"{path}.component invalid: {item['component']}")
        if "workflow_state" in item and item["workflow_state"] not in WORKFLOW_ENUM:
            errors.append(f"{path}.workflow_state invalid: {item['workflow_state']}")
        if "loop_profile" in item and item["loop_profile"] not in LOOP_ENUM:
            errors.append(f"{path}.loop_profile invalid: {item['loop_profile']}")
        if "workflow_state" in item and "loop_profile" in item:
            expected_profiles = WORKFLOW_LOOP_PROFILE_MATRIX.get(item["workflow_state"])
            if expected_profiles and item["loop_profile"] not in expected_profiles:
                errors.append(
                    f"{path}.loop_profile {item['loop_profile']} incompatible with workflow_state {item['workflow_state']}"
                )
        if "plan_lane" in item and item["plan_lane"] not in PLAN_LANE_ENUM:
            errors.append(f"{path}.plan_lane invalid: {item['plan_lane']}")

        if "depends_on" in item:
            deps = item["depends_on"]
            if not isinstance(deps, list):
                errors.append(f"{path}.depends_on must be list")
            else:
                for dep in deps:
                    if not isinstance(dep, int) or dep <= 0:
                        errors.append(f"{path}.depends_on contains invalid value: {dep}")

    # Cross-reference dependency orders after all orders are known.
    for idx, item in enumerate(ec["items"]):
        path = f"execution_contract.items[{idx}]"
        for dep in item.get("depends_on", []):
            if dep not in all_orders:
                errors.append(f"{path}.depends_on references unknown execution_order: {dep}")

    return errors


def issue_body(source_of_truth, plan_id, plan_revision, item):
    depends = ",".join(str(x) for x in item["depends_on"]) if item["depends_on"] else "-"
    evidence_refs = [source_of_truth, item["primary_output"]]
    evidence_lines = "\n".join(f"- `{ref}`" for ref in evidence_refs)
    planning_context_lines = [
        "## Planning Context",
        f"- plan_doc: `{source_of_truth}`",
        f"- plan_id: `{plan_id}`",
        f"- plan_revision: `{plan_revision}`",
        f"- plan_item_id: `{item['plan_item_id']}`",
        f"- execution_order: `{item['execution_order']}`",
        f"- target_repo: `{item['target_repo']}`",
        f"- component: `{item['component']}`",
        f"- workflow_state: `{item['workflow_state']}`",
        f"- loop_profile: `{item['loop_profile']}`",
        f"- depends_on: `{depends}`",
        f"- primary_output: `{item['primary_output']}`",
    ]
    if item.get("plan_lane"):
        planning_context_lines.insert(-2, f"- plan_lane: `{item['plan_lane']}`")

    return "\n".join(
        [
            *planning_context_lines,
            "",
            "## Problem Statement",
            "- Resolve this plan item with deterministic artifacts and contract-aligned updates.",
            "",
            "## Interfaces & Dependencies",
            f"- target_repo: `{item['target_repo']}`",
            f"- depends_on: `{depends}`",
            "",
            "## Evidence",
            evidence_lines,
            "",
            "## Acceptance Criteria",
            "- [ ] Required artifact created and linked under Evidence.",
            "- [ ] Contract/path references are updated and validated.",
            "",
            "## Definition of Done",
            "- [ ] Required artifact created",
            "- [ ] Validation report attached",
            "- [ ] Project fields updated with evidence",
        ]
    )


def parse_issue_metadata(body: str):
    metadata = {}
    if not body:
        return metadata
    for key, value in re.findall(r"(plan_id|plan_item_id|target_repo): `([^`]*)`", body):
        metadata[key] = value
    return metadata


def list_existing_issues(repo: str, state: str):
    page = 1
    issues = []
    while True:
        rc, out, err = run(["gh", "api", f"repos/{repo}/issues?state={state}&per_page=100&page={page}"])
        if rc != 0:
            raise RuntimeError(f"failed to list issues (state={state}, page={page}): {err}")
        batch = json.loads(out)
        if not batch:
            break
        for issue in batch:
            if issue.get("pull_request"):
                continue
            issues.append(
                {
                    "number": issue["number"],
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


def find_issue_for_item(issues, plan_id: str, plan_item_id: str, target_repo: str):
    exact_matches = []
    legacy_matches = []
    for issue in issues:
        metadata = parse_issue_metadata(issue.get("body") or "")
        if metadata.get("plan_item_id") != plan_item_id:
            continue
        if metadata.get("target_repo") != target_repo:
            continue
        if metadata.get("plan_id") == plan_id:
            exact_matches.append(issue)
        elif "plan_id" not in metadata:
            legacy_matches.append(issue)

    if len(exact_matches) > 1:
        raise RuntimeError(
            f"multiple open issues matched identity (plan_id={plan_id}, plan_item_id={plan_item_id}, target_repo={target_repo})"
        )
    if exact_matches:
        return exact_matches[0], "identity_exact"

    if len(legacy_matches) > 1:
        raise RuntimeError(
            f"multiple legacy issues matched identity (plan_item_id={plan_item_id}, target_repo={target_repo})"
        )
    if legacy_matches:
        return legacy_matches[0], "identity_legacy_no_plan_id"

    return None, None


def create_issue(repo: str, title: str, body: str):
    rc, out, err = run(["gh", "issue", "create", "--repo", repo, "--title", title, "--body", body])
    if rc != 0:
        raise RuntimeError(f"failed to create issue: {err}")
    return out.strip()


def edit_issue(repo: str, issue_number: int, title: str, body: str):
    rc, _, err = run(["gh", "issue", "edit", str(issue_number), "--repo", repo, "--title", title, "--body", body])
    if rc != 0:
        raise RuntimeError(f"failed to edit issue #{issue_number}: {err}")


def reopen_issue(repo: str, issue_number: int):
    rc, _, err = run(["gh", "issue", "reopen", str(issue_number), "--repo", repo])
    if rc != 0:
        raise RuntimeError(f"failed to reopen issue #{issue_number}: {err}")


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
            issue_index[(number, repo_name)] = item.get("id")
        if not page_info.get("hasNextPage"):
            break
        cursor = page_info.get("endCursor")
        if not cursor:
            break
    return issue_index


def find_project_item_id(owner, project_number, issue_number, issue_repo, project_item_issue_index):
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
            if doc.get("id"):
                return doc["id"]
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


def compile_item(project, source_of_truth, plan_id, plan_revision, item, apply_mode, open_issues, closed_issues, allow_reopen_closed, project_item_issue_index):
    desired_title = f"plan: [{item['execution_order']}] {item['title']}"
    desired_body = issue_body(source_of_truth, plan_id, plan_revision, item)
    issue, dedup_strategy = find_issue_for_item(open_issues, plan_id, item["plan_item_id"], item["target_repo"])
    reused_closed_issue = False
    reopened_closed_issue = False
    dedup_match_state = "open" if issue else None

    if issue is None and allow_reopen_closed:
        closed_issue, dedup_strategy = find_issue_for_item(closed_issues, plan_id, item["plan_item_id"], item["target_repo"])
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
        if apply_mode:
            issue_url = create_issue(CONTROL_REPO, desired_title, desired_body)
        else:
            issue_url = f"https://github.com/{CONTROL_REPO}/issues/DRY-RUN-{item['execution_order']}"
        issue_number = None
        created = True

    if apply_mode and issue_number is None:
        issue_number = int(issue_url.rstrip("/").split("/")[-1])
        open_issues.append(
            {"number": issue_number, "url": issue_url, "title": desired_title, "body": desired_body, "state": "open"}
        )

    metadata_sync_required = False
    metadata_sync_action = "none"
    if issue:
        current_title = issue.get("title") or ""
        current_body = issue.get("body") or ""
        metadata_sync_required = current_title != desired_title or current_body != desired_body
        if metadata_sync_required:
            if apply_mode:
                edit_issue(CONTROL_REPO, issue_number, desired_title, desired_body)
                metadata_sync_action = "applied"
                issue["title"] = desired_title
                issue["body"] = desired_body
            else:
                metadata_sync_action = "planned"

    status_key = WORKFLOW_TO_STATUS[item["workflow_state"]]
    result = {
        "plan_item_id": item["plan_item_id"],
        "execution_order": item["execution_order"],
        "issue_number": issue_number,
        "issue_url": issue_url,
        "created_issue": created,
        "dedup_match_state": dedup_match_state,
        "dedup_strategy": dedup_strategy,
        "reused_closed_issue": reused_closed_issue,
        "reopened_closed_issue": reopened_closed_issue,
        "metadata_sync_required": metadata_sync_required,
        "metadata_sync_action": metadata_sync_action,
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
        if item.get("plan_lane"):
            result["field_updates"].append(f"plan_lane({item['plan_lane']})")
        return result

    item_id = ensure_project_item(project["owner"], project["project_number"], issue_url)
    if not item_id:
        item_id = find_project_item_id(project["owner"], project["project_number"], issue_number, CONTROL_REPO, project_item_issue_index)
    if not item_id:
        raise RuntimeError(f"could not resolve project item id for issue #{issue_number}")

    fields = project["fields"]
    set_text_field(project["project_id"], item_id, fields["initiative"]["id"], project["initiative"])
    set_text_field(project["project_id"], item_id, fields["target_repo"]["id"], item["target_repo"])
    set_number_field(project["project_id"], item_id, fields["execution_order"]["id"], item["execution_order"])
    result["field_updates"].extend(["initiative", "target_repo", "execution_order"])

    status_field_id, status_option_id = field_option_id(fields, "status", status_key)
    set_select_field(project["project_id"], item_id, status_field_id, status_option_id)
    comp_field_id, comp_option_id = field_option_id(fields, "component", item["component"])
    set_select_field(project["project_id"], item_id, comp_field_id, comp_option_id)
    wf_field_id, wf_option_id = field_option_id(fields, "workflow_state", item["workflow_state"])
    set_select_field(project["project_id"], item_id, wf_field_id, wf_option_id)
    loop_field_id, loop_option_id = field_option_id(fields, "loop_profile", item["loop_profile"])
    set_select_field(project["project_id"], item_id, loop_field_id, loop_option_id)
    result["field_updates"].extend(["status", "component", "workflow_state", "loop_profile"])

    if item.get("plan_lane") and "plan_lane" in fields:
        lane_field_id, lane_option_id = field_option_id(fields, "plan_lane", item["plan_lane"])
        set_select_field(project["project_id"], item_id, lane_field_id, lane_option_id)
        result["field_updates"].append("plan_lane")

    return result


def main():
    parser = argparse.ArgumentParser(description="Compile Plan Execution Contract (PEC v1) into backlog issues and project fields")
    parser.add_argument("--contract-file", required=True, help="PEC v1 JSON file path")
    parser.add_argument("--config", default="planningops/config/project-field-ids.json", help="Project field config JSON path")
    parser.add_argument("--apply", action="store_true", help="Apply GitHub mutations (default dry-run)")
    parser.add_argument("--allow-reopen-closed", action="store_true", help="Allow closed dedup matches and reopen in apply mode")
    parser.add_argument("--output", default="planningops/artifacts/validation/plan-compile-report.json", help="Output report path")
    args = parser.parse_args()

    contract_doc = read_json(Path(args.contract_file))
    validation_errors = validate_contract(contract_doc)
    report = {
        "mode": "apply" if args.apply else "dry-run",
        "contract_file": args.contract_file,
        "validation_errors": validation_errors,
        "results": [],
    }
    if validation_errors:
        report["verdict"] = "fail"
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1

    ec = contract_doc["execution_contract"]
    items = sorted(ec["items"], key=lambda x: x["execution_order"])
    project = load_project_config(Path(args.config))
    open_issues = list_existing_issues(CONTROL_REPO, "open")
    closed_issues = list_existing_issues(CONTROL_REPO, "closed") if args.allow_reopen_closed else []
    project_item_issue_index = {}

    report.update(
        {
            "plan_id": ec["plan_id"],
            "plan_revision": ec["plan_revision"],
            "source_of_truth": ec["source_of_truth"],
            "items_total": len(items),
            "open_issues_scanned": len(open_issues),
            "closed_issues_scanned": len(closed_issues),
        }
    )

    try:
        for item in items:
            report["results"].append(
                compile_item(
                    project,
                    ec["source_of_truth"],
                    ec["plan_id"],
                    ec["plan_revision"],
                    item,
                    args.apply,
                    open_issues,
                    closed_issues,
                    args.allow_reopen_closed,
                    project_item_issue_index,
                )
            )
    except Exception as exc:
        report["verdict"] = "fail"
        report["error"] = str(exc)
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
        print(json.dumps(report, ensure_ascii=True, indent=2))
        return 1

    report["verdict"] = "pass"
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
