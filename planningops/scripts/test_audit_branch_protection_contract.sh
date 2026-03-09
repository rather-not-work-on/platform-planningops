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
      "required_status_checks_all": ["template-and-link-check", "validate-and-dry-run", "federated-summary"]
    },
    {
      "name": "monday",
      "required_status_checks_all": ["template-and-link-check", "monday-local-ci"]
    }
  ]
}
JSON

cat > "$tmp_dir/snapshot-valid.json" <<'JSON'
{
  "repositories": [
    {
      "name": "platform-planningops",
      "default_branch": "main",
      "rules": [
        {
          "pattern": "main",
          "requiresApprovingReviews": true,
          "requiredApprovingReviewCount": 1,
          "requiresStatusChecks": true,
          "requiredStatusCheckContexts": [
            "template-and-link-check",
            "validate-and-dry-run",
            "federated-summary"
          ],
          "requiresStrictStatusChecks": true,
          "requiresConversationResolution": true,
          "allowsForcePushes": false,
          "allowsDeletions": false,
          "isAdminEnforced": false
        }
      ]
    },
    {
      "name": "monday",
      "default_branch": "main",
      "rules": [
        {
          "pattern": "main",
          "requiresApprovingReviews": true,
          "requiredApprovingReviewCount": 1,
          "requiresStatusChecks": true,
          "requiredStatusCheckContexts": ["template-and-link-check", "monday-local-ci"],
          "requiresStrictStatusChecks": true,
          "requiresConversationResolution": true,
          "allowsForcePushes": false,
          "allowsDeletions": false,
          "isAdminEnforced": false
        }
      ]
    }
  ]
}
JSON

python3 planningops/scripts/audit_branch_protection.py \
  --policy "$tmp_dir/policy.json" \
  --snapshot-file "$tmp_dir/snapshot-valid.json" \
  --output "$tmp_dir/branch-protection-valid.test.json" \
  --strict

cat > "$tmp_dir/snapshot-invalid.json" <<'JSON'
{
  "repositories": [
    {
      "name": "platform-planningops",
      "default_branch": "main",
      "rules": [
        {
          "pattern": "main",
          "requiresApprovingReviews": true,
          "requiredApprovingReviewCount": 1,
          "requiresStatusChecks": true,
          "requiredStatusCheckContexts": [
            "template-and-link-check",
            "validate-and-dry-run"
          ],
          "requiresStrictStatusChecks": true,
          "requiresConversationResolution": true,
          "allowsForcePushes": false,
          "allowsDeletions": false,
          "isAdminEnforced": false
        }
      ]
    },
    {
      "name": "monday",
      "default_branch": "main",
      "rules": [
        {
          "pattern": "main",
          "requiresApprovingReviews": false,
          "requiredApprovingReviewCount": 0,
          "requiresStatusChecks": false,
          "requiredStatusCheckContexts": [],
          "requiresStrictStatusChecks": false,
          "requiresConversationResolution": false,
          "allowsForcePushes": true,
          "allowsDeletions": true,
          "isAdminEnforced": false
        }
      ]
    }
  ]
}
JSON

set +e
python3 planningops/scripts/audit_branch_protection.py \
  --policy "$tmp_dir/policy.json" \
  --snapshot-file "$tmp_dir/snapshot-invalid.json" \
  --output "$tmp_dir/branch-protection-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid branch protection snapshot"
  exit 1
fi

echo "branch protection audit contract test ok"
