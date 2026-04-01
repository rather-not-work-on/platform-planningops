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

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun30.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun30",
  "started_at_utc": "2026-03-19T00:00:55+00:00",
  "generated_at_utc": "2026-03-19T00:10:55+00:00",
  "finished_at_utc": "2026-03-19T00:10:55+00:00",
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

cat >"$CI_DIR/federated-ci-runtime-gates-20260319-rerun30.checkpoint.json" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-20260319-rerun30",
  "started_at_utc": "2026-03-19T00:00:55+00:00",
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
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun30-summary-validation.json"
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun30-summary-readiness.json" <<'JSON'
{
  "summary_run_id": "federated-ci-runtime-gates-20260319-rerun30",
  "readiness_status": "ready",
  "ready": true,
  "blocking_reasons": []
}
JSON
touch "$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun30-summary-readiness-validation.json"
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
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun30-summary-tmp-reconcile.json" <<JSON
{
  "generated_at_utc": "2026-03-19T00:11:55+00:00",
  "summary_path": "${CI_DIR}/federated-ci-runtime-gates-20260319-rerun30.json",
  "checkpoint_path": "${CI_DIR}/federated-ci-runtime-gates-20260319-rerun30.checkpoint.json",
  "output_path": "${VALIDATION_DIR}/federated-ci-runtime-gates-20260319-rerun30-summary-tmp-reconcile.json",
  "run_id": "federated-ci-runtime-gates-20260319-rerun30",
  "check_name": null,
  "checkpoint_check_count": 1,
  "summary_check_count": 1,
  "restored": false,
  "status": "healthy",
  "reasons": [],
  "reconcile_count": 0,
  "restored_check_names": []
}
JSON
cat >"$VALIDATION_DIR/federated-ci-runtime-gates-20260319-rerun30-summary-tmp-reconcile-validation.json" <<JSON
{
  "reconcile_report_path": "${VALIDATION_DIR}/federated-ci-runtime-gates-20260319-rerun30-summary-tmp-reconcile.json",
  "reconcile_generated_at_utc": "2026-03-19T00:11:55+00:00",
  "reconcile_run_id": "federated-ci-runtime-gates-20260319-rerun30",
  "reconcile_status": "healthy",
  "reconcile_restored": false,
  "reconcile_count": 0,
  "verdict": "pass"
}
JSON
touch "$VALIDATION_DIR/federated-ci-summary-validation.json"
touch "$CONFORMANCE_DIR/federated-ci-runtime-gates-20260319-rerun26-contract.json"

RUNS_OUTPUT="$TMP_DIR/runs.json"
RUNS_HEALTHY_OUTPUT="$TMP_DIR/runs-healthy.json"
CHECKS_OUTPUT="$TMP_DIR/checks.json"
CHECKS_AUTO_OUTPUT="$TMP_DIR/checks-auto.json"
FAILED_OUTPUT="$TMP_DIR/failed.json"
LATEST_OUTPUT="$TMP_DIR/latest.json"
RUNS_RECONCILE_OUTPUT="$TMP_DIR/runs-reconcile.json"
HEALTH_SCAN_OUTPUT="$TMP_DIR/health-scan.json"
HEALTH_SCAN_DEGRADED_OUTPUT="$TMP_DIR/health-scan-degraded.json"
HEALTH_SUMMARY_OUTPUT="$TMP_DIR/health-summary.json"
HEALTH_SUMMARY_BLOCKED_OUTPUT="$TMP_DIR/health-summary-blocked.json"
HEALTH_SUMMARY_RUNTIME_OUTPUT="$TMP_DIR/health-summary-runtime.json"
HEALTH_SUMMARY_MISSING_OUTPUT="$TMP_DIR/health-summary-missing.json"
HEALTH_SUMMARY_STALE_OUTPUT="$TMP_DIR/health-summary-stale.json"
HEALTH_SUMMARY_GAP_OUTPUT="$TMP_DIR/health-summary-gap.json"
HEALTH_SUMMARY_LATEST_RUNTIME_OUTPUT="$TMP_DIR/health-summary-latest-runtime.json"
OPERATOR_TRIAGE_OUTPUT="$TMP_DIR/operator-triage.json"
OPERATOR_TRIAGE_LAGGING_OUTPUT="$TMP_DIR/operator-triage-lagging.json"
OPERATOR_TRIAGE_ACTIVE_OUTPUT="$TMP_DIR/operator-triage-active.json"
TRIAGE_SUMMARY_OUTPUT="$TMP_DIR/triage-summary.json"
TRIAGE_SUMMARY_ACTIVE_OUTPUT="$TMP_DIR/triage-summary-active.json"
TRIAGE_SUMMARY_ALL_OUTPUT="$TMP_DIR/triage-summary-all.json"
TRIAGE_OVERVIEW_OUTPUT="$TMP_DIR/triage-overview.json"
TRIAGE_OVERVIEW_ALL_OUTPUT="$TMP_DIR/triage-overview-all.json"
TRIAGE_TARGETS_OUTPUT="$TMP_DIR/triage-targets.json"
TRIAGE_TARGETS_LAGGING_OUTPUT="$TMP_DIR/triage-targets-lagging.json"
TRIAGE_TARGETS_ALL_OUTPUT="$TMP_DIR/triage-targets-all.json"
TRIAGE_QUEUE_OUTPUT="$TMP_DIR/triage-queue.json"
TRIAGE_QUEUE_LAGGING_OUTPUT="$TMP_DIR/triage-queue-lagging.json"
TRIAGE_QUEUE_ALL_OUTPUT="$TMP_DIR/triage-queue-all.json"
TRIAGE_FEED_OUTPUT="$TMP_DIR/triage-feed.json"
TRIAGE_FEED_ALL_OUTPUT="$TMP_DIR/triage-feed-all.json"
TRIAGE_BRIEF_OUTPUT="$TMP_DIR/triage-brief.json"
TRIAGE_BRIEF_ALL_OUTPUT="$TMP_DIR/triage-brief-all.json"
TRIAGE_REPORT_OUTPUT="$TMP_DIR/triage-report.json"
TRIAGE_REPORT_ALL_OUTPUT="$TMP_DIR/triage-report-all.json"
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
assert len(records) == 6, records
assert records[0]["source_kind"] == "latest", records
assert records[1]["run_id"] == "federated-ci-runtime-gates-20260319-rerun30", records
assert records[2]["run_id"] == "federated-ci-runtime-gates-20260319-rerun29", records
assert records[3]["run_id"] == "federated-ci-runtime-gates-20260319-rerun28", records
assert records[4]["run_id"] == "federated-ci-runtime-gates-20260319-rerun27", records
assert records[5]["source_kind"] == "stamped", records

latest = records[0]
healthy = records[1]
unknown = records[2]
restored = records[3]
failed = records[4]
stamped = records[5]

assert latest["has_summary_validation"] is True, latest
assert latest["has_readiness"] is False, latest
assert latest["readiness_status"] == "missing", latest
assert latest["has_conformance_contract"] is True, latest
assert latest["health_status"] == "degraded", latest
assert latest["health_reasons"] == [
    "readiness_missing",
    "reconcile_restored",
    "reconcile_artifact_missing",
    "reconcile_validation_missing",
], latest
assert latest["reconcile_status"] == "restored", latest
assert latest["reconcile_artifact_state"] == "missing", latest
assert latest["reconcile_validation_state"] == "missing", latest
assert latest["checkpoint_state"] == "present", latest

assert healthy["run_id"] == "federated-ci-runtime-gates-20260319-rerun30", healthy
assert healthy["health_status"] == "healthy", healthy
assert healthy["health_reasons"] == [], healthy
assert healthy["readiness_status"] == "ready", healthy
assert healthy["reconcile_status"] == "healthy", healthy
assert healthy["reconcile_artifact_state"] == "fresh", healthy
assert healthy["reconcile_validation_state"] == "fresh", healthy
assert healthy["checkpoint_state"] == "present", healthy

assert unknown["run_id"] == "federated-ci-runtime-gates-20260319-rerun29", unknown
assert unknown["health_status"] == "unknown", unknown
assert unknown["health_reasons"] == ["checkpoint_missing", "reconcile_unknown"], unknown
assert unknown["reconcile_status"] == "unknown", unknown
assert unknown["reconcile_artifact_state"] == "missing", unknown
assert unknown["reconcile_validation_state"] == "missing", unknown
assert unknown["checkpoint_state"] == "missing", unknown

assert restored["run_id"] == "federated-ci-runtime-gates-20260319-rerun28", restored
assert restored["health_status"] == "blocked", restored
assert restored["health_reasons"] == [
    "summary_verdict_fail",
    "summary_status_interrupted",
    "missing_required_checks",
], restored
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
assert failed["health_status"] == "blocked", failed
assert failed["health_reasons"] == ["summary_verdict_fail", "failed_checks_present", "readiness_blocked"], failed
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
assert stamped["health_status"] == "degraded", stamped
assert stamped["health_reasons"] == ["reconcile_artifact_stale", "reconcile_validation_stale"], stamped
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
assert records[0]["health_status"] == "degraded", records
assert records[0]["reconcile_status"] == "restored", records
PY

python3 "$QUERY_PATH" runs \
  --family federated-ci-runtime-gates \
  --health-status healthy \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$RUNS_HEALTHY_OUTPUT"

python3 - <<'PY' "$RUNS_HEALTHY_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["run_id"] == "federated-ci-runtime-gates-20260319-rerun30", records
assert records[0]["health_status"] == "healthy", records
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

python3 "$QUERY_PATH" health-scan \
  --family federated-ci-runtime-gates \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SCAN_OUTPUT"

python3 - <<'PY' "$HEALTH_SCAN_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["run_id"] for record in records] == [
    "federated-ci-runtime-gates-20260319-rerun26",
    "federated-ci-runtime-gates-20260319-rerun30",
    "federated-ci-runtime-gates-20260319-rerun29",
    "federated-ci-runtime-gates-20260319-rerun28",
    "federated-ci-runtime-gates-20260319-rerun27",
    "federated-ci-runtime-gates-20260319-rerun26",
], records
assert [record["health_status"] for record in records] == [
    "degraded",
    "healthy",
    "unknown",
    "blocked",
    "blocked",
    "degraded",
], records
PY

python3 "$QUERY_PATH" health-scan \
  --family federated-ci-runtime-gates \
  --source-kind stamped \
  --health-status degraded \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SCAN_DEGRADED_OUTPUT"

python3 - <<'PY' "$HEALTH_SCAN_DEGRADED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["run_id"] == "federated-ci-runtime-gates-20260319-rerun26", records
assert records[0]["health_status"] == "degraded", records
PY

python3 "$QUERY_PATH" health-summary \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["family"] for record in records] == [
    "federated-ci-runtime-gates",
    "federated-ci-local",
], records

runtime, local = records
assert runtime["run_count"] == 5, runtime
assert runtime["latest_gap_status"] == "clear", runtime
assert runtime["latest_gap_count"] == 0, runtime
assert runtime["latest_gap_reasons"] == [], runtime
assert runtime["healthy_count"] == 1, runtime
assert runtime["degraded_count"] == 1, runtime
assert runtime["blocked_count"] == 2, runtime
assert runtime["unknown_count"] == 1, runtime
assert runtime["latest_run_id"] == "federated-ci-runtime-gates-20260319-rerun30", runtime
assert runtime["latest_run_health_status"] == "healthy", runtime
assert runtime["latest_alert_run_id"] == "federated-ci-runtime-gates-20260319-rerun29", runtime
assert runtime["latest_alert_health_status"] == "unknown", runtime
assert runtime["latest_alert_failed_checks"] == [], runtime
assert runtime["latest_alert_reasons"] == ["checkpoint_missing", "reconcile_unknown"], runtime
assert runtime["failure_domain_counts"] == {"runtime": 1}, runtime
assert runtime["latest_failure_run_id"] == "federated-ci-runtime-gates-20260319-rerun27", runtime
assert runtime["latest_failure_source_kind"] == "stamped", runtime
assert runtime["latest_failure_health_status"] == "blocked", runtime
assert runtime["latest_failure_domains"] == ["runtime"], runtime
assert runtime["readiness_status_counts"] == {"blocked": 1, "missing": 2, "ready": 2}, runtime
assert runtime["reconcile_artifact_state_counts"] == {"fresh": 2, "missing": 2, "stale": 1}, runtime
assert runtime["reconcile_validation_state_counts"] == {"fresh": 2, "missing": 2, "stale": 1}, runtime

assert local["run_count"] == 1, local
assert local["latest_gap_status"] == "attention", local
assert local["latest_gap_count"] == 5, local
assert local["latest_gap_reasons"] == [
    "readiness_missing",
    "reconcile_unknown",
    "reconcile_artifact_missing",
    "reconcile_validation_missing",
    "checkpoint_missing",
], local
assert local["healthy_count"] == 0, local
assert local["degraded_count"] == 0, local
assert local["blocked_count"] == 0, local
assert local["unknown_count"] == 1, local
assert local["latest_run_id"] == "federated-ci-local-20260301", local
assert local["latest_run_health_status"] == "unknown", local
assert local["latest_alert_run_id"] == "federated-ci-local-20260301", local
assert local["latest_alert_health_status"] == "unknown", local
assert local["failure_domain_counts"] == {}, local
assert local["latest_failure_run_id"] is None, local
assert local["latest_failure_domains"] == [], local
assert local["readiness_status_counts"] == {"missing": 1}, local
assert local["reconcile_artifact_state_counts"] == {"missing": 1}, local
assert local["reconcile_validation_state_counts"] == {"missing": 1}, local
PY

python3 "$QUERY_PATH" health-summary \
  --has-health-status blocked \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_BLOCKED_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_BLOCKED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["family"] == "federated-ci-runtime-gates", records
assert records[0]["blocked_count"] == 2, records
PY

python3 "$QUERY_PATH" health-summary \
  --has-failure-domain runtime \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_RUNTIME_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_RUNTIME_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["family"] == "federated-ci-runtime-gates", records
assert records[0]["failure_domain_counts"] == {"runtime": 1}, records
assert records[0]["latest_failure_run_id"] == "federated-ci-runtime-gates-20260319-rerun27", records
PY

python3 "$QUERY_PATH" health-summary \
  --has-readiness-status missing \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_MISSING_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_MISSING_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["family"] for record in records] == [
    "federated-ci-runtime-gates",
    "federated-ci-local",
], records
PY

python3 "$QUERY_PATH" health-summary \
  --has-reconcile-artifact-state stale \
  --has-reconcile-validation-state stale \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_STALE_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_STALE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["family"] == "federated-ci-runtime-gates", records
assert records[0]["reconcile_artifact_state_counts"] == {"fresh": 2, "missing": 2, "stale": 1}, records
assert records[0]["reconcile_validation_state_counts"] == {"fresh": 2, "missing": 2, "stale": 1}, records
PY

python3 "$QUERY_PATH" health-summary \
  --latest-gap-status attention \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_GAP_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_GAP_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["family"] == "federated-ci-local", records
assert records[0]["latest_gap_status"] == "attention", records
assert records[0]["latest_gap_reasons"] == [
    "readiness_missing",
    "reconcile_unknown",
    "reconcile_artifact_missing",
    "reconcile_validation_missing",
    "checkpoint_missing",
], records
PY

python3 "$QUERY_PATH" health-summary \
  --family federated-ci-runtime-gates \
  --source-kind all \
  --has-latest-gap reconcile_artifact_missing \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$HEALTH_SUMMARY_LATEST_RUNTIME_OUTPUT"

python3 - <<'PY' "$HEALTH_SUMMARY_LATEST_RUNTIME_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["family"] == "federated-ci-runtime-gates", record
assert record["run_count"] == 6, record
assert record["latest_run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["latest_run_source_kind"] == "latest", record
assert record["latest_gap_status"] == "attention", record
assert record["latest_gap_count"] == 4, record
assert record["latest_gap_reasons"] == [
    "readiness_missing",
    "reconcile_restored",
    "reconcile_artifact_missing",
    "reconcile_validation_missing",
], record
PY

python3 "$QUERY_PATH" operator-triage \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$OPERATOR_TRIAGE_OUTPUT"

python3 - <<'PY' "$OPERATOR_TRIAGE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["family"] for record in records] == [
    "federated-ci-runtime-gates",
    "federated-ci-local",
], records

runtime, local = records
assert runtime["triage_status"] == "lagging", runtime
assert runtime["alert_alignment"] == "lagging", runtime
assert runtime["latest_gap_status"] == "clear", runtime
assert runtime["latest_gap_domains"] == [], runtime
assert runtime["latest_alert_run_id"] == "federated-ci-runtime-gates-20260319-rerun29", runtime
assert runtime["latest_alert_domains"] == ["checkpoint", "readiness", "reconcile"], runtime
assert runtime["latest_failure_run_id"] == "federated-ci-runtime-gates-20260319-rerun27", runtime
assert runtime["latest_failure_domains"] == ["runtime"], runtime

assert local["triage_status"] == "active", local
assert local["alert_alignment"] == "current", local
assert local["latest_gap_status"] == "attention", local
assert local["latest_gap_domains"] == ["checkpoint", "readiness", "reconcile"], local
assert local["latest_alert_run_id"] == "federated-ci-local-20260301", local
assert local["latest_alert_domains"] == ["checkpoint", "readiness", "reconcile"], local
PY

python3 "$QUERY_PATH" operator-triage \
  --triage-status lagging \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$OPERATOR_TRIAGE_LAGGING_OUTPUT"

python3 - <<'PY' "$OPERATOR_TRIAGE_LAGGING_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["family"] == "federated-ci-runtime-gates", records
assert records[0]["alert_alignment"] == "lagging", records
assert records[0]["latest_gap_status"] == "clear", records
PY

python3 "$QUERY_PATH" operator-triage \
  --family federated-ci-runtime-gates \
  --source-kind all \
  --triage-status active \
  --has-latest-gap-domain reconcile \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$OPERATOR_TRIAGE_ACTIVE_OUTPUT"

python3 - <<'PY' "$OPERATOR_TRIAGE_ACTIVE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["family"] == "federated-ci-runtime-gates", record
assert record["triage_status"] == "active", record
assert record["alert_alignment"] == "current", record
assert record["latest_run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["latest_run_source_kind"] == "latest", record
assert record["latest_gap_domains"] == ["readiness", "reconcile"], record
assert record["latest_alert_domains"] == ["readiness", "reconcile"], record
PY

python3 "$QUERY_PATH" triage-summary \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_SUMMARY_OUTPUT"

python3 - <<'PY' "$TRIAGE_SUMMARY_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["triage_status"] for record in records] == [
    "lagging",
    "active",
], records

lagging, active = records
assert lagging["family_count"] == 1, lagging
assert lagging["families"] == ["federated-ci-runtime-gates"], lagging
assert lagging["newest_family"] == "federated-ci-runtime-gates", lagging
assert lagging["newest_run_id"] == "federated-ci-runtime-gates-20260319-rerun30", lagging
assert lagging["newest_run_source_kind"] == "stamped", lagging
assert lagging["alert_alignment_counts"] == {"lagging": 1}, lagging
assert lagging["latest_gap_domain_counts"] == {}, lagging
assert lagging["latest_alert_domain_counts"] == {"checkpoint": 1, "readiness": 1, "reconcile": 1}, lagging

assert active["family_count"] == 1, active
assert active["families"] == ["federated-ci-local"], active
assert active["newest_family"] == "federated-ci-local", active
assert active["newest_run_id"] == "federated-ci-local-20260301", active
assert active["newest_run_source_kind"] == "stamped", active
assert active["alert_alignment_counts"] == {"current": 1}, active
assert active["latest_gap_domain_counts"] == {"checkpoint": 1, "readiness": 1, "reconcile": 1}, active
assert active["latest_alert_domain_counts"] == {"checkpoint": 1, "readiness": 1, "reconcile": 1}, active
PY

python3 "$QUERY_PATH" triage-summary \
  --triage-status active \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_SUMMARY_ACTIVE_OUTPUT"

python3 - <<'PY' "$TRIAGE_SUMMARY_ACTIVE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
assert records[0]["triage_status"] == "active", records
assert records[0]["families"] == ["federated-ci-local"], records
PY

python3 "$QUERY_PATH" triage-summary \
  --source-kind all \
  --triage-status active \
  --has-latest-gap-domain reconcile \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_SUMMARY_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_SUMMARY_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["triage_status"] == "active", record
assert record["family_count"] == 2, record
assert record["families"] == ["federated-ci-runtime-gates", "federated-ci-local"], record
assert record["newest_family"] == "federated-ci-runtime-gates", record
assert record["newest_run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["newest_run_source_kind"] == "latest", record
assert record["alert_alignment_counts"] == {"current": 2}, record
assert record["latest_gap_domain_counts"] == {"checkpoint": 1, "readiness": 2, "reconcile": 2}, record
assert record["latest_alert_domain_counts"] == {"checkpoint": 1, "readiness": 2, "reconcile": 2}, record
PY

python3 "$QUERY_PATH" triage-overview \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_OVERVIEW_OUTPUT"

python3 - <<'PY' "$TRIAGE_OVERVIEW_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["total_families"] == 2, record
assert record["triage_status_counts"] == {"active": 1, "lagging": 1}, record
assert record["alert_alignment_counts"] == {"current": 1, "lagging": 1}, record
assert record["latest_gap_domain_counts"] == {"checkpoint": 1, "readiness": 1, "reconcile": 1}, record
assert record["latest_alert_domain_counts"] == {"checkpoint": 2, "readiness": 2, "reconcile": 2}, record
assert record["newest_failing_family"] == "federated-ci-runtime-gates", record
assert record["newest_failing_run_id"] == "federated-ci-runtime-gates-20260319-rerun30", record
assert record["newest_failing_source_kind"] == "stamped", record
assert record["newest_failing_triage_status"] == "lagging", record
assert record["newest_failing_gap_domains"] == [], record
assert record["newest_failing_alert_domains"] == ["checkpoint", "readiness", "reconcile"], record
assert record["newest_recovered_family"] is None, record
assert record["newest_recovered_run_id"] is None, record
assert record["newest_recovered_source_kind"] is None, record
PY

python3 "$QUERY_PATH" triage-overview \
  --source-kind all \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_OVERVIEW_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_OVERVIEW_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["total_families"] == 2, record
assert record["triage_status_counts"] == {"active": 2}, record
assert record["alert_alignment_counts"] == {"current": 2}, record
assert record["latest_gap_domain_counts"] == {"checkpoint": 1, "readiness": 2, "reconcile": 2}, record
assert record["latest_alert_domain_counts"] == {"checkpoint": 1, "readiness": 2, "reconcile": 2}, record
assert record["newest_failing_family"] == "federated-ci-runtime-gates", record
assert record["newest_failing_run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["newest_failing_source_kind"] == "latest", record
assert record["newest_failing_triage_status"] == "active", record
assert record["newest_failing_gap_domains"] == ["readiness", "reconcile"], record
assert record["newest_failing_alert_domains"] == ["readiness", "reconcile"], record
assert record["newest_recovered_family"] is None, record
assert record["newest_recovered_run_id"] is None, record
assert record["newest_recovered_source_kind"] is None, record
PY

python3 "$QUERY_PATH" triage-targets \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_TARGETS_OUTPUT"

python3 - <<'PY' "$TRIAGE_TARGETS_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["family"] for record in records] == [
    "federated-ci-local",
    "federated-ci-runtime-gates",
], records

local, runtime = records
assert local["priority_bucket"] == "active", local
assert local["target_kind"] == "latest-gap", local
assert local["triage_status"] == "active", local
assert local["target_run_id"] == "federated-ci-local-20260301", local
assert local["target_source_kind"] == "stamped", local
assert local["target_health_status"] == "unknown", local
assert local["target_domains"] == ["checkpoint", "readiness", "reconcile"], local
assert local["target_reasons"] == [
    "readiness_missing",
    "reconcile_unknown",
    "reconcile_artifact_missing",
    "reconcile_validation_missing",
    "checkpoint_missing",
], local

assert runtime["priority_bucket"] == "lagging", runtime
assert runtime["target_kind"] == "latest-alert-follow-up", runtime
assert runtime["triage_status"] == "lagging", runtime
assert runtime["target_run_id"] == "federated-ci-runtime-gates-20260319-rerun29", runtime
assert runtime["target_source_kind"] == "stamped", runtime
assert runtime["target_health_status"] == "unknown", runtime
assert runtime["target_domains"] == ["checkpoint", "readiness", "reconcile"], runtime
assert runtime["target_reasons"] == ["checkpoint_missing", "reconcile_unknown"], runtime
PY

python3 "$QUERY_PATH" triage-targets \
  --triage-status lagging \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_TARGETS_LAGGING_OUTPUT"

python3 - <<'PY' "$TRIAGE_TARGETS_LAGGING_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["family"] == "federated-ci-runtime-gates", record
assert record["priority_bucket"] == "lagging", record
assert record["target_kind"] == "latest-alert-follow-up", record
assert record["target_run_id"] == "federated-ci-runtime-gates-20260319-rerun29", record
assert record["target_domains"] == ["checkpoint", "readiness", "reconcile"], record
PY

python3 "$QUERY_PATH" triage-targets \
  --source-kind all \
  --has-target-domain checkpoint \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_TARGETS_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_TARGETS_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["family"] == "federated-ci-local", record
assert record["priority_bucket"] == "active", record
assert record["target_kind"] == "latest-gap", record
assert record["target_run_id"] == "federated-ci-local-20260301", record
assert record["target_domains"] == ["checkpoint", "readiness", "reconcile"], record
PY

python3 "$QUERY_PATH" triage-queue \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_QUEUE_OUTPUT"

python3 - <<'PY' "$TRIAGE_QUEUE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["priority_bucket"] for record in records] == ["active", "lagging"], records

active, lagging = records
assert active["target_count"] == 1, active
assert active["families"] == ["federated-ci-local"], active
assert active["newest_target_family"] == "federated-ci-local", active
assert active["newest_target_run_id"] == "federated-ci-local-20260301", active
assert active["newest_target_source_kind"] == "stamped", active
assert active["newest_target_kind"] == "latest-gap", active
assert active["target_kind_counts"] == {"latest-gap": 1}, active
assert active["target_domain_counts"] == {"checkpoint": 1, "readiness": 1, "reconcile": 1}, active

assert lagging["target_count"] == 1, lagging
assert lagging["families"] == ["federated-ci-runtime-gates"], lagging
assert lagging["newest_target_family"] == "federated-ci-runtime-gates", lagging
assert lagging["newest_target_run_id"] == "federated-ci-runtime-gates-20260319-rerun29", lagging
assert lagging["newest_target_source_kind"] == "stamped", lagging
assert lagging["newest_target_kind"] == "latest-alert-follow-up", lagging
assert lagging["target_kind_counts"] == {"latest-alert-follow-up": 1}, lagging
assert lagging["target_domain_counts"] == {"checkpoint": 1, "readiness": 1, "reconcile": 1}, lagging
PY

python3 "$QUERY_PATH" triage-queue \
  --priority-bucket lagging \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_QUEUE_LAGGING_OUTPUT"

python3 - <<'PY' "$TRIAGE_QUEUE_LAGGING_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["priority_bucket"] == "lagging", record
assert record["families"] == ["federated-ci-runtime-gates"], record
assert record["target_kind_counts"] == {"latest-alert-follow-up": 1}, record
PY

python3 "$QUERY_PATH" triage-queue \
  --source-kind all \
  --has-target-domain checkpoint \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_QUEUE_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_QUEUE_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["priority_bucket"] == "active", record
assert record["target_count"] == 2, record
assert record["families"] == ["federated-ci-runtime-gates", "federated-ci-local"], record
assert record["newest_target_family"] == "federated-ci-runtime-gates", record
assert record["newest_target_run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["newest_target_source_kind"] == "latest", record
assert record["newest_target_kind"] == "latest-gap", record
assert record["target_kind_counts"] == {"latest-gap": 2}, record
assert record["target_domain_counts"] == {"checkpoint": 1, "readiness": 2, "reconcile": 2}, record
PY

python3 "$QUERY_PATH" triage-feed \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_FEED_OUTPUT"

python3 - <<'PY' "$TRIAGE_FEED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "stamped", record
assert record["target_limit"] == 3, record
assert record["overview"]["triage_status_counts"] == {"active": 1, "lagging": 1}, record
assert [queue["priority_bucket"] for queue in record["queue_records"]] == ["active", "lagging"], record
assert [target["family"] for target in record["target_records"]] == [
    "federated-ci-local",
    "federated-ci-runtime-gates",
], record
assert record["target_records"][0]["priority_bucket"] == "active", record
assert record["target_records"][1]["priority_bucket"] == "lagging", record
PY

python3 "$QUERY_PATH" triage-feed \
  --source-kind all \
  --target-limit 1 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_FEED_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_FEED_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "all", record
assert record["target_limit"] == 1, record
assert record["overview"]["triage_status_counts"] == {"active": 2}, record
assert len(record["queue_records"]) == 1, record
queue = record["queue_records"][0]
assert queue["priority_bucket"] == "active", queue
assert queue["target_count"] == 2, queue
assert queue["newest_target_family"] == "federated-ci-runtime-gates", queue
assert len(record["target_records"]) == 1, record
target = record["target_records"][0]
assert target["family"] == "federated-ci-runtime-gates", target
assert target["priority_bucket"] == "active", target
assert target["target_source_kind"] == "latest", target
PY

python3 "$QUERY_PATH" triage-brief \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_BRIEF_OUTPUT"

python3 - <<'PY' "$TRIAGE_BRIEF_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "stamped", record
assert record["target_limit"] == 3, record
assert record["attention_family_count"] == 2, record
assert record["active_family_count"] == 1, record
assert record["lagging_family_count"] == 1, record
assert record["clear_family_count"] == 0, record
assert record["newest_failing_family"] == "federated-ci-runtime-gates", record
assert record["newest_failing_run_id"] == "federated-ci-runtime-gates-20260319-rerun30", record
assert record["newest_failing_triage_status"] == "lagging", record
assert record["queue_lines"] == [
    "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1",
    "lagging: targets=1 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint=1,readiness=1,reconcile=1",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "[lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile",
], record
PY

python3 "$QUERY_PATH" triage-brief \
  --source-kind all \
  --target-limit 1 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_BRIEF_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_BRIEF_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "all", record
assert record["target_limit"] == 1, record
assert record["attention_family_count"] == 2, record
assert record["active_family_count"] == 2, record
assert record["lagging_family_count"] == 0, record
assert record["clear_family_count"] == 0, record
assert record["newest_failing_family"] == "federated-ci-runtime-gates", record
assert record["newest_failing_run_id"] == "federated-ci-runtime-gates-20260319-rerun26", record
assert record["newest_failing_triage_status"] == "active", record
assert record["queue_lines"] == [
    "active: targets=2 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun26 domains=checkpoint=1,readiness=2,reconcile=2",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun26 domains=readiness,reconcile",
], record
PY

python3 "$QUERY_PATH" triage-report \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_REPORT_OUTPUT"

python3 - <<'PY' "$TRIAGE_REPORT_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "stamped", record
assert record["target_limit"] == 3, record
assert record["headline"] == "Federated CI triage report: 2 attention families", record
assert record["attention_summary"] == "active=1, lagging=1, clear=0", record
assert record["newest_failing_summary"] == "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun30 / lagging", record
assert record["newest_recovered_summary"] is None, record
assert record["queue_lines"] == [
    "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1",
    "lagging: targets=1 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint=1,readiness=1,reconcile=1",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "[lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile",
], record
assert "## Federated CI Triage Report" in record["markdown"], record
assert "### Queue" in record["markdown"], record
assert "### Top Targets" in record["markdown"], record
PY

python3 "$QUERY_PATH" triage-report \
  --source-kind all \
  --target-limit 1 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" >"$TRIAGE_REPORT_ALL_OUTPUT"

python3 - <<'PY' "$TRIAGE_REPORT_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "all", record
assert record["target_limit"] == 1, record
assert record["headline"] == "Federated CI triage report: 2 attention families", record
assert record["attention_summary"] == "active=2, lagging=0, clear=0", record
assert record["newest_failing_summary"] == "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun26 / active", record
assert record["newest_recovered_summary"] is None, record
assert record["queue_lines"] == [
    "active: targets=2 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun26 domains=checkpoint=1,readiness=2,reconcile=2",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun26 domains=readiness,reconcile",
], record
assert "source_kind: `all`" in record["markdown"], record
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
    "federated-ci-runtime-gates-20260319-rerun30",
    "federated-ci-runtime-gates-20260319-rerun29",
    "federated-ci-runtime-gates-20260319-rerun28",
    "federated-ci-runtime-gates-20260319-rerun27",
    "federated-ci-runtime-gates-20260319-rerun26",
], records
healthy, unknown, restored, missing, stale = records
assert healthy["status"] == "healthy", healthy
assert healthy["reconcile_artifact_state"] == "fresh", healthy
assert healthy["reconcile_validation_state"] == "fresh", healthy
assert healthy["checkpoint_state"] == "present", healthy
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
