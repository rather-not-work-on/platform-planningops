#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

workspace="$tmpdir/ws"
mkdir -p \
  "$workspace/platform-provider-gateway/scripts" \
  "$workspace/platform-observability-gateway/scripts" \
  "$workspace/monday/scripts"

cat > "$workspace/platform-provider-gateway/.gitignore" <<'EOF'
runtime-artifacts/
EOF
cat > "$workspace/platform-provider-gateway/scripts/litellm_gateway_smoke.py" <<'EOF'
def run():
    default="runtime-artifacts/smoke"
EOF
cat > "$workspace/platform-provider-gateway/scripts/validate_provider_smoke_evidence.py" <<'EOF'
REPORT = "runtime-artifacts/validation/provider-smoke-evidence-report.json"
EOF
cat > "$workspace/platform-provider-gateway/scripts/validate_contract_pin.py" <<'EOF'
REPORT = "runtime-artifacts/validation/contract-pin-report.json"
EOF
cat > "$workspace/platform-provider-gateway/scripts/litellm_profile_drill.py" <<'EOF'
TARGET = "runtime-artifacts/launcher/"
EOF

cat > "$workspace/platform-observability-gateway/.gitignore" <<'EOF'
runtime-artifacts/
EOF
cat > "$workspace/platform-observability-gateway/scripts/langfuse_ingest_smoke.py" <<'EOF'
def run():
    default="runtime-artifacts/ingest"
EOF
cat > "$workspace/platform-observability-gateway/scripts/validate_ingest_smoke_evidence.py" <<'EOF'
REPORT = "runtime-artifacts/validation/ingest-smoke-evidence-report.json"
EOF
cat > "$workspace/platform-observability-gateway/scripts/validate_contract_pin.py" <<'EOF'
REPORT = "runtime-artifacts/validation/contract-pin-report.json"
EOF
cat > "$workspace/platform-observability-gateway/scripts/langfuse_stack_launcher.sh" <<'EOF'
TARGET="runtime-artifacts/launcher"
EOF

cat > "$workspace/monday/.gitignore" <<'EOF'
runtime-artifacts/
EOF
cat > "$workspace/monday/scripts/validate_handoff_mapping.py" <<'EOF'
REPORT = "runtime-artifacts/interface/handoff-smoke-report.json"
EOF
cat > "$workspace/monday/scripts/scheduler_queue.py" <<'EOF'
RUN_REPORT = "runtime-artifacts/scheduler/run-report.json"
TRANSITION_LOG = "runtime-artifacts/transition-log/scheduler.ndjson"
EOF
cat > "$workspace/monday/scripts/integrate_planningops_handoff.py" <<'EOF'
ROOT = "runtime-artifacts/integration/"
EOF
cat > "$workspace/monday/scripts/validate_runtime_evidence.py" <<'EOF'
REPORT = "runtime-artifacts/validation/runtime-evidence-report.json"
EOF
cat > "$workspace/monday/scripts/validate_contract_pin.py" <<'EOF'
REPORT = "runtime-artifacts/validation/contract-pin-report.json"
EOF

output="$tmpdir/federated-artifact-policy-rollout-report.sample.json"

python3 planningops/scripts/rollout_external_artifact_policy.py \
  --workspace-root "$workspace" \
  --output "$output" \
  --strict

python3 - <<'PY' "$output" "planningops/artifacts/validation/federated-artifact-policy-rollout-report.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    normalized["workspace_root"] = "__WORKSPACE_ROOT__"
    return normalized


actual = normalize(load(sys.argv[1]))
expected = normalize(load(sys.argv[2]))

assert actual == expected, (actual, expected)
print("rollout external artifact policy artifact lane ok")
PY
