#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import subprocess
from pathlib import Path

wrapper_path = Path("planningops/scripts/repo_execution_adapters.py")
canonical_path = Path("planningops/scripts/federation/adapter_registry.py")

wrapper_spec = importlib.util.spec_from_file_location("repo_execution_adapters_wrapper", wrapper_path)
wrapper_mod = importlib.util.module_from_spec(wrapper_spec)
wrapper_spec.loader.exec_module(wrapper_mod)

canonical_spec = importlib.util.spec_from_file_location("adapter_registry", canonical_path)
canonical_mod = importlib.util.module_from_spec(canonical_spec)
canonical_spec.loader.exec_module(canonical_mod)

assert wrapper_mod.supported_repositories() == canonical_mod.supported_repositories()
assert wrapper_mod.classify_adapter_error("permission denied by token") == canonical_mod.classify_adapter_error(
    "permission denied by token"
)
ctx = {
    "issue_number": 34,
    "issue_repo": "rather-not-work-on/platform-planningops",
    "target_repo": "rather-not-work-on/platform-contracts",
    "workflow_state": "ready-implementation",
}
wrapper_pre = wrapper_mod.invoke_adapter_hook(wrapper_mod.resolve_execution_adapter(ctx["target_repo"]), "before_loop", ctx)
canonical_pre = canonical_mod.invoke_adapter_hook(canonical_mod.resolve_execution_adapter(ctx["target_repo"]), "before_loop", ctx)
assert wrapper_pre == canonical_pre, (wrapper_pre, canonical_pre)

completed = subprocess.run(
    ["python3", str(wrapper_path)],
    capture_output=True,
    text=True,
    check=True,
)
repos = [line.strip() for line in completed.stdout.splitlines() if line.strip()]
assert repos == canonical_mod.supported_repositories(), repos
print("repo execution adapters wrapper compatibility ok")
PY
