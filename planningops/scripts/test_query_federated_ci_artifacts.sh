#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUERY_PATH="$ROOT_DIR/scripts/federation/query_federated_ci_artifacts.py"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

python3 - <<'PY' "$QUERY_PATH" "$ROOT_DIR"
import importlib.util
import sys
from pathlib import Path

query_path = Path(sys.argv[1])
root_dir = Path(sys.argv[2]).resolve().parent

spec = importlib.util.spec_from_file_location("query_federated_ci_artifacts", query_path)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.path.insert(0, str(query_path.parent))
sys.modules[spec.name] = module
spec.loader.exec_module(module)

assert module.WORKSPACE_ROOT == root_dir, (module.WORKSPACE_ROOT, root_dir)
assert module.DEFAULT_CI_ROOT == root_dir / "planningops/artifacts/ci", module.DEFAULT_CI_ROOT
PY

CI_DIR="$TMP_DIR/ci"
VALIDATION_DIR="$TMP_DIR/validation"
CONFORMANCE_DIR="$TMP_DIR/conformance"
mkdir -p "$CI_DIR" "$VALIDATION_DIR" "$CONFORMANCE_DIR"

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun26.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun26",
  "started_at_utc": "2026-03-19T00:00:00+00:00",
  "generated_at_utc": "2026-03-19T00:10:00+00:00",
  "finished_at_utc": "2026-03-19T00:10:00+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log"
    },
    {
      "name": "loop-guardrails",
      "domain": "policy",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/policy.stdout.log",
      "stderr_log": "/tmp/policy.stderr.log"
    }
  ],
  "required_checks": [
    "contract-conformance",
    "loop-guardrails"
  ],
  "overall_status": "complete",
  "check_count": 2,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "demo"
  },
  "verdict": "pass",
  "shell_exit_code": 0
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun27.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun27",
  "started_at_utc": "2026-03-19T00:00:30+00:00",
  "generated_at_utc": "2026-03-19T00:10:30+00:00",
  "finished_at_utc": "2026-03-19T00:10:30+00:00",
  "checks": [
    {
      "name": "runtime-handoff",
      "domain": "runtime",
      "exit_code": 1,
      "verdict": "fail",
      "stdout_log": "/tmp/runtime.stdout.log",
      "stderr_log": "/tmp/runtime.stderr.log"
    }
  ],
  "required_checks": [
    "runtime-handoff"
  ],
  "overall_status": "complete",
  "check_count": 1,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 1,
    "domains": ["runtime"],
    "deterministic_rule": "demo"
  },
  "verdict": "fail",
  "shell_exit_code": 1
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun28.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun28",
  "started_at_utc": "2026-03-19T00:00:45+00:00",
  "generated_at_utc": "2026-03-19T00:10:45+00:00",
  "finished_at_utc": "2026-03-19T00:10:45+00:00",
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
  "required_checks": [
    "contract-conformance",
    "loop-guardrails"
  ],
  "overall_status": "interrupted",
  "check_count": 1,
  "missing_required_checks": [
    "loop-guardrails"
  ],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "demo"
  },
  "verdict": "fail",
  "shell_exit_code": 1
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun29.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun29",
  "started_at_utc": "2026-03-19T00:00:50+00:00",
  "generated_at_utc": "2026-03-19T00:10:50+00:00",
  "finished_at_utc": "2026-03-19T00:10:50+00:00",
  "checks": [
    {
      "name": "provider-profile",
      "domain": "infra",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/provider.stdout.log",
      "stderr_log": "/tmp/provider.stderr.log"
    }
  ],
  "required_checks": [
    "provider-profile"
  ],
  "overall_status": "complete",
  "check_count": 1,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "demo"
  },
  "verdict": "pass",
  "shell_exit_code": 0
}
JSON

cat >"$CI_DIR/federated-ci-summary.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun26",
  "started_at_utc": "2026-03-19T00:00:00+00:00",
  "generated_at_utc": "2026-03-19T00:11:00+00:00",
  "finished_at_utc": "2026-03-19T00:11:00+00:00",
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
  "required_checks": [
    "contract-conformance"
  ],
  "overall_status": "complete",
  "check_count": 1,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "demo"
  },
  "verdict": "pass",
  "shell_exit_code": 0
}
JSON

cat >"$CI_DIR/federated-ci-local-20260301.json" <<'JSON'
{
  "run_id": "federated-ci-local-20260301",
  "started_at_utc": "2026-03-01T00:00:00+00:00",
  "generated_at_utc": "2026-03-01T00:05:00+00:00",
  "finished_at_utc": "2026-03-01T00:05:00+00:00",
  "checks": [],
  "required_checks": [],
  "overall_status": "complete",
  "check_count": 0,
  "missing_required_checks": [],
  "failure_classification": {
    "count": 0,
    "domains": [],
    "deterministic_rule": "demo"
  },
  "verdict": "pass",
  "shell_exit_code": 0
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun26.tmp.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun26",
  "checks": [],
  "required_checks": []
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun26.checkpoint.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun26",
  "started_at_utc": "2026-03-19T00:00:00+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log"
    },
    {
      "name": "loop-guardrails",
      "domain": "policy",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/policy.stdout.log",
      "stderr_log": "/tmp/policy.stderr.log"
    }
  ],
  "required_checks": [
    "contract-conformance",
    "loop-guardrails"
  ]
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun27.checkpoint.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun27",
  "started_at_utc": "2026-03-19T00:00:30+00:00",
  "checks": [
    {
      "name": "runtime-handoff",
      "domain": "runtime",
      "exit_code": 1,
      "verdict": "fail",
      "stdout_log": "/tmp/runtime.stdout.log",
      "stderr_log": "/tmp/runtime.stderr.log"
    }
  ],
  "required_checks": [
    "runtime-handoff"
  ]
}
JSON

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun28.checkpoint.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun28",
  "started_at_utc": "2026-03-19T00:00:45+00:00",
  "checks": [
    {
      "name": "contract-conformance",
      "domain": "contract",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/contract.stdout.log",
      "stderr_log": "/tmp/contract.stderr.log"
    },
    {
      "name": "loop-guardrails",
      "domain": "policy",
      "exit_code": 0,
      "verdict": "pass",
      "stdout_log": "/tmp/loop.stdout.log",
      "stderr_log": "/tmp/loop.stderr.log"
    }
  ],
  "required_checks": [
    "contract-conformance",
    "loop-guardrails"
  ]
}
JSON

python3 - <<'PY' "$CI_DIR/._federated-ci-runtime-gates-20260319-rerun26.json"
from pathlib import Path
import sys

Path(sys.argv[1]).write_bytes(b"\x00\xffappledouble")
PY

touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun26-summary-validation.json"
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun26-summary-readiness.json" <<'JSON'
{
  "summary_run_id": "federated-ci-runtime-gates-20260319-rerun26",
  "readiness_status": "ready",
  "ready": true,
  "blocking_reasons": []
}
JSON
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun26-summary-readiness-validation.json"
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun26-summary-tmp-reconcile.json"
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun26-summary-tmp-reconcile-validation.json"
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun27-summary-validation.json"
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun27-summary-readiness.json" <<'JSON'
{
  "summary_run_id": "federated-ci-runtime-gates-20260319-rerun27",
  "readiness_status": "blocked",
  "ready": false,
  "blocking_reasons": ["summary_verdict_fail"]
}
JSON
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun27-summary-readiness-validation.json"
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun28-summary-tmp-reconcile.json" <<JSON
{
  "generated_at_utc": "2026-03-19T00:11:45+00:00",
  "summary_path": "${CI_DIR}/federated-ci-runtime-gates-20260319-rerun28.json",
  "checkpoint_path": "${CI_DIR}/federated-ci-runtime-gates-20260319-rerun28.checkpoint.json",
  "output_path": "${VALIDATION_DIR}/federated-ci-runtime-gates-20260319-rerun28-summary-tmp-reconcile.json",
  "run_id": "federated-ci-runtime-gates-20260319-rerun28",
  "check_name": null,
  "checkpoint_check_count": 2,
  "summary_check_count": 1,
  "restored": true,
  "status": "restored",
  "reasons": ["summary_check_count_regressed"],
  "reconcile_count": 1,
  "restored_check_names": ["loop-guardrails"]
}
JSON
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun28-summary-tmp-reconcile-validation.json" <<JSON
{
  "reconcile_report_path": "${VALIDATION_DIR}/federated-ci-runtime-gates-20260319-rerun28-summary-tmp-reconcile.json",
  "reconcile_generated_at_utc": "2026-03-19T00:11:45+00:00",
  "reconcile_run_id": "federated-ci-runtime-gates-20260319-rerun28",
  "reconcile_status": "restored",
  "reconcile_restored": true,
  "reconcile_count": 1,
  "verdict": "pass"
}
JSON
touch "$VALIDATION_DIR/federated-ci-summary-validation.json"
touch "$CONFORMANCE_DIR/federated-ci-runtime-gates-20260319-rerun26-contract.json"

RUNS_OUTPUT="$TMP_DIR/runs.json"
CHECKS_OUTPUT="$TMP_DIR/checks.json"
CHECKS_AUTO_OUTPUT="$TMP_DIR/checks-auto.json"
FAILED_OUTPUT="$TMP_DIR/failed.json"
LATEST_OUTPUT="$TMP_DIR/latest.json"
RUNS_RECONCILE_OUTPUT="$TMP_DIR/runs-reconcile.json"
RECONCILE_HEALTHY_OUTPUT="$TMP_DIR/reconcile-healthy.json"
RECONCILE_RESTORED_OUTPUT="$TMP_DIR/reconcile-restored.json"
RECONCILE_SCAN_OUTPUT="$TMP_DIR/reconcile-scan.json"
RECONCILE_SCAN_FRESH_OUTPUT="$TMP_DIR/reconcile-scan-fresh.json"
RUNS_UNKNOWN_OUTPUT="$TMP_DIR/runs-unknown.json"
RESTORED_SUMMARY_PATH="$TMP_DIR/federated-ci-runtime-gates-20260319-rerun27.tmp-query.json"
RESTORED_CHECKPOINT_PATH="$TMP_DIR/federated-ci-runtime-gates-20260319-rerun27.checkpoint.json"
RESTORED_PREVIOUS_PATH="$TMP_DIR/federated-ci-runtime-gates-20260319-rerun27-summary-tmp-reconcile.json"

python3 "$QUERY_PATH" runs \
  --family federated-ci-runtime-gates \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RUNS_OUTPUT"

python3 - <<'PY' "$RUNS_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 5, records
assert records[0]["source_kind"] == "latest", records
assert records[1]["run_id"] == "federated-ci-runtime-gates-20260319-rerun29", records
assert records[2]["run_id"] == "federated-ci-runtime-gates-20260319-rerun28", records
assert records[3]["run_id"] == "federated-ci-runtime-gates-20260319-rerun27", records
assert records[4]["source_kind"] == "stamped", records

latest = records[0]
unknown = records[1]
restored = records[2]
failed = records[3]
stamped = records[4]

assert latest["has_summary_validation"] is True, latest
assert latest["has_readiness"] is False, latest
assert latest["readiness_status"] == "missing", latest
assert latest["has_conformance_contract"] is True, latest
assert latest["reconcile_status"] == "restored", latest
assert latest["reconcile_artifact_state"] == "missing", latest
assert latest["reconcile_validation_state"] == "missing", latest
assert latest["checkpoint_state"] == "present", latest

assert unknown["run_id"] == "federated-ci-runtime-gates-20260319-rerun29", unknown
assert unknown["reconcile_status"] == "unknown", unknown
assert unknown["reconcile_artifact_state"] == "missing", unknown
assert unknown["reconcile_validation_state"] == "missing", unknown
assert unknown["checkpoint_state"] == "missing", unknown

assert restored["run_id"] == "federated-ci-runtime-gates-20260319-rerun28", restored
assert restored["check_count"] == 1, restored
assert restored["missing_required_checks"] == ["loop-guardrails"], restored
assert restored["reconcile_status"] == "restored", restored
assert restored["reconcile_artifact_state"] == "fresh", restored
assert restored["reconcile_validation_verdict"] == "pass", restored
assert restored["reconcile_validation_state"] == "fresh", restored
assert restored["checkpoint_state"] == "present", restored

assert failed["verdict"] == "fail", failed
assert failed["source_kind"] == "stamped", failed
assert failed["readiness_status"] == "blocked", failed
assert failed["ready"] is False, failed
assert failed["failed_checks"] == ["runtime-handoff"], failed
assert failed["failure_domains"] == ["runtime"], failed
assert failed["reconcile_status"] == "healthy", failed
assert failed["reconcile_artifact_state"] == "missing", failed
assert failed["checkpoint_state"] == "present", failed

assert stamped["run_id"] == "federated-ci-runtime-gates-20260319-rerun26", stamped
assert stamped["family"] == "federated-ci-runtime-gates", stamped
assert stamped["has_summary_validation"] is True, stamped
assert stamped["has_readiness"] is True, stamped
assert stamped["readiness_status"] == "ready", stamped
assert stamped["ready"] is True, stamped
assert stamped["has_readiness_validation"] is True, stamped
assert stamped["has_reconcile_report"] is True, stamped
assert stamped["has_reconcile_validation"] is True, stamped
assert stamped["has_conformance_contract"] is True, stamped
assert stamped["reconcile_status"] == "healthy", stamped
assert stamped["reconcile_artifact_state"] == "stale", stamped
assert stamped["reconcile_validation_verdict"] == "unknown", stamped
assert stamped["reconcile_validation_state"] == "stale", stamped
assert stamped["checkpoint_state"] == "present", stamped
PY

python3 "$QUERY_PATH" runs \
  --family federated-ci-runtime-gates \
  --source-kind stamped \
  --readiness-status blocked \
  --failed-check runtime-handoff \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$FAILED_OUTPUT"

python3 - <<'PY' "$FAILED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["run_id"] == "federated-ci-runtime-gates-20260319-rerun27", records
assert records[0]["readiness_status"] == "blocked", records
assert records[0]["failed_checks"] == ["runtime-handoff"], records
PY

python3 "$QUERY_PATH" runs \
  --family federated-ci-runtime-gates \
  --source-kind latest \
  --readiness-status missing \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$LATEST_OUTPUT"

python3 - <<'PY' "$LATEST_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["source_kind"] == "latest", records
assert records[0]["readiness_status"] == "missing", records
assert records[0]["reconcile_status"] == "restored", records
PY

python3 "$QUERY_PATH" runs \
  --family federated-ci-runtime-gates \
  --reconcile-status restored \
  --reconcile-artifact-state fresh \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RUNS_RECONCILE_OUTPUT"

python3 - <<'PY' "$RUNS_RECONCILE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["run_id"] == "federated-ci-runtime-gates-20260319-rerun28", records
assert records[0]["reconcile_status"] == "restored", records
assert records[0]["reconcile_artifact_state"] == "fresh", records
assert records[0]["reconcile_validation_state"] == "fresh", records
PY

python3 "$QUERY_PATH" runs \
  --family federated-ci-runtime-gates \
  --reconcile-status unknown \
  --checkpoint-state missing \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RUNS_UNKNOWN_OUTPUT"

python3 - <<'PY' "$RUNS_UNKNOWN_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["run_id"] == "federated-ci-runtime-gates-20260319-rerun29", records
assert records[0]["reconcile_status"] == "unknown", records
assert records[0]["checkpoint_state"] == "missing", records
PY

python3 "$QUERY_PATH" reconcile-status \
  --run-id federated-ci-runtime-gates-20260319-rerun26 \
  --source-kind stamped \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RECONCILE_HEALTHY_OUTPUT"

python3 - <<'PY' "$RECONCILE_HEALTHY_OUTPUT" "$CI_DIR/federated-ci-runtime-gates-20260319-rerun26.checkpoint.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["source_kind"] == "stamped", record
assert record["status"] == "healthy", record
assert record["restored"] is False, record
assert record["reconcile_count"] == 0, record
assert record["reasons"] == [], record
assert record["restored_check_names"] == [], record
assert record["reconcile_artifact_state"] == "stale", record
assert record["reconcile_validation_state"] == "stale", record
assert record["checkpoint_state"] == "present", record
assert record["checkpoint_path"] == str(Path(sys.argv[2]).resolve()), record
assert record["summary_check_count"] == 2, record
assert record["checkpoint_check_count"] == 2, record
PY

cat >"$RESTORED_SUMMARY_PATH" <<'JSON'
{
  "checks": []
}
JSON

cat >"$RESTORED_CHECKPOINT_PATH" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun27",
  "started_at_utc": "2026-03-19T00:00:30+00:00",
  "checks": [
    {
      "name": "runtime-handoff",
      "domain": "runtime",
      "exit_code": 1,
      "verdict": "fail",
      "stdout_log": "/tmp/runtime.stdout.log",
      "stderr_log": "/tmp/runtime.stderr.log"
    }
  ],
  "required_checks": [
    "runtime-handoff"
  ]
}
JSON

cat >"$RESTORED_PREVIOUS_PATH" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun27",
  "restored_check_names": [
    "contract-conformance"
  ]
}
JSON

python3 "$QUERY_PATH" reconcile-status \
  --summary "$RESTORED_SUMMARY_PATH" \
  --checkpoint "$RESTORED_CHECKPOINT_PATH" \
  --previous-report "$RESTORED_PREVIOUS_PATH" \
  --check-name runtime-handoff \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RECONCILE_RESTORED_OUTPUT"

python3 - <<'PY' "$RECONCILE_RESTORED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["run_id"] == "federated-ci-runtime-gates-20260319-rerun27", record
assert record["status"] == "restored", record
assert record["restored"] is True, record
assert "summary_missing_run_id" in record["reasons"], record
assert "summary_missing_started_at_utc" in record["reasons"], record
assert "summary_missing_required_checks" in record["reasons"], record
assert record["check_name"] == "runtime-handoff", record
assert record["reconcile_count"] == 2, record
assert record["restored_check_names"] == ["contract-conformance", "runtime-handoff"], record
assert record["reconcile_artifact_state"] == "stale", record
assert record["reconcile_validation_state"] == "missing", record
assert record["summary_check_count"] == 0, record
assert record["checkpoint_check_count"] == 1, record
PY

python3 "$QUERY_PATH" reconcile-status \
  --family federated-ci-runtime-gates \
  --source-kind stamped \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RECONCILE_SCAN_OUTPUT"

python3 - <<'PY' "$RECONCILE_SCAN_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["run_id"] for record in records] == [
    "federated-ci-runtime-gates-20260319-rerun29",
    "federated-ci-runtime-gates-20260319-rerun28",
    "federated-ci-runtime-gates-20260319-rerun27",
    "federated-ci-runtime-gates-20260319-rerun26",
], records
unknown, restored, missing, stale = records
assert unknown["status"] == "unknown", unknown
assert unknown["checkpoint_state"] == "missing", unknown
assert unknown["reconcile_artifact_state"] == "missing", unknown
assert restored["status"] == "restored", restored
assert restored["reconcile_artifact_state"] == "fresh", restored
assert restored["reconcile_validation_state"] == "fresh", restored
assert restored["checkpoint_state"] == "present", restored
assert restored["restored_check_names"] == ["loop-guardrails"], restored
assert missing["status"] == "healthy", missing
assert missing["reconcile_artifact_state"] == "missing", missing
assert missing["reconcile_validation_state"] == "missing", missing
assert stale["status"] == "healthy", stale
assert stale["reconcile_artifact_state"] == "stale", stale
assert stale["reconcile_validation_state"] == "stale", stale
PY

python3 "$QUERY_PATH" reconcile-status \
  --family federated-ci-runtime-gates \
  --source-kind stamped \
  --status restored \
  --artifact-state fresh \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RECONCILE_SCAN_FRESH_OUTPUT"

python3 - <<'PY' "$RECONCILE_SCAN_FRESH_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["run_id"] == "federated-ci-runtime-gates-20260319-rerun28", records
assert records[0]["status"] == "restored", records
assert records[0]["reconcile_artifact_state"] == "fresh", records
PY

python3 "$QUERY_PATH" checks \
  --run-id federated-ci-runtime-gates-20260319-rerun26 \
  --source-kind stamped \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$CHECKS_OUTPUT"

python3 - <<'PY' "$CHECKS_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
checks = doc["checks"]

assert record["source_kind"] == "stamped", record
assert len(checks) == 2, checks
assert checks[0]["name"] == "contract-conformance", checks
assert checks[1]["name"] == "loop-guardrails", checks
PY

python3 "$QUERY_PATH" checks \
  --run-id federated-ci-runtime-gates-20260319-rerun26 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$CHECKS_AUTO_OUTPUT"

python3 - <<'PY' "$CHECKS_AUTO_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert doc["record"]["source_kind"] == "stamped", doc
PY

echo "query federated ci artifacts ok"
