#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/validate_worker_task_pack.py")
spec = importlib.util.spec_from_file_location("validate_worker_task_pack", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

with tempfile.TemporaryDirectory() as td:
    td_path = Path(td)
    runtime_file = td_path / "runtime-profiles.json"
    output_file = td_path / "report.json"

    runtime_file.write_text(
        json.dumps(
            {
                "active_profile": "local",
                "profiles": {
                    "local": {
                        "execution_mode": "local"
                    }
                },
                "task_overrides": {
                    "default": {
                        "runtime_profile": "local",
                        "provider_policy": {"max_retries": 2, "timeout_ms": 45000},
                        "worker_policy": {"kind": "parser_diff_dry_run"},
                    },
                    "issue-7": {
                        "runtime_profile": "local",
                        "worker_policy": {
                            "kind": "python_script",
                            "script": "planningops/scripts/parser_diff_dry_run.py",
                            "args": ["--run-id", "{loop_id}", "--mode", "{mode}"],
                        },
                    },
                },
            },
            ensure_ascii=True,
        ),
        encoding="utf-8",
    )

    argv_before = list(sys.argv)
    sys.argv = [
        "validate_worker_task_pack.py",
        "--runtime-profile-file",
        str(runtime_file),
        "--task-key",
        "issue-7",
        "--issue-number",
        "7",
        "--mode",
        "dry-run",
        "--loop-profile",
        "L3 Implementation-TDD",
        "--target-repo",
        "rather-not-work-on/platform-planningops",
        "--output",
        str(output_file),
        "--strict",
    ]
    rc = mod.main()
    sys.argv = argv_before
    assert rc == 0, rc
    report = json.loads(output_file.read_text(encoding="utf-8"))
    assert report["verdict"] == "pass", report
    assert report["worker_task_pack"]["worker_policy_kind"] == "python_script", report
    assert report["worker_task_pack"]["retry_policy"]["max_retries"] == 2, report
    assert report["worker_task_pack"]["timeout_ms"] == 45000, report

    runtime_bad = json.loads(runtime_file.read_text(encoding="utf-8"))
    runtime_bad["task_overrides"]["issue-7"]["worker_policy"] = {"kind": "unknown_kind"}
    runtime_file.write_text(json.dumps(runtime_bad, ensure_ascii=True), encoding="utf-8")

    argv_before = list(sys.argv)
    sys.argv = [
        "validate_worker_task_pack.py",
        "--runtime-profile-file",
        str(runtime_file),
        "--task-key",
        "issue-7",
        "--issue-number",
        "7",
        "--mode",
        "apply",
        "--loop-profile",
        "L3 Implementation-TDD",
        "--target-repo",
        "rather-not-work-on/platform-planningops",
        "--output",
        str(output_file),
        "--strict",
    ]
    rc_bad = mod.main()
    sys.argv = argv_before
    assert rc_bad == 1, rc_bad
    bad_report = json.loads(output_file.read_text(encoding="utf-8"))
    assert bad_report["verdict"] == "fail", bad_report
    assert bad_report["reason"] == "worker_policy_render_failed", bad_report

print("validate_worker_task_pack contract smoke ok")
PY
