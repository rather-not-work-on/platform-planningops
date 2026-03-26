#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

report_path="$tmp_dir/federated-ci-summary-tmp-reconcile.json"
validation_path="$tmp_dir/federated-ci-summary-tmp-reconcile-validation.json"
bundle_path="$tmp_dir/federated-ci-summary-tmp-reconcile-bundle.json"
bundle_validation_path="$tmp_dir/federated-ci-summary-tmp-reconcile-bundle-validation.json"
status_path="$tmp_dir/federated-ci-summary-tmp-reconcile-bundle-status.json"
status_validation_path="$tmp_dir/federated-ci-summary-tmp-reconcile-bundle-status-validation.json"
status_path_resolved="$(python3 - <<'PY' "$status_path"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"
status_validation_path_resolved="$(python3 - <<'PY' "$status_validation_path"
from pathlib import Path
import sys
print(Path(sys.argv[1]).resolve())
PY
)"

cat > "$report_path" <<'JSON'
{
  "generated_at_utc": "2026-03-22T00:01:05+00:00",
  "summary_path": "/tmp/federated-ci-summary.json",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__REPORT_PATH__",
  "run_id": "reconcile-bundle-pass-sample",
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
  "reconcile_run_id": "reconcile-bundle-pass-sample",
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

python3 "$ROOT_DIR/scripts/resolve_federated_ci_summary_tmp_reconcile.py" \
  --artifact-file "$report_path" \
  --output "$bundle_path" >/dev/null

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py" \
  --bundle-file "$bundle_path" \
  --output "$bundle_validation_path" \
  --strict >/dev/null

output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" --bundle-file "$bundle_path" --validation-report "$bundle_validation_path" --status-output "$status_path" --status-validation-output "$status_validation_path" --require-pass)"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle run_id: reconcile-bundle-pass-sample"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle status: healthy"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle check: loop-guardrails"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle count: 0"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile nested validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: none"
printf '%s\n' "$output" | rg -q "status output path: ${status_path_resolved}"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle status validation verdict: pass"
printf '%s\n' "$output" | rg -q "status validation output path: ${status_validation_path_resolved}"

python3 - <<'PY' "$report_path" "$validation_path" "$bundle_path" "$bundle_validation_path" "$ROOT_DIR"
import json
import subprocess
import sys
from pathlib import Path

report_path = Path(sys.argv[1]).resolve()
validation_path = Path(sys.argv[2]).resolve()
bundle_path = Path(sys.argv[3]).resolve()
bundle_validation_path = Path(sys.argv[4]).resolve()
root_dir = Path(sys.argv[5]).resolve()

report = json.loads(report_path.read_text(encoding="utf-8"))
report["generated_at_utc"] = "2026-03-22T00:02:05+00:00"
report["restored"] = True
report["status"] = "restored"
report["reasons"] = ["summary_run_id_mismatch"]
report["reconcile_count"] = 1
report["restored_check_names"] = ["loop-guardrails"]
report_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

validation = json.loads(validation_path.read_text(encoding="utf-8"))
validation["reconcile_generated_at_utc"] = "2026-03-22T00:02:05+00:00"
validation["reconcile_status"] = "restored"
validation["reconcile_restored"] = True
validation["reconcile_count"] = 1
validation["reconcile_restored_check_names"] = ["loop-guardrails"]
validation_path.write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

subprocess.run(
    [
        "python3",
        str(root_dir / "scripts/resolve_federated_ci_summary_tmp_reconcile.py"),
        "--artifact-file",
        str(report_path),
        "--output",
        str(bundle_path),
    ],
    check=True,
    stdout=subprocess.DEVNULL,
)
subprocess.run(
    [
        "python3",
        str(root_dir / "scripts/validate_federated_ci_summary_tmp_reconcile_bundle.py"),
        "--bundle-file",
        str(bundle_path),
        "--output",
        str(bundle_validation_path),
        "--strict",
    ],
    check=True,
    stdout=subprocess.DEVNULL,
)
PY

output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" --bundle-file "$bundle_path" --validation-report "$bundle_validation_path" --status-output "$status_path" --status-validation-output "$status_validation_path" --require-pass)"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle status: restored"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle count: 1"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile nested validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: none"
printf '%s\n' "$output" | rg -q "status output path: ${status_path_resolved}"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle status validation verdict: pass"
printf '%s\n' "$output" | rg -q "status validation output path: ${status_validation_path_resolved}"

python3 - <<'PY' "$bundle_validation_path"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation["run_id"] = "reconcile-bundle-pass-sample-stale"
Path(sys.argv[1]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary_tmp_reconcile_bundle.py" --bundle-file "$bundle_path" --validation-report "$bundle_validation_path" --status-output "$status_path" --status-validation-output "$status_validation_path" --require-pass 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected bundle doctor to fail when bundle validation report is stale"
  exit 1
fi

printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle status: restored"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle validation state: stale"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile bundle status validation verdict: pass"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

echo "doctor federated ci summary tmp reconcile bundle ok"
