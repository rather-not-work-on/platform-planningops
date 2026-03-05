#!/usr/bin/env python3

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path
import subprocess
import sys

ALL_LOOP_PROFILES = {
    "L1 Contract-Clarification",
    "L2 Simulation",
    "L3 Implementation-TDD",
    "L4 Integration-Reconcile",
    "L5 Recovery-Replan",
}

WORKFLOW_LOOP_PROFILE_MATRIX = {
    "backlog": {"L1 Contract-Clarification", "L2 Simulation"},
    "ready-contract": {"L1 Contract-Clarification", "L2 Simulation"},
    "ready-implementation": {"L3 Implementation-TDD", "L4 Integration-Reconcile"},
    # Active execution can be in contract/implementation/recovery loops.
    "in-progress": set(ALL_LOOP_PROFILES),
    # Review gate mainly validates implementation/recovery outcomes.
    "review-gate": {"L3 Implementation-TDD", "L4 Integration-Reconcile", "L5 Recovery-Replan"},
    "blocked": {"L5 Recovery-Replan"},
    "done": set(ALL_LOOP_PROFILES),
}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(args):
    cp = subprocess.run(args, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def index_fields_by_id(fields):
    return {f.get("id"): f for f in fields if f.get("id")}


def find_item_field_value(item, field_name):
    # gh project item-list json can expose custom fields on the root item.
    return item.get(field_name)


def expected_loop_profiles_for_workflow_state(workflow_state):
    return WORKFLOW_LOOP_PROFILE_MATRIX.get(workflow_state)


def main():
    parser = argparse.ArgumentParser(description="Validate GitHub Project field schema and mapping rules")
    parser.add_argument("--owner", default="rather-not-work-on")
    parser.add_argument("--project-num", type=int, default=2)
    parser.add_argument(
        "--config",
        default="planningops/config/project-field-ids.json",
        help="Field catalog configuration path",
    )
    parser.add_argument(
        "--initiative",
        default="unified-personal-agent-platform",
        help="Initiative id filter for card-level validation",
    )
    parser.add_argument(
        "--control-repo",
        default="rather-not-work-on/platform-planningops",
        help="Repository used as control plane issue source",
    )
    parser.add_argument(
        "--output",
        default="planningops/artifacts/validation/project-field-schema-report.json",
        help="Report output path",
    )
    parser.add_argument(
        "--fail-on-mismatch",
        action="store_true",
        help="Return non-zero when mismatch/missing violations are detected",
    )
    parser.add_argument(
        "--allow-fetch-failure",
        action="store_true",
        help="Treat GitHub Project fetch errors as soft-skip and exit zero",
    )
    args = parser.parse_args()

    cfg = load_json(Path(args.config))
    expected_fields = cfg.get("fields", {})

    def write_soft_skip_report(stage: str, message: str):
        report = {
            "generated_at_utc": now_utc(),
            "project": {
                "owner": args.owner,
                "project_num": args.project_num,
                "initiative": args.initiative,
            },
            "required_field_checks": [],
            "evaluated_items": 0,
            "violation_count": 0,
            "violations": [],
            "info_count": 1,
            "infos": [
                {
                    "type": "FETCH_ERROR",
                    "stage": stage,
                    "message": message,
                }
            ],
            "fetch_failed": True,
            "verdict": "inconclusive",
        }
        out_path = Path(args.output)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")
        print(f"report written: {out_path}")
        print("evaluated_items=0 violation_count=0 verdict=inconclusive fetch_failed=true")

    rc_f, out_f, err_f = run(
        ["gh", "project", "field-list", str(args.project_num), "--owner", args.owner, "--format", "json"]
    )
    if rc_f != 0:
        msg = f"failed to fetch field-list: {err_f}"
        print(msg)
        if args.allow_fetch_failure:
            write_soft_skip_report("field-list", msg)
            return 0
        return 1
    field_doc = json.loads(out_f)
    fields = field_doc.get("fields", [])
    fields_by_id = index_fields_by_id(fields)

    rc_i, out_i, err_i = run(
        ["gh", "project", "item-list", str(args.project_num), "--owner", args.owner, "--limit", "200", "--format", "json"]
    )
    if rc_i != 0:
        msg = f"failed to fetch item-list: {err_i}"
        print(msg)
        if args.allow_fetch_failure:
            write_soft_skip_report("item-list", msg)
            return 0
        return 1
    item_doc = json.loads(out_i)
    items = item_doc.get("items", [])

    required_field_checks = []
    for key in [
        "status",
        "initiative",
        "target_repo",
        "component",
        "execution_order",
        "plan_lane",
        "workflow_state",
        "loop_profile",
    ]:
        expected = expected_fields.get(key, {})
        field_id = expected.get("id")
        ok = bool(field_id and field_id in fields_by_id)
        detail = {
            "field_key": key,
            "expected_id": field_id,
            "exists": ok,
            "actual_name": fields_by_id.get(field_id, {}).get("name") if ok else None,
        }
        if key in ["status", "component", "plan_lane", "workflow_state", "loop_profile"]:
            expected_opts = (expected.get("options") or {}).values()
            actual_opts = {o.get("id") for o in (fields_by_id.get(field_id, {}).get("options") or [])}
            missing_opts = sorted([opt for opt in expected_opts if opt not in actual_opts])
            detail["missing_option_ids"] = missing_opts
            detail["options_ok"] = len(missing_opts) == 0
        required_field_checks.append(detail)

    violations = []
    infos = []
    evaluated = 0
    for item in items:
        content = item.get("content", {})
        content_type = content.get("type")
        if content_type not in {"Issue", "DraftIssue"}:
            continue

        initiative_value = find_item_field_value(item, "initiative")
        if initiative_value != args.initiative:
            continue

        evaluated += 1
        item_id = item.get("id")
        issue_number = content.get("number")
        target_repo = find_item_field_value(item, "target_repo")
        component_value = find_item_field_value(item, "component")
        workflow_state = find_item_field_value(item, "workflow_state")
        loop_profile = find_item_field_value(item, "loop_profile")
        status_value = item.get("status")
        repo_value = content.get("repository")

        if not initiative_value:
            violations.append(
                {
                    "type": "MISSING_FIELD",
                    "field": "initiative",
                    "item_id": item_id,
                    "issue_number": issue_number,
                    "message": "initiative field is required",
                }
            )
        if not component_value:
            violations.append(
                {
                    "type": "MISSING_FIELD",
                    "field": "component",
                    "item_id": item_id,
                    "issue_number": issue_number,
                    "message": "component field is required",
                }
            )
        if not target_repo:
            violations.append(
                {
                    "type": "MISSING_FIELD",
                    "field": "target_repo",
                    "item_id": item_id,
                    "issue_number": issue_number,
                    "message": "target_repo field is required for initiative cards",
                }
            )
        if not workflow_state:
            violations.append(
                {
                    "type": "MISSING_FIELD",
                    "field": "workflow_state",
                    "item_id": item_id,
                    "issue_number": issue_number,
                    "message": "workflow_state field is required for initiative cards",
                }
            )
        if not loop_profile:
            violations.append(
                {
                    "type": "MISSING_FIELD",
                    "field": "loop_profile",
                    "item_id": item_id,
                    "issue_number": issue_number,
                    "message": "loop_profile field is required for initiative cards",
                }
            )

        if target_repo and "/" not in target_repo:
            violations.append(
                {
                    "type": "INVALID_FORMAT",
                    "field": "target_repo",
                    "item_id": item_id,
                    "issue_number": issue_number,
                    "actual": target_repo,
                    "message": "target_repo must use owner/repo format",
                }
            )

        if content_type == "Issue" and target_repo and repo_value:
            if repo_value == args.control_repo and target_repo != repo_value:
                infos.append(
                    {
                        "type": "CROSS_REPO_MAPPING",
                        "field": "target_repo",
                        "item_id": item_id,
                        "issue_number": issue_number,
                        "control_repo": repo_value,
                        "target_repo": target_repo,
                        "message": "control-repo issue intentionally targets external repository",
                    }
                )
            elif repo_value != args.control_repo and target_repo != repo_value:
                violations.append(
                    {
                        "type": "FIELD_MISMATCH",
                        "field": "target_repo",
                        "item_id": item_id,
                        "issue_number": issue_number,
                        "expected": repo_value,
                        "actual": target_repo,
                        "message": "target_repo must match built-in Issue repository for non-control repo cards",
                    }
                )

        if workflow_state and status_value:
            expected_status = None
            if workflow_state in {"backlog", "ready-contract", "ready-implementation"}:
                expected_status = "Todo"
            elif workflow_state in {"in-progress", "review-gate"}:
                expected_status = "In Progress"
            elif workflow_state == "blocked":
                expected_status = "Blocked"
            elif workflow_state == "done":
                expected_status = "Done"

            if expected_status and status_value != expected_status:
                violations.append(
                    {
                        "type": "STATUS_WORKFLOW_MISMATCH",
                        "field": "workflow_state",
                        "item_id": item_id,
                        "issue_number": issue_number,
                        "workflow_state": workflow_state,
                        "expected_status": expected_status,
                        "actual_status": status_value,
                        "message": "Status projection must match workflow_state contract",
                    }
                )

        if workflow_state and loop_profile:
            expected_profiles = expected_loop_profiles_for_workflow_state(workflow_state)
            if expected_profiles is None:
                infos.append(
                    {
                        "type": "WORKFLOW_STATE_UNCOVERED",
                        "field": "loop_profile",
                        "item_id": item_id,
                        "issue_number": issue_number,
                        "workflow_state": workflow_state,
                        "message": "no loop_profile matrix rule for workflow_state",
                    }
                )

            if expected_profiles and loop_profile not in expected_profiles:
                violations.append(
                    {
                        "type": "LOOP_PROFILE_WORKFLOW_MISMATCH",
                        "field": "loop_profile",
                        "item_id": item_id,
                        "issue_number": issue_number,
                        "workflow_state": workflow_state,
                        "expected_profiles": sorted(expected_profiles),
                        "actual": loop_profile,
                        "message": "loop_profile must match workflow_state default contract",
                    }
                )

    report = {
        "generated_at_utc": now_utc(),
        "project": {
            "owner": args.owner,
            "project_num": args.project_num,
            "initiative": args.initiative,
        },
        "required_field_checks": required_field_checks,
        "evaluated_items": evaluated,
        "violation_count": len(violations),
        "violations": violations,
        "info_count": len(infos),
        "infos": infos,
        "verdict": "pass" if len(violations) == 0 else "fail",
    }

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out_path}")
    print(f"evaluated_items={evaluated} violation_count={len(violations)} verdict={report['verdict']}")

    fields_ok = all(
        check.get("exists", False) and check.get("options_ok", True) for check in required_field_checks
    )
    should_fail = (not fields_ok) or (args.fail_on_mismatch and len(violations) > 0)
    return 1 if should_fail else 0


if __name__ == "__main__":
    sys.exit(main())
