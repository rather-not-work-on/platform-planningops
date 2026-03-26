#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
backup_dir="$(mktemp -d)"
canonical_readiness="$ROOT_DIR/artifacts/validation/federated-ci-summary-readiness.json"
canonical_readiness_validation="$ROOT_DIR/artifacts/validation/federated-ci-summary-readiness-validation.json"

restore_canonical_artifacts() {
  for path in "$canonical_readiness" "$canonical_readiness_validation"; do
    backup_path="$backup_dir/$(basename "$path")"
    if [[ -f "$backup_path" ]]; then
      cp "$backup_path" "$path"
    else
      rm -f "$path"
    fi
  done
  rm -rf "$tmp_dir" "$backup_dir"
}

for path in "$canonical_readiness" "$canonical_readiness_validation"; do
  if [[ -f "$path" ]]; then
    cp "$path" "$backup_dir/$(basename "$path")"
  fi
done

trap restore_canonical_artifacts EXIT

summary_path="$tmp_dir/federated-ci-summary.json"
validation_path="$tmp_dir/federated-ci-summary-validation.json"
report_path="$tmp_dir/federated-ci-summary-readiness.json"
validation_output="$tmp_dir/federated-ci-summary-readiness-validation.json"

cat > "$summary_path" <<'JSON'
{
  "run_id": "readiness-pass-sample",
  "started_at_utc": "2026-03-19T00:00:00+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log"
    }
  ],
  "required_checks": ["contract-conformance"],
  "generated_at_utc": "2026-03-19T00:01:00+00:00",
  "finished_at_utc": "2026-03-19T00:01:01+00:00",
  "overall_status": "complete",
  "check_count": 1,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "contract-conformance->contract"
  },
  "verdict": "pass",
  "shell_exit_code": 0
}
JSON

cat > "$validation_path" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:02+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "summary_run_id": "readiness-pass-sample",
  "summary_generated_at_utc": "2026-03-19T00:01:00+00:00",
  "summary_verdict": "pass",
  "schema_path": "/tmp/federated-ci-summary.schema.json",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "verdict": "pass"
}
JSON

python3 "$ROOT_DIR/scripts/assess_federated_ci_summary_readiness.py" \
  --summary "$summary_path" \
  --validation-report "$validation_path" \
  --output "$report_path" \
  --validation-output "$validation_output" \
  --strict

python3 - <<'PY' "$report_path" "$validation_output"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert report["ready"] is True, report
assert report["readiness_status"] == "ready", report
assert report["blocking_reasons"] == [], report
assert report["next_step"] == "none", report
assert validation["verdict"] == "pass", validation
PY

python3 - <<'PY' "$validation_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["summary_generated_at_utc"] = "2026-03-19T00:00:59+00:00"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/assess_federated_ci_summary_readiness.py" \
  --summary "$summary_path" \
  --validation-report "$validation_path" \
  --output "$report_path" \
  --validation-output "$validation_output" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict readiness assessment to fail on stale validation"
  exit 1
fi

python3 - <<'PY' "$report_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["ready"] is False, report
assert report["readiness_status"] == "blocked", report
assert report["blocking_reasons"] == ["validation_stale"], report
assert report["next_step"].startswith("bash planningops/scripts/federation/federated_ci_matrix_local.sh"), report
PY

python3 - <<'PY' "$validation_output"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert validation["verdict"] == "pass", validation
PY

python3 - <<'PY' "$validation_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["summary_generated_at_utc"] = "2026-03-19T00:01:00+00:00"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/assess_federated_ci_summary_readiness.py" \
  --summary "$summary_path" \
  --validation-report "$validation_path" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict readiness assessment to fail when canonical latest readiness points at non-canonical inputs"
  exit 1
fi

python3 - <<'PY' "$canonical_readiness_validation"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert validation["verdict"] == "fail", validation
assert any("canonical latest readiness must reference latest summary path" in item for item in validation["errors"]), validation
assert any("canonical latest readiness must reference latest summary validation path" in item for item in validation["errors"]), validation
PY

echo "assess federated ci summary readiness ok"
