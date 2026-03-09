#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import tempfile
from pathlib import Path

module_path = Path("planningops/scripts/worker_executor.py")
spec = importlib.util.spec_from_file_location("worker_executor", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# 1) success path
success = mod.execute_worker_command(
    ["python3", "-c", "print('ok')"],
    mod.WorkerExecutionPolicy(max_retries=1, timeout_ms=2000, max_attempts=3),
)
assert success["status"] == "pass", success
assert success["reason_code"] == "ok", success
assert success["attempts_executed"] == 1, success
assert success["final_return_code"] == 0, success

# 2) retry path (fail once, then pass)
with tempfile.TemporaryDirectory() as td:
    flag = Path(td) / "flag.txt"
    retry_cmd = (
        "from pathlib import Path; import sys; "
        f"flag = Path({str(flag)!r}); "
        "seen = flag.exists(); "
        "flag.touch(exist_ok=True); "
        "sys.stdout.write('second-ok\\n' if seen else ''); "
        "sys.stderr.write('first-fail\\n' if not seen else ''); "
        "raise SystemExit(0 if seen else 1)"
    )
    retry = mod.execute_worker_command(
        ["python3", "-c", retry_cmd],
        mod.WorkerExecutionPolicy(max_retries=2, timeout_ms=5000, max_attempts=3),
    )
    assert retry["status"] == "pass", retry
    assert retry["attempts_executed"] == 2, retry
    assert retry["attempts"][0]["return_code"] == 1, retry
    assert retry["attempts"][1]["return_code"] == 0, retry

# 3) timeout + retry exhausted path
timeout_fail = mod.execute_worker_command(
    ["python3", "-c", "import time; time.sleep(0.2)"],
    mod.WorkerExecutionPolicy(max_retries=1, timeout_ms=50, max_attempts=3),
)
assert timeout_fail["status"] == "fail", timeout_fail
assert timeout_fail["reason_code"] == "runtime_timeout_retries_exhausted", timeout_fail
assert timeout_fail["attempts_executed"] == 2, timeout_fail
assert timeout_fail["timed_out"] is True, timeout_fail

# 4) budget exhausted path (budget tighter than retry cap)
budget_fail = mod.execute_worker_command(
    ["python3", "-c", "import sys; sys.exit(2)"],
    mod.WorkerExecutionPolicy(max_retries=5, timeout_ms=2000, max_attempts=1),
)
assert budget_fail["status"] == "fail", budget_fail
assert budget_fail["reason_code"] == "attempt_budget_exhausted", budget_fail
assert budget_fail["attempts_executed"] == 1, budget_fail
assert budget_fail["attempt_budget_limited"] is True, budget_fail

# 5) immediate budget exhausted (no attempt permitted)
no_attempt = mod.execute_worker_command(
    ["python3", "-c", "print('unused')"],
    mod.WorkerExecutionPolicy(max_retries=1, timeout_ms=1000, max_attempts=0),
)
assert no_attempt["status"] == "fail", no_attempt
assert no_attempt["reason_code"] == "attempt_budget_exhausted", no_attempt
assert no_attempt["attempts_executed"] == 0, no_attempt

print("worker_executor contract tests ok")
PY
