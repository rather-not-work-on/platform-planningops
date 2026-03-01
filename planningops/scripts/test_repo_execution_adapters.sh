#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path

module_path = Path("planningops/scripts/repo_execution_adapters.py")
spec = importlib.util.spec_from_file_location("repo_execution_adapters", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

repos = mod.supported_repositories()
assert "rather-not-work-on/platform-contracts" in repos, repos
assert "rather-not-work-on/platform-provider-gateway" in repos, repos
assert "rather-not-work-on/platform-observability-gateway" in repos, repos
assert "rather-not-work-on/monday" in repos, repos

ctx = {
    "issue_number": 34,
    "issue_repo": "rather-not-work-on/platform-planningops",
    "target_repo": "rather-not-work-on/platform-contracts",
    "workflow_state": "ready-implementation",
    "loop_profile": "L3 Implementation-TDD",
    "mode": "dry-run",
    "selection_transition_id": "loop-test-intake",
}

contracts_adapter = mod.resolve_execution_adapter("rather-not-work-on/platform-contracts")
pre = mod.invoke_adapter_hook(contracts_adapter, "before_loop", ctx)
post = mod.invoke_adapter_hook(contracts_adapter, "after_loop", ctx, {"last_verdict": "pass"})

for row in [pre, post]:
    assert row["status"] == "ok", row
    assert row["reason_code"] in mod.ADAPTER_REASON_CODES, row
    for key in ["status", "phase", "adapter", "target_repo", "reason_code", "message"]:
        assert key in row, key

unknown_adapter = mod.resolve_execution_adapter("rather-not-work-on/unknown-repo")
unknown_pre = mod.invoke_adapter_hook(unknown_adapter, "before_loop", ctx)
assert unknown_pre["adapter"] == "generic-adapter", unknown_pre
assert unknown_pre["status"] == "ok", unknown_pre
assert "reason_code" in unknown_pre, unknown_pre

assert mod.classify_adapter_error("permission denied by token") == "permission"
assert mod.classify_adapter_error("missing required field") == "contract"
assert mod.classify_adapter_error("context dependency missing") == "context"
assert mod.classify_adapter_error("feedback write failed") == "feedback_failed"
assert mod.classify_adapter_error("unexpected crash") == "runtime"

out_dir = Path("planningops/artifacts/adapter-hooks/integration-smoke")
out_dir.mkdir(parents=True, exist_ok=True)
manifest = {
    "generated_at_utc": datetime.now(timezone.utc).isoformat(),
    "result": "pass",
    "covered_repositories": repos,
    "checks": [
        "supported_repositories",
        "hook_result_shape",
        "unknown_repo_fallback",
        "error_reason_classification",
    ],
}
latest_path = out_dir / "latest.json"
timestamp_path = out_dir / f"smoke-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.json"
latest_path.write_text(json.dumps(manifest, ensure_ascii=True, indent=2), encoding="utf-8")
timestamp_path.write_text(json.dumps(manifest, ensure_ascii=True, indent=2), encoding="utf-8")

print("repo execution adapters contract smoke ok")
print(f"evidence: {latest_path}")
print(f"evidence: {timestamp_path}")
PY
