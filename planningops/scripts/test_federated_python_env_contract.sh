#!/usr/bin/env bash
set -euo pipefail

python3 planningops/scripts/federation/federated_python_env.py --test-mode

python3 - <<'PY'
import importlib.util
import sys
from pathlib import Path

module_path = Path("planningops/scripts/federation/federated_python_env.py").resolve()
spec = importlib.util.spec_from_file_location("federated_python_env", module_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)

captured = {}

def fake_run(command, check, stdout, stderr):
    captured["command"] = command
    captured["check"] = check
    captured["stdout"] = stdout
    captured["stderr"] = stderr
    class Result:
        returncode = 0
    return Result()

module.subprocess.run = fake_run
module.run_bootstrap_command(["python3", "-V"])

assert captured["command"] == ["python3", "-V"], captured
assert captured["check"] is True, captured
assert captured["stdout"] is sys.stderr, captured
assert captured["stderr"] is sys.stderr, captured
PY
