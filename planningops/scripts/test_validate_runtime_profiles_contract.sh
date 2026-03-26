#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
import sys
import tempfile
from pathlib import Path


module_path = Path("planningops/scripts/validate_runtime_profiles.py")
spec = importlib.util.spec_from_file_location("validate_runtime_profiles", module_path)
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
                        "execution_mode": "local",
                        "litellm_base_url": "http://127.0.0.1:4000",
                        "langfuse_host": "http://127.0.0.1:3001",
                        "planner_policy": {
                            "engine_hint": "deepagents",
                            "execution_mode": "embedded",
                            "capability_profile": "repo_local_skills",
                        }
                    }
                },
                "task_overrides": {
                    "default": {
                        "runtime_profile": "local",
                        "provider_policy": {"max_retries": 2, "timeout_ms": 60000},
                        "worker_policy": {"kind": "parser_diff_dry_run"},
                    }
                },
            },
            ensure_ascii=True,
        ),
        encoding="utf-8",
    )

    argv_before = list(sys.argv)
    sys.argv = [
        "validate_runtime_profiles.py",
        "--runtime-profile-file",
        str(runtime_file),
        "--schema-file",
        "planningops/schemas/runtime-profiles.schema.json",
        "--output",
        str(output_file),
        "--strict",
    ]
    rc = mod.main()
    sys.argv = argv_before
    assert rc == 0, rc
    report = json.loads(output_file.read_text(encoding="utf-8"))
    assert report["verdict"] == "pass", report
    assert report["reason"] == "ok", report

    invalid = json.loads(runtime_file.read_text(encoding="utf-8"))
    invalid["active_profile"] = "missing"
    invalid["profiles"]["local"]["planner_policy"]["engine_hint"] = ""
    invalid["profiles"]["local"]["nanoclaw_endpoint"] = "http://127.0.0.1:8787"
    invalid["task_overrides"]["default"]["runtime_profile"] = "missing"
    invalid["task_overrides"]["default"]["worker_policy"] = {"kind": "unknown"}
    runtime_file.write_text(json.dumps(invalid, ensure_ascii=True), encoding="utf-8")

    argv_before = list(sys.argv)
    sys.argv = [
        "validate_runtime_profiles.py",
        "--runtime-profile-file",
        str(runtime_file),
        "--schema-file",
        "planningops/schemas/runtime-profiles.schema.json",
        "--output",
        str(output_file),
        "--strict",
    ]
    rc_bad = mod.main()
    sys.argv = argv_before
    assert rc_bad == 1, rc_bad
    bad_report = json.loads(output_file.read_text(encoding="utf-8"))
    assert bad_report["verdict"] == "fail", bad_report
    assert bad_report["reason"] == "runtime_profiles_invalid", bad_report
    errors = "\n".join(bad_report["validation_errors"])
    assert "active_profile 'missing' is not defined in profiles" in errors, bad_report
    assert "schema: $.profiles.local unexpected key: nanoclaw_endpoint" in errors, bad_report
    assert "planner_policy.engine_hint must be a non-empty string" in errors, bad_report
    assert "runtime_profile 'missing' is not defined" in errors, bad_report
    assert "worker_policy.kind must be parser_diff_dry_run, python_script, or shell" in errors, bad_report

print("validate_runtime_profiles contract ok")
PY
