#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

workspace_root="$tmp_dir/workspace"
mkdir -p "$workspace_root/platform-contracts" \
  "$workspace_root/platform-provider-gateway" \
  "$workspace_root/platform-observability-gateway" \
  "$workspace_root/monday"

for rel in \
  platform-contracts/requirements-dev.txt \
  platform-provider-gateway/requirements-dev.txt \
  platform-observability-gateway/requirements-dev.txt \
  monday/requirements-dev.txt
  do
  cat > "$workspace_root/$rel" <<'REQ'
jsonschema==4.23.0
rfc3339-validator==0.1.4
REQ
done

python3 planningops/scripts/federation/cross_repo_conformance_check.py \
  --workspace-root "$workspace_root" \
  --bootstrap-root "$tmp_dir/bootstrap-root" \
  --bootstrap-mode auto \
  --bootstrap-plan-only \
  --bootstrap-plan-output "$tmp_dir/plan-a.json"

python3 planningops/scripts/federation/cross_repo_conformance_check.py \
  --workspace-root "$workspace_root" \
  --bootstrap-root "$tmp_dir/bootstrap-root" \
  --bootstrap-mode auto \
  --bootstrap-plan-only \
  --bootstrap-plan-output "$tmp_dir/plan-b.json"

python3 - <<'PY' "$tmp_dir/plan-a.json" "$tmp_dir/plan-b.json" "$tmp_dir/bootstrap-root"
import json
import sys
from pathlib import Path

plan_a = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
plan_b = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
bootstrap_root = Path(sys.argv[3]).absolute()

assert plan_a['requirements_hash'] == plan_b['requirements_hash'], (plan_a, plan_b)
assert sorted(plan_a['requirements_files']) == sorted([
    'platform-contracts/requirements-dev.txt',
    'platform-provider-gateway/requirements-dev.txt',
    'platform-observability-gateway/requirements-dev.txt',
    'monday/requirements-dev.txt',
]), plan_a
assert plan_a['missing_requirement_files'] == [], plan_a
assert Path(plan_a['bootstrap_root']).absolute() == bootstrap_root, plan_a
assert Path(plan_a['managed_python']).absolute().as_posix().startswith(bootstrap_root.as_posix()), plan_a
print('cross repo conformance bootstrap contract ok')
PY
