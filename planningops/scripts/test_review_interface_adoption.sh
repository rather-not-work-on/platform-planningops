#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cd "$ROOT_DIR"

cat >"$TMP_DIR/review-spec.json" <<'JSON'
{
  "wave_id": "test-review-interface-adoption",
  "issues_repo": "rather-not-work-on/platform-planningops",
  "required_closed_issues": [],
  "gap_checks": [],
  "file_checks": [],
  "command_checks": [
    {
      "name": "pass-command",
      "repo": "rather-not-work-on/platform-planningops",
      "repo_dir": "platform-planningops",
      "command": ["python3", "-c", "print('pass-command')"]
    },
    {
      "name": "fail-command",
      "repo": "rather-not-work-on/platform-planningops",
      "repo_dir": "platform-planningops",
      "command": ["python3", "-c", "import sys; sys.exit(3)"]
    }
  ]
}
JSON

if python3 planningops/scripts/federation/review_interface_adoption.py \
  --spec "$TMP_DIR/review-spec.json" \
  --workspace-root .. \
  --output "$TMP_DIR/review-report.json" >/dev/null; then
  echo "expected review_interface_adoption.py to fail when a command check fails"
  exit 1
fi

python3 - "$TMP_DIR/review-report.json" <<'PY'
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))

assert report["wave_id"] == "test-review-interface-adoption", report
assert report["check_count"] == 2, report
assert report["failure_count"] == 1, report
assert report["verdict"] == "fail", report
assert len(report["command_checks"]) == 2, report
assert report["command_checks"][0]["name"] == "pass-command", report
assert report["command_checks"][0]["verdict"] == "pass", report
assert report["command_checks"][0]["actual_exit_code"] == 0, report
assert report["command_checks"][1]["name"] == "fail-command", report
assert report["command_checks"][1]["verdict"] == "fail", report
assert report["command_checks"][1]["actual_exit_code"] == 3, report

print("review interface adoption test passed")
PY
