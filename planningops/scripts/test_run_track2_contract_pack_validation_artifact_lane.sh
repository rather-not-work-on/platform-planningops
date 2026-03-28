#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mockbin="$tmpdir/bin"
mkdir -p "$mockbin"

cat > "$mockbin/bash" <<'EOF'
#!/bin/bash
set -euo pipefail

cmd="$*"
case "$cmd" in
  "docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check --profile all"|"planningops/scripts/test_module_readme_contract.sh"|"planningops/scripts/test_escalation_gate.sh")
    exit 0
    ;;
  *)
    echo "unexpected bash invocation: $cmd" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$mockbin/bash"

cat > "$mockbin/python3" <<'EOF'
#!/bin/bash
set -euo pipefail

cmd="$*"
case "$cmd" in
  "planningops/scripts/validate_project_field_schema.py --fail-on-mismatch"|"planningops/scripts/normalize_ready_implementation_blueprint_refs.py --fail-on-missing")
    exit 0
    ;;
  *)
    echo "unexpected python3 invocation: $cmd" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$mockbin/python3"

output="$tmpdir/track2-contract-pack-report.sample.json"
sys_python="$(command -v python3)"

PATH="$mockbin:$PATH" \
  "$sys_python" planningops/scripts/run_track2_contract_pack_validation.py \
  --output "$output" \
  --strict

python3 - <<'PY' "$output" "planningops/artifacts/validation/track2-contract-pack-report.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual = normalize(load(sys.argv[1]))
expected = normalize(load(sys.argv[2]))

assert actual == expected, (actual, expected)
print("track2 contract pack artifact lane ok")
PY
