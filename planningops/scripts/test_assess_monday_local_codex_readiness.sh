#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/assess_monday_local_codex_readiness.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

workspace_root="$TMP_DIR/workspace"
mkdir -p "$workspace_root/monday/config"
mkdir -p "$workspace_root/platform-provider-gateway"
mkdir -p "$workspace_root/platform-observability-gateway"

planningops_runtime="$TMP_DIR/runtime-profiles.json"
cat >"$planningops_runtime" <<'JSON'
{
  "active_profile": "local",
  "profiles": {
    "local": {
      "execution_mode": "local",
      "litellm_base_url": "http://127.0.0.1:4000",
      "langfuse_host": "http://127.0.0.1:3001"
    }
  }
}
JSON

monday_runtime_ready="$workspace_root/monday/config/planner-runtime-ready.json"
cat >"$monday_runtime_ready" <<'JSON'
{
  "config_version": 1,
  "active_profile": "local",
  "profiles": {
    "local": {
      "planner_engine": "deepagents",
      "deepagents_model_backend": "openai_compatible",
      "deepagents_model": "gemini-2.5-flash-lite",
      "deepagents_base_url": "http://127.0.0.1:4000/v1"
    },
    "local_ollama": {
      "planner_engine": "deepagents",
      "deepagents_model_backend": "ollama",
      "deepagents_model": "llama-3.1:8b",
      "deepagents_base_url": "http://127.0.0.1:11434"
    },
    "local_lmstudio": {
      "planner_engine": "deepagents",
      "deepagents_model_backend": "openai_compatible",
      "deepagents_model": "local-model",
      "deepagents_base_url": "http://127.0.0.1:1234/v1"
    }
  }
}
JSON

fake_codex="$TMP_DIR/codex"
cat >"$fake_codex" <<'EOF'
#!/usr/bin/env bash
echo "codex 0.test"
EOF
chmod +x "$fake_codex"

ready_report="$TMP_DIR/ready.json"
python3 "$SCRIPT_PATH" \
  --workspace-root "$workspace_root" \
  --planningops-runtime-profile-file "$planningops_runtime" \
  --monday-planner-runtime-file "$monday_runtime_ready" \
  --probe-endpoints off \
  --codex-bin "$fake_codex" \
  --output "$ready_report"

python3 - <<'PY' "$ready_report"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["assessment_status"] == "ready", report
assert report["verdict"] == "pass", report
assert report["capabilities"]["gateway_first_configured"] is True, report
assert report["capabilities"]["direct_local_llm_configured"] is True, report
assert report["capabilities"]["codex_cli_available"] is True, report
assert report["capabilities"]["structural_ready"] is True, report
assert report["blocking_details"] == [], report
assert report["bootstrap_details"] == [], report
assert report["recommended_commands"]["planningops_stack_smoke"].startswith(
    "python3 planningops/scripts/federation/run_local_runtime_stack_smoke.py"
), report
assert report["monday_runtime"]["local_profiles"][0]["endpoint_probe_status"] == "skipped", report
assert any(
    "planningops federated local smoke" in step
    for step in report["recommended_next_steps"]
), report
PY

monday_runtime_blocked="$workspace_root/monday/config/planner-runtime-blocked.json"
cat >"$monday_runtime_blocked" <<'JSON'
{
  "config_version": 1,
  "active_profile": "local",
  "profiles": {
    "local": {
      "planner_engine": "deepagents",
      "deepagents_model_backend": "openai_compatible",
      "deepagents_model": "gemini-2.5-flash-lite",
      "deepagents_base_url": "http://127.0.0.1:4000/v1"
    }
  }
}
JSON

blocked_report="$TMP_DIR/blocked.json"
set +e
python3 "$SCRIPT_PATH" \
  --workspace-root "$workspace_root" \
  --planningops-runtime-profile-file "$planningops_runtime" \
  --monday-planner-runtime-file "$monday_runtime_blocked" \
  --probe-endpoints off \
  --codex-bin "$TMP_DIR/missing-codex" \
  --output "$blocked_report"
status=$?
set -e

test "$status" -ne 0

python3 - <<'PY' "$blocked_report"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["assessment_status"] == "blocked", report
assert report["verdict"] == "fail", report
reason_codes = {row["reason_code"] for row in report["blocking_details"]}
assert "codex_cli_missing" in reason_codes, report
assert "direct_local_llm_profiles_missing" in reason_codes, report
assert any("Codex CLI" in step for step in report["recommended_next_steps"]), report
assert any("direct local LLM profile" in step for step in report["recommended_next_steps"]), report
PY

echo "monday local codex readiness contract ok"
