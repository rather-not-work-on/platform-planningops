#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

summary_path="$tmp_dir/federated-summary.json"
report_path="$tmp_dir/federated-summary-validation.json"

cat > "$summary_path" <<'JSON'
{
  "run_id": "ci-contract-sample",
  "started_at_utc": "2026-03-19T00:00:00+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log",
      "result": "success"
    },
    {
      "name": "federated-conformance",
      "domain": "federation",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/federated.stdout.log",
      "stderr_log": "/tmp/federated.stderr.log",
      "result": "success"
    }
  ],
  "required_checks": [
    "contract-conformance",
    "federated-conformance"
  ],
  "generated_at_utc": "2026-03-19T00:01:00+00:00",
  "finished_at_utc": "2026-03-19T00:01:01+00:00",
  "overall_status": "complete",
  "check_count": 2,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "contract-conformance->contract, federated-conformance->federation"
  },
  "verdict": "pass",
  "shell_exit_code": 0
}
JSON

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary.py" \
  --summary "$summary_path" \
  --schema-file "$ROOT_DIR/schemas/federated-ci-summary.schema.json" \
  --output "$report_path" \
  --strict

python3 - <<'PY' "$report_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
assert report["summary_run_id"] == "ci-contract-sample", report
assert report["summary_generated_at_utc"] == "2026-03-19T00:01:00+00:00", report
assert report["summary_verdict"] == "pass", report
PY

python3 - <<'PY' "$summary_path" "$tmp_dir/invalid-summary.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["check_count"] = 3
doc["failure_classification"]["count"] = 1
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary.py" \
  --summary "$tmp_dir/invalid-summary.json" \
  --schema-file "$ROOT_DIR/schemas/federated-ci-summary.schema.json" \
  --output "$tmp_dir/invalid-validation.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid federated summary"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/invalid-validation.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert report["error_count"] >= 2, report
assert any("check_count must equal len(checks)" in item for item in report["errors"]), report
assert any("failure_classification.count must equal failed check count" in item for item in report["errors"]), report
PY

echo "validate federated ci summary contract ok"
