#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import threading
from datetime import datetime, timedelta, timezone
from pathlib import Path


def checkpoint_path(checkpoint_dir: Path, issue_num: int):
    return checkpoint_dir / f"issue-{issue_num}.json"


def load_checkpoint(checkpoint_dir: Path, load_json_fn, issue_num: int):
    return load_json_fn(checkpoint_path(checkpoint_dir, issue_num), {})


def save_checkpoint(checkpoint_dir: Path, save_json_fn, issue_num: int, stage: str, data: dict):
    payload = dict(data)
    payload["issue_number"] = issue_num
    payload["stage"] = stage
    payload["updated_at_utc"] = datetime.now(timezone.utc).isoformat()
    save_json_fn(checkpoint_path(checkpoint_dir, issue_num), payload)


def clear_checkpoint(checkpoint_dir: Path, issue_num: int):
    path = checkpoint_path(checkpoint_dir, issue_num)
    if path.exists():
        path.unlink()


def lock_path(lock_dir: Path, issue_num: int):
    return lock_dir / f"issue-{issue_num}.lock.json"


def parse_iso8601(value: str):
    try:
        return datetime.fromisoformat(value)
    except Exception:  # noqa: BLE001
        return None


def acquire_issue_lock(lock_dir: Path, load_json_fn, save_json_fn, issue_num: int, owner_id: str, ttl_seconds: int):
    now = datetime.now(timezone.utc)
    path = lock_path(lock_dir, issue_num)
    lock_dir.mkdir(parents=True, exist_ok=True)

    stale_recovered = False
    if path.exists():
        doc = load_json_fn(path, {})
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
    save_json_fn(path, lock_doc)
    return True, lock_doc, stale_recovered


def heartbeat_issue_lock(lock_dir: Path, load_json_fn, save_json_fn, issue_num: int, owner_id: str, ttl_seconds: int):
    path = lock_path(lock_dir, issue_num)
    if not path.exists():
        return False
    doc = load_json_fn(path, {})
    if doc.get("owner_id") != owner_id:
        return False

    now = datetime.now(timezone.utc)
    doc["last_heartbeat_utc"] = now.isoformat()
    doc["expires_at_utc"] = (now + timedelta(seconds=ttl_seconds)).isoformat()
    save_json_fn(path, doc)
    return True


def release_issue_lock(lock_dir: Path, load_json_fn, issue_num: int, owner_id: str):
    path = lock_path(lock_dir, issue_num)
    if not path.exists():
        return True
    doc = load_json_fn(path, {})
    if doc.get("owner_id") != owner_id:
        return False
    path.unlink()
    return True


def read_issue_lock(lock_dir: Path, load_json_fn, issue_num: int):
    path = lock_path(lock_dir, issue_num)
    if not path.exists():
        return {
            "exists": False,
            "path": str(path),
            "doc": {},
        }
    doc = load_json_fn(path, {})
    return {
        "exists": True,
        "path": str(path),
        "doc": doc if isinstance(doc, dict) else {},
    }


def run_with_runtime_heartbeat(lock_dir: Path, load_json_fn, save_json_fn, command, issue_num: int, owner_id: str, ttl_seconds: int):
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
            heartbeat_refreshed = heartbeat_issue_lock(
                lock_dir, load_json_fn, save_json_fn, issue_num, owner_id, ttl_seconds
            )
            lock_snapshot = read_issue_lock(lock_dir, load_json_fn, issue_num)
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
