#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

report_path="$tmp_dir/federated-ci-summary-tmp-reconcile.json"
validation_path="$tmp_dir/federated-ci-summary-tmp-reconcile-validation.json"

cat > "$report_path" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-pass-sample",
  "check_name": "loop-guardrails",
  "checkpoint_check_count": 7,
  "summary_check_count": 7,
  "restored": false,
  "status": "healthy",
  "reasons": [],
  "reconcile_count": 0,
  "restored_check_names": []
}
JSON

python3 - <<'PY' "$report_path"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["output_path"] = str(path)
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat > "$validation_path" <<'JSON'
{
  "reconcile_report_path": "__REPORT_PATH__",
  "schema_path": "/tmp/federated-ci-summary-tmp-reconcile.schema.json",
  "output_path": "__VALIDATION_PATH__",
  "generated_at_utc": "2026-03-22T00:01:06+00:00",
  "verdict": "pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "reconcile_generated_at_utc": "2026-03-22T00:01:05+00:00",
  "reconcile_run_id": "reconcile-pass-sample",
  "reconcile_status": "healthy",
  "reconcile_restored": false,
  "reconcile_check_name": "loop-guardrails",
  "reconcile_checkpoint_check_count": 7,
  "reconcile_summary_check_count": 7,
  "reconcile_count": 0,
  "reconcile_restored_check_names": []
}
JSON

python3 - <<'PY' "$validation_path" "$report_path"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["reconcile_report_path"] = str(Path(sys.argv[2]).resolve())
doc["output_path"] = str(path)
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile.py" --report-file "$report_path" --validation-report "$validation_path" --require-pass)"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile run_id: reconcile-pass-sample"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile status: healthy"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile check: loop-guardrails"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile count: 0"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile restored checks: none"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile reasons: none"
printf '%s\n' "$output" | rg -q "validation verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: none"

python3 - <<'PY' "$report_path" "$validation_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
report["generated_at_utc"] = "2026-03-22T00:02:05+00:00"
report["restored"] = True
report["status"] = "restored"
report["reasons"] = ["summary_run_id_mismatch"]
report["reconcile_count"] = 1
report["restored_check_names"] = ["loop-guardrails"]
Path(sys.argv[1]).write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation["reconcile_generated_at_utc"] = "2026-03-22T00:02:05+00:00"
validation["reconcile_status"] = "restored"
validation["reconcile_restored"] = True
validation["reconcile_count"] = 1
validation["reconcile_restored_check_names"] = ["loop-guardrails"]
Path(sys.argv[2]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile.py" --report-file "$report_path" --validation-report "$validation_path" --require-pass)"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile status: restored"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile count: 1"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile restored checks: loop-guardrails"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile reasons: summary_run_id_mismatch"
printf '%s\n' "$output" | rg -q "validation verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: none"

python3 - <<'PY' "$validation_path"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation["reconcile_run_id"] = "reconcile-pass-sample-stale"
Path(sys.argv[1]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile.py" --report-file "$report_path" --validation-report "$validation_path" --require-pass 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected doctor to fail when reconcile validation report is stale"
  exit 1
fi

printf '%s\n' "$output" | rg -q "tmp-summary reconcile status: restored"
printf '%s\n' "$output" | rg -q "validation verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: stale"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

echo "doctor federated ci summary tmp reconcile ok"
