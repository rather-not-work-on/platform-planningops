#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT_PATH="${ROOT_DIR}/planningops/scripts/run_monday_local_operator_stack.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

workspace_root="$TMP_DIR/workspace"
mkdir -p "$workspace_root/monday/config" "$workspace_root/monday/scripts"
mkdir -p "$workspace_root/platform-provider-gateway" "$workspace_root/platform-observability-gateway"

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

fake_stack_smoke="$TMP_DIR/fake_stack_smoke.py"
cat >"$fake_stack_smoke" <<'PY'
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

args = sys.argv[1:]
output = Path(args[args.index("--output") + 1])
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({"verdict": "pass", "failure_count": 0, "component_runs": []}, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
print(f"report written: {output}")
PY
chmod +x "$fake_stack_smoke"

fake_monday_smoke="$workspace_root/monday/scripts/run_local_runtime_smoke.py"
cat >"$fake_monday_smoke" <<'PY'
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

args = sys.argv[1:]
output = Path(args[args.index("--output") + 1])
profile = args[args.index("--profile") + 1]
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps({"verdict": "pass", "profile": profile, "runtime_run_id": "fake-runtime"}, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
print(f"report written: {output}")
PY
chmod +x "$fake_monday_smoke"

ready_output="$TMP_DIR/ready-output.json"
validation_root="$TMP_DIR/validation"
python3 "$SCRIPT_PATH" \
  --workspace-root "$workspace_root" \
  --planningops-runtime-profile-file "$planningops_runtime" \
  --monday-planner-runtime-file "$monday_runtime_ready" \
  --execution-mode both \
  --direct-profile local_ollama \
  --probe-endpoints off \
  --codex-bin "$fake_codex" \
  --run-id monday-local-operator-stack-ready-test \
  --stack-smoke-script "$fake_stack_smoke" \
  --monday-smoke-script "$fake_monday_smoke" \
  --validation-root "$validation_root" \
  --output "$ready_output"

python3 - <<'PY' "$ready_output" "$validation_root"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation_root = Path(sys.argv[2])
assert report["verdict"] == "pass", report
assert report["reason_code"] == "monday_local_operator_stack_ok", report
assert report["run_id"] == "monday-local-operator-stack-ready-test", report
assert report["readiness"]["status"] == "ready", report
assert report["stack_smoke"]["status"] == "pass", report
assert report["direct_smoke"]["status"] == "pass", report
assert report["direct_smoke"]["report_summary"]["profile"] == "local_ollama", report
artifact_paths = report["artifact_paths"]
assert Path(artifact_paths["validation_latest_report_path"]).resolve() == (
    validation_root / "monday-local-operator-stack-report.json"
).resolve(), report
assert Path(artifact_paths["validation_stamped_report_path"]).resolve() == (
    validation_root / "monday-local-operator-stack-ready-test-monday-local-operator-stack-report.json"
).resolve(), report
latest_doc = json.loads((validation_root / "monday-local-operator-stack-report.json").resolve().read_text(encoding="utf-8"))
stamped_doc = json.loads(
    (validation_root / "monday-local-operator-stack-ready-test-monday-local-operator-stack-report.json")
    .resolve()
    .read_text(encoding="utf-8")
)
assert latest_doc["run_id"] == "monday-local-operator-stack-ready-test", latest_doc
assert stamped_doc["run_id"] == "monday-local-operator-stack-ready-test", stamped_doc
PY

fake_readiness="$TMP_DIR/fake_readiness.py"
cat >"$fake_readiness" <<'PY'
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

args = sys.argv[1:]
output = Path(args[args.index("--output") + 1])
report = {
    "assessment_status": "bootstrap_required",
    "verdict": "fail",
    "capabilities": {
        "direct_local_llm_configured": True,
        "codex_cli_available": True,
        "workspace_components_present": True,
        "structural_ready": True,
        "direct_local_llm_endpoint_reachable": True,
        "gateway_endpoint_reachable": False
    },
    "recommended_next_steps": ["Start the provider gateway stack first if you want stack mode."],
}
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
print(f"report written: {output}")
print("assessment_status=bootstrap_required verdict=fail")
sys.exit(1)
PY
chmod +x "$fake_readiness"

bootstrap_output="$TMP_DIR/bootstrap-output.json"
python3 "$SCRIPT_PATH" \
  --workspace-root "$workspace_root" \
  --planningops-runtime-profile-file "$planningops_runtime" \
  --monday-planner-runtime-file "$monday_runtime_ready" \
  --execution-mode direct \
  --direct-profile local_ollama \
  --probe-endpoints off \
  --codex-bin "$fake_codex" \
  --run-id monday-local-operator-stack-bootstrap-test \
  --readiness-script "$fake_readiness" \
  --stack-smoke-script "$fake_stack_smoke" \
  --monday-smoke-script "$fake_monday_smoke" \
  --validation-root "$validation_root" \
  --output "$bootstrap_output"

python3 - <<'PY' "$bootstrap_output" "$validation_root"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation_root = Path(sys.argv[2])
assert report["verdict"] == "pass", report
assert report["run_id"] == "monday-local-operator-stack-bootstrap-test", report
assert report["readiness"]["status"] == "bootstrap_required", report
assert report["stack_smoke"]["status"] == "skipped", report
assert report["direct_smoke"]["status"] == "pass", report
latest_doc = json.loads((validation_root / "monday-local-operator-stack-report.json").resolve().read_text(encoding="utf-8"))
stamped_doc = json.loads(
    (validation_root / "monday-local-operator-stack-bootstrap-test-monday-local-operator-stack-report.json")
    .resolve()
    .read_text(encoding="utf-8")
)
assert latest_doc["run_id"] == "monday-local-operator-stack-bootstrap-test", latest_doc
assert stamped_doc["run_id"] == "monday-local-operator-stack-bootstrap-test", stamped_doc
PY

blocked_readiness="$TMP_DIR/blocked_readiness.py"
cat >"$blocked_readiness" <<'PY'
#!/usr/bin/env python3
import json
import sys
from pathlib import Path

args = sys.argv[1:]
output = Path(args[args.index("--output") + 1])
report = {
    "assessment_status": "blocked",
    "verdict": "fail",
    "capabilities": {
        "direct_local_llm_configured": False,
        "codex_cli_available": False,
        "workspace_components_present": True,
        "structural_ready": False,
        "direct_local_llm_endpoint_reachable": False,
        "gateway_endpoint_reachable": False
    },
    "recommended_next_steps": ["Expose Codex and add a direct local LLM profile."],
}
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
print(f"report written: {output}")
print("assessment_status=blocked verdict=fail")
sys.exit(1)
PY
chmod +x "$blocked_readiness"

blocked_output="$TMP_DIR/blocked-output.json"
set +e
python3 "$SCRIPT_PATH" \
  --workspace-root "$workspace_root" \
  --planningops-runtime-profile-file "$planningops_runtime" \
  --monday-planner-runtime-file "$monday_runtime_ready" \
  --execution-mode both \
  --direct-profile local_ollama \
  --probe-endpoints off \
  --codex-bin "$fake_codex" \
  --run-id monday-local-operator-stack-blocked-test \
  --readiness-script "$blocked_readiness" \
  --stack-smoke-script "$fake_stack_smoke" \
  --monday-smoke-script "$fake_monday_smoke" \
  --validation-root "$validation_root" \
  --output "$blocked_output"
status=$?
set -e
test "$status" -ne 0

python3 - <<'PY' "$blocked_output" "$validation_root"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation_root = Path(sys.argv[2])
assert report["verdict"] == "fail", report
assert report["run_id"] == "monday-local-operator-stack-blocked-test", report
assert report["reason_code"] == "readiness_blocked", report
assert report["stack_smoke"]["status"] == "skipped", report
assert report["direct_smoke"]["status"] == "skipped", report
latest_doc = json.loads((validation_root / "monday-local-operator-stack-report.json").resolve().read_text(encoding="utf-8"))
stamped_doc = json.loads(
    (validation_root / "monday-local-operator-stack-blocked-test-monday-local-operator-stack-report.json")
    .resolve()
    .read_text(encoding="utf-8")
)
assert latest_doc["run_id"] == "monday-local-operator-stack-blocked-test", latest_doc
assert stamped_doc["run_id"] == "monday-local-operator-stack-blocked-test", stamped_doc
PY

echo "monday local operator stack contract ok"
