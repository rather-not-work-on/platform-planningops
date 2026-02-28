#!/usr/bin/env python3

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime, timezone


IDEMPOTENCY_PATH = Path("planningops/artifacts/loop-runner/idempotency.json")


def run(args):
    cp = subprocess.run(args, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def append_ndjson(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=True) + "\n")


def parse_depends_on(issue_body: str):
    deps = set()
    for line in issue_body.splitlines():
        if "depends_on:" in line:
            deps.update(int(n) for n in re.findall(r"#(\d+)", line))
    return sorted(deps)


def issue_is_closed(issue_num: int, repo: str):
    rc, out, err = run(["gh", "issue", "view", str(issue_num), "--repo", repo, "--json", "state", "--jq", ".state"])
    if rc != 0:
        return False
    return out.strip().upper() == "CLOSED"


def parse_csv(value: str):
    return [x.strip() for x in value.split(",") if x.strip()]


def normalize_candidates(items, allowed_workflow_states):
    candidates = []
    for it in items:
        content = it.get("content", {})
        if content.get("type") != "Issue":
            continue
        if it.get("status") != "Todo":
            continue

        workflow_state = it.get("workflow_state")
        if workflow_state not in allowed_workflow_states:
            continue

        issue_repo = content.get("repository")
        number = content.get("number")
        if not issue_repo or not number:
            continue

        target_repo = it.get("target_repo") or issue_repo
        order = it.get("execution_order") or 0
        candidates.append(
            {
                "item": it,
                "number": number,
                "order": order,
                "workflow_state": workflow_state,
                "issue_repo": issue_repo,
                "target_repo": target_repo,
            }
        )

    candidates.sort(key=lambda x: (x["order"], x["number"]))
    return candidates


def build_selection_trace(candidates, selected, attempts, allowed_workflow_states):
    selected_ref = None
    if selected is not None:
        selected_ref = {
            "number": selected.get("number"),
            "order": selected.get("order"),
            "workflow_state": selected.get("workflow_state"),
            "issue_repo": selected.get("issue_repo"),
            "target_repo": selected.get("target_repo"),
            "depends_on": selected.get("deps", []),
        }

    return {
        "allowed_workflow_states": sorted(allowed_workflow_states),
        "candidate_count": len(candidates),
        "candidates": [
            {
                "number": c.get("number"),
                "order": c.get("order"),
                "workflow_state": c.get("workflow_state"),
                "issue_repo": c.get("issue_repo"),
                "target_repo": c.get("target_repo"),
            }
            for c in candidates
        ],
        "attempts": attempts,
        "selected": selected_ref,
    }


def ensure_text_field(owner: str, project_num: int, field_name: str):
    rc, out, err = run(["gh", "project", "field-list", str(project_num), "--owner", owner, "--format", "json"])
    if rc != 0:
        raise RuntimeError(f"failed field-list: {err}")
    doc = json.loads(out)
    for f in doc.get("fields", []):
        if f.get("name") == field_name:
            return f.get("id")

    rc2, out2, err2 = run(
        [
            "gh",
            "project",
            "field-create",
            str(project_num),
            "--owner",
            owner,
            "--name",
            field_name,
            "--data-type",
            "TEXT",
            "--format",
            "json",
            "--jq",
            ".id",
        ]
    )
    if rc2 != 0:
        raise RuntimeError(f"failed field-create {field_name}: {err2}")
    return out2.strip()


def main():
    parser = argparse.ArgumentParser(description="Issue intake and feedback loop runner")
    parser.add_argument("--owner", default="rather-not-work-on")
    parser.add_argument("--control-repo", default="rather-not-work-on/platform-planningops")
    parser.add_argument("--project-num", type=int, default=2)
    parser.add_argument("--project-id", default="PVT_kwDOD8NujM4BQYNE")
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="apply")
    parser.add_argument(
        "--no-feedback",
        action="store_true",
        help="Skip issue/project feedback writes (for non-destructive smoke runs)",
    )
    parser.add_argument(
        "--pull-workflow-states",
        default="ready-contract,ready-implementation",
        help="Comma-separated workflow_state values eligible for intake",
    )
    parser.add_argument(
        "--runtime-profile-file",
        default="planningops/config/runtime-profiles.json",
        help="Runtime profile catalog path used by local harness",
    )
    args = parser.parse_args()
    allowed_workflow_states = set(parse_csv(args.pull_workflow_states))

    rc, out, err = run(
        [
            "gh",
            "project",
            "item-list",
            str(args.project_num),
            "--owner",
            args.owner,
            "--limit",
            "200",
            "--format",
            "json",
        ]
    )
    if rc != 0:
        print(f"failed to list project items: {err}")
        return 1

    items = json.loads(out).get("items", [])
    candidates = normalize_candidates(items, allowed_workflow_states)

    selected = None
    selection_attempts = []
    for c in candidates:
        num = c["number"]
        issue_repo = c.get("issue_repo") or args.control_repo
        rc_i, out_i, err_i = run(["gh", "issue", "view", str(num), "--repo", issue_repo, "--json", "body,state"])
        if rc_i != 0:
            selection_attempts.append(
                {
                    "number": num,
                    "issue_repo": issue_repo,
                    "result": "issue_fetch_error",
                    "error": err_i,
                }
            )
            continue
        issue_doc = json.loads(out_i)
        if issue_doc.get("state") != "OPEN":
            selection_attempts.append(
                {
                    "number": num,
                    "issue_repo": issue_repo,
                    "result": "issue_not_open",
                    "state": issue_doc.get("state"),
                }
            )
            continue
        deps = parse_depends_on(issue_doc.get("body", ""))
        closed_checks = [{"dep": dep, "closed": issue_is_closed(dep, issue_repo)} for dep in deps]
        if all(x["closed"] for x in closed_checks):
            c["deps"] = deps
            selected = c
            selection_attempts.append(
                {
                    "number": num,
                    "issue_repo": issue_repo,
                    "result": "selected",
                    "depends_on": deps,
                    "dep_checks": closed_checks,
                }
            )
            break
        selection_attempts.append(
            {
                "number": num,
                "issue_repo": issue_repo,
                "result": "dependency_blocked",
                "depends_on": deps,
                "dep_checks": closed_checks,
            }
        )

    selection_trace = build_selection_trace(candidates, selected, selection_attempts, allowed_workflow_states)

    if selected is None:
        print(json.dumps({"result": "no_eligible_todo_issue", "selection_trace": selection_trace}, ensure_ascii=True))
        return 2

    issue_num = selected["number"]

    # run loop
    rc_loop, out_loop, err_loop = run(
        [
            "python3",
            "planningops/scripts/ralph_loop_local.py",
            "--issue-number",
            str(issue_num),
            "--mode",
            args.mode,
            "--runtime-profile-file",
            args.runtime_profile_file,
            "--task-key",
            f"issue-{issue_num}",
        ]
    )

    # find latest loop dir for this issue
    loop_root = Path("planningops/artifacts/loops")
    loop_dirs = sorted(loop_root.glob(f"*/loop-*-issue-{issue_num}"))
    if not loop_dirs:
        print("loop execution did not produce artifacts")
        return 1
    loop_dir = loop_dirs[-1]
    date_part = loop_dir.parent.name
    loop_id = loop_dir.name
    transition_log = Path(f"planningops/artifacts/transition-log/{date_part}.ndjson")
    selection_event = {
        "transition_id": f"{loop_id}-intake-selection",
        "run_id": loop_id,
        "card_id": issue_num,
        "from_state": "Todo",
        "to_state": selected.get("workflow_state", "ready-contract"),
        "transition_reason": "intake.selection.target_repo",
        "actor_type": "agent",
        "actor_id": "issue-loop-runner",
        "decided_at_utc": datetime.now(timezone.utc).isoformat(),
        "replanning_flag": False,
        "selection_trace": selection_trace,
    }
    append_ndjson(transition_log, selection_event)

    rc_verify, out_verify, err_verify = run(
        [
            "python3",
            "planningops/scripts/verify_loop_run.py",
            "--loop-dir",
            str(loop_dir),
            "--transition-log",
            str(transition_log),
            "--output",
            f"planningops/artifacts/verification/issue-{issue_num}-verification.json",
            "--project-payload",
            f"planningops/artifacts/verification/issue-{issue_num}-project-payload.json",
        ]
    )

    verification = load_json(
        Path(f"planningops/artifacts/verification/issue-{issue_num}-verification.json"),
        {},
    )
    payload = load_json(
        Path(f"planningops/artifacts/verification/issue-{issue_num}-project-payload.json"),
        {},
    )

    loop_id = verification.get("loop_dir", "")
    idem_key = hashlib.sha256(f"issue:{issue_num}:{loop_id}:{payload.get('last_verdict','')}".encode("utf-8")).hexdigest()
    idem = load_json(IDEMPOTENCY_PATH, {"processed_keys": []})
    seen = set(idem.get("processed_keys", []))

    already_processed = idem_key in seen

    comment_body = "\n".join(
        [
            f"Ralph Loop result for issue #{issue_num}",
            f"- verdict: {payload.get('last_verdict', 'unknown')}",
            f"- reason_code: {payload.get('reason_code', 'unknown')}",
            f"- replanning_triggered: {payload.get('replanning_triggered', False)}",
            f"- verification: planningops/artifacts/verification/issue-{issue_num}-verification.json",
            f"- payload: planningops/artifacts/verification/issue-{issue_num}-project-payload.json",
        ]
    )

    if not already_processed and not args.no_feedback:
        # comment on issue
        run(["gh", "issue", "comment", str(issue_num), "--repo", selected.get("issue_repo"), "--body", comment_body])

        # project status + verdict fields
        rc_fields, out_fields, err_fields = run(
            ["gh", "project", "field-list", str(args.project_num), "--owner", args.owner, "--format", "json"]
        )
        if rc_fields == 0:
            fields_doc = json.loads(out_fields)
            status_field = next((f for f in fields_doc.get("fields", []) if f.get("name") == "Status"), None)
            workflow_field = next((f for f in fields_doc.get("fields", []) if f.get("name") == "workflow_state"), None)
            status_target_name = str(payload.get("status_update", "Blocked"))
            status_target_opt = next(
                (o.get("id") for o in (status_field or {}).get("options", []) if o.get("name") == status_target_name),
                None,
            )
            workflow_target_name = "done" if payload.get("last_verdict") == "pass" else "blocked"
            workflow_target_opt = next(
                (o.get("id") for o in (workflow_field or {}).get("options", []) if o.get("name") == workflow_target_name),
                None,
            )

            item_id = selected["item"].get("id")
            if item_id and status_field and status_target_opt:
                run(
                    [
                        "gh",
                        "project",
                        "item-edit",
                        "--id",
                        item_id,
                        "--project-id",
                        args.project_id,
                        "--field-id",
                        status_field.get("id"),
                        "--single-select-option-id",
                        status_target_opt,
                    ]
                )
            if item_id and workflow_field and workflow_target_opt:
                run(
                    [
                        "gh",
                        "project",
                        "item-edit",
                        "--id",
                        item_id,
                        "--project-id",
                        args.project_id,
                        "--field-id",
                        workflow_field.get("id"),
                        "--single-select-option-id",
                        workflow_target_opt,
                    ]
                )

            # ensure verdict text fields exist
            verdict_field_id = ensure_text_field(args.owner, args.project_num, "last_verdict")
            reason_field_id = ensure_text_field(args.owner, args.project_num, "last_reason")
            if item_id:
                run(
                    [
                        "gh",
                        "project",
                        "item-edit",
                        "--id",
                        item_id,
                        "--project-id",
                        args.project_id,
                        "--field-id",
                        verdict_field_id,
                        "--text",
                        str(payload.get("last_verdict", "unknown")),
                    ]
                )
                run(
                    [
                        "gh",
                        "project",
                        "item-edit",
                        "--id",
                        item_id,
                        "--project-id",
                        args.project_id,
                        "--field-id",
                        reason_field_id,
                        "--text",
                        str(payload.get("reason_code", "unknown")),
                    ]
                )

        seen.add(idem_key)
        save_json(IDEMPOTENCY_PATH, {"processed_keys": sorted(seen)})

    result = {
        "selected_issue": issue_num,
        "selected_issue_repo": selected.get("issue_repo"),
        "selected_target_repo": selected.get("target_repo"),
        "selected_workflow_state": selected.get("workflow_state"),
        "deps": selected.get("deps", []),
        "candidate_count": len(candidates),
        "allowed_workflow_states": sorted(allowed_workflow_states),
        "selection_trace": selection_trace,
        "selection_transition_id": selection_event["transition_id"],
        "loop_rc": rc_loop,
        "verify_rc": rc_verify,
        "already_processed": already_processed,
        "idempotency_key": idem_key,
        "loop_stdout": out_loop,
        "verify_stdout": out_verify,
        "loop_stderr": err_loop,
        "verify_stderr": err_verify,
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "runtime_profile_file": args.runtime_profile_file,
        "no_feedback": args.no_feedback,
    }
    out_path = Path("planningops/artifacts/loop-runner/last-run.json")
    save_json(out_path, result)
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
