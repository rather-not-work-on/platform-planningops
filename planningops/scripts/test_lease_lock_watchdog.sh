#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import threading
import time
import tempfile
from datetime import datetime, timezone, timedelta
from pathlib import Path

module_path = Path("planningops/scripts/core/loop/runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner_core", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as td:
    mod.LOCK_DIR = Path(td) / "locks"
    issue_number = 777

    acquired1, lock1, stale1 = mod.acquire_issue_lock(issue_number, "owner-a", ttl_seconds=300)
    assert acquired1, (acquired1, lock1, stale1)
    assert stale1 is False, (acquired1, lock1, stale1)

    # Duplicate run with different owner must be blocked while lock active.
    acquired2, lock2, stale2 = mod.acquire_issue_lock(issue_number, "owner-b", ttl_seconds=300)
    assert acquired2 is False, (acquired2, lock2, stale2)
    assert lock2["owner_id"] == "owner-a", lock2

    # Simulate stale/zombie lock and recover.
    lock_path = mod.lock_path(issue_number)
    stale_doc = json.loads(lock_path.read_text(encoding="utf-8"))
    stale_doc["expires_at_utc"] = (datetime.now(timezone.utc) - timedelta(seconds=1)).isoformat()
    lock_path.write_text(json.dumps(stale_doc, ensure_ascii=True, indent=2), encoding="utf-8")

    acquired3, lock3, stale3 = mod.acquire_issue_lock(issue_number, "owner-b", ttl_seconds=300)
    assert acquired3, (acquired3, lock3, stale3)
    assert stale3 is True, (acquired3, lock3, stale3)
    assert lock3["owner_id"] == "owner-b", lock3

    assert mod.heartbeat_issue_lock(issue_number, "owner-b", ttl_seconds=300) is True
    assert mod.release_issue_lock(issue_number, "owner-b") is True
    assert not mod.lock_path(issue_number).exists(), mod.lock_path(issue_number)

    # Runtime-window heartbeat should tick while worker command is running.
    runtime_issue = 778
    acquired_runtime, _, _ = mod.acquire_issue_lock(runtime_issue, "owner-runtime", ttl_seconds=3)
    assert acquired_runtime is True
    runtime_run = mod.run_with_runtime_heartbeat(
        command=["python3", "-c", "import time; time.sleep(2); print('done')"],
        issue_num=runtime_issue,
        owner_id="owner-runtime",
        ttl_seconds=3,
    )
    assert runtime_run["drift_detected"] is False, runtime_run
    assert runtime_run["return_code"] == 0, runtime_run
    runtime_events = runtime_run["heartbeat_events"]
    assert any(e.get("event") == "runtime_heartbeat_started" for e in runtime_events), runtime_events
    assert any(e.get("event") == "runtime_heartbeat_stopped" for e in runtime_events), runtime_events
    assert any(
        e.get("event") == "runtime_heartbeat_tick" and e.get("heartbeat_refreshed") is True
        for e in runtime_events
    ), runtime_events
    assert mod.release_issue_lock(runtime_issue, "owner-runtime") is True

    # Lock owner drift during runtime should be detected and classified.
    drift_issue = 779
    acquired_drift, _, _ = mod.acquire_issue_lock(drift_issue, "owner-drift", ttl_seconds=3)
    assert acquired_drift is True

    def mutate_owner():
        time.sleep(1.2)
        drift_path = mod.lock_path(drift_issue)
        drift_doc = json.loads(drift_path.read_text(encoding="utf-8"))
        drift_doc["owner_id"] = "owner-hijack"
        drift_path.write_text(json.dumps(drift_doc, ensure_ascii=True, indent=2), encoding="utf-8")

    t = threading.Thread(target=mutate_owner, daemon=True)
    t.start()
    drift_run = mod.run_with_runtime_heartbeat(
        command=["python3", "-c", "import time; time.sleep(6); print('late')"],
        issue_num=drift_issue,
        owner_id="owner-drift",
        ttl_seconds=3,
    )
    t.join(timeout=1.0)
    assert drift_run["drift_detected"] is True, drift_run
    assert drift_run["drift_reason"] == "lock_owner_drift", drift_run
    drift_events = drift_run["heartbeat_events"]
    assert any(e.get("event") == "runtime_heartbeat_drift_detected" for e in drift_events), drift_events
    drift_path = mod.lock_path(drift_issue)
    if drift_path.exists():
        drift_path.unlink()

print("lease lock watchdog contract smoke ok")
PY
