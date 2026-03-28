#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

policy="planningops/fixtures/repository-governance-apply-policy.sample.json"
policy_invalid="planningops/fixtures/repository-governance-apply-policy-invalid.sample.json"
snapshot="planningops/fixtures/branch-protection-apply-snapshot.sample.json"

python3 planningops/scripts/apply_branch_protection.py \
  --policy "$policy" \
  --snapshot-file "$snapshot" \
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

set +e
python3 planningops/scripts/apply_branch_protection.py \
  --policy "$policy_invalid" \
  --snapshot-file "$snapshot" \
  --output "$tmp_dir/branch-protection-apply-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure when only required_status_checks_any is configured"
  exit 1
fi

echo "branch protection apply contract test ok"
