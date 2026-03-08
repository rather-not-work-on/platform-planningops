#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import subprocess
from pathlib import Path

wrapper_path = Path("planningops/scripts/issue_loop_runner.py")
canonical_path = Path("planningops/scripts/core/loop/runner.py")

wrapper_spec = importlib.util.spec_from_file_location("issue_loop_runner_wrapper", wrapper_path)
wrapper_mod = importlib.util.module_from_spec(wrapper_spec)
wrapper_spec.loader.exec_module(wrapper_mod)

canonical_spec = importlib.util.spec_from_file_location("issue_loop_runner_core", canonical_path)
canonical_mod = importlib.util.module_from_spec(canonical_spec)
canonical_spec.loader.exec_module(canonical_mod)

selected = {"workflow_state": "ready-implementation", "target_repo": "rather-not-work-on/monday"}
payload = {"replanning_triggered": False}
control_repo = "rather-not-work-on/platform-planningops"

assert wrapper_mod.determine_loop_profile(selected, payload, control_repo) == canonical_mod.determine_loop_profile(
    selected, payload, control_repo
)
assert wrapper_mod.parse_selector_hints("simulation_required: true\nuncertainty_level: high\n") == canonical_mod.parse_selector_hints(
    "simulation_required: true\nuncertainty_level: high\n"
)
assert wrapper_mod.parse_execution_kind("- execution_kind: inventory") == canonical_mod.parse_execution_kind(
    "- execution_kind: inventory"
)
assert wrapper_mod.parse_blueprint_refs("interface_contract_refs: a\n") == canonical_mod.parse_blueprint_refs(
    "interface_contract_refs: a\n"
)

completed = subprocess.run(
    ["python3", str(wrapper_path), "--help"],
    capture_output=True,
    text=True,
    check=True,
)
assert "--mode" in completed.stdout, completed.stdout
assert "--pec-preflight-mode" in completed.stdout, completed.stdout
print("issue loop runner wrapper compatibility ok")
PY
