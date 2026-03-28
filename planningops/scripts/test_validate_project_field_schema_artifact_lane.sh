#!/usr/bin/env bash
set -euo pipefail

repo_root="$(pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mock_bin="$tmpdir/bin"
mkdir -p "$mock_bin"

cat > "$mock_bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

repo_root="${PROJECT_FIELD_SCHEMA_REPO_ROOT:?}"

if [[ "${1:-}" == "project" && "${2:-}" == "field-list" ]]; then
  cat "$repo_root/planningops/fixtures/project-field-schema-field-list.sample.json"
  exit 0
fi

if [[ "${1:-}" == "project" && "${2:-}" == "item-list" ]]; then
  cat "$repo_root/planningops/fixtures/project-field-schema-item-list.sample.json"
  exit 0
fi

echo "unexpected gh invocation: $*" >&2
exit 1
EOF
chmod +x "$mock_bin/gh"

output="$tmpdir/project-field-schema-report.sample.json"

PROJECT_FIELD_SCHEMA_REPO_ROOT="$repo_root" \
PATH="$mock_bin:$PATH" \
python3 planningops/scripts/validate_project_field_schema.py \
  --config planningops/config/project-field-ids.json \
  --output "$output" \
  --fail-on-mismatch

python3 - <<'PY' "$output" "planningops/artifacts/validation/project-field-schema-report.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


actual = normalize(load(sys.argv[1]))
expected = normalize(load(sys.argv[2]))

assert actual == expected, (actual, expected)
print("validate project field schema artifact lane ok")
PY
