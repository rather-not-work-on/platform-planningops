#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

workspace_root="$tmp_dir/workspace"
mkdir -p \
  "$workspace_root/monday" \
  "$workspace_root/platform-provider-gateway" \
  "$workspace_root/platform-observability-gateway"

for repo in monday platform-provider-gateway platform-observability-gateway; do
  cat > "$workspace_root/$repo/package.json" <<'JSON'
{
  "name": "@rather-not-work-on/test",
  "private": true,
  "version": "0.0.0",
  "scripts": {
    "typecheck": "echo ok"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
JSON
  touch "$workspace_root/$repo/pnpm-workspace.yaml"
  touch "$workspace_root/$repo/tsconfig.base.json"
  touch "$workspace_root/$repo/pnpm-lock.yaml"
done

python3 planningops/scripts/federation/validate_runtime_workspace_build.py \
  --workspace-root "$workspace_root" \
  --policy planningops/config/node-workspace-bootstrap-policy.json \
  --skip-install \
  --skip-typecheck \
  --output "$tmp_dir/pass-report.json"

python3 - <<'PY' "$tmp_dir/pass-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
assert report["repos_checked"] == 3, report
print("runtime workspace build validator pass case ok")
PY

rm "$workspace_root/monday/pnpm-lock.yaml"

if python3 planningops/scripts/federation/validate_runtime_workspace_build.py \
  --workspace-root "$workspace_root" \
  --policy planningops/config/node-workspace-bootstrap-policy.json \
  --skip-install \
  --skip-typecheck \
  --output "$tmp_dir/fail-report.json"; then
  echo "expected failure for missing lockfile"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/fail-report.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert report["error_count"] == 1, report
assert report["errors"][0]["target_repo"] == "rather-not-work-on/monday", report
print("runtime workspace build validator failure case ok")
PY

echo "validate_runtime_workspace_build contract ok"
