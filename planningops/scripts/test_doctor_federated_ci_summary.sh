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
  "run_id": "doctor-pass-sample",
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
  "summary_run_id": "doctor-pass-sample",
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

cat > "$readiness_path" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:03+00:00",
  "summary_path": "__SUMMARY_PATH__",
  "validation_report_path": "__VALIDATION_PATH__",
  "summary_present": true,
  "validation_present": true,
  "summary_run_id": "doctor-pass-sample",
  "summary_generated_at_utc": "2026-03-19T00:01:00+00:00",
  "summary_verdict": "pass",
  "overall_status": "complete",
  "check_count": 1,
  "failed_checks": [],
  "missing_required_checks": [],
  "validation_verdict": "pass",
  "validation_state": "fresh",
  "ready": true,
  "readiness_status": "ready",
  "blocking_reasons": [],
  "next_step": "none"
}
JSON

python3 - <<'PY' "$readiness_path" "$summary_path" "$validation_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["summary_path"] = sys.argv[2]
doc["validation_report_path"] = sys.argv[3]
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat > "$readiness_validation_path" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:04+00:00",
  "readiness_path": "__READINESS_PATH__",
  "readiness_generated_at_utc": "2026-03-19T00:01:03+00:00",
  "readiness_summary_run_id": "doctor-pass-sample",
  "readiness_status": "ready",
  "readiness_ready": true,
  "schema_path": "/tmp/federated-ci-summary-readiness.schema.json",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "verdict": "pass"
}
JSON

python3 - <<'PY' "$readiness_validation_path" "$readiness_path"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["readiness_path"] = sys.argv[2]
Path(sys.argv[1]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat > "$reconcile_path" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:01:05+00:00",
  "summary_path": "__SUMMARY_PATH__",
  "checkpoint_path": "/tmp/federated-ci-summary.checkpoint.json",
  "output_path": "__RECONCILE_PATH__",
  "run_id": "doctor-pass-sample",
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
  "reconcile_run_id": "doctor-pass-sample",
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

output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary.py" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path" --require-pass)"
printf '%s\n' "$output" | rg -q "summary verdict: pass"
printf '%s\n' "$output" | rg -q "validation verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation verdict: pass"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile count: 0"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile restored checks: none"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: none"

python3 - <<'PY' "$summary_path"
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
PY

python3 - <<'PY' "$readiness_path"
import json
import sys
from pathlib import Path

readiness = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
readiness["summary_verdict"] = "fail"
readiness["failed_checks"] = ["contract-conformance (contract)"]
readiness["ready"] = False
readiness["readiness_status"] = "blocked"
readiness["blocking_reasons"] = ["summary_verdict_fail"]
readiness["next_step"] = "bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"
Path(sys.argv[1]).write_text(json.dumps(readiness, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "$readiness_validation_path"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation["readiness_status"] = "blocked"
validation["readiness_ready"] = False
Path(sys.argv[1]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

python3 - <<'PY' "$validation_path"
import json
import sys
from pathlib import Path

validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
validation["summary_verdict"] = "fail"
Path(sys.argv[1]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary.py" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path" --require-pass 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected doctor to fail when summary verdict is fail"
  exit 1
fi

printf '%s\n' "$output" | rg -q "summary verdict: fail"
printf '%s\n' "$output" | rg -q "failed checks: contract-conformance \\(contract\\)"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

python3 - <<'PY' "$summary_path" "$validation_path"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
summary["verdict"] = "pass"
summary["failure_classification"]["count"] = 0
summary["failure_classification"]["domains"] = []
summary["checks"][0]["exit_code"] = 0
summary["checks"][0]["verdict"] = "pass"
summary["generated_at_utc"] = "2026-03-19T00:02:00+00:00"
Path(sys.argv[1]).write_text(json.dumps(summary, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation["summary_generated_at_utc"] = "2026-03-19T00:01:00+00:00"
Path(sys.argv[2]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary.py" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path" --require-pass 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected doctor to fail when validation report is stale"
  exit 1
fi

printf '%s\n' "$output" | rg -q "summary verdict: pass"
printf '%s\n' "$output" | rg -q "validation verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: stale"
printf '%s\n' "$output" | rg -q "readiness artifact state: stale"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

python3 - <<'PY' "$summary_path" "$validation_path" "$readiness_path" "$readiness_validation_path"
import json
import sys
from pathlib import Path

summary = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
summary["generated_at_utc"] = "2026-03-19T00:03:00+00:00"
Path(sys.argv[1]).write_text(json.dumps(summary, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation["summary_generated_at_utc"] = "2026-03-19T00:03:00+00:00"
validation["summary_verdict"] = "pass"
Path(sys.argv[2]).write_text(json.dumps(validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

readiness = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))
readiness["generated_at_utc"] = "2026-03-19T00:03:01+00:00"
readiness["summary_generated_at_utc"] = "2026-03-19T00:03:00+00:00"
readiness["summary_verdict"] = "pass"
readiness["failed_checks"] = []
readiness["validation_state"] = "fresh"
readiness["ready"] = True
readiness["readiness_status"] = "ready"
readiness["blocking_reasons"] = []
readiness["next_step"] = "none"
Path(sys.argv[3]).write_text(json.dumps(readiness, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

readiness_validation = json.loads(Path(sys.argv[4]).read_text(encoding="utf-8"))
readiness_validation["readiness_generated_at_utc"] = "2026-03-19T00:03:00+00:00"
readiness_validation["readiness_status"] = "ready"
readiness_validation["readiness_ready"] = True
Path(sys.argv[4]).write_text(json.dumps(readiness_validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary.py" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path" --require-pass 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected doctor to fail when readiness validation report is stale"
  exit 1
fi

printf '%s\n' "$output" | rg -q "summary verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation verdict: pass"
printf '%s\n' "$output" | rg -q "readiness validation state: stale"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: fresh"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

python3 - <<'PY' "$readiness_validation_path" "$reconcile_validation_path"
import json
import sys
from pathlib import Path

readiness_validation = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
readiness_validation["readiness_generated_at_utc"] = "2026-03-19T00:03:01+00:00"
readiness_validation["readiness_status"] = "ready"
readiness_validation["readiness_ready"] = True
Path(sys.argv[1]).write_text(json.dumps(readiness_validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

reconcile_validation = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
reconcile_validation["reconcile_generated_at_utc"] = "2026-03-19T00:01:05+00:00"
reconcile_validation["reconcile_run_id"] = "doctor-pass-sample-stale"
Path(sys.argv[2]).write_text(json.dumps(reconcile_validation, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
output="$("$ROOT_DIR/scripts/doctor_federated_ci_summary.py" --summary "$summary_path" --validation-report "$validation_path" --readiness-report "$readiness_path" --readiness-validation-report "$readiness_validation_path" --reconcile-report "$reconcile_path" --reconcile-validation-report "$reconcile_validation_path" --require-pass 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected doctor to fail when reconcile validation report is stale"
  exit 1
fi

printf '%s\n' "$output" | rg -q "summary verdict: pass"
printf '%s\n' "$output" | rg -q "validation state: fresh"
printf '%s\n' "$output" | rg -q "readiness artifact state: fresh"
printf '%s\n' "$output" | rg -q "readiness validation state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile state: fresh"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation verdict: pass"
printf '%s\n' "$output" | rg -q "tmp-summary reconcile validation state: stale"
printf '%s\n' "$output" | rg -q "next step: bash planningops/scripts/federation/federated_ci_matrix_local.sh <run-id>"

python3 - <<'PY' "$ROOT_DIR/scripts/doctor_federated_ci_summary.py" "$ROOT_DIR/.."
import importlib.util
import sys
from pathlib import Path

module_path = Path(sys.argv[1])
workspace_root = Path(sys.argv[2]).resolve()
spec = importlib.util.spec_from_file_location("doctor_federated_ci_summary", module_path)
module = importlib.util.module_from_spec(spec)
assert spec is not None and spec.loader is not None
spec.loader.exec_module(module)
resolved = module.resolve_artifact_path("planningops/artifacts/ci/federated-ci-summary.json")
assert resolved == (workspace_root / "planningops/artifacts/ci/federated-ci-summary.json").resolve(), resolved
PY

echo "doctor federated ci summary ok"
