#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
from pathlib import Path

module_path = Path("planningops/scripts/normalize_ready_implementation_blueprint_refs.py")
spec = importlib.util.spec_from_file_location("normalize_blueprint", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

defaults_doc = {
    "global_defaults": {
        "interface_contract_refs": "global/interface.md",
        "package_topology_ref": "global/topology.md",
        "dependency_manifest_ref": "global/deps.md",
        "file_plan_ref": "global/file-plan.md",
    },
    "target_repo_defaults": {
        "rather-not-work-on/monday": {
            "interface_contract_refs": "repo/monday-interface.md",
            "package_topology_ref": "repo/monday-topology.md",
            "dependency_manifest_ref": "repo/monday-deps.md",
            "file_plan_ref": "repo/monday-file-plan.md",
        }
    },
}

body_empty = "## Context\nsomething"
normalized_empty = mod.normalize_issue_body(body_empty, "rather-not-work-on/monday", defaults_doc)
assert normalized_empty["changed"] is True, normalized_empty
assert normalized_empty["missing_keys"] == [], normalized_empty
assert "interface_contract_refs: repo/monday-interface.md" in normalized_empty["normalized_body"], normalized_empty
assert normalized_empty["source"]["interface_contract_refs"] == "default", normalized_empty

body_partial = "\n".join(
    [
        "## Existing",
        "interface_contract_refs: keep/me.md",
        "random: value",
    ]
)
normalized_partial = mod.normalize_issue_body(body_partial, "rather-not-work-on/monday", defaults_doc)
assert normalized_partial["resolved_refs"]["interface_contract_refs"] == "keep/me.md", normalized_partial
assert normalized_partial["source"]["interface_contract_refs"] == "existing", normalized_partial
assert normalized_partial["source"]["package_topology_ref"] == "default", normalized_partial

body_duplicate = "\n".join(
    [
        "## Existing",
        "## Implementation Blueprint Refs",
        "interface_contract_refs: old/path.md",
        "package_topology_ref: old/topology.md",
        "dependency_manifest_ref: old/dep.md",
        "file_plan_ref: old/file.md",
        "file_plan_ref: old/file-v2.md",
    ]
)
normalized_duplicate = mod.normalize_issue_body(body_duplicate, "rather-not-work-on/monday", defaults_doc)
assert normalized_duplicate["normalized_body"].count("## Implementation Blueprint Refs") == 1, normalized_duplicate
assert normalized_duplicate["normalized_body"].count("interface_contract_refs:") == 1, normalized_duplicate
assert normalized_duplicate["resolved_refs"]["interface_contract_refs"] == "old/path.md", normalized_duplicate

defaults_missing = {
    "global_defaults": {},
    "target_repo_defaults": {},
}
normalized_missing = mod.normalize_issue_body("plain body", "rather-not-work-on/unknown", defaults_missing)
assert sorted(normalized_missing["missing_keys"]) == sorted(mod.BLUEPRINT_KEYS), normalized_missing
for key in mod.BLUEPRINT_KEYS:
    assert f"{key}:" in normalized_missing["normalized_body"], normalized_missing

print("normalize_ready_implementation_blueprint_refs contract ok")
PY
