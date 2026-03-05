#!/usr/bin/env python3

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
from datetime import datetime, timezone, timedelta

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from repo_execution_adapters import invoke_adapter_hook, resolve_execution_adapter


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
HIGH_VALUE_READY_STATES = {"ready-contract", "ready-implementation"}


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


def checkpoint_path(issue_num: int):
    return CHECKPOINT_DIR / f"issue-{issue_num}.json"


def load_checkpoint(issue_num: int):
    path = checkpoint_path(issue_num)
    return load_json(path, {})


def save_checkpoint(issue_num: int, stage: str, data: dict):
    payload = dict(data)
    payload["issue_number"] = issue_num
    payload["stage"] = stage
    payload["updated_at_utc"] = datetime.now(timezone.utc).isoformat()
    save_json(checkpoint_path(issue_num), payload)


def clear_checkpoint(issue_num: int):
    path = checkpoint_path(issue_num)
    if path.exists():
        path.unlink()


def lock_path(issue_num: int):
    return LOCK_DIR / f"issue-{issue_num}.lock.json"


def parse_iso8601(value: str):
    try:
        return datetime.fromisoformat(value)
    except Exception:  # noqa: BLE001
        return None


def acquire_issue_lock(issue_num: int, owner_id: str, ttl_seconds: int):
    now = datetime.now(timezone.utc)
    path = lock_path(issue_num)
    LOCK_DIR.mkdir(parents=True, exist_ok=True)

    stale_recovered = False
    if path.exists():
        doc = load_json(path, {})
        expires_at = parse_iso8601(str(doc.get("expires_at_utc", "")))
        if expires_at and expires_at > now and doc.get("owner_id") != owner_id:
            return False, doc, stale_recovered
        stale_recovered = True

    lock_doc = {
        "issue_number": issue_num,
        "owner_id": owner_id,
        "acquired_at_utc": now.isoformat(),
        "last_heartbeat_utc": now.isoformat(),
        "expires_at_utc": (now + timedelta(seconds=ttl_seconds)).isoformat(),
    }
    save_json(path, lock_doc)
    return True, lock_doc, stale_recovered


def heartbeat_issue_lock(issue_num: int, owner_id: str, ttl_seconds: int):
    path = lock_path(issue_num)
    if not path.exists():
        return False
    doc = load_json(path, {})
    if doc.get("owner_id") != owner_id:
        return False

    now = datetime.now(timezone.utc)
    doc["last_heartbeat_utc"] = now.isoformat()
    doc["expires_at_utc"] = (now + timedelta(seconds=ttl_seconds)).isoformat()
    save_json(path, doc)
    return True


def release_issue_lock(issue_num: int, owner_id: str):
    path = lock_path(issue_num)
    if not path.exists():
        return True
    doc = load_json(path, {})
    if doc.get("owner_id") != owner_id:
        return False
    path.unlink()
    return True


def read_issue_lock(issue_num: int):
    path = lock_path(issue_num)
    if not path.exists():
        return {
            "exists": False,
            "path": str(path),
            "doc": {},
        }
    doc = load_json(path, {})
    return {
        "exists": True,
        "path": str(path),
        "doc": doc if isinstance(doc, dict) else {},
    }


def run_with_runtime_heartbeat(command, issue_num: int, owner_id: str, ttl_seconds: int):
    if ttl_seconds <= 0:
        raise ValueError("ttl_seconds must be positive")

    heartbeat_interval_seconds = max(1, ttl_seconds // 3)
    heartbeat_interval_seconds = min(heartbeat_interval_seconds, 30)
    started_at = datetime.now(timezone.utc).isoformat()

    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    stop_event = threading.Event()
    state = {
        "drift_detected": False,
        "drift_reason": "",
    }
    heartbeat_events = [
        {
            "event": "runtime_heartbeat_started",
            "decided_at_utc": started_at,
            "issue_number": issue_num,
            "lock_owner_id": owner_id,
            "pid": process.pid,
            "heartbeat_interval_seconds": heartbeat_interval_seconds,
        }
    ]
    event_lock = threading.Lock()

    def monitor_loop():
        while not stop_event.wait(heartbeat_interval_seconds):
            heartbeat_refreshed = heartbeat_issue_lock(issue_num, owner_id, ttl_seconds)
            lock_snapshot = read_issue_lock(issue_num)
            lock_owner = lock_snapshot["doc"].get("owner_id") if lock_snapshot["exists"] else None
            lock_owner_matches = bool(lock_snapshot["exists"]) and lock_owner == owner_id
            drift_reason = ""
            if not lock_owner_matches:
                drift_reason = "lock_owner_drift"
            elif not heartbeat_refreshed:
                drift_reason = "heartbeat_refresh_failed"

            event = {
                "event": "runtime_heartbeat_tick",
                "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                "issue_number": issue_num,
                "heartbeat_refreshed": heartbeat_refreshed,
                "lock_exists": lock_snapshot["exists"],
                "lock_owner": lock_owner,
                "lock_owner_matches": lock_owner_matches,
                "drift_detected": bool(drift_reason),
                "drift_reason": drift_reason or None,
            }
            with event_lock:
                heartbeat_events.append(event)

            if drift_reason:
                state["drift_detected"] = True
                state["drift_reason"] = drift_reason
                with event_lock:
                    heartbeat_events.append(
                        {
                            "event": "runtime_heartbeat_drift_detected",
                            "decided_at_utc": datetime.now(timezone.utc).isoformat(),
                            "issue_number": issue_num,
                            "drift_reason": drift_reason,
                        }
                    )
                try:
                    process.terminate()
                except Exception:  # noqa: BLE001
                    pass
                return

    monitor_thread = threading.Thread(target=monitor_loop, daemon=True)
    monitor_thread.start()
    out, err = process.communicate()
    stop_event.set()
    monitor_thread.join(timeout=1.0)
    ended_at = datetime.now(timezone.utc).isoformat()

    with event_lock:
        heartbeat_events.append(
            {
                "event": "runtime_heartbeat_stopped",
                "decided_at_utc": ended_at,
                "issue_number": issue_num,
                "return_code": process.returncode,
                "drift_detected": state["drift_detected"],
                "drift_reason": state["drift_reason"] or None,
            }
        )

    return {
        "return_code": int(process.returncode),
        "stdout": out.strip(),
        "stderr": err.strip(),
        "drift_detected": state["drift_detected"],
        "drift_reason": state["drift_reason"] or None,
        "heartbeat_events": heartbeat_events,
        "heartbeat_interval_seconds": heartbeat_interval_seconds,
    }


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

    same_reason_consecutive = 0
    if reason_code:
        for row in reversed(rows):
            if row.get("reason_code") == reason_code:
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


def parse_depends_on(issue_body: str):
    deps = set()
    for line in issue_body.splitlines():
        if "depends_on:" in line:
            deps.update(int(n) for n in re.findall(r"#(\d+)", line))
    return sorted(deps)


def parse_plan_item_id(issue_body: str):
    match = re.search(r"plan_item_id:\s*`([^`]+)`", issue_body or "")
    if not match:
        return None
    value = match.group(1).strip()
    return value or None


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


def parse_bool_token(raw: str):
    v = raw.strip().lower()
    if v in {"1", "true", "yes", "y", "on"}:
        return True
    if v in {"0", "false", "no", "n", "off"}:
        return False
    return None


def parse_selector_hints(issue_body: str):
    simulation_required = False
    uncertainty_level = None
    for line in issue_body.splitlines():
        m_sim = re.match(r"\s*simulation_required\s*:\s*(\S+)\s*$", line, re.IGNORECASE)
        if m_sim:
            parsed = parse_bool_token(m_sim.group(1))
            if parsed is not None:
                simulation_required = parsed
            continue

        m_unc = re.match(r"\s*uncertainty_level\s*:\s*(\S+)\s*$", line, re.IGNORECASE)
        if m_unc:
            raw = m_unc.group(1).strip().lower()
            if raw in {"low", "medium", "high", "critical"}:
                uncertainty_level = raw
    return {
        "simulation_required": simulation_required,
        "uncertainty_level": uncertainty_level,
    }


def parse_blueprint_refs(issue_body: str):
    required_keys = [
        "interface_contract_refs",
        "package_topology_ref",
        "dependency_manifest_ref",
        "file_plan_ref",
    ]
    refs = {}
    for key in required_keys:
        refs[key] = None
        for line in issue_body.splitlines():
            m = re.match(rf"\s*{key}\s*:\s*(.+)\s*$", line, re.IGNORECASE)
            if not m:
                continue
            value = m.group(1).strip()
            if value:
                refs[key] = value
            break

    missing = [k for k in required_keys if not refs.get(k)]
    return {
        "refs": refs,
        "missing": missing,
        "complete": len(missing) == 0,
    }


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
                "status": it.get("status"),
                "initiative": it.get("initiative"),
                "component": it.get("component"),
                "loop_profile": it.get("loop_profile"),
                "workflow_state": workflow_state,
                "issue_repo": issue_repo,
                "target_repo": target_repo,
            }
        )

    candidates.sort(
        key=lambda x: (
            0 if x.get("workflow_state") in HIGH_VALUE_READY_STATES else 1,
            x["order"],
            x["number"],
        )
    )
    return candidates


def build_selection_trace(candidates, selected, attempts, allowed_workflow_states):
    selected_ref = None
    if selected is not None:
        selected_ref = {
            "number": selected.get("number"),
            "order": selected.get("order"),
            "status": selected.get("status"),
            "workflow_state": selected.get("workflow_state"),
            "issue_repo": selected.get("issue_repo"),
            "target_repo": selected.get("target_repo"),
            "component": selected.get("component"),
            "loop_profile": selected.get("loop_profile"),
            "initiative": selected.get("initiative"),
            "plan_item_id": selected.get("plan_item_id"),
            "depends_on": selected.get("deps", []),
            "attempt_budget": selected.get("attempt_budget", dict(DEFAULT_ATTEMPT_BUDGET)),
            "simulation_required": selected.get("simulation_required", False),
            "uncertainty_level": selected.get("uncertainty_level"),
            "blueprint_refs": selected.get("blueprint_refs", {}),
            "blueprint_complete": selected.get("blueprint_complete", True),
        }

    return {
        "selection_policy": {
            "name": "high_value_ready_first",
            "ready_workflow_states": sorted(HIGH_VALUE_READY_STATES),
            "tie_breaker": ["execution_order_asc", "issue_number_asc"],
        },
        "allowed_workflow_states": sorted(allowed_workflow_states),
        "candidate_count": len(candidates),
        "candidates": [
            {
                "number": c.get("number"),
                "order": c.get("order"),
                "status": c.get("status"),
                "workflow_state": c.get("workflow_state"),
                "issue_repo": c.get("issue_repo"),
                "target_repo": c.get("target_repo"),
                "component": c.get("component"),
                "loop_profile": c.get("loop_profile"),
                "initiative": c.get("initiative"),
                "plan_item_id": c.get("plan_item_id"),
                "simulation_required": c.get("simulation_required", False),
                "uncertainty_level": c.get("uncertainty_level"),
                "blueprint_refs": c.get("blueprint_refs", {}),
                "blueprint_complete": c.get("blueprint_complete", True),
            }
            for c in candidates
        ],
        "attempts": attempts,
        "selected": selected_ref,
    }


def build_replenishment_candidates(
    issue_num: int,
    payload: dict,
    selected: dict,
    verification_path: Path,
    payload_path: Path,
    watchdog_path: Path,
    replan_decision_path: Path | None,
):
    verdict = str(payload.get("last_verdict", "")).lower()
    reason_code = str(payload.get("reason_code", "")).strip() or "unknown_reason"
    trigger = bool(payload.get("replanning_triggered")) or bool(payload.get("auto_paused"))
    if verdict not in {"fail", "inconclusive"} and not trigger:
        return []

    evidence_refs = [str(verification_path), str(payload_path), str(watchdog_path)]
    if replan_decision_path:
        evidence_refs.append(str(replan_decision_path))

    target_repo = selected.get("target_repo") or selected.get("issue_repo") or ""
    candidate = {
        "candidate_id": f"issue-{issue_num}-follow-up",
        "title": f"Recovery follow-up for issue #{issue_num} ({reason_code})",
        "target_repo": target_repo,
        "depends_on": [issue_num],
        "acceptance_criteria": [
            f"Root cause for `{reason_code}` is documented with evidence.",
            "Contract/plan references are updated before resuming implementation.",
            "A rerun exits escalation state without repeating the previous trigger.",
        ],
        "evidence_refs": evidence_refs,
        "generated_from": {
            "issue_number": issue_num,
            "verdict": verdict,
            "reason_code": reason_code,
        },
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    return [candidate]


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


def ensure_single_select_field(owner: str, project_num: int, field_name: str, option_names):
    rc, out, err = run(["gh", "project", "field-list", str(project_num), "--owner", owner, "--format", "json"])
    if rc != 0:
        raise RuntimeError(f"failed field-list: {err}")
    doc = json.loads(out)
    for f in doc.get("fields", []):
        if f.get("name") != field_name:
            continue
        options = {o.get("name"): o.get("id") for o in (f.get("options") or []) if o.get("name") and o.get("id")}
        missing = [opt for opt in option_names if opt not in options]
        if missing:
            raise RuntimeError(f"field '{field_name}' missing options: {missing}")
        return f.get("id"), options

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
            "SINGLE_SELECT",
            "--single-select-options",
            ",".join(option_names),
            "--format",
            "json",
        ]
    )
    if rc2 != 0:
        raise RuntimeError(f"failed field-create {field_name}: {err2}")
    field_doc = json.loads(out2)
    options = {o.get("name"): o.get("id") for o in (field_doc.get("options") or []) if o.get("name") and o.get("id")}
    return field_doc.get("id"), options


def determine_loop_profile(selected: dict, payload: dict, control_repo: str):
    if payload.get("replanning_triggered"):
        return "L5 Recovery-Replan"

    workflow_state = selected.get("workflow_state")
    target_repo = selected.get("target_repo") or selected.get("issue_repo")
    if workflow_state == "ready-contract":
        simulation_required = bool(selected.get("simulation_required")) or bool(payload.get("simulation_required"))
        uncertainty_level = str(selected.get("uncertainty_level") or payload.get("uncertainty_level") or "").lower()
        if simulation_required or uncertainty_level in {"medium", "high", "critical"}:
            return "L2 Simulation"
        return "L1 Contract-Clarification"
    if workflow_state == "ready-implementation":
        if target_repo and target_repo != control_repo:
            return "L4 Integration-Reconcile"
        return "L3 Implementation-TDD"
    if workflow_state == "blocked":
        return "L5 Recovery-Replan"
    return "L1 Contract-Clarification"


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
    adapter_artifact_dir = Path(f"planningops/artifacts/adapter-hooks/{date_part}")
    adapter_artifact_dir.mkdir(parents=True, exist_ok=True)
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
                str(transition_log),
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
        replan_decision_path.parent.mkdir(parents=True, exist_ok=True)
        replan_decision_path.write_text(
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
            encoding="utf-8",
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
    out_path = Path("planningops/artifacts/loop-runner/last-run.json")
    save_json(out_path, result)
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
