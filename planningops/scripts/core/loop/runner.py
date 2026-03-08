#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from datetime import datetime, timedelta, timezone

SCRIPTS_ROOT = Path(__file__).resolve().parents[2]
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from artifact_sink import ArtifactSink
from core.loop.checkpoint_lock import (
    acquire_issue_lock as _acquire_issue_lock,
    checkpoint_path as _checkpoint_path,
    clear_checkpoint as _clear_checkpoint,
    heartbeat_issue_lock as _heartbeat_issue_lock,
    load_checkpoint as _load_checkpoint,
    lock_path as _lock_path,
    read_issue_lock as _read_issue_lock,
    release_issue_lock as _release_issue_lock,
    run_with_runtime_heartbeat as _run_with_runtime_heartbeat,
    save_checkpoint as _save_checkpoint,
)
from core.loop.selection import (
    HIGH_VALUE_READY_STATES,
    build_replenishment_candidates,
    build_selection_trace,
    determine_loop_profile,
    ensure_single_select_field,
    ensure_text_field,
    normalize_candidates,
    parse_blueprint_refs,
    parse_depends_on,
    parse_plan_item_id,
    parse_selector_hints,
)
from federation.adapter_registry import invoke_adapter_hook, resolve_execution_adapter

ARTIFACT_SINK = ArtifactSink(local_cache_external=True)

IDEMPOTENCY_PATH = Path("planningops/artifacts/loop-runner/idempotency.json")
CHECKPOINT_DIR = Path("planningops/artifacts/loop-runner/checkpoints")
LOCK_DIR = Path("planningops/artifacts/loop-runner/locks")
WATCHDOG_DIR = Path("planningops/artifacts/loop-runner/watchdog")
ESCALATION_HISTORY_PATH = Path("planningops/artifacts/loop-runner/escalation-history.json")
DEFAULT_ATTEMPT_BUDGET = {
    "max_attempts": 3,
    "max_duration_minutes": 30,
    "max_token_budget": 120000,
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

def run(args):
    cp = subprocess.run(args, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path, default):
    read_path = ARTIFACT_SINK.resolve_read_path(path)
    if not read_path.exists():
        return default
    return json.loads(read_path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    ARTIFACT_SINK.write_json(path, data)


def append_ndjson(path: Path, data):
    ARTIFACT_SINK.append_ndjson_row(path, data)


def save_text(path: Path, text: str):
    ARTIFACT_SINK.write_text(path, text, append=False)


def externalize_and_prune_external_cache(loop_dir: Path, adapter_artifact_dir: Path, transition_log: Path):
    paths = []
    for root in [loop_dir, adapter_artifact_dir]:
        if root.exists():
            paths.extend([p for p in root.rglob("*") if p.is_file()])
    if transition_log.exists():
        paths.append(transition_log)

    externalized = 0
    for file_path in sorted(set(paths)):
        result = ARTIFACT_SINK.externalize_existing_file(file_path, delete_local=True)
        if result.get("externalized"):
            externalized += 1

    ARTIFACT_SINK.prune_local_external_tree(loop_dir)
    ARTIFACT_SINK.prune_local_external_tree(adapter_artifact_dir)
    ARTIFACT_SINK.prune_local_external_file(transition_log)
    return externalized



def checkpoint_path(issue_num: int):
    return _checkpoint_path(CHECKPOINT_DIR, issue_num)


def load_checkpoint(issue_num: int):
    return _load_checkpoint(CHECKPOINT_DIR, load_json, issue_num)


def save_checkpoint(issue_num: int, stage: str, data: dict):
    return _save_checkpoint(CHECKPOINT_DIR, save_json, issue_num, stage, data)


def clear_checkpoint(issue_num: int):
    return _clear_checkpoint(CHECKPOINT_DIR, issue_num)


def lock_path(issue_num: int):
    return _lock_path(LOCK_DIR, issue_num)


def acquire_issue_lock(issue_num: int, owner_id: str, ttl_seconds: int):
    return _acquire_issue_lock(LOCK_DIR, load_json, save_json, issue_num, owner_id, ttl_seconds)


def heartbeat_issue_lock(issue_num: int, owner_id: str, ttl_seconds: int):
    return _heartbeat_issue_lock(LOCK_DIR, load_json, save_json, issue_num, owner_id, ttl_seconds)


def release_issue_lock(issue_num: int, owner_id: str):
    return _release_issue_lock(LOCK_DIR, load_json, issue_num, owner_id)


def read_issue_lock(issue_num: int):
    return _read_issue_lock(LOCK_DIR, load_json, issue_num)


def run_with_runtime_heartbeat(command, issue_num: int, owner_id: str, ttl_seconds: int):
    return _run_with_runtime_heartbeat(LOCK_DIR, load_json, save_json, command, issue_num, owner_id, ttl_seconds)

def evaluate_escalation(issue_num: int, verdict: str, reason_code: str):
    history = load_json(ESCALATION_HISTORY_PATH, {"issues": {}})
    issues = history.get("issues", {})
    issue_key = str(issue_num)
    rows = issues.get(issue_key, [])

    current = {
        "recorded_at_utc": datetime.now(timezone.utc).isoformat(),
        "verdict": verdict,
        "reason_code": reason_code,
    }
    rows.append(current)
    rows = rows[-20:]
    issues[issue_key] = rows
    save_json(ESCALATION_HISTORY_PATH, {"issues": issues})

    normalized_verdict = str(verdict or "").strip().lower()
    normalized_reason = str(reason_code or "").strip().lower()
    same_reason_eligible = bool(normalized_reason) and normalized_reason != "ok" and normalized_verdict != "pass"

    same_reason_consecutive = 0
    if same_reason_eligible:
        for row in reversed(rows):
            row_reason = str(row.get("reason_code") or "").strip().lower()
            row_verdict = str(row.get("verdict") or "").strip().lower()
            if row_reason == normalized_reason and row_verdict != "pass":
                same_reason_consecutive += 1
            else:
                break

    inconclusive_consecutive = 0
    for row in reversed(rows):
        if row.get("verdict") == "inconclusive":
            inconclusive_consecutive += 1
        else:
            break

    trigger_type = None
    if same_reason_consecutive >= 3:
        trigger_type = "same_reason_x3"
    elif inconclusive_consecutive >= 2:
        trigger_type = "inconclusive_x2"

    return {
        "auto_paused": trigger_type is not None,
        "trigger_type": trigger_type,
        "same_reason_consecutive": same_reason_consecutive,
        "inconclusive_consecutive": inconclusive_consecutive,
        "history_count": len(rows),
    }


def normalize_contract_key(value):
    if value is None:
        return ""
    return str(value).strip().lower().replace(" ", "_").replace("-", "_")


def validate_pec_contract(pec_doc):
    errors = []
    ec = pec_doc.get("execution_contract")
    if not isinstance(ec, dict):
        return ["execution_contract object is required"]
    for key in ["plan_id", "plan_revision", "source_of_truth", "items"]:
        if key not in ec:
            errors.append(f"execution_contract.{key} is required")
    if errors:
        return errors
    if not isinstance(ec.get("items"), list) or not ec.get("items"):
        errors.append("execution_contract.items must be non-empty list")
        return errors

    seen_item_ids = set()
    for idx, item in enumerate(ec["items"]):
        if not isinstance(item, dict):
            errors.append(f"execution_contract.items[{idx}] must be object")
            continue
        plan_item_id = item.get("plan_item_id")
        if not isinstance(plan_item_id, str) or not plan_item_id.strip():
            errors.append(f"execution_contract.items[{idx}].plan_item_id is required")
            continue
        if plan_item_id in seen_item_ids:
            errors.append(f"duplicate plan_item_id: {plan_item_id}")
        seen_item_ids.add(plan_item_id)
    return errors


def evaluate_pec_preflight(mode, contract_file, selected, initiative):
    result = {
        "mode": mode,
        "contract_file": contract_file,
        "plan_item_id": selected.get("plan_item_id"),
        "status": "pass",
        "reason_code": "pec_preflight_pass",
        "validation_errors": [],
        "mismatches": [],
    }

    if mode == "legacy":
        result["status"] = "skipped"
        result["reason_code"] = "pec_legacy_mode"
        return result

    if not contract_file:
        if mode == "strict-pec":
            result["status"] = "fail"
            result["reason_code"] = "pec_contract_file_required"
        else:
            result["status"] = "skipped"
            result["reason_code"] = "pec_contract_file_missing_hybrid"
        return result

    plan_item_id = selected.get("plan_item_id")
    if not plan_item_id:
        if mode == "strict-pec":
            result["status"] = "fail"
            result["reason_code"] = "pec_plan_item_id_missing"
        else:
            result["status"] = "skipped"
            result["reason_code"] = "pec_plan_item_id_missing_hybrid"
        return result

    try:
        pec_doc = load_json(Path(contract_file), {})
    except Exception as exc:  # noqa: BLE001
        result["status"] = "fail"
        result["reason_code"] = "pec_contract_file_unreadable"
        result["validation_errors"] = [str(exc)]
        return result

    validation_errors = validate_pec_contract(pec_doc)
    if validation_errors:
        result["status"] = "fail"
        result["reason_code"] = "pec_contract_invalid"
        result["validation_errors"] = validation_errors
        return result

    contract_items = {
        item.get("plan_item_id"): item
        for item in pec_doc["execution_contract"]["items"]
        if isinstance(item, dict) and item.get("plan_item_id")
    }
    contract_item = contract_items.get(plan_item_id)
    if contract_item is None:
        if mode == "strict-pec":
            result["status"] = "fail"
            result["reason_code"] = "pec_plan_item_missing_in_contract"
        else:
            result["status"] = "skipped"
            result["reason_code"] = "pec_plan_item_missing_in_contract_hybrid"
        return result

    expected = {
        "execution_order": int(contract_item.get("execution_order", 0)),
        "target_repo": contract_item.get("target_repo"),
        "component": normalize_contract_key(contract_item.get("component")),
        "workflow_state": normalize_contract_key(contract_item.get("workflow_state")),
        "loop_profile": normalize_contract_key(contract_item.get("loop_profile")),
        "status": WORKFLOW_TO_STATUS.get(normalize_contract_key(contract_item.get("workflow_state")), ""),
        "initiative": initiative,
    }
    actual = {
        "execution_order": int(selected.get("order", 0)),
        "target_repo": selected.get("target_repo"),
        "component": normalize_contract_key(selected.get("component")),
        "workflow_state": normalize_contract_key(selected.get("workflow_state")),
        "loop_profile": normalize_contract_key(selected.get("loop_profile")),
        "status": normalize_contract_key(selected.get("status")),
        "initiative": selected.get("initiative"),
    }

    mismatches = []
    for field in [
        "execution_order",
        "target_repo",
        "component",
        "workflow_state",
        "loop_profile",
        "status",
        "initiative",
    ]:
        if expected[field] != actual[field]:
            mismatches.append(
                {
                    "field": field,
                    "expected": expected[field],
                    "actual": actual[field],
                }
            )

    if mismatches:
        result["status"] = "fail"
        result["reason_code"] = "pec_projection_mismatch"
        result["mismatches"] = mismatches
        return result

    return result


def evaluate_worker_task_pack_preflight(runtime_profile_file, selected, mode, loop_profile):
    issue_num = int(selected.get("number", 0))
    task_key = f"issue-{issue_num}"
    report_path = Path(f"planningops/artifacts/validation/worker-task-pack-issue-{issue_num}.json")
    cmd = [
        "python3",
        "planningops/scripts/validate_worker_task_pack.py",
        "--runtime-profile-file",
        runtime_profile_file,
        "--task-key",
        task_key,
        "--issue-number",
        str(issue_num),
        "--mode",
        mode,
        "--loop-profile",
        loop_profile,
        "--target-repo",
        selected.get("target_repo") or selected.get("issue_repo") or "",
        "--output",
        str(report_path),
        "--strict",
    ]
    rc, out, err = run(cmd)
    report_doc = {}
    if report_path.exists():
        try:
            report_doc = load_json(report_path, {})
        except Exception:  # noqa: BLE001
            report_doc = {}
    worker_task_pack = report_doc.get("worker_task_pack") if isinstance(report_doc, dict) else None
    return {
        "status": "pass" if rc == 0 else "fail",
        "reason_code": "worker_task_pack_ok" if rc == 0 else "worker_task_pack_invalid",
        "report_path": str(report_path),
        "rc": rc,
        "stdout": out[-2000:],
        "stderr": err[-2000:],
        "worker_task_pack": worker_task_pack,
        "validation_errors": report_doc.get("validation_errors", []) if isinstance(report_doc, dict) else [],
    }


def issue_is_closed(issue_num: int, repo: str):
    rc, out, err = run(["gh", "issue", "view", str(issue_num), "--repo", repo, "--json", "state", "--jq", ".state"])
    if rc != 0:
        return False
    return out.strip().upper() == "CLOSED"


def parse_csv(value: str):
    return [x.strip() for x in value.split(",") if x.strip()]


def parse_attempt_budget(issue_body: str):
    budget = dict(DEFAULT_ATTEMPT_BUDGET)
    errors = []
    for line in issue_body.splitlines():
        m = re.match(
            r"\s*(max_attempts|max_duration_minutes|max_token_budget)\s*:\s*(\S+)\s*$",
            line,
            re.IGNORECASE,
        )
        if not m:
            continue
        key = m.group(1).lower()
        raw = m.group(2).strip()
        if raw.isdigit():
            value = int(raw)
            if value <= 0:
                errors.append(f"{key} must be positive integer")
            else:
                budget[key] = value
            continue

        if raw.startswith("-") and raw[1:].isdigit():
            errors.append(f"{key} must be positive integer")
        else:
            errors.append(f"{key} must be integer")

    return budget, sorted(set(errors))


def main():
    parser = argparse.ArgumentParser(description="Issue intake and feedback loop runner")
    parser.add_argument("--owner", default="rather-not-work-on")
    parser.add_argument("--control-repo", default="rather-not-work-on/platform-planningops")
    parser.add_argument("--project-num", type=int, default=2)
    parser.add_argument("--project-id", default="PVT_kwDOD8NujM4BQYNE")
    parser.add_argument("--initiative", default="unified-personal-agent-platform")
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="apply")
    parser.add_argument(
        "--pec-preflight-mode",
        choices=["legacy", "hybrid", "strict-pec"],
        default="hybrid",
        help="Preflight strictness for Plan Execution Contract checks",
    )
    parser.add_argument(
        "--pec-contract-file",
        default=None,
        help="Optional PEC contract JSON file for runner preflight alignment checks",
    )
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
    parser.add_argument(
        "--resume-from-checkpoint",
        action="store_true",
        help="Resume from saved checkpoint for selected issue if available",
    )
    parser.add_argument(
        "--simulate-interrupt-after",
        choices=["pre_hook", "loop_executed", "verified", "feedback_applied"],
        default=None,
        help="Testing hook: stop after a checkpoint stage and return non-zero",
    )
    parser.add_argument(
        "--lease-ttl-seconds",
        type=int,
        default=900,
        help="Lease lock TTL in seconds for duplicate/zombie execution prevention",
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
        issue_body = issue_doc.get("body", "")
        deps = parse_depends_on(issue_body)
        plan_item_id = parse_plan_item_id(issue_body)
        attempt_budget, budget_errors = parse_attempt_budget(issue_body)
        selector_hints = parse_selector_hints(issue_body)
        blueprint_meta = parse_blueprint_refs(issue_body)
        c["plan_item_id"] = plan_item_id
        if budget_errors:
            selection_attempts.append(
                {
                    "number": num,
                    "issue_repo": issue_repo,
                    "result": "invalid_attempt_budget",
                    "plan_item_id": plan_item_id,
                    "attempt_budget_errors": budget_errors,
                }
            )
            continue
        if c.get("workflow_state") == "ready-implementation" and not blueprint_meta["complete"]:
            selection_attempts.append(
                {
                    "number": num,
                    "issue_repo": issue_repo,
                    "result": "missing_blueprint_refs",
                    "plan_item_id": plan_item_id,
                    "missing_refs": blueprint_meta["missing"],
                    "blueprint_refs": blueprint_meta["refs"],
                    "selector_hints": selector_hints,
                }
            )
            continue
        closed_checks = [{"dep": dep, "closed": issue_is_closed(dep, issue_repo)} for dep in deps]
        if all(x["closed"] for x in closed_checks):
            c["deps"] = deps
            c["attempt_budget"] = attempt_budget
            c["simulation_required"] = selector_hints["simulation_required"]
            c["uncertainty_level"] = selector_hints["uncertainty_level"]
            c["blueprint_refs"] = blueprint_meta["refs"]
            c["blueprint_complete"] = blueprint_meta["complete"]
            selected = c
            selection_attempts.append(
                {
                    "number": num,
                    "issue_repo": issue_repo,
                    "result": "selected",
                    "plan_item_id": plan_item_id,
                    "depends_on": deps,
                    "dep_checks": closed_checks,
                    "attempt_budget": attempt_budget,
                    "selector_hints": selector_hints,
                    "blueprint_refs": blueprint_meta["refs"],
                }
            )
            break
        selection_attempts.append(
            {
                "number": num,
                "issue_repo": issue_repo,
                "result": "dependency_blocked",
                "plan_item_id": plan_item_id,
                "depends_on": deps,
                "dep_checks": closed_checks,
                "selector_hints": selector_hints,
                "blueprint_refs": blueprint_meta["refs"],
            }
        )

    selection_trace = build_selection_trace(candidates, selected, selection_attempts, allowed_workflow_states)
    selection_trace["pec_preflight"] = {
        "mode": args.pec_preflight_mode,
        "contract_file": args.pec_contract_file,
        "status": "not_evaluated",
        "reason_code": "selected_issue_missing",
    }

    if selected is None:
        print(json.dumps({"result": "no_eligible_todo_issue", "selection_trace": selection_trace}, ensure_ascii=True))
        return 2

    pec_preflight = evaluate_pec_preflight(
        args.pec_preflight_mode,
        args.pec_contract_file,
        selected,
        args.initiative,
    )
    selection_trace["pec_preflight"] = pec_preflight
    if pec_preflight.get("status") == "fail":
        print(
            json.dumps(
                {
                    "result": "pec_preflight_failed",
                    "issue_number": selected.get("number"),
                    "issue_repo": selected.get("issue_repo"),
                    "plan_item_id": selected.get("plan_item_id"),
                    "pec_preflight": pec_preflight,
                    "selection_trace": selection_trace,
                },
                ensure_ascii=True,
            )
        )
        return 5

    selected_loop_profile = determine_loop_profile(selected, {}, args.control_repo)
    worker_task_pack_preflight = evaluate_worker_task_pack_preflight(
        runtime_profile_file=args.runtime_profile_file,
        selected=selected,
        mode=args.mode,
        loop_profile=selected_loop_profile,
    )
    selection_trace["worker_task_pack_preflight"] = worker_task_pack_preflight
    if worker_task_pack_preflight.get("status") == "fail":
        print(
            json.dumps(
                {
                    "result": "worker_task_pack_preflight_failed",
                    "issue_number": selected.get("number"),
                    "issue_repo": selected.get("issue_repo"),
                    "target_repo": selected.get("target_repo"),
                    "plan_item_id": selected.get("plan_item_id"),
                    "loop_profile": selected_loop_profile,
                    "worker_task_pack_preflight": worker_task_pack_preflight,
                    "selection_trace": selection_trace,
                },
                ensure_ascii=True,
            )
        )
        return 6

    selected_attempt_budget = selected.get("attempt_budget", dict(DEFAULT_ATTEMPT_BUDGET))
    max_attempts = int(selected_attempt_budget.get("max_attempts", DEFAULT_ATTEMPT_BUDGET["max_attempts"]))
    if max_attempts <= 0:
        print(
            json.dumps(
                {
                    "result": "attempt_budget_invalid",
                    "issue_number": selected.get("number"),
                    "issue_repo": selected.get("issue_repo"),
                    "plan_item_id": selected.get("plan_item_id"),
                    "attempt_budget": selected_attempt_budget,
                    "selection_trace": selection_trace,
                },
                ensure_ascii=True,
            )
        )
        return 7

    worker_pack = worker_task_pack_preflight.get("worker_task_pack") or {}
    retry_policy = worker_pack.get("retry_policy") if isinstance(worker_pack, dict) else {}
    max_retries = int((retry_policy or {}).get("max_retries", 0))
    retry_cap_attempts = max_retries + 1
    enforced_attempts = min(max_attempts, retry_cap_attempts)
    selection_trace["attempt_budget_guard"] = {
        "attempt_budget": selected_attempt_budget,
        "max_attempts": max_attempts,
        "max_retries": max_retries,
        "retry_cap_attempts": retry_cap_attempts,
        "enforced_worker_attempts": enforced_attempts,
    }

    issue_num = selected["number"]
    lock_owner_id = f"issue-loop-runner-{os.getpid()}-{int(datetime.now(timezone.utc).timestamp())}"
    lock_acquired, lock_doc, stale_lock_recovered = acquire_issue_lock(issue_num, lock_owner_id, args.lease_ttl_seconds)
    watchdog_events = [
        {
            "event": "lock_attempt",
            "decided_at_utc": datetime.now(timezone.utc).isoformat(),
            "issue_number": issue_num,
            "lock_owner_id": lock_owner_id,
            "lock_acquired": lock_acquired,
            "stale_lock_recovered": stale_lock_recovered,
        }
    ]
    watchdog_path = WATCHDOG_DIR / f"issue-{issue_num}.json"

    if not lock_acquired:
        WATCHDOG_DIR.mkdir(parents=True, exist_ok=True)
        save_json(
            watchdog_path,
            {
                "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                "issue_number": issue_num,
                "verdict": "lock_conflict",
                "lock_owner_id": lock_owner_id,
                "active_lock": lock_doc,
                "events": watchdog_events,
            },
        )
        print(
            json.dumps(
                {
                    "result": "lock_conflict",
                    "issue_number": issue_num,
                    "active_lock_owner": lock_doc.get("owner_id"),
                    "watchdog_report": str(watchdog_path),
                },
                ensure_ascii=True,
            )
        )
        return 4

    resume_checkpoint = load_checkpoint(issue_num) if args.resume_from_checkpoint else {}
    resume_stage = resume_checkpoint.get("stage") if resume_checkpoint else None
    adapter = resolve_execution_adapter(selected.get("target_repo") or selected.get("issue_repo"))
    adapter_context = {
        "issue_number": issue_num,
        "issue_repo": selected.get("issue_repo"),
        "target_repo": selected.get("target_repo"),
        "workflow_state": selected.get("workflow_state"),
        "loop_profile": selected_loop_profile,
        "mode": args.mode,
        "runtime_profile_file": args.runtime_profile_file,
        "pec_preflight_mode": args.pec_preflight_mode,
        "pec_contract_file": args.pec_contract_file,
        "selection_trace": selection_trace,
        "selection_transition_id": "",
    }
    if resume_stage in {"pre_hook", "loop_executed", "verified", "feedback_applied"} and resume_checkpoint.get(
        "adapter_pre_hook"
    ):
        pre_hook_result = resume_checkpoint.get("adapter_pre_hook")
    else:
        pre_hook_result = invoke_adapter_hook(adapter, "before_loop", context=adapter_context)
    save_checkpoint(
        issue_num,
        "pre_hook",
        {
            "selected_issue_repo": selected.get("issue_repo"),
            "selected_target_repo": selected.get("target_repo"),
            "selected_workflow_state": selected.get("workflow_state"),
            "selected_loop_profile": selected_loop_profile,
            "selected_plan_item_id": selected.get("plan_item_id"),
            "attempt_budget": selected_attempt_budget,
            "attempt_budget_guard": selection_trace.get("attempt_budget_guard", {}),
            "pec_preflight": pec_preflight,
            "adapter_pre_hook": pre_hook_result,
        },
    )
    watchdog_events.append(
        {
            "event": "pre_hook_checkpoint_saved",
            "decided_at_utc": datetime.now(timezone.utc).isoformat(),
            "heartbeat_refreshed": heartbeat_issue_lock(issue_num, lock_owner_id, args.lease_ttl_seconds),
        }
    )
    if args.simulate_interrupt_after == "pre_hook":
        release_ok = release_issue_lock(issue_num, lock_owner_id)
        save_json(
            watchdog_path,
            {
                "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                "issue_number": issue_num,
                "verdict": "interrupted",
                "stage": "pre_hook",
                "release_ok": release_ok,
                "events": watchdog_events,
            },
        )
        print(json.dumps({"result": "interrupted", "stage": "pre_hook", "issue_number": issue_num}, ensure_ascii=True))
        return 3

    reused_loop_artifacts = False
    if args.resume_from_checkpoint and resume_stage in {"loop_executed", "verified", "feedback_applied"}:
        checkpoint_loop_dir = Path(resume_checkpoint.get("loop_dir", ""))
        if checkpoint_loop_dir.exists():
            loop_dir = checkpoint_loop_dir
            date_part = resume_checkpoint.get("date_part", loop_dir.parent.name)
            loop_id = resume_checkpoint.get("loop_id", loop_dir.name)
            rc_loop = int(resume_checkpoint.get("loop_rc", 0))
            out_loop = str(resume_checkpoint.get("loop_stdout", "resumed-from-checkpoint"))
            err_loop = str(resume_checkpoint.get("loop_stderr", ""))
            reused_loop_artifacts = True
        else:
            resume_stage = None

    if not reused_loop_artifacts:
        # run loop with runtime-window heartbeat pump and lock drift detection
        loop_run = run_with_runtime_heartbeat(
            command=[
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
                "--max-attempts",
                str(max_attempts),
                "--worker-task-pack-report",
                str(worker_task_pack_preflight.get("report_path")),
            ],
            issue_num=issue_num,
            owner_id=lock_owner_id,
            ttl_seconds=args.lease_ttl_seconds,
        )
        rc_loop = loop_run["return_code"]
        out_loop = loop_run["stdout"]
        err_loop = loop_run["stderr"]
        watchdog_events.extend(loop_run["heartbeat_events"])

        if loop_run["drift_detected"]:
            release_ok = release_issue_lock(issue_num, lock_owner_id)
            watchdog_events.append(
                {
                    "event": "lock_released_after_runtime_drift",
                    "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                    "release_ok": release_ok,
                }
            )
            save_json(
                watchdog_path,
                {
                    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                    "issue_number": issue_num,
                    "verdict": "fail",
                    "stage": "loop_executed",
                    "reason_code": loop_run["drift_reason"],
                    "release_ok": release_ok,
                    "events": watchdog_events,
                },
            )
            clear_checkpoint(issue_num)
            print(
                json.dumps(
                    {
                        "result": "runtime_lock_drift_detected",
                        "issue_number": issue_num,
                        "reason_code": loop_run["drift_reason"],
                        "watchdog_report": str(watchdog_path),
                    },
                    ensure_ascii=True,
                )
            )
            return 8

        # find latest loop dir for this issue
        loop_root = Path("planningops/artifacts/loops")
        loop_dirs = sorted(loop_root.glob(f"*/loop-*-issue-{issue_num}"))
        if not loop_dirs:
            release_ok = release_issue_lock(issue_num, lock_owner_id)
            save_json(
                watchdog_path,
                {
                    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                    "issue_number": issue_num,
                    "verdict": "fail",
                    "stage": "loop_executed",
                    "reason": "missing_loop_artifacts",
                    "release_ok": release_ok,
                    "events": watchdog_events,
                },
            )
            print("loop execution did not produce artifacts")
            return 1
        loop_dir = loop_dirs[-1]
        date_part = loop_dir.parent.name
        loop_id = loop_dir.name
        save_checkpoint(
            issue_num,
            "loop_executed",
            {
                "loop_dir": str(loop_dir),
                "date_part": date_part,
                "loop_id": loop_id,
                "loop_rc": rc_loop,
                "loop_stdout": out_loop[-2000:],
                "loop_stderr": err_loop[-2000:],
                "adapter_pre_hook": pre_hook_result,
            },
        )
        watchdog_events.append(
            {
                "event": "loop_executed_checkpoint_saved",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "heartbeat_refreshed": heartbeat_issue_lock(issue_num, lock_owner_id, args.lease_ttl_seconds),
            }
        )
        if args.simulate_interrupt_after == "loop_executed":
            release_ok = release_issue_lock(issue_num, lock_owner_id)
            save_json(
                watchdog_path,
                {
                    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                    "issue_number": issue_num,
                    "verdict": "interrupted",
                    "stage": "loop_executed",
                    "release_ok": release_ok,
                    "events": watchdog_events,
                },
            )
            print(
                json.dumps(
                    {"result": "interrupted", "stage": "loop_executed", "issue_number": issue_num},
                    ensure_ascii=True,
                )
            )
            return 3

    transition_log = Path(f"planningops/artifacts/transition-log/{date_part}.ndjson")
    transition_log_runtime = ARTIFACT_SINK.runtime_path(transition_log)
    adapter_artifact_dir = Path(f"planningops/artifacts/adapter-hooks/{date_part}")
    pre_hook_path = adapter_artifact_dir / f"{loop_id}-adapter-pre.json"
    save_json(pre_hook_path, pre_hook_result)
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
        "loop_profile": selected_loop_profile,
        "selection_trace": selection_trace,
        "adapter_pre_hook": pre_hook_result,
    }
    append_ndjson(transition_log, selection_event)
    adapter_context["loop_id"] = loop_id
    adapter_context["selection_transition_id"] = selection_event["transition_id"]

    verification_path = Path(f"planningops/artifacts/verification/issue-{issue_num}-verification.json")
    payload_path = Path(f"planningops/artifacts/verification/issue-{issue_num}-project-payload.json")
    reused_verify_artifacts = False
    if args.resume_from_checkpoint and resume_stage in {"verified", "feedback_applied"}:
        checkpoint_verification_path = Path(resume_checkpoint.get("verification_path", ""))
        checkpoint_payload_path = Path(resume_checkpoint.get("payload_path", ""))
        if checkpoint_verification_path.exists() and checkpoint_payload_path.exists():
            verification_path = checkpoint_verification_path
            payload_path = checkpoint_payload_path
            rc_verify, out_verify, err_verify = 0, "resumed-from-checkpoint", ""
            reused_verify_artifacts = True

    if not reused_verify_artifacts:
        rc_verify, out_verify, err_verify = run(
            [
                "python3",
                "planningops/scripts/verify_loop_run.py",
                "--loop-dir",
                str(loop_dir),
                "--transition-log",
                str(transition_log_runtime),
                "--output",
                str(verification_path),
                "--project-payload",
                str(payload_path),
            ]
        )
        save_checkpoint(
            issue_num,
            "verified",
            {
                "loop_dir": str(loop_dir),
                "date_part": date_part,
                "loop_id": loop_id,
                "verification_path": str(verification_path),
                "payload_path": str(payload_path),
                "verify_rc": rc_verify,
                "verify_stdout": out_verify[-2000:],
                "verify_stderr": err_verify[-2000:],
                "adapter_pre_hook": pre_hook_result,
            },
        )
        watchdog_events.append(
            {
                "event": "verified_checkpoint_saved",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "heartbeat_refreshed": heartbeat_issue_lock(issue_num, lock_owner_id, args.lease_ttl_seconds),
            }
        )
        if args.simulate_interrupt_after == "verified":
            release_ok = release_issue_lock(issue_num, lock_owner_id)
            save_json(
                watchdog_path,
                {
                    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                    "issue_number": issue_num,
                    "verdict": "interrupted",
                    "stage": "verified",
                    "release_ok": release_ok,
                    "events": watchdog_events,
                },
            )
            print(json.dumps({"result": "interrupted", "stage": "verified", "issue_number": issue_num}, ensure_ascii=True))
            return 3

    verification = load_json(verification_path, {})
    payload = load_json(payload_path, {})
    final_loop_profile = determine_loop_profile(selected, payload, args.control_repo)
    payload["loop_profile"] = final_loop_profile
    adapter_context["loop_profile"] = final_loop_profile
    post_hook_result = invoke_adapter_hook(adapter, "after_loop", context=adapter_context, payload=payload)
    post_hook_path = adapter_artifact_dir / f"{loop_id}-adapter-post.json"
    save_json(post_hook_path, post_hook_result)

    escalation = evaluate_escalation(
        issue_num,
        str(payload.get("last_verdict", "")),
        str(payload.get("reason_code", "")),
    )
    replan_decision_path = None
    payload["escalation"] = escalation
    payload["auto_paused"] = escalation.get("auto_paused", False)
    if escalation.get("auto_paused"):
        payload["status_update"] = "Blocked"
        payload["replanning_triggered"] = True
        replan_decision_path = Path(
            f"planningops/artifacts/replan/issue-{issue_num}-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.md"
        )
        save_text(
            replan_decision_path,
            "\n".join(
                [
                    f"# Replan Decision for issue #{issue_num}",
                    "",
                    f"- trigger_type: {escalation.get('trigger_type')}",
                    f"- same_reason_consecutive: {escalation.get('same_reason_consecutive')}",
                    f"- inconclusive_consecutive: {escalation.get('inconclusive_consecutive')}",
                    f"- decided_at_utc: {datetime.now(timezone.utc).isoformat()}",
                    "",
                    "Action: auto-pause current execution path and require recovery/replan loop (L5).",
                ]
            ),
        )
        payload["replan_decision_path"] = str(replan_decision_path)
        append_ndjson(
            transition_log,
            {
                "transition_id": f"{loop_id}-auto-pause",
                "run_id": loop_id,
                "card_id": issue_num,
                "from_state": selected.get("workflow_state", "ready-contract"),
                "to_state": "blocked",
                "transition_reason": "escalation.auto_pause",
                "actor_type": "agent",
                "actor_id": "issue-loop-runner",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "replanning_flag": True,
            },
        )

    replenishment_candidates = build_replenishment_candidates(
        issue_num=issue_num,
        payload=payload,
        selected=selected,
        verification_path=verification_path,
        payload_path=payload_path,
        watchdog_path=watchdog_path,
        replan_decision_path=replan_decision_path,
    )
    replenishment_path = Path(f"planningops/artifacts/backlog/issue-{issue_num}-replenishment-candidates.json")
    save_json(
        replenishment_path,
        {
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "issue_number": issue_num,
            "issue_repo": selected.get("issue_repo"),
            "target_repo": selected.get("target_repo"),
            "last_verdict": payload.get("last_verdict"),
            "reason_code": payload.get("reason_code"),
            "candidate_count": len(replenishment_candidates),
            "candidates": replenishment_candidates,
        },
    )
    payload["replenishment_candidates_path"] = str(replenishment_path)
    payload["replenishment_candidates_count"] = len(replenishment_candidates)
    if replenishment_candidates:
        append_ndjson(
            transition_log,
            {
                "transition_id": f"{loop_id}-backlog-replenishment",
                "run_id": loop_id,
                "card_id": issue_num,
                "from_state": selected.get("workflow_state", "ready-contract"),
                "to_state": selected.get("workflow_state", "ready-contract"),
                "transition_reason": "backlog.replenishment.generated",
                "actor_type": "agent",
                "actor_id": "issue-loop-runner",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "replanning_flag": bool(payload.get("replanning_triggered")),
                "candidate_count": len(replenishment_candidates),
                "candidate_ids": [c.get("candidate_id") for c in replenishment_candidates],
            },
        )
    save_json(payload_path, payload)

    verification_loop_ref = verification.get("loop_dir", "")
    idem_key = hashlib.sha256(
        f"issue:{issue_num}:{verification_loop_ref}:{payload.get('last_verdict','')}".encode("utf-8")
    ).hexdigest()
    idem = load_json(IDEMPOTENCY_PATH, {"processed_keys": []})
    seen = set(idem.get("processed_keys", []))

    already_processed = idem_key in seen

    comment_body = "\n".join(
        [
            f"Ralph Loop result for issue #{issue_num}",
            f"- verdict: {payload.get('last_verdict', 'unknown')}",
            f"- reason_code: {payload.get('reason_code', 'unknown')}",
            f"- loop_profile: {final_loop_profile}",
            f"- replanning_triggered: {payload.get('replanning_triggered', False)}",
            f"- auto_paused: {payload.get('auto_paused', False)}",
            f"- adapter: {getattr(adapter, 'adapter_id', 'unknown-adapter')} ({selected.get('target_repo')})",
            f"- adapter_pre: {pre_hook_result.get('status')} / {pre_hook_result.get('reason_code')}",
            f"- adapter_post: {post_hook_result.get('status')} / {post_hook_result.get('reason_code')}",
            f"- verification: planningops/artifacts/verification/issue-{issue_num}-verification.json",
            f"- payload: planningops/artifacts/verification/issue-{issue_num}-project-payload.json",
            f"- adapter_pre_artifact: {pre_hook_path}",
            f"- adapter_post_artifact: {post_hook_path}",
            f"- replan_decision: {replan_decision_path}" if replan_decision_path else "- replan_decision: none",
            f"- replenishment_candidates: {replenishment_path} ({len(replenishment_candidates)})",
        ]
    )

    feedback_error = None
    if not already_processed and not args.no_feedback:
        try:
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

                loop_profile_field_id, loop_profile_options = ensure_single_select_field(
                    args.owner,
                    args.project_num,
                    "loop_profile",
                    [
                        "L1 Contract-Clarification",
                        "L2 Simulation",
                        "L3 Implementation-TDD",
                        "L4 Integration-Reconcile",
                        "L5 Recovery-Replan",
                    ],
                )

                # ensure verdict text fields exist
                verdict_field_id = ensure_text_field(args.owner, args.project_num, "last_verdict")
                reason_field_id = ensure_text_field(args.owner, args.project_num, "last_reason")
                if item_id:
                    if loop_profile_field_id and final_loop_profile in loop_profile_options:
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
                                loop_profile_field_id,
                                "--single-select-option-id",
                                loop_profile_options.get(final_loop_profile),
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
        except Exception as exc:  # noqa: BLE001
            feedback_error = str(exc)

    if feedback_error:
        payload["last_verdict"] = "fail"
        payload["reason_code"] = "feedback_failed"
        payload["status_update"] = "Blocked"
        payload["replanning_triggered"] = True
        payload["feedback_error"] = feedback_error
        save_json(payload_path, payload)
        append_ndjson(
            transition_log,
            {
                "transition_id": f"{loop_id}-feedback-failed",
                "run_id": loop_id,
                "card_id": issue_num,
                "from_state": selected.get("workflow_state", "ready-contract"),
                "to_state": "blocked",
                "transition_reason": "feedback.failed",
                "actor_type": "agent",
                "actor_id": "issue-loop-runner",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "replanning_flag": True,
                "loop_profile": final_loop_profile,
                "reason_code": "feedback_failed",
                "error": feedback_error,
            },
        )
        release_ok = release_issue_lock(issue_num, lock_owner_id)
        watchdog_events.append(
            {
                "event": "feedback_failed",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "release_ok": release_ok,
                "error": feedback_error,
            }
        )
        save_json(
            watchdog_path,
            {
                "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                "issue_number": issue_num,
                "verdict": "fail",
                "stage": "feedback_applied",
                "reason_code": "feedback_failed",
                "release_ok": release_ok,
                "events": watchdog_events,
            },
        )
        clear_checkpoint(issue_num)
        failure_result = {
            "selected_issue": issue_num,
            "selected_issue_repo": selected.get("issue_repo"),
            "selected_target_repo": selected.get("target_repo"),
            "selected_workflow_state": selected.get("workflow_state"),
            "selected_loop_profile": selected_loop_profile,
            "selected_plan_item_id": selected.get("plan_item_id"),
            "attempt_budget": selected_attempt_budget,
            "attempt_budget_guard": selection_trace.get("attempt_budget_guard", {}),
            "final_loop_profile": final_loop_profile,
            "lock_owner_id": lock_owner_id,
            "watchdog_report": str(watchdog_path),
            "reason_code": "feedback_failed",
            "last_verdict": "fail",
            "feedback_error": feedback_error,
            "selection_trace": selection_trace,
            "pec_preflight": pec_preflight,
            "adapter_id": getattr(adapter, "adapter_id", "unknown-adapter"),
            "adapter_pre_hook": pre_hook_result,
            "adapter_post_hook": post_hook_result,
            "adapter_pre_artifact": str(pre_hook_path),
            "adapter_post_artifact": str(post_hook_path),
            "replenishment_candidates_path": str(replenishment_path),
            "replenishment_candidates_count": len(replenishment_candidates),
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "runtime_profile_file": args.runtime_profile_file,
            "no_feedback": args.no_feedback,
        }
        failure_result["externalized_artifact_files"] = externalize_and_prune_external_cache(
            loop_dir=loop_dir,
            adapter_artifact_dir=adapter_artifact_dir,
            transition_log=transition_log,
        )
        out_path = Path("planningops/artifacts/loop-runner/last-run.json")
        save_json(out_path, failure_result)
        print(json.dumps(failure_result, ensure_ascii=True, indent=2))
        return 1

    checkpoint_payload = {
        "loop_dir": str(loop_dir),
        "date_part": date_part,
        "loop_id": loop_id,
        "verification_path": str(verification_path),
        "payload_path": str(payload_path),
        "adapter_pre_hook": pre_hook_result,
        "adapter_post_hook": post_hook_result,
        "already_processed": already_processed,
        "idempotency_key": idem_key,
    }
    save_checkpoint(issue_num, "feedback_applied", checkpoint_payload)
    watchdog_events.append(
        {
            "event": "feedback_applied_checkpoint_saved",
            "decided_at_utc": datetime.now(timezone.utc).isoformat(),
            "heartbeat_refreshed": heartbeat_issue_lock(issue_num, lock_owner_id, args.lease_ttl_seconds),
        }
    )
    if args.simulate_interrupt_after == "feedback_applied":
        release_ok = release_issue_lock(issue_num, lock_owner_id)
        save_json(
            watchdog_path,
            {
                "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                "issue_number": issue_num,
                "verdict": "interrupted",
                "stage": "feedback_applied",
                "release_ok": release_ok,
                "events": watchdog_events,
            },
        )
        print(json.dumps({"result": "interrupted", "stage": "feedback_applied", "issue_number": issue_num}, ensure_ascii=True))
        return 3
    release_ok = release_issue_lock(issue_num, lock_owner_id)
    watchdog_events.append(
        {
            "event": "lock_released",
            "decided_at_utc": datetime.now(timezone.utc).isoformat(),
            "release_ok": release_ok,
        }
    )
    save_json(
        watchdog_path,
        {
            "generated_at_utc": datetime.now(timezone.utc).isoformat(),
            "issue_number": issue_num,
            "verdict": "pass",
            "stage": "feedback_applied",
            "release_ok": release_ok,
            "stale_lock_recovered": stale_lock_recovered,
            "events": watchdog_events,
        },
    )
    clear_checkpoint(issue_num)

    result = {
        "selected_issue": issue_num,
        "selected_issue_repo": selected.get("issue_repo"),
        "selected_target_repo": selected.get("target_repo"),
        "selected_workflow_state": selected.get("workflow_state"),
        "selected_loop_profile": selected_loop_profile,
        "selected_plan_item_id": selected.get("plan_item_id"),
        "attempt_budget": selected_attempt_budget,
        "attempt_budget_guard": selection_trace.get("attempt_budget_guard", {}),
        "checkpoint_resumed": bool(args.resume_from_checkpoint and resume_checkpoint),
        "checkpoint_stage_at_start": resume_stage,
        "lock_owner_id": lock_owner_id,
        "stale_lock_recovered": stale_lock_recovered,
        "watchdog_report": str(watchdog_path),
        "final_loop_profile": final_loop_profile,
        "auto_paused": payload.get("auto_paused", False),
        "escalation": escalation,
        "replan_decision_path": str(replan_decision_path) if replan_decision_path else None,
        "deps": selected.get("deps", []),
        "candidate_count": len(candidates),
        "allowed_workflow_states": sorted(allowed_workflow_states),
        "selection_trace": selection_trace,
        "pec_preflight": pec_preflight,
        "selection_transition_id": selection_event["transition_id"],
        "blueprint_refs": selected.get("blueprint_refs", {}),
        "blueprint_complete": selected.get("blueprint_complete", True),
        "adapter_id": getattr(adapter, "adapter_id", "unknown-adapter"),
        "adapter_pre_hook": pre_hook_result,
        "adapter_post_hook": post_hook_result,
        "adapter_pre_artifact": str(pre_hook_path),
        "adapter_post_artifact": str(post_hook_path),
        "replenishment_candidates_path": str(replenishment_path),
        "replenishment_candidates_count": len(replenishment_candidates),
        "last_verdict": payload.get("last_verdict", "unknown"),
        "reason_code": payload.get("reason_code", "unknown"),
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
    result["externalized_artifact_files"] = externalize_and_prune_external_cache(
        loop_dir=loop_dir,
        adapter_artifact_dir=adapter_artifact_dir,
        transition_log=transition_log,
    )
    out_path = Path("planningops/artifacts/loop-runner/last-run.json")
    save_json(out_path, result)
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
