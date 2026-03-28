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

repo_root="${MOCK_REPO_ROOT:?}"

if [[ "${1:-}" == "project" && "${2:-}" == "item-list" ]]; then
  cat "$repo_root/planningops/fixtures/ready-implementation-blueprint-project-items.sample.json"
  exit 0
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "view" ]]; then
  cat "$repo_root/planningops/fixtures/ready-implementation-blueprint-issue-view.sample.json"
  exit 0
fi

if [[ "${1:-}" == "issue" && "${2:-}" == "edit" ]]; then
  exit 0
fi

echo "unexpected gh invocation: $*" >&2
exit 1
EOF
chmod +x "$mock_bin/gh"

output="$tmpdir/ready-implementation-blueprint-normalize-report.sample.json"

MOCK_REPO_ROOT="$repo_root" \
PATH="$mock_bin:$PATH" \
python3 planningops/scripts/normalize_ready_implementation_blueprint_refs.py \
  --config planningops/config/ready-implementation-blueprint-defaults.json \
  --output "$output"

python3 - <<'PY' "$output" "planningops/artifacts/validation/ready-implementation-blueprint-normalize-report.sample.json"
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
print("normalize ready implementation blueprint refs artifact lane ok")
PY
