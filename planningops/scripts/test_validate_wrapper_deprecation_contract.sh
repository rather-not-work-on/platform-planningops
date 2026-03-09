#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/planningops/scripts/core/loop" "$tmp_dir/planningops/scripts/federation" "$tmp_dir/planningops/config"

cat > "$tmp_dir/planningops/scripts/issue_loop_runner.py" <<'PY'
#!/usr/bin/env python3
print("wrapper")
PY
cat > "$tmp_dir/planningops/scripts/core/loop/runner.py" <<'PY'
#!/usr/bin/env python3
print("core")
PY
cat > "$tmp_dir/planningops/scripts/repo_execution_adapters.py" <<'PY'
#!/usr/bin/env python3
print("wrapper")
PY
cat > "$tmp_dir/planningops/scripts/federation/adapter_registry.py" <<'PY'
#!/usr/bin/env python3
print("federation")
PY
cat > "$tmp_dir/planningops/scripts/bootstrap_two_track_backlog.py" <<'PY'
#!/usr/bin/env python3
print("wrapper")
PY
mkdir -p "$tmp_dir/planningops/scripts/oneoff"
cat > "$tmp_dir/planningops/scripts/oneoff/bootstrap_two_track_backlog.py" <<'PY'
#!/usr/bin/env python3
print("oneoff")
PY
cat > "$tmp_dir/planningops/scripts/consumer.py" <<'PY'
WRAPPED = "planningops/scripts/issue_loop_runner.py"
PY
ln -s /opt/homebrew/bin/python3 "$tmp_dir/planningops/scripts/external-python"

cat > "$tmp_dir/planningops/config/script-role-map.json" <<'JSON'
{
  "compatibility_wrappers": {
    "bootstrap_two_track_backlog.py": {"target": "oneoff/bootstrap_two_track_backlog.py", "role": "oneoff"},
    "issue_loop_runner.py": {"target": "core/loop/runner.py", "role": "core"},
    "repo_execution_adapters.py": {"target": "federation/adapter_registry.py", "role": "federation"}
  }
}
JSON

cat > "$tmp_dir/planningops/config/wrapper-deprecation-map.json" <<'JSON'
{
  "policy_version": 1,
  "scan_roots": ["planningops"],
  "exclude_globs": ["planningops/config/wrapper-deprecation-map.json"],
  "wrappers": [
    {
      "wrapper_path": "planningops/scripts/bootstrap_two_track_backlog.py",
      "target_path": "planningops/scripts/oneoff/bootstrap_two_track_backlog.py",
      "role": "oneoff",
      "warn_after": "2026-03-01",
      "fail_after": "2026-05-01",
      "allowed_reference_paths": []
    },
    {
      "wrapper_path": "planningops/scripts/issue_loop_runner.py",
      "target_path": "planningops/scripts/core/loop/runner.py",
      "role": "core",
      "warn_after": "2026-03-01",
      "fail_after": "2026-04-01",
      "allowed_reference_paths": []
    },
    {
      "wrapper_path": "planningops/scripts/repo_execution_adapters.py",
      "target_path": "planningops/scripts/federation/adapter_registry.py",
      "role": "federation",
      "warn_after": "2026-03-01",
      "fail_after": "2026-05-01",
      "allowed_reference_paths": []
    }
  ]
}
JSON

python3 planningops/scripts/validate_wrapper_deprecation.py \
  --repo-root "$tmp_dir" \
  --config planningops/config/wrapper-deprecation-map.json \
  --script-role-map planningops/config/script-role-map.json \
  --mode warn \
  --current-date 2026-03-08 \
  --output "$tmp_dir/warn-report.json"

python3 - <<'PY' "$tmp_dir/warn-report.json"
import json
import sys
from pathlib import Path
report = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert report['verdict'] == 'warn', report
assert report['warning_count'] == 1, report
assert report['error_count'] == 0, report
assert report['findings'][0]['wrapper_path'] == 'planningops/scripts/issue_loop_runner.py', report
PY

set +e
python3 planningops/scripts/validate_wrapper_deprecation.py \
  --repo-root "$tmp_dir" \
  --config planningops/config/wrapper-deprecation-map.json \
  --script-role-map planningops/config/script-role-map.json \
  --mode fail \
  --current-date 2026-04-10 \
  --output "$tmp_dir/fail-report.json"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected fail-mode to reject expired wrapper reference"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/fail-report.json"
import json
import sys
from pathlib import Path
report = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
assert report['verdict'] == 'fail', report
assert report['error_count'] == 1, report
assert report['findings'][0]['severity'] == 'error', report
PY

echo "wrapper deprecation contract ok"
