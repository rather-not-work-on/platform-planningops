#!/usr/bin/env bash
set -euo pipefail

repo_root="$(pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

work_repo="$tmp_dir/work-repo"
mkdir -p "$work_repo/planningops/artifacts/loops/demo" "$work_repo/planningops/artifacts/validation"
cd "$work_repo"
git init -q
git config user.name "Codex"
git config user.email "codex@example.com"

cat > policy.json <<'JSON'
{
  "policy_version": 1,
  "default_external_backend": "local",
  "pointer_manifest_root": "planningops/artifacts/pointers",
  "tiers": {
    "git_canonical": ["planningops/artifacts/validation/**"],
    "git_optional": [],
    "external_only": ["planningops/artifacts/loops/**"]
  },
  "backends": {
    "local": {"kind": "local", "base_path": "planningops/runtime-artifacts/local"},
    "s3": {"kind": "s3_mock", "bucket": "demo", "prefix": "planningops", "mock_base_path": "planningops/runtime-artifacts/s3"},
    "oci": {"kind": "oci_mock", "namespace": "demo", "bucket": "demo", "prefix": "planningops", "mock_base_path": "planningops/runtime-artifacts/oci"}
  },
  "retention": {
    "git_canonical_days": 3650,
    "git_optional_days": 180,
    "external_only_days": 30
  },
  "commit_guard": {
    "forbidden_external_only_in_git": true
  }
}
JSON

printf '{"tracked":true}\n' > planningops/artifacts/loops/demo/run.json
printf '{"untracked":true}\n' > planningops/artifacts/loops/demo/extra.json
git add policy.json planningops/artifacts/loops/demo/run.json

python3 "$repo_root/planningops/scripts/migrate_external_only_artifacts.py" \
  --policy policy.json \
  --scope tracked \
  --output "$tmp_dir/migrate-dry-run.json"

python3 - <<'PY' "$tmp_dir/migrate-dry-run.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["scope"] == "tracked", report
assert report["candidate_count"] == 1, report
assert report["rows"][0]["logical_path"] == "planningops/artifacts/loops/demo/run.json", report
PY

python3 "$repo_root/planningops/scripts/migrate_external_only_artifacts.py" \
  --policy policy.json \
  --scope tracked \
  --apply \
  --output "$tmp_dir/migrate-apply.json"

python3 - <<'PY' "$tmp_dir/migrate-apply.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["mode"] == "apply", report
assert report["scope"] == "tracked", report
assert report["candidate_count"] == 1, report
assert report["migrated_count"] == 1, report
pointer_path = Path(report["rows"][0]["pointer_path"])
assert pointer_path.exists(), pointer_path
backend_target = Path(report["rows"][0]["backend_target_path"])
assert backend_target.exists(), backend_target
assert not Path("planningops/artifacts/loops/demo/run.json").exists()
assert Path("planningops/artifacts/loops/demo/extra.json").exists()
PY

echo "migrate external-only artifacts contract test ok"
