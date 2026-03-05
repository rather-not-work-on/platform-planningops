#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/ralph_loop_local.py")
spec = importlib.util.spec_from_file_location("ralph_loop_local", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

# 1) default fallback should use parser_diff_dry_run.
runtime_ctx_default = {"task_key": "issue-1", "selected_profile": "local", "worker_policy": {"kind": "parser_diff_dry_run"}}
default_plan = mod.resolve_worker_command(1, "dry-run", "loop-abc", runtime_ctx_default)
assert default_plan["kind"] == "parser_diff_dry_run", default_plan
assert default_plan["command"][:2] == ["python3", "planningops/scripts/parser_diff_dry_run.py"], default_plan
assert "loop-abc" in default_plan["command"], default_plan

# 2) python_script worker policy must template-render args.
runtime_ctx_python = {
    "task_key": "issue-44",
    "selected_profile": "local",
    "worker_policy": {
        "kind": "python_script",
        "script": "planningops/scripts/parser_diff_dry_run.py",
        "args": ["--run-id", "{loop_id}", "--mode", "{mode}"],
    },
}
python_plan = mod.resolve_worker_command(44, "apply", "loop-xyz", runtime_ctx_python)
assert python_plan["kind"] == "python_script", python_plan
assert python_plan["command"] == [
    "python3",
    "planningops/scripts/parser_diff_dry_run.py",
    "--run-id",
    "loop-xyz",
    "--mode",
    "apply",
], python_plan

# 3) shell worker policy must template-render command string.
runtime_ctx_shell = {
    "task_key": "issue-77",
    "selected_profile": "oracle_cloud",
    "worker_policy": {
        "kind": "shell",
        "command": "echo issue={issue_number} mode={mode} profile={runtime_profile}",
    },
}
shell_plan = mod.resolve_worker_command(77, "dry-run", "loop-shell", runtime_ctx_shell)
assert shell_plan["kind"] == "shell", shell_plan
assert shell_plan["command"][0:2] == ["bash", "-lc"], shell_plan
assert "issue=77" in shell_plan["command"][2], shell_plan
assert "profile=oracle_cloud" in shell_plan["command"][2], shell_plan

# 4) unknown policy kind must fail.
try:
    mod.resolve_worker_command(
        1,
        "dry-run",
        "loop-bad",
        {"task_key": "issue-1", "selected_profile": "local", "worker_policy": {"kind": "unknown-kind"}},
    )
    raise AssertionError("expected ValueError for unknown worker policy")
except ValueError as exc:
    assert "unknown worker policy kind" in str(exc), exc

# 5) load_runtime_context should resolve worker policy by priority:
# task override > default override > profile payload > fallback.
with tempfile.TemporaryDirectory() as td:
    runtime_path = Path(td) / "runtime-profiles.json"
    runtime_path.write_text(
        json.dumps(
            {
                "active_profile": "local",
                "profiles": {
                    "local": {
                        "execution_mode": "local",
                        "worker_policy": {"kind": "shell", "command": "echo from-profile"},
                    }
                },
                "task_overrides": {
                    "default": {
                        "runtime_profile": "local",
                        "worker_policy": {"kind": "shell", "command": "echo from-default"},
                    },
                    "issue-11": {
                        "runtime_profile": "local",
                        "worker_policy": {"kind": "shell", "command": "echo from-task"},
                    },
                },
            },
            ensure_ascii=True,
        ),
        encoding="utf-8",
    )

    task_ctx = mod.load_runtime_context(runtime_path, "issue-11")
    default_ctx = mod.load_runtime_context(runtime_path, "issue-22")
    assert task_ctx["worker_policy"]["command"] == "echo from-task", task_ctx
    assert default_ctx["worker_policy"]["command"] == "echo from-default", default_ctx

    task_ctx["provider_policy"] = {"max_retries": 2, "timeout_ms": 25000}
    policy_from_runtime = mod.resolve_worker_execution_policy(
        runtime_ctx=task_ctx,
        max_attempts=3,
        worker_task_pack_report=None,
    )
    assert policy_from_runtime["source"] == "runtime_context.provider_policy", policy_from_runtime
    assert policy_from_runtime["policy"].max_retries == 2, policy_from_runtime
    assert policy_from_runtime["policy"].timeout_ms == 25000, policy_from_runtime
    assert policy_from_runtime["policy"].max_attempts == 3, policy_from_runtime

    report_path = Path(td) / "worker-task-pack-report.json"
    report_path.write_text(
        json.dumps(
            {
                "worker_task_pack": {
                    "retry_policy": {"max_retries": 1},
                    "timeout_ms": 45000,
                }
            },
            ensure_ascii=True,
        ),
        encoding="utf-8",
    )
    policy_from_pack = mod.resolve_worker_execution_policy(
        runtime_ctx=task_ctx,
        max_attempts=2,
        worker_task_pack_report=str(report_path),
    )
    assert policy_from_pack["source"] == "worker_task_pack.report", policy_from_pack
    assert policy_from_pack["policy"].max_retries == 1, policy_from_pack
    assert policy_from_pack["policy"].timeout_ms == 45000, policy_from_pack
    assert policy_from_pack["policy"].max_attempts == 2, policy_from_pack

print("ralph_loop_local worker policy contract smoke ok")
PY
