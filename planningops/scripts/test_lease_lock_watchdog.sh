#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from datetime import datetime, timezone, timedelta
from pathlib import Path

module_path = Path("planningops/scripts/issue_loop_runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner", module_path)
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

print("lease lock watchdog contract smoke ok")
PY
