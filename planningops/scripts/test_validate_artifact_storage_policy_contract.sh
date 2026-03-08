#!/usr/bin/env bash
set -euo pipefail

python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy planningops/config/artifact-storage-policy.json \
  --output planningops/artifacts/validation/artifact-storage-policy-valid.test.json \
  --strict

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/invalid-policy.json" <<'JSON'
{
  "policy_version": 0,
  "default_external_backend": "",
  "pointer_manifest_root": "planningops/artifacts/invalid-root",
  "tiers": {
    "git_canonical": [],
    "git_optional": [],
    "external_only": []
  },
  "backends": {
    "local": {
      "kind": "local"
    }
  },
  "portability_profile": {
    "mode": "remote_first",
    "default_backend": "s3",
    "approved_migration_backends": [],
    "target_platforms": [],
    "canonical_pointer_strategy": "inline_git"
  },
  "execution_event_families": {
    "broken_family": {
      "logical_root": "planningops/artifacts/validation",
      "residency": "git_canonical",
      "pointer_visibility": "inline_git",
      "default_backend": "s3",
      "migration_backends": ["local"],
      "retention_days": 999,
      "owner_scripts": ["planningops/scripts/does-not-exist.py"]
    }
  },
  "retention": {
    "git_canonical_days": 0,
    "git_optional_days": -1,
    "external_only_days": 0
  },
  "commit_guard": {
    "forbidden_external_only_in_git": "yes"
  }
}
JSON

set +e
python3 planningops/scripts/validate_artifact_storage_policy.py \
  --policy "$tmp_dir/invalid-policy.json" \
  --output "$tmp_dir/artifact-storage-policy-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid artifact-storage policy fixture"
  exit 1
fi

echo "artifact storage policy contract test ok"
