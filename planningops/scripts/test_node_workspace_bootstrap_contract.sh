#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

python3 planningops/scripts/validate_node_workspace_bootstrap_policy.py \
  --policy planningops/config/node-workspace-bootstrap-policy.json \
  --output "$tmp_dir/node-workspace-bootstrap-policy-valid.json" \
  --strict

python3 - "$tmp_dir/node-workspace-bootstrap-policy-valid.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
PY

cat > "$tmp_dir/invalid-policy.json" <<'JSON'
{
  "policy_version": 0,
  "package_manager": {
    "name": "npm",
    "version": "latest",
    "invocation_prefix": ["npm", "exec", "--", "pnpm"]
  },
  "root_files": ["package.json"],
  "required_root_scripts": [],
  "required_root_dev_dependencies": [],
  "lockfile": {
    "path": "package-lock.json",
    "committed": false
  },
  "commands": {
    "local_install": ["npm", "install"],
    "ci_install": ["npm", "install"],
    "typecheck": ["npm", "run", "build"]
  }
}
JSON

set +e
python3 planningops/scripts/validate_node_workspace_bootstrap_policy.py \
  --policy "$tmp_dir/invalid-policy.json" \
  --output "$tmp_dir/node-workspace-bootstrap-policy-invalid.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid node workspace bootstrap policy"
  exit 1
fi

python3 - <<'PY'
from pathlib import Path

text = Path("planningops/contracts/node-workspace-bootstrap-contract.md").read_text(encoding="utf-8")
required = [
    "npm exec --yes pnpm@9.15.9 --",
    "pnpm-lock.yaml",
    "typecheck",
    "typescript",
    "--frozen-lockfile",
]
missing = [item for item in required if item not in text]
if missing:
    raise SystemExit("node workspace bootstrap contract missing required content: " + ", ".join(missing))
print("node workspace bootstrap contract test ok")
PY

echo "node workspace bootstrap contract ok"
