#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

summary_path="$tmp_dir/federated-ci-summary.json"
validation_path="$tmp_dir/federated-ci-summary-validation.json"
readiness_path="$tmp_dir/federated-ci-summary-readiness.json"
readiness_validation_path="$tmp_dir/federated-ci-summary-readiness-validation.json"
reconcile_path="$tmp_dir/federated-ci-summary-tmp-reconcile.json"
reconcile_validation_path="$tmp_dir/federated-ci-summary-tmp-reconcile-validation.json"

cat > "$summary_path" <<'JSON'
{
  "run_id": "gate-pass-sample",
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
  "summary_run_id": "gate-pass-sample",
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

cat > "$reconcile_path" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:05+00:00",
  "summary_path": "__SUMMARY_PATH__",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__RECONCILE_PATH__",
  "run_id": "gate-pass-sample",
  "check_name": "loop-guardrails",
  "checkpoint_check_count": 0,
  "summary_check_count": 0,
  "restored": false,
  "status": "healthy",
  "reasons": [],
  "reconcile_count": 0,
  "restored_check_names": []
}
JSON

python3 - <<'PY' "$reconcile_path" "$summary_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["summary_path"] = sys.argv[2]
doc["output_path"] = sys.argv[1]
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat > "$reconcile_validation_path" <<'JSON'
{
  "reconcile_report_path": "__RECONCILE_PATH__",
  "schema_path": "/tmp/federated-ci-summary-tmp-reconcile.schema.json",
  "output_path": "__RECONCILE_VALIDATION_PATH__",
  "generated_at_utc": "2026-03-19T00:01:06+00:00",
  "verdict": "pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "reconcile_generated_at_utc": "2026-03-19T00:01:05+00:00",
  "reconcile_run_id": "gate-pass-sample",
  "reconcile_status": "healthy",
  "reconcile_restored": false,
  "reconcile_check_name": "loop-guardrails",
  "reconcile_checkpoint_check_count": 0,
  "reconcile_summary_check_count": 0,
  "reconcile_count": 0,
  "reconcile_restored_check_names": []
}
JSON

python3 - <<'PY' "$reconcile_validation_path" "$reconcile_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["reconcile_report_path"] = sys.argv[2]
doc["output_path"] = sys.argv[1]
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

output="$("$ROOT_DIR/scripts/gate_federated_ci_summary.sh" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path")"
printf '%s\n' "$output" | rg -q "summary verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile count: 0"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile restored checks: none"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
test -f "$readiness_path"
test -f "$readiness_validation_path"

python3 - <<'PY' "$summary_path" "$validation_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["verdict"] = "fail"
doc["failure_classification"]["count"] = 1
doc["failure_classification"]["domains"] = ["contract"]
doc["checks"][0]["exit_code"] = 1
doc["checks"][0]["verdict"] = "fail"
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation["summary_verdict"] = "fail"
Path(sys.argv[2]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/gate_federated_ci_summary.sh" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path" 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected gate to fail when summary verdict is fail"
  exit 1
fi

printf '%s\n' "$output" | rg -q "summary verdict: fail"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

shadow_root="$tmp_dir/default-gate-shadow"
mkdir -p "$shadow_root/planningops/scripts" "$shadow_root/planningops/schemas" "$shadow_root/planningops/artifacts/ci" "$shadow_root/planningops/artifacts/validation"
cp "$ROOT_DIR/scripts/assess_federated_ci_summary_readiness.py" "$shadow_root/planningops/scripts/assess_federated_ci_summary_readiness.py"
cp "$ROOT_DIR/scripts/validate_federated_ci_summary_readiness.py" "$shadow_root/planningops/scripts/validate_federated_ci_summary_readiness.py"
cp "$ROOT_DIR/scripts/doctor_federated_ci_summary.py" "$shadow_root/planningops/scripts/doctor_federated_ci_summary.py"
cp "$ROOT_DIR/scripts/gate_federated_ci_summary.sh" "$shadow_root/planningops/scripts/gate_federated_ci_summary.sh"
cp "$ROOT_DIR/schemas/federated-ci-summary-readiness.schema.json" "$shadow_root/planningops/schemas/federated-ci-summary-readiness.schema.json"
chmod +x "$shadow_root/planningops/scripts/gate_federated_ci_summary.sh"

cat > "$shadow_root/planningops/artifacts/ci/federated-ci-summary.json" <<'JSON'
{
  "run_id": "gate-default-pass-sample",
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

cat > "$shadow_root/planningops/artifacts/validation/federated-ci-summary-validation.json" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:02+00:00",
  "summary_path": "__SUMMARY_PATH__",
  "summary_run_id": "gate-default-pass-sample",
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

cat > "$shadow_root/planningops/artifacts/validation/federated-ci-summary-tmp-reconcile.json" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:05+00:00",
  "summary_path": "__SUMMARY_PATH__",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__RECONCILE_PATH__",
  "run_id": "gate-default-pass-sample",
  "check_name": "loop-guardrails",
  "checkpoint_check_count": 0,
  "summary_check_count": 0,
  "restored": false,
  "status": "healthy",
  "reasons": [],
  "reconcile_count": 0,
  "restored_check_names": []
}
JSON

cat > "$shadow_root/planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-validation.json" <<'JSON'
{
  "reconcile_report_path": "__RECONCILE_PATH__",
  "schema_path": "/tmp/federated-ci-summary-tmp-reconcile.schema.json",
  "output_path": "__RECONCILE_VALIDATION_PATH__",
  "generated_at_utc": "2026-03-19T00:01:06+00:00",
  "verdict": "pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "reconcile_generated_at_utc": "2026-03-19T00:01:05+00:00",
  "reconcile_run_id": "gate-default-pass-sample",
  "reconcile_status": "healthy",
  "reconcile_restored": false,
  "reconcile_check_name": "loop-guardrails",
  "reconcile_checkpoint_check_count": 0,
  "reconcile_summary_check_count": 0,
  "reconcile_count": 0,
  "reconcile_restored_check_names": []
}
JSON

python3 - <<'PY' "$shadow_root"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
summary_path = root / "planningops/artifacts/ci/federated-ci-summary.json"
validation_path = root / "planningops/artifacts/validation/federated-ci-summary-validation.json"
reconcile_path = root / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile.json"
reconcile_validation_path = root / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-validation.json"

validation = json.loads(validation_path.read_text(encoding="utf-8"))
validation["summary_path"] = str(summary_path)
validation_path.write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

reconcile = json.loads(reconcile_path.read_text(encoding="utf-8"))
reconcile["summary_path"] = str(summary_path)
reconcile["output_path"] = str(reconcile_path)
reconcile_path.write_text(json.dumps(reconcile, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

reconcile_validation = json.loads(reconcile_validation_path.read_text(encoding="utf-8"))
reconcile_validation["reconcile_report_path"] = str(reconcile_path)
reconcile_validation["output_path"] = str(reconcile_validation_path)
reconcile_validation_path.write_text(json.dumps(reconcile_validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

output="$("$shadow_root/planningops/scripts/gate_federated_ci_summary.sh")"
printf '%s\n' "$output" | rg -q "summary verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: none"

echo "gate federated ci summary ok"
