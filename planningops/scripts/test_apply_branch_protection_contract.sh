#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/policy.json" <<'JSON'
{
  "owner": "rather-not-work-on",
  "default_branch": "main",
  "defaults": {
    "require_approving_reviews": true,
    "min_approving_review_count": 1,
    "require_conversation_resolution": true,
    "require_status_checks": true,
    "require_strict_status_checks": true,
    "allow_force_pushes": false,
    "allow_deletions": false,
    "enforce_admins": false
  },
  "repos": [
    {
      "name": "platform-planningops",
      "required_status_checks_all": [
        "template-and-link-check",
        "validate-and-dry-run",
        "federated-summary"
      ]
    },
    {
      "name": "platform-provider-gateway",
      "required_status_checks_all": [
        "template-and-link-check",
        "provider-local-ci"
      ]
    }
  ]
}
JSON

cat > "$tmp_dir/snapshot.json" <<'JSON'
{
  "repositories": [
    {"name": "platform-planningops", "default_branch": "main"},
    {"name": "platform-provider-gateway", "default_branch": "main"}
  ]
}
JSON

python3 planningops/scripts/apply_branch_protection.py \
  --policy "$tmp_dir/policy.json" \
  --snapshot-file "$tmp_dir/snapshot.json" \
  --output "$tmp_dir/branch-protection-apply.test.json" \
  --strict

python3 - "$tmp_dir/branch-protection-apply.test.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["repo_evaluated_count"] == 2, report

rows = {row["repo"]: row for row in report["results"]}
planningops = rows["platform-planningops"]
provider = rows["platform-provider-gateway"]

assert planningops["required_status_checks"] == [
    "template-and-link-check",
    "validate-and-dry-run",
    "federated-summary",
], planningops
assert provider["required_status_checks"] == ["template-and-link-check", "provider-local-ci"], provider

payload = planningops["payload"]
assert payload["required_status_checks"]["strict"] is True, payload
assert payload["required_pull_request_reviews"]["required_approving_review_count"] == 1, payload
assert payload["allow_force_pushes"] is False, payload
assert payload["allow_deletions"] is False, payload
assert payload["required_conversation_resolution"] is True, payload
PY

cat > "$tmp_dir/policy-invalid.json" <<'JSON'
{
  "owner": "rather-not-work-on",
  "default_branch": "main",
  "defaults": {
    "require_approving_reviews": true,
    "min_approving_review_count": 1,
    "require_conversation_resolution": true,
    "require_status_checks": true,
    "require_strict_status_checks": true,
    "allow_force_pushes": false,
    "allow_deletions": false,
    "enforce_admins": false
  },
  "repos": [
    {
      "name": "platform-planningops",
      "required_status_checks_any": ["template-and-link-check", "federated-summary"]
    }
  ]
}
JSON

set +e
python3 planningops/scripts/apply_branch_protection.py \
  --policy "$tmp_dir/policy-invalid.json" \
  --snapshot-file "$tmp_dir/snapshot.json" \
  --output "$tmp_dir/branch-protection-apply-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure when only required_status_checks_any is configured"
  exit 1
fi

echo "branch protection apply contract test ok"
