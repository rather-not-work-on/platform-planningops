#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cat > "$tmp_dir/config.json" <<'JSON'
{
  "default_priority_label": "p2",
  "required": {
    "required_labels_all": ["task"],
    "required_priority_labels_any": ["p1", "p2", "p3"],
    "required_label_prefixes": ["area/", "type/"]
  },
  "repos": [
    {
      "repo": "rather-not-work-on/platform-contracts",
      "default_area_label": "area/contracts",
      "default_type_label": "type/governance"
    }
  ]
}
JSON

cat > "$tmp_dir/issues-valid.json" <<'JSON'
[
  {
    "repo": "rather-not-work-on/platform-contracts",
    "number": 1,
    "title": "valid sample",
    "url": "https://example.com/1",
    "body": "## Planning Context\n- plan_item_id: `B10`",
    "labels": [
      {"name": "task"},
      {"name": "p2"},
      {"name": "area/contracts"},
      {"name": "type/governance"}
    ]
  }
]
JSON

python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$tmp_dir/config.json" \
  --issues-file "$tmp_dir/issues-valid.json" \
  --output "$tmp_dir/federated-issue-quality-valid.test.json" \
  --strict

cat > "$tmp_dir/issues-invalid.json" <<'JSON'
[
  {
    "repo": "rather-not-work-on/platform-contracts",
    "number": 2,
    "title": "invalid sample",
    "url": "https://example.com/2",
    "body": "## Planning Context\n- plan_item_id: `B11`",
    "labels": []
  }
]
JSON

set +e
python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$tmp_dir/config.json" \
  --issues-file "$tmp_dir/issues-invalid.json" \
  --output "$tmp_dir/federated-issue-quality-invalid.test.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid federated issue quality sample"
  exit 1
fi

python3 planningops/scripts/validate_federated_issue_quality.py \
  --config "$tmp_dir/config.json" \
  --issues-file "$tmp_dir/issues-invalid.json" \
  --output "$tmp_dir/federated-issue-quality-auto-fix.test.json" \
  --apply-default-labels \
  --strict

echo "federated issue quality contract test ok"
