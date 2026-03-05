#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
from pathlib import Path

module_path = Path("planningops/scripts/validate_project_field_schema.py")
spec = importlib.util.spec_from_file_location("validate_project_field_schema", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

expected_states = {
    "backlog",
    "ready-contract",
    "ready-implementation",
    "in-progress",
    "review-gate",
    "blocked",
    "done",
}

assert expected_states.issubset(set(mod.WORKFLOW_LOOP_PROFILE_MATRIX.keys())), mod.WORKFLOW_LOOP_PROFILE_MATRIX

assert mod.expected_loop_profiles_for_workflow_state("ready-contract") == {
    "L1 Contract-Clarification",
    "L2 Simulation",
}
assert mod.expected_loop_profiles_for_workflow_state("ready-implementation") == {
    "L3 Implementation-TDD",
    "L4 Integration-Reconcile",
}
assert mod.expected_loop_profiles_for_workflow_state("blocked") == {"L5 Recovery-Replan"}

in_progress = mod.expected_loop_profiles_for_workflow_state("in-progress")
assert in_progress == mod.ALL_LOOP_PROFILES, in_progress

done_profiles = mod.expected_loop_profiles_for_workflow_state("done")
assert done_profiles == mod.ALL_LOOP_PROFILES, done_profiles

assert mod.expected_loop_profiles_for_workflow_state("unknown-state") is None

print("validate_project_field_schema loop-profile matrix contract ok")
PY
