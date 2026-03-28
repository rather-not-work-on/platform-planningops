#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
repo_probe="planningops/scripts/._github_sync_adapter.py"
role_probe="planningops/scripts/._bootstrap_two_track_backlog.py"
trap 'rm -rf "$tmpdir"; rm -f "$repo_probe" "$role_probe"' EXIT

repo_report="$tmpdir/repo-boundary-report.test.json"
role_report="$tmpdir/script-role-report.test.json"
policy_report="$tmpdir/artifact-storage-policy-valid.test.json"

printf '# metadata probe\n' > "$repo_probe"
python3 planningops/scripts/validate_repo_boundaries.py --output "$repo_report" >/dev/null
rm -f "$repo_probe"

printf '# metadata probe\n' > "$role_probe"
python3 planningops/scripts/validate_script_roles.py --output "$role_report" >/dev/null
rm -f "$role_probe"

python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy planningops/config/artifact-storage-policy.json \
  --output "$policy_report" \
  --strict \
  >/dev/null

python3 - <<'PY' \
  "$repo_report" \
  "$role_report" \
  "$policy_report" \
  "planningops/artifacts/validation/repo-boundary-report.test.json" \
  "planningops/artifacts/validation/script-role-report.test.json" \
  "planningops/artifacts/validation/artifact-storage-policy-valid.test.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual_repo = normalize(load(sys.argv[1]))
actual_role = normalize(load(sys.argv[2]))
actual_policy = normalize(load(sys.argv[3]))

expected_repo = normalize(load(sys.argv[4]))
expected_role = normalize(load(sys.argv[5]))
expected_policy = normalize(load(sys.argv[6]))

assert actual_repo == expected_repo, (actual_repo, expected_repo)
assert actual_role == expected_role, (actual_role, expected_role)
assert actual_policy == expected_policy, (actual_policy, expected_policy)

print("governance validation artifact lanes ok")
PY
