#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/core/loop/runner.py")
spec = importlib.util.spec_from_file_location("issue_loop_runner_core", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as td:
    mod.ESCALATION_HISTORY_PATH = Path(td) / "escalation-history.json"
    issue = 940

    r1 = mod.evaluate_escalation(issue, "fail", "runtime_error")
    assert r1["auto_paused"] is False, r1

    r2 = mod.evaluate_escalation(issue, "fail", "runtime_error")
    assert r2["auto_paused"] is False, r2

    r3 = mod.evaluate_escalation(issue, "fail", "runtime_error")
    assert r3["auto_paused"] is True, r3
    assert r3["trigger_type"] == "same_reason_x3", r3

with tempfile.TemporaryDirectory() as td:
    mod.ESCALATION_HISTORY_PATH = Path(td) / "escalation-history.json"
    issue = 941

    r1 = mod.evaluate_escalation(issue, "inconclusive", "missing_artifact")
    assert r1["auto_paused"] is False, r1

    r2 = mod.evaluate_escalation(issue, "inconclusive", "missing_artifact")
    assert r2["auto_paused"] is True, r2
    assert r2["trigger_type"] == "inconclusive_x2", r2

with tempfile.TemporaryDirectory() as td:
    mod.ESCALATION_HISTORY_PATH = Path(td) / "escalation-history.json"
    issue = 942

    r1 = mod.evaluate_escalation(issue, "pass", "ok")
    r2 = mod.evaluate_escalation(issue, "pass", "ok")
    r3 = mod.evaluate_escalation(issue, "pass", "ok")
    r4 = mod.evaluate_escalation(issue, "pass", "ok")
    assert r1["auto_paused"] is False, r1
    assert r2["auto_paused"] is False, r2
    assert r3["auto_paused"] is False, r3
    assert r4["auto_paused"] is False, r4
    assert r4["same_reason_consecutive"] == 0, r4

print("escalation gate contract smoke ok")
PY
