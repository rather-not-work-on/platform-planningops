#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUERY_PATH="$ROOT_DIR/scripts/federation/query_federated_ci_artifacts.py"
WRITE_LOCAL_INBOX_VALIDATION_MIRROR_PATH="$ROOT_DIR/scripts/write_monday_local_inbox_validation_mirror.py"
WRITE_MONDAY_VALIDATION_REPORT_MIRROR_PATH="$ROOT_DIR/scripts/write_monday_validation_report_mirror.py"
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
LOCAL_OPERATOR_DIR="$TMP_DIR/local-operator-stack"
MONDAY_CONSUMER_DIR="$TMP_DIR/monday/runtime-artifacts/integration/planningops-local-operator-inbox"
MONDAY_VALIDATION_DIR="$TMP_DIR/monday/runtime-artifacts/validation"
mkdir -p "$CI_DIR" "$VALIDATION_DIR" "$CONFORMANCE_DIR"
mkdir -p "$LOCAL_OPERATOR_DIR" "$MONDAY_CONSUMER_DIR" "$MONDAY_VALIDATION_DIR"

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

mkdir -p "$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060415Z"
mkdir -p "$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060416Z"
mkdir -p "$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060524Z"

cat >"$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060415Z.json" <<JSON
{
  "generated_at_utc": "2026-04-01T06:04:15+00:00",
  "run_id": "monday-local-operator-stack-20260401T060415Z",
  "workspace_root": "${TMP_DIR}/workspace",
  "execution_mode": "both",
  "direct_profile": "local_ollama",
  "dry_run": false,
  "verdict": "pass",
  "reason_code": "monday_local_operator_stack_ok",
  "readiness": {
    "status": "ready",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060415Z/readiness.json",
    "report": {
      "assessment_status": "ready"
    },
    "step": {
      "status": "pass"
    }
  },
  "stack_smoke": {
    "status": "pass",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060415Z/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "pass",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060415Z/local_ollama.json"
  },
  "recommended_next_steps": [
    "Inspect stamped reports and carry the direct smoke output into handoff."
  ]
}
JSON

cat >"$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060416Z.json" <<JSON
{
  "generated_at_utc": "2026-04-01T06:04:16+00:00",
  "run_id": "monday-local-operator-stack-20260401T060416Z",
  "workspace_root": "${TMP_DIR}/workspace",
  "execution_mode": "direct",
  "direct_profile": "local_ollama",
  "dry_run": false,
  "verdict": "pass",
  "reason_code": "monday_local_operator_stack_ok",
  "readiness": {
    "status": "bootstrap_required",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060416Z/readiness.json",
    "report": {
      "assessment_status": "bootstrap_required"
    },
    "step": {
      "status": "report_only"
    }
  },
  "stack_smoke": {
    "status": "skipped",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060416Z/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "pass",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060416Z/local_ollama.json"
  },
  "recommended_next_steps": [
    "Start the provider gateway stack first if you want stack mode."
  ]
}
JSON

cat >"$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060524Z.json" <<JSON
{
  "generated_at_utc": "2026-04-01T06:05:24+00:00",
  "run_id": "monday-local-operator-stack-20260401T060524Z",
  "workspace_root": "${TMP_DIR}/workspace",
  "execution_mode": "both",
  "direct_profile": "local_lmstudio",
  "dry_run": false,
  "verdict": "fail",
  "reason_code": "readiness_blocked",
  "readiness": {
    "status": "blocked",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060524Z/readiness.json",
    "report": {
      "assessment_status": "blocked"
    },
    "step": {
      "status": "report_only"
    }
  },
  "stack_smoke": {
    "status": "skipped",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060524Z/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "skipped",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060524Z/local_lmstudio.json"
  },
  "recommended_next_steps": [
    "Expose Codex and add a direct local LLM profile."
  ]
}
JSON

cat >"$LOCAL_OPERATOR_DIR/monday-local-operator-stack-20260401T060700Z.json" <<JSON
{
  "generated_at_utc": "2026-04-01T06:07:00+00:00",
  "run_id": "monday-local-operator-stack-20260401T060700Z",
  "workspace_root": "${TMP_DIR}/workspace",
  "execution_mode": "stack",
  "direct_profile": null,
  "dry_run": true,
  "verdict": "planned",
  "reason_code": "operator_stack_dry_run_only",
  "readiness": {
    "status": "ready",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060700Z/readiness.json",
    "report": {
      "assessment_status": "ready"
    },
    "step": {
      "status": "pass"
    }
  },
  "stack_smoke": {
    "status": "planned",
    "report_path": "${LOCAL_OPERATOR_DIR}/monday-local-operator-stack-20260401T060700Z/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "skipped",
    "report_path": null
  },
  "recommended_next_steps": []
}
JSON

python3 - <<'PY' "$LOCAL_OPERATOR_DIR/._monday-local-operator-stack-20260401T060800Z.json"
from pathlib import Path
import sys

Path(sys.argv[1]).write_bytes(b"\x00\xffappledouble")
PY

cat >"$LOCAL_OPERATOR_DIR/broken-report.json" <<'EOF'
{broken json
EOF

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
TRIAGE_FEED_WITH_CROSS_REPO_VALIDATION_OUTPUT="$TMP_DIR/triage-feed-with-cross-repo-validation.json"
TRIAGE_BRIEF_OUTPUT="$TMP_DIR/triage-brief.json"
TRIAGE_BRIEF_ALL_OUTPUT="$TMP_DIR/triage-brief-all.json"
TRIAGE_BRIEF_WITH_CROSS_REPO_VALIDATION_OUTPUT="$TMP_DIR/triage-brief-with-cross-repo-validation.json"
TRIAGE_REPORT_OUTPUT="$TMP_DIR/triage-report.json"
TRIAGE_REPORT_ALL_OUTPUT="$TMP_DIR/triage-report-all.json"
TRIAGE_REPORT_WITH_CROSS_REPO_VALIDATION_OUTPUT="$TMP_DIR/triage-report-with-cross-repo-validation.json"
HANDOFF_REPORT_OUTPUT="$TMP_DIR/handoff-report.json"
HANDOFF_REPORT_ALL_OUTPUT="$TMP_DIR/handoff-report-all.json"
HANDOFF_REPORT_WITH_MONDAY_VALIDATION_OUTPUT="$TMP_DIR/handoff-report-with-monday-validation.json"
HANDOFF_REPORT_WITH_CROSS_REPO_PACKET_OUTPUT="$TMP_DIR/handoff-report-with-cross-repo-packet.json"
HANDOFF_WRITE_OUTPUT="$TMP_DIR/handoff-write.json"
LOCAL_VALIDATION_OUTPUT="$TMP_DIR/local-validation-freshness.json"
LOCAL_VALIDATION_BLOCKED_OUTPUT="$TMP_DIR/local-validation-freshness-blocked.json"
LOCAL_VALIDATION_STALE_OUTPUT="$TMP_DIR/local-validation-freshness-stale.json"
LOCAL_VALIDATION_MIRROR_WRITE_OUTPUT="$TMP_DIR/local-validation-mirror-write.json"
LOCAL_VALIDATION_WITH_CONSUMER_OUTPUT="$TMP_DIR/local-validation-freshness-with-consumer.json"
LOCAL_VALIDATION_WITH_CROSS_REPO_REPORT_OUTPUT="$TMP_DIR/local-validation-freshness-with-cross-repo-report.json"
LOCAL_VALIDATION_CROSS_REPO_REPORT_OUTPUT="$TMP_DIR/local-validation-cross-repo-report.json"
LOCAL_VALIDATION_RUNTIME_BLOCKED_OUTPUT="$TMP_DIR/local-validation-runtime-blocked.json"
LOCAL_INBOX_PAYLOAD_OUTPUT="$TMP_DIR/local-inbox-payload.json"
LOCAL_INBOX_PAYLOAD_ALL_OUTPUT="$TMP_DIR/local-inbox-payload-all.json"
LOCAL_INBOX_PAYLOAD_FILTERED_OUTPUT="$TMP_DIR/local-inbox-payload-filtered.json"
LOCAL_INBOX_PAYLOAD_WITH_MONDAY_VALIDATION_OUTPUT="$TMP_DIR/local-inbox-payload-with-monday-validation.json"
MONDAY_CONSUMER_OUTPUT="$TMP_DIR/monday-consumer-report.json"
MONDAY_CONSUMER_FILTERED_OUTPUT="$TMP_DIR/monday-consumer-report-filtered.json"
MONDAY_CONSUMER_BLOCKED_OUTPUT="$TMP_DIR/monday-consumer-report-blocked.json"
MONDAY_CONSUMER_OVERRIDE_OUTPUT="$TMP_DIR/monday-consumer-report-override.json"
MONDAY_CONSUMER_WITH_MONDAY_VALIDATION_OUTPUT="$TMP_DIR/monday-consumer-report-with-monday-validation.json"
MONDAY_VALIDATION_OUTPUT="$TMP_DIR/monday-validation-report.json"
MONDAY_VALIDATION_FAIL_OUTPUT="$TMP_DIR/monday-validation-report-fail.json"
MONDAY_VALIDATION_BRIDGE_OUTPUT="$TMP_DIR/monday-validation-report-bridge.json"
MONDAY_VALIDATION_MIRROR_WRITE_OUTPUT="$TMP_DIR/monday-validation-report-mirror-write.json"
CROSS_REPO_VALIDATION_REPORT_OUTPUT="$TMP_DIR/cross-repo-validation-report.json"
CROSS_REPO_VALIDATION_PACKET_OUTPUT="$TMP_DIR/cross-repo-validation-packet.json"
CROSS_REPO_VALIDATION_PACKET_STAMPED_OUTPUT="$TMP_DIR/cross-repo-validation-packet-stamped.json"
LOCAL_INBOX_PAYLOAD_WITH_CROSS_REPO_PACKET_OUTPUT="$TMP_DIR/local-inbox-payload-with-cross-repo-packet.json"
LOCAL_INBOX_PAYLOAD_WITH_CROSS_REPO_PACKET_MARKDOWN_OUTPUT="$TMP_DIR/local-inbox-payload-with-cross-repo-packet.md"
MONDAY_CONSUMER_WITH_CROSS_REPO_PACKET_OUTPUT="$TMP_DIR/monday-consumer-report-with-cross-repo-packet.json"
MONDAY_CONSUMER_WITH_CROSS_REPO_PACKET_MARKDOWN_OUTPUT="$TMP_DIR/monday-consumer-report-with-cross-repo-packet.md"
CROSS_REPO_VALIDATION_WRITE_OUTPUT="$TMP_DIR/cross-repo-validation-write.json"
CROSS_REPO_VALIDATION_WRITE_STDOUT="$TMP_DIR/cross-repo-validation-write-stdout.json"
LOCAL_VALIDATION_WITH_MONDAY_VALIDATION_OUTPUT="$TMP_DIR/local-validation-freshness-with-monday-validation.json"
LOCAL_VALIDATION_MONDAY_VALIDATION_BLOCKED_OUTPUT="$TMP_DIR/local-validation-monday-validation-blocked.json"
LOCAL_OPERATOR_OUTPUT="$TMP_DIR/local-operator-stack.json"
LOCAL_OPERATOR_FILTERED_OUTPUT="$TMP_DIR/local-operator-stack-filtered.json"
LOCAL_OPERATOR_DETAIL_OUTPUT="$TMP_DIR/local-operator-stack-detail.json"
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
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_FEED_OUTPUT"

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
assert record["local_operator_record"]["run_id"] == "monday-local-operator-stack-20260401T060524Z", record
assert record["local_operator_record"]["verdict"] == "fail", record
assert record["local_operator_record"]["readiness_status"] == "blocked", record
assert record["local_operator_record"]["stack_status"] == "skipped", record
assert record["local_operator_record"]["direct_status"] == "skipped", record
assert record["cross_repo_validation_snapshot_status"] == "missing", record
assert record["cross_repo_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] is None, record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
assert record["target_records"][0]["priority_bucket"] == "active", record
assert record["target_records"][1]["priority_bucket"] == "lagging", record
PY

python3 "$QUERY_PATH" triage-feed \
  --source-kind all \
  --target-limit 1 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_FEED_ALL_OUTPUT"

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
assert record["local_operator_record"]["run_id"] == "monday-local-operator-stack-20260401T060524Z", record
assert record["cross_repo_validation_snapshot_status"] == "missing", record
assert record["cross_repo_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] is None, record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
PY

python3 "$QUERY_PATH" triage-brief \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_BRIEF_OUTPUT"

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
assert record["local_operator_record"]["run_id"] == "monday-local-operator-stack-20260401T060524Z", record
assert record["local_operator_summary"] == (
    "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
    "stack=skipped direct=skipped mode=both reason=readiness_blocked"
), record
assert record["local_operator_next_step"] == "Expose Codex and add a direct local LLM profile.", record
assert record["cross_repo_validation_snapshot_status"] == "missing", record
assert record["cross_repo_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] is None, record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
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
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_BRIEF_ALL_OUTPUT"

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
assert record["local_operator_summary"] == (
    "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
    "stack=skipped direct=skipped mode=both reason=readiness_blocked"
), record
assert record["cross_repo_validation_snapshot_status"] == "missing", record
assert record["cross_repo_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] is None, record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
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
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_REPORT_OUTPUT"

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
assert record["local_operator_record"]["run_id"] == "monday-local-operator-stack-20260401T060524Z", record
assert record["local_operator_summary"] == (
    "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
    "stack=skipped direct=skipped mode=both reason=readiness_blocked"
), record
assert record["local_operator_next_step"] == "Expose Codex and add a direct local LLM profile.", record
assert record["cross_repo_validation_snapshot_status"] == "missing", record
assert record["cross_repo_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] is None, record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
assert record["queue_lines"] == [
    "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1",
    "lagging: targets=1 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint=1,readiness=1,reconcile=1",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "[lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile",
], record
assert "## Federated CI Triage Report" in record["markdown"], record
assert "### Local Operator Stack" not in record["markdown"], record
assert "local operator:" in record["markdown"], record
assert "local operator next step:" in record["markdown"], record
assert "### Queue" in record["markdown"], record
assert "### Top Targets" in record["markdown"], record
PY

python3 "$QUERY_PATH" triage-report \
  --source-kind all \
  --target-limit 1 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_REPORT_ALL_OUTPUT"

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
assert record["local_operator_summary"] == (
    "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
    "stack=skipped direct=skipped mode=both reason=readiness_blocked"
), record
assert record["cross_repo_validation_snapshot_status"] == "missing", record
assert record["cross_repo_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] is None, record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
assert record["queue_lines"] == [
    "active: targets=2 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun26 domains=checkpoint=1,readiness=2,reconcile=2",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun26 domains=readiness,reconcile",
], record
assert "source_kind: `all`" in record["markdown"], record
assert "local operator:" in record["markdown"], record
PY

cat >"$VALIDATION_DIR/monday-local-operator-stack-report.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T06:05:24+00:00",
  "run_id": "monday-local-operator-stack-20260401T060524Z",
  "workspace_root": "/tmp/workspace",
  "execution_mode": "both",
  "direct_profile": "local_lmstudio",
  "dry_run": false,
  "verdict": "fail",
  "reason_code": "readiness_blocked",
  "readiness": {
    "status": "blocked",
    "report_path": "/tmp/readiness.json",
    "report": {},
    "step": {
      "status": "report_only"
    }
  },
  "stack_smoke": {
    "status": "skipped",
    "report_path": "/tmp/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "skipped",
    "report_path": "/tmp/local_lmstudio.json"
  },
  "recommended_next_steps": [
    "Expose Codex and add a direct local LLM profile."
  ],
  "artifact_paths": {
    "detail_dir": "/tmp/monday-local-operator-stack-20260401T060524Z",
    "runtime_report_path": "/tmp/monday-local-operator-stack-20260401T060524Z.json",
    "validation_latest_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json",
    "validation_stamped_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json"
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/monday-local-operator-stack-report.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["validation_latest_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
doc["artifact_paths"]["validation_stamped_report_path"] = str((validation_dir / "monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json").write_text(payload, encoding="utf-8")
PY

cat >"$VALIDATION_DIR/operator-handoff-report.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T07:00:00+00:00",
  "report_id": "operator-handoff-20260401T070000Z",
  "artifact_paths": {
    "latest_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
    "stamped_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-20260401T070000Z-operator-handoff-report.json",
    "output_path": null
  },
  "record": {
    "headline": "Operator handoff report: 2 attention families",
    "attention_summary": "active=1, lagging=1, clear=0",
    "immediate_action_lines": [
      "local-runtime: Expose Codex and add a direct local LLM profile."
    ]
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/operator-handoff-report.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["artifact_paths"]["stamped_report_path"] = str((validation_dir / "operator-handoff-20260401T070000Z-operator-handoff-report.json").resolve())
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat >"$VALIDATION_DIR/monday-local-mission-packet.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T08:00:00+00:00",
  "packet_id": "monday-local-mission-20260401T080000Z",
  "contract_ref": "planningops/contracts/monday-local-mission-packet-contract.md",
  "artifact_paths": {
    "latest_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
    "stamped_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-20260401T080000Z-monday-local-mission-packet.json",
    "output_path": null
  },
  "mission_packet": {
    "version": "v1",
    "packet_id": "monday-local-mission-20260401T080000Z",
    "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_prompt": "Use monday planner profile `local_ollama` via `direct_local_ollama`.",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "source_kind": "stamped",
    "attention_summary": "active=2, lagging=0, clear=0",
    "newest_failing_summary": "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun26 / active",
    "local_runtime_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_runtime_next_step": "Expose Codex and add a direct local LLM profile.",
    "primary_action": "local-runtime: Expose Codex and add a direct local LLM profile.",
    "immediate_actions": [
      "local-runtime: Expose Codex and add a direct local LLM profile."
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "preflight_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
    "expected_evidence_outputs": [
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-20260401T080000Z-monday-local-mission-packet.json"
    ],
    "source_artifacts": {
      "handoff_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "local_operator_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    }
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/monday-local-mission-packet.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_packet_path"] = str((validation_dir / "monday-local-mission-packet.json").resolve())
doc["artifact_paths"]["stamped_packet_path"] = str((validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").resolve())
doc["mission_packet"]["expected_evidence_outputs"] = [
    str((validation_dir / "monday-local-mission-packet.json").resolve()),
    str((validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").resolve()),
]
doc["mission_packet"]["source_artifacts"]["handoff_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["mission_packet"]["source_artifacts"]["local_operator_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").write_text(payload, encoding="utf-8")
PY

cat >"$VALIDATION_DIR/monday-local-operator-day-packet.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T08:30:00+00:00",
  "day_packet_id": "monday-local-day-20260401T083000Z",
  "contract_ref": "planningops/contracts/monday-local-operator-day-packet-contract.md",
  "artifact_paths": {
    "latest_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-day-packet.json",
    "stamped_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-day-20260401T083000Z-monday-local-operator-day-packet.json",
    "output_path": null
  },
  "day_packet": {
    "version": "v1",
    "day_packet_id": "monday-local-day-20260401T083000Z",
    "mission_packet_id": "monday-local-mission-20260401T080000Z",
    "headline": "Monday local operator day packet: Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_prompt": "Use monday planner profile `local_ollama` via `direct_local_ollama`.",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "first_action_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
    "monday_runtime_entrypoint_command": "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-mission-20260401T080000Z",
    "rollback_command": "",
    "local_runtime_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_runtime_next_step": "Expose Codex and add a direct local LLM profile.",
    "local_validation_snapshot_status": "present",
    "local_validation_records": [],
    "local_validation_summary_lines": [
      "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
      "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing",
      "monday_local_mission_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=operator_handoff_report=current,monday_local_operator_stack_report=current"
    ],
    "local_validation_action_lines": [
      "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
      "local-validation: repair monday_local_mission_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)"
    ],
    "queue_lines": [
      "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1"
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "immediate_actions": [
      "local-runtime: Expose Codex and add a direct local LLM profile.",
      "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "attachments": [
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    ],
    "body_markdown": "## Monday Local Operator Day Packet",
    "source_artifacts": {
      "mission_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "handoff_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "local_operator_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    }
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/monday-local-operator-day-packet.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_packet_path"] = str((validation_dir / "monday-local-operator-day-packet.json").resolve())
doc["artifact_paths"]["stamped_packet_path"] = str((validation_dir / "monday-local-day-20260401T083000Z-monday-local-operator-day-packet.json").resolve())
doc["day_packet"]["attachments"] = [
    str((validation_dir / "monday-local-mission-packet.json").resolve()),
    str((validation_dir / "operator-handoff-report.json").resolve()),
    str((validation_dir / "monday-local-operator-stack-report.json").resolve()),
]
doc["day_packet"]["source_artifacts"]["mission_packet_path"] = str((validation_dir / "monday-local-mission-packet.json").resolve())
doc["day_packet"]["source_artifacts"]["handoff_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["day_packet"]["source_artifacts"]["local_operator_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-day-20260401T083000Z-monday-local-operator-day-packet.json").write_text(payload, encoding="utf-8")
PY

cat >"$VALIDATION_DIR/monday-local-operator-inbox-payload.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T08:45:00+00:00",
  "bridge_id": "monday-local-inbox-20260401T084500Z",
  "contract_ref": "planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md",
  "artifact_paths": {
    "latest_payload_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-inbox-payload.json",
    "stamped_payload_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-inbox-20260401T084500Z-monday-local-operator-inbox-payload.json",
    "output_path": null
  },
  "payload": {
    "title": "Monday local operator day packet: Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "status": "blocked",
    "headline": "Monday local operator day packet: Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "priority_headline": "Monday local operator day packet: Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "operator_action": "launch_monday_local_runtime",
    "recommended_wait_minutes": 5,
    "retry_mode": "manual_recheck",
    "needs_human_attention": true,
    "message_class_hint": "decision_request",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "day_packet_id": "monday-local-day-20260401T083000Z",
    "mission_packet_id": "monday-local-mission-20260401T080000Z",
    "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "first_action_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
    "monday_runtime_entrypoint_command": "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-mission-20260401T080000Z",
    "rollback_command": "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start",
    "local_validation_snapshot_status": "present",
    "local_validation_summary_lines": [
      "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
      "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing",
      "monday_local_mission_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=operator_handoff_report=current,monday_local_operator_stack_report=current",
      "monday_local_operator_day_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current"
    ],
    "local_validation_action_lines": [
      "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
      "local-validation: repair monday_local_mission_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)",
      "local-validation: repair monday_local_operator_day_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)"
    ],
    "queue_lines": [
      "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1"
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "immediate_actions": [
      "local-runtime: Expose Codex and add a direct local LLM profile."
    ],
    "attachments": [
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-inbox-payload.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-day-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    ],
    "body_markdown": "## Monday Local Operator Day Packet",
    "bridge_contract_ref": "planningops/contracts/monday-local-operator-inbox-payload-bridge-contract.md",
    "source_artifacts": {
      "day_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-day-packet.json",
      "mission_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "handoff_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "local_operator_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    }
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/monday-local-operator-inbox-payload.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_payload_path"] = str((validation_dir / "monday-local-operator-inbox-payload.json").resolve())
doc["artifact_paths"]["stamped_payload_path"] = str((validation_dir / "monday-local-inbox-20260401T084500Z-monday-local-operator-inbox-payload.json").resolve())
doc["payload"]["attachments"] = [
    str((validation_dir / "monday-local-operator-inbox-payload.json").resolve()),
    str((validation_dir / "monday-local-operator-day-packet.json").resolve()),
    str((validation_dir / "monday-local-mission-packet.json").resolve()),
    str((validation_dir / "operator-handoff-report.json").resolve()),
    str((validation_dir / "monday-local-operator-stack-report.json").resolve()),
]
doc["payload"]["source_artifacts"]["day_packet_path"] = str((validation_dir / "monday-local-operator-day-packet.json").resolve())
doc["payload"]["source_artifacts"]["mission_packet_path"] = str((validation_dir / "monday-local-mission-packet.json").resolve())
doc["payload"]["source_artifacts"]["handoff_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["payload"]["source_artifacts"]["local_operator_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
payload = json.dumps(doc, ensure_ascii=True, indent=2) + "\n"
path.write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-inbox-20260401T084500Z-monday-local-operator-inbox-payload.json").write_text(payload, encoding="utf-8")
(validation_dir / "monday-local-inbox-20260331T235959Z-monday-local-operator-inbox-payload.json").write_text(
    json.dumps(
        {
            **doc,
            "generated_at_utc": "2026-03-31T23:59:59+00:00",
            "bridge_id": "monday-local-inbox-20260331T235959Z",
            "artifact_paths": {
                **doc["artifact_paths"],
                "stamped_payload_path": str(
                    (validation_dir / "monday-local-inbox-20260331T235959Z-monday-local-operator-inbox-payload.json").resolve()
                ),
            },
            "payload": {
                **doc["payload"],
                "status": "ready",
                "recommended_wait_minutes": 0,
                "retry_mode": "none",
                "needs_human_attention": False,
                "message_class_hint": "status_update",
                "local_model_route": "direct_local_lmstudio",
                "local_validation_snapshot_status": "fresh",
                "local_validation_action_lines": [],
                "immediate_actions": [
                    "launch monday local runtime via local_lmstudio"
                ],
            },
        },
        ensure_ascii=True,
        indent=2,
    ) + "\n",
    encoding="utf-8",
)
PY

mkdir -p "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z"

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json" <<'JSON'
{
  "planner_profile": "local_ollama",
  "launch_mode": "direct",
  "local_model_route": "direct_local_ollama"
}
JSON

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json" <<'JSON'
{
  "consumer_status": "blocked"
}
JSON

cat >"$VALIDATION_DIR/monday-local-inbox-launch-request.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:31:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z",
  "artifact_family": "monday_local_inbox_launch_request",
  "artifact_kind": "request",
  "contract_ref": "planningops/contracts/monday-local-inbox-validation-mirror-contract.md",
  "artifact_paths": {
    "latest_mirror_path": "$VALIDATION_DIR/monday-local-inbox-launch-request.json",
    "stamped_mirror_path": "$VALIDATION_DIR/planningops-local-inbox-consumer-20260401T103000Z-monday-local-inbox-launch-request.json",
    "source_artifact_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json",
    "source_launch_request_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json",
    "source_runtime_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/local-runtime-smoke.json",
    "source_consumer_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json"
  },
  "mirror": {
    "source_artifact_present": true,
    "bridge_id": "monday-local-inbox-20260401T084500Z",
    "mode": "apply",
    "consumer_verdict": "blocked",
    "consumer_status": "blocked",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "has_runtime_input_overrides": false,
    "override_kinds": [],
    "validation_dependency_paths": {
      "monday_local_operator_inbox_payload": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json"
    },
    "payload": {
      "planner_profile": "local_ollama",
      "launch_mode": "direct",
      "local_model_route": "direct_local_ollama"
    }
  }
}
JSON

cp "$VALIDATION_DIR/monday-local-inbox-launch-request.json" \
  "$VALIDATION_DIR/planningops-local-inbox-consumer-20260401T103000Z-monday-local-inbox-launch-request.json"

cat >"$VALIDATION_DIR/monday-local-inbox-runtime-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:32:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z",
  "artifact_family": "monday_local_inbox_runtime_report",
  "artifact_kind": "report",
  "contract_ref": "planningops/contracts/monday-local-inbox-validation-mirror-contract.md",
  "artifact_paths": {
    "latest_mirror_path": "$VALIDATION_DIR/monday-local-inbox-runtime-report.json",
    "stamped_mirror_path": "$VALIDATION_DIR/planningops-local-inbox-consumer-20260401T103000Z-monday-local-inbox-runtime-report.json",
    "source_artifact_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/local-runtime-smoke.json",
    "source_launch_request_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json",
    "source_runtime_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/local-runtime-smoke.json",
    "source_consumer_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json"
  },
  "mirror": {
    "source_artifact_present": false,
    "bridge_id": "monday-local-inbox-20260401T084500Z",
    "mode": "apply",
    "consumer_verdict": "blocked",
    "consumer_status": "blocked",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "has_runtime_input_overrides": false,
    "override_kinds": [],
    "validation_dependency_paths": {
      "monday_local_operator_inbox_payload": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json",
      "monday_local_inbox_launch_request": "$VALIDATION_DIR/monday-local-inbox-launch-request.json"
    },
    "payload": null
  }
}
JSON

cp "$VALIDATION_DIR/monday-local-inbox-runtime-report.json" \
  "$VALIDATION_DIR/planningops-local-inbox-consumer-20260401T103000Z-monday-local-inbox-runtime-report.json"

cat >"$VALIDATION_DIR/monday-local-inbox-consumer-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:33:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z",
  "artifact_family": "monday_local_inbox_consumer_report",
  "artifact_kind": "report",
  "contract_ref": "planningops/contracts/monday-local-inbox-validation-mirror-contract.md",
  "artifact_paths": {
    "latest_mirror_path": "$VALIDATION_DIR/monday-local-inbox-consumer-report.json",
    "stamped_mirror_path": "$VALIDATION_DIR/planningops-local-inbox-consumer-20260401T103000Z-monday-local-inbox-consumer-report.json",
    "source_artifact_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json",
    "source_launch_request_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json",
    "source_runtime_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/local-runtime-smoke.json",
    "source_consumer_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json"
  },
  "mirror": {
    "source_artifact_present": true,
    "bridge_id": "monday-local-inbox-20260401T084500Z",
    "mode": "apply",
    "consumer_verdict": "blocked",
    "consumer_status": "blocked",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "has_runtime_input_overrides": false,
    "override_kinds": [],
    "validation_dependency_paths": {
      "monday_local_operator_inbox_payload": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json",
      "monday_local_inbox_launch_request": "$VALIDATION_DIR/monday-local-inbox-launch-request.json",
      "monday_local_inbox_runtime_report": "$VALIDATION_DIR/monday-local-inbox-runtime-report.json"
    },
    "payload": {
      "consumer_status": "blocked"
    }
  }
}
JSON

cp "$VALIDATION_DIR/monday-local-inbox-consumer-report.json" \
  "$VALIDATION_DIR/planningops-local-inbox-consumer-20260401T103000Z-monday-local-inbox-consumer-report.json"

python3 "$QUERY_PATH" handoff-report \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$HANDOFF_REPORT_OUTPUT"

python3 - <<'PY' "$HANDOFF_REPORT_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "stamped", record
assert record["target_limit"] == 3, record
assert record["headline"] == "Operator handoff report: 2 attention families", record
assert record["attention_summary"] == "active=1, lagging=1, clear=0", record
assert record["newest_failing_summary"] == "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun30 / lagging", record
assert record["local_operator_summary"] == (
    "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
    "stack=skipped direct=skipped mode=both reason=readiness_blocked"
), record
assert record["local_operator_next_step"] == "Expose Codex and add a direct local LLM profile.", record
assert record["local_validation_snapshot_status"] == "present", record
assert record["local_validation_snapshot_summary"] == "total=8 promotable=4 blocked=4 stale=1", record
assert record["monday_validation_snapshot_status"] == "missing", record
assert record["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_validation_summary_lines"] == [], record
assert record["monday_validation_action_lines"] == [], record
assert record["cross_repo_validation_snapshot_status"] == "present", record
assert record["cross_repo_validation_snapshot_summary"] == "total=3 promotable=2 blocked=1 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] == (
    "local-validation: repair monday_local_inbox_runtime_report "
    "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
), record
assert record["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
], record
assert record["monday_source_validation_report_lines"] == [], record
assert record["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
], record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
assert record["local_validation_summary_lines"] == [
    "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
    "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing",
    "monday_local_mission_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=operator_handoff_report=current,monday_local_operator_stack_report=current",
    "monday_local_operator_day_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current",
    "monday_local_operator_inbox_payload: freshness=fresh promotability=promotable dependencies=monday_local_operator_day_packet=current,monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current",
    "monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
], record
assert record["local_validation_action_lines"] == [
    "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
    "local-validation: repair monday_local_mission_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)",
    "local-validation: repair monday_local_operator_day_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)",
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
], record
assert record["queue_lines"] == [
    "active: targets=1 newest=federated-ci-local/federated-ci-local-20260301 domains=checkpoint=1,readiness=1,reconcile=1",
    "lagging: targets=1 newest=federated-ci-runtime-gates/federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint=1,readiness=1,reconcile=1",
], record
assert record["target_lines"] == [
    "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "[lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile",
], record
assert record["immediate_action_lines"] == [
    "local-runtime: Expose Codex and add a direct local LLM profile.",
    "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
    "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "follow-up: [lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile",
], record
assert "## Operator Handoff Report" in record["markdown"], record
assert "### Snapshot" in record["markdown"], record
assert "### Local Runtime" in record["markdown"], record
assert "### Local Validation" in record["markdown"], record
assert "### Monday Schema Validation" not in record["markdown"], record
assert "### Cross-Repo Validation" in record["markdown"], record
assert "### Cross-Repo Validation Packet" not in record["markdown"], record
assert "### Cross-Repo Validation Details" in record["markdown"], record
assert "### Cross-Repo Validation Actions" in record["markdown"], record
assert "snapshot status: `present`" in record["markdown"], record
assert "snapshot summary: `total=8 promotable=4 blocked=4 stale=1`" in record["markdown"], record
assert "### Cross-Repo Validation" in record["markdown"], record
assert "snapshot summary: `total=3 promotable=2 blocked=1 stale=0`" in record["markdown"], record
assert "monday source validation status: `missing`" in record["markdown"], record
assert "monday source validation summary: `total=0 pass=0 fail=0 errors=0 warnings=0`" in record["markdown"], record
assert "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing" in record["markdown"], record
assert "1. local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)" in record["markdown"], record
assert "### Local Validation Actions" in record["markdown"], record
assert "### Queue" in record["markdown"], record
assert "### Top Targets" in record["markdown"], record
assert "### Immediate Actions" in record["markdown"], record
PY

python3 "$QUERY_PATH" handoff-report \
  --source-kind all \
  --target-limit 1 \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$HANDOFF_REPORT_ALL_OUTPUT"

python3 - <<'PY' "$HANDOFF_REPORT_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["source_kind"] == "all", record
assert record["target_limit"] == 1, record
assert record["headline"] == "Operator handoff report: 2 attention families", record
assert record["attention_summary"] == "active=2, lagging=0, clear=0", record
assert record["newest_failing_summary"] == "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun26 / active", record
assert record["local_operator_summary"] == (
    "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
    "stack=skipped direct=skipped mode=both reason=readiness_blocked"
), record
assert record["local_validation_snapshot_status"] == "present", record
assert record["local_validation_snapshot_summary"] == "total=8 promotable=4 blocked=4 stale=1", record
assert record["monday_validation_snapshot_status"] == "missing", record
assert record["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_validation_summary_lines"] == [], record
assert record["monday_validation_action_lines"] == [], record
assert record["cross_repo_validation_snapshot_status"] == "present", record
assert record["cross_repo_validation_snapshot_summary"] == "total=3 promotable=2 blocked=1 stale=0", record
assert record["monday_source_validation_status"] == "missing", record
assert record["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", record
assert record["cross_repo_validation_action_line"] == (
    "local-validation: repair monday_local_inbox_runtime_report "
    "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
), record
assert record["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
], record
assert record["monday_source_validation_report_lines"] == [], record
assert record["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
], record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
assert record["local_validation_summary_lines"] == [
    "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
    "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing",
    "monday_local_mission_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=operator_handoff_report=current,monday_local_operator_stack_report=current",
    "monday_local_operator_day_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current",
    "monday_local_operator_inbox_payload: freshness=fresh promotability=promotable dependencies=monday_local_operator_day_packet=current,monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current",
    "monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
], record
assert record["immediate_action_lines"] == [
    "local-runtime: Expose Codex and add a direct local LLM profile.",
    "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
    "triage-target: [active/latest-gap] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun26 domains=readiness,reconcile",
], record
assert "source_kind: `all`" in record["markdown"], record
assert "### Local Validation" in record["markdown"], record
assert "### Cross-Repo Validation" in record["markdown"], record
assert "### Immediate Actions" in record["markdown"], record
PY

python3 "$QUERY_PATH" write-handoff-report \
  --report-id operator-handoff-20260401T070000Z \
  --output "$HANDOFF_WRITE_OUTPUT" \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$HANDOFF_WRITE_OUTPUT.stdout"

python3 - <<'PY' "$HANDOFF_WRITE_OUTPUT.stdout" "$HANDOFF_WRITE_OUTPUT" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()
latest_path = validation_dir / "operator-handoff-report.json"
stamped_path = validation_dir / "operator-handoff-20260401T070000Z-operator-handoff-report.json"
latest_doc = json.loads(latest_path.read_text(encoding="utf-8"))
stamped_doc = json.loads(stamped_path.read_text(encoding="utf-8"))

for doc in (stdout_doc, output_doc, latest_doc, stamped_doc):
    assert doc["report_id"] == "operator-handoff-20260401T070000Z", doc
    assert doc["artifact_paths"]["latest_report_path"] == str(latest_path), doc
    assert doc["artifact_paths"]["stamped_report_path"] == str(stamped_path), doc
    assert doc["record"]["headline"] == "Operator handoff report: 2 attention families", doc
    assert doc["record"]["source_kind"] == "stamped", doc
    assert doc["record"]["local_operator_summary"] == (
        "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked "
        "stack=skipped direct=skipped mode=both reason=readiness_blocked"
    ), doc
    assert doc["record"]["local_validation_snapshot_status"] == "present", doc
    assert doc["record"]["local_validation_snapshot_summary"] == "total=8 promotable=4 blocked=4 stale=1", doc
    assert doc["record"]["monday_validation_snapshot_status"] == "missing", doc
    assert doc["record"]["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", doc
    assert doc["record"]["monday_validation_summary_lines"] == [], doc
    assert doc["record"]["monday_validation_action_lines"] == [], doc
    assert doc["record"]["cross_repo_validation_snapshot_status"] == "present", doc
    assert doc["record"]["cross_repo_validation_snapshot_summary"] == "total=3 promotable=2 blocked=1 stale=0", doc
    assert doc["record"]["monday_source_validation_status"] == "missing", doc
    assert doc["record"]["monday_source_validation_summary"] == "total=0 pass=0 fail=0 errors=0 warnings=0", doc
    assert doc["record"]["cross_repo_validation_action_line"] == (
        "local-validation: repair monday_local_inbox_runtime_report "
        "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
    ), doc
    assert doc["record"]["cross_repo_validation_detail_lines"] == [
        "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
        "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
        "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    ], doc
    assert doc["record"]["monday_source_validation_report_lines"] == [], doc
    assert doc["record"]["cross_repo_validation_action_lines"] == [
        "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    ], doc
    assert doc["record"]["cross_repo_validation_packet_report_id"] is None, doc
    assert doc["record"]["cross_repo_validation_packet_path"] is None, doc
    assert doc["record"]["local_validation_summary_lines"] == [
        "monday_local_operator_stack_report: freshness=fresh promotability=promotable",
        "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing",
        "monday_local_mission_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=operator_handoff_report=current,monday_local_operator_stack_report=current",
        "monday_local_operator_day_packet: freshness=fresh promotability=blocked reasons=missing_rollback_command dependencies=monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current",
        "monday_local_operator_inbox_payload: freshness=fresh promotability=promotable dependencies=monday_local_operator_day_packet=current,monday_local_mission_packet=current,operator_handoff_report=current,monday_local_operator_stack_report=current",
        "monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
        "monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
        "monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    ], doc
    assert doc["record"]["local_validation_action_lines"] == [
        "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
        "local-validation: repair monday_local_mission_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)",
        "local-validation: repair monday_local_operator_day_packet (freshness=fresh, promotability=blocked, reasons=missing_rollback_command)",
        "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    ], doc
    assert doc["record"]["immediate_action_lines"] == [
        "local-runtime: Expose Codex and add a direct local LLM profile.",
        "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)",
        "triage-target: [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
        "follow-up: [lagging/latest-alert-follow-up] federated-ci-runtime-gates -> federated-ci-runtime-gates-20260319-rerun29 domains=checkpoint,readiness,reconcile",
    ], doc

assert stdout_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stdout_doc
assert output_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), output_doc
assert latest_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), latest_doc
assert stamped_doc["artifact_paths"]["output_path"] == str(Path(sys.argv[2]).resolve()), stamped_doc
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

python3 "$QUERY_PATH" local-operator-stack \
  --format json \
  --local-root "$LOCAL_OPERATOR_DIR" >"$LOCAL_OPERATOR_OUTPUT"

python3 - <<'PY' "$LOCAL_OPERATOR_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["run_id"] for record in records] == [
    "monday-local-operator-stack-20260401T060700Z",
    "monday-local-operator-stack-20260401T060524Z",
    "monday-local-operator-stack-20260401T060416Z",
    "monday-local-operator-stack-20260401T060415Z",
], records

planned, blocked, bootstrap, ready = records
assert planned["verdict"] == "planned", planned
assert planned["execution_mode"] == "stack", planned
assert planned["stack_status"] == "planned", planned
assert planned["direct_status"] == "skipped", planned
assert planned["has_detail_dir"] is False, planned
assert planned["detail_dir"] is None, planned
assert planned["expected_detail_dir"].endswith(planned["run_id"]), planned

assert blocked["verdict"] == "fail", blocked
assert blocked["reason_code"] == "readiness_blocked", blocked
assert blocked["readiness_status"] == "blocked", blocked
assert blocked["readiness_step_status"] == "report_only", blocked
assert blocked["stack_status"] == "skipped", blocked
assert blocked["direct_status"] == "skipped", blocked
assert blocked["direct_profile"] == "local_lmstudio", blocked
assert blocked["has_detail_dir"] is True, blocked

assert bootstrap["verdict"] == "pass", bootstrap
assert bootstrap["execution_mode"] == "direct", bootstrap
assert bootstrap["readiness_status"] == "bootstrap_required", bootstrap
assert bootstrap["direct_status"] == "pass", bootstrap
assert bootstrap["stack_status"] == "skipped", bootstrap

assert ready["verdict"] == "pass", ready
assert ready["execution_mode"] == "both", ready
assert ready["readiness_status"] == "ready", ready
assert ready["stack_status"] == "pass", ready
assert ready["direct_status"] == "pass", ready
assert len(ready["recommended_next_steps"]) == 1, ready
PY

python3 "$QUERY_PATH" local-operator-stack \
  --verdict pass \
  --execution-mode direct \
  --readiness-status bootstrap_required \
  --direct-status pass \
  --format json \
  --local-root "$LOCAL_OPERATOR_DIR" >"$LOCAL_OPERATOR_FILTERED_OUTPUT"

python3 - <<'PY' "$LOCAL_OPERATOR_FILTERED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["run_id"] == "monday-local-operator-stack-20260401T060416Z", record
assert record["readiness_status"] == "bootstrap_required", record
assert record["direct_status"] == "pass", record
assert record["stack_status"] == "skipped", record
PY

python3 "$QUERY_PATH" local-operator-stack \
  --verdict planned \
  --has-detail-dir no \
  --format json \
  --local-root "$LOCAL_OPERATOR_DIR" >"$LOCAL_OPERATOR_DETAIL_OUTPUT"

python3 - <<'PY' "$LOCAL_OPERATOR_DETAIL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["run_id"] == "monday-local-operator-stack-20260401T060700Z", record
assert record["has_detail_dir"] is False, record
assert record["expected_detail_dir"].endswith("monday-local-operator-stack-20260401T060700Z"), record
PY

rm -f "$VALIDATION_DIR/operator-handoff-20260401T070000Z-operator-handoff-report.json"

cat >"$VALIDATION_DIR/monday-local-operator-stack-report.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T06:05:24+00:00",
  "run_id": "monday-local-operator-stack-20260401T060524Z",
  "workspace_root": "/tmp/workspace",
  "execution_mode": "both",
  "direct_profile": "local_lmstudio",
  "dry_run": false,
  "verdict": "fail",
  "reason_code": "readiness_blocked",
  "readiness": {
    "status": "blocked",
    "report_path": "/tmp/readiness.json",
    "report": {},
    "step": {
      "status": "report_only"
    }
  },
  "stack_smoke": {
    "status": "skipped",
    "report_path": "/tmp/stack-smoke.json"
  },
  "direct_smoke": {
    "status": "skipped",
    "report_path": "/tmp/local_lmstudio.json"
  },
  "recommended_next_steps": [
    "Expose Codex and add a direct local LLM profile."
  ],
  "artifact_paths": {
    "detail_dir": "/tmp/monday-local-operator-stack-20260401T060524Z",
    "runtime_report_path": "/tmp/monday-local-operator-stack-20260401T060524Z.json",
    "validation_latest_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json",
    "validation_stamped_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json"
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/monday-local-operator-stack-report.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["validation_latest_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
doc["artifact_paths"]["validation_stamped_report_path"] = str((validation_dir / "monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json").resolve())
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
(validation_dir / "monday-local-operator-stack-20260401T060524Z-monday-local-operator-stack-report.json").write_text(
    json.dumps(doc, ensure_ascii=True, indent=2) + "\n",
    encoding="utf-8",
)
PY

cat >"$VALIDATION_DIR/monday-local-mission-packet.json" <<'JSON'
{
  "generated_at_utc": "2026-04-01T08:00:00+00:00",
  "packet_id": "monday-local-mission-20260401T080000Z",
  "contract_ref": "planningops/contracts/monday-local-mission-packet-contract.md",
  "artifact_paths": {
    "latest_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
    "stamped_packet_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-20260401T080000Z-monday-local-mission-packet.json",
    "output_path": null
  },
  "mission_packet": {
    "version": "v1",
    "packet_id": "monday-local-mission-20260401T080000Z",
    "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
    "mission_prompt": "Use monday planner profile `local_ollama` via `direct_local_ollama`.",
    "planner_profile": "local_ollama",
    "launch_mode": "direct",
    "local_model_route": "direct_local_ollama",
    "source_kind": "stamped",
    "attention_summary": "active=2, lagging=0, clear=0",
    "newest_failing_summary": "federated-ci-runtime-gates / federated-ci-runtime-gates-20260319-rerun26 / active",
    "local_runtime_summary": "monday-local-operator-stack-20260401T060524Z verdict=fail readiness=blocked stack=skipped direct=skipped mode=both reason=readiness_blocked",
    "local_runtime_next_step": "Expose Codex and add a direct local LLM profile.",
    "primary_action": "local-runtime: Expose Codex and add a direct local LLM profile.",
    "immediate_actions": [
      "local-runtime: Expose Codex and add a direct local LLM profile."
    ],
    "target_lines": [
      "[active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
    ],
    "preflight_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
    "expected_evidence_outputs": [
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-packet.json",
      "VALIDATION_ROOT_PLACEHOLDER/monday-local-mission-20260401T080000Z-monday-local-mission-packet.json"
    ],
    "source_artifacts": {
      "handoff_report_path": "VALIDATION_ROOT_PLACEHOLDER/operator-handoff-report.json",
      "local_operator_report_path": "VALIDATION_ROOT_PLACEHOLDER/monday-local-operator-stack-report.json"
    }
  }
}
JSON

python3 - <<'PY' "$VALIDATION_DIR/monday-local-mission-packet.json" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
validation_dir = Path(sys.argv[2]).resolve()
doc = json.loads(path.read_text(encoding="utf-8"))
doc["artifact_paths"]["latest_packet_path"] = str((validation_dir / "monday-local-mission-packet.json").resolve())
doc["artifact_paths"]["stamped_packet_path"] = str((validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").resolve())
doc["mission_packet"]["expected_evidence_outputs"] = [
    str((validation_dir / "monday-local-mission-packet.json").resolve()),
    str((validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").resolve()),
]
doc["mission_packet"]["source_artifacts"]["handoff_report_path"] = str((validation_dir / "operator-handoff-report.json").resolve())
doc["mission_packet"]["source_artifacts"]["local_operator_report_path"] = str((validation_dir / "monday-local-operator-stack-report.json").resolve())
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
(validation_dir / "monday-local-mission-20260401T080000Z-monday-local-mission-packet.json").write_text(
    json.dumps(doc, ensure_ascii=True, indent=2) + "\n",
    encoding="utf-8",
)
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["artifact_family"] for record in records] == [
    "monday_local_operator_stack_report",
    "operator_handoff_report",
    "monday_local_mission_packet",
    "monday_local_operator_day_packet",
    "monday_local_operator_inbox_payload",
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
], records

local_operator, handoff, mission, day_packet, inbox_payload, launch_request, runtime_report, consumer_report = records

assert local_operator["freshness_state"] == "fresh", local_operator
assert local_operator["promotability_status"] == "promotable", local_operator
assert local_operator["promoted_id"] == "monday-local-operator-stack-20260401T060524Z", local_operator
assert local_operator["reasons"] == [], local_operator

assert handoff["freshness_state"] == "stale", handoff
assert handoff["promotability_status"] == "blocked", handoff
assert handoff["promoted_id"] == "operator-handoff-20260401T070000Z", handoff
assert handoff["reasons"] == ["stamped_missing"], handoff

assert mission["freshness_state"] == "fresh", mission
assert mission["promotability_status"] == "blocked", mission
assert mission["promoted_id"] == "monday-local-mission-20260401T080000Z", mission
assert mission["dependency_states"] == {
    "operator_handoff_report": "current",
    "monday_local_operator_stack_report": "current",
}, mission
assert mission["reasons"] == ["missing_rollback_command"], mission

assert day_packet["freshness_state"] == "fresh", day_packet
assert day_packet["promotability_status"] == "blocked", day_packet
assert day_packet["promoted_id"] == "monday-local-day-20260401T083000Z", day_packet
assert day_packet["dependency_states"] == {
    "monday_local_mission_packet": "current",
    "operator_handoff_report": "current",
    "monday_local_operator_stack_report": "current",
}, day_packet
assert day_packet["reasons"] == ["missing_rollback_command"], day_packet

assert inbox_payload["freshness_state"] == "fresh", inbox_payload
assert inbox_payload["promotability_status"] == "promotable", inbox_payload
assert inbox_payload["promoted_id"] == "monday-local-inbox-20260401T084500Z", inbox_payload
assert inbox_payload["dependency_states"] == {
    "monday_local_operator_day_packet": "current",
    "monday_local_mission_packet": "current",
    "operator_handoff_report": "current",
    "monday_local_operator_stack_report": "current",
}, inbox_payload
assert inbox_payload["reasons"] == [], inbox_payload

assert launch_request["freshness_state"] == "fresh", launch_request
assert launch_request["promotability_status"] == "promotable", launch_request
assert launch_request["promoted_id"] == "planningops-local-inbox-consumer-20260401T103000Z", launch_request
assert launch_request["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
}, launch_request
assert launch_request["reasons"] == [], launch_request

assert runtime_report["freshness_state"] == "fresh", runtime_report
assert runtime_report["promotability_status"] == "blocked", runtime_report
assert runtime_report["promoted_id"] == "planningops-local-inbox-consumer-20260401T103000Z", runtime_report
assert runtime_report["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
    "monday_local_inbox_launch_request": "current",
}, runtime_report
assert runtime_report["reasons"] == ["source_artifact_missing"], runtime_report

assert consumer_report["freshness_state"] == "fresh", consumer_report
assert consumer_report["promotability_status"] == "promotable", consumer_report
assert consumer_report["promoted_id"] == "planningops-local-inbox-consumer-20260401T103000Z", consumer_report
assert consumer_report["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
    "monday_local_inbox_launch_request": "current",
    "monday_local_inbox_runtime_report": "current",
}, consumer_report
assert consumer_report["reasons"] == [], consumer_report
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --promotability-status blocked \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_BLOCKED_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_BLOCKED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["artifact_family"] for record in records] == [
    "operator_handoff_report",
    "monday_local_mission_packet",
    "monday_local_operator_day_packet",
    "monday_local_inbox_runtime_report",
], records
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --freshness-state stale \
  --has-reason stamped_missing \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_STALE_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_STALE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["artifact_family"] == "operator_handoff_report", record
assert record["freshness_state"] == "stale", record
assert record["reasons"] == ["stamped_missing"], record
PY

python3 "$QUERY_PATH" local-inbox-payload \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_INBOX_PAYLOAD_OUTPUT"

python3 - <<'PY' "$LOCAL_INBOX_PAYLOAD_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["bridge_id"] == "monday-local-inbox-20260401T084500Z", record
assert record["source_kind"] == "latest", record
assert record["status"] == "blocked", record
assert record["needs_human_attention"] is True, record
assert record["message_class_hint"] == "decision_request", record
assert record["retry_mode"] == "manual_recheck", record
assert record["planner_profile"] == "local_ollama", record
assert record["launch_mode"] == "direct", record
assert record["local_model_route"] == "direct_local_ollama", record
assert record["local_validation_snapshot_status"] == "present", record
assert record["monday_validation_snapshot_status"] == "missing", record
assert record["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_validation_summary_lines"] == [], record
assert record["monday_validation_action_lines"] == [], record
assert record["attachment_count"] == 5, record
assert len(record["local_validation_action_lines"]) == 3, record
assert len(record["immediate_actions"]) == 1, record
assert len(record["queue_lines"]) == 1, record
assert len(record["target_lines"]) == 1, record
assert record["dependency_states"] == {
    "monday_local_operator_day_packet": "current",
    "monday_local_mission_packet": "current",
    "operator_handoff_report": "current",
    "monday_local_operator_stack_report": "current",
}, record
PY

python3 "$QUERY_PATH" local-inbox-payload \
  --source-kind all \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_INBOX_PAYLOAD_ALL_OUTPUT"

python3 - <<'PY' "$LOCAL_INBOX_PAYLOAD_ALL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["bridge_id"] for record in records] == [
    "monday-local-inbox-20260401T084500Z",
    "monday-local-inbox-20260401T084500Z",
    "monday-local-inbox-20260331T235959Z",
], records
assert [record["source_kind"] for record in records] == [
    "latest",
    "stamped",
    "stamped",
], records
PY

python3 "$QUERY_PATH" local-inbox-payload \
  --source-kind stamped \
  --status ready \
  --needs-human-attention no \
  --local-model-route direct_local_lmstudio \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_INBOX_PAYLOAD_FILTERED_OUTPUT"

python3 - <<'PY' "$LOCAL_INBOX_PAYLOAD_FILTERED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["bridge_id"] == "monday-local-inbox-20260331T235959Z", record
assert record["source_kind"] == "stamped", record
assert record["status"] == "ready", record
assert record["needs_human_attention"] is False, record
assert record["message_class_hint"] == "status_update", record
assert record["retry_mode"] == "none", record
assert record["local_model_route"] == "direct_local_lmstudio", record
assert record["local_validation_snapshot_status"] == "fresh", record
assert record["monday_validation_snapshot_status"] == "missing", record
assert record["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", record
assert record["monday_validation_summary_lines"] == [], record
assert record["monday_validation_action_lines"] == [], record
assert record["immediate_actions"] == ["launch monday local runtime via local_lmstudio"], record
PY

mkdir -p \
  "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z" \
  "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z" \
  "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z"

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/launch-request.json" <<JSON
{
  "source_bridge_id": "monday-local-inbox-20260401T084500Z",
  "source_day_packet_id": "monday-local-day-20260401T083000Z",
  "source_mission_packet_id": "monday-local-mission-20260401T080000Z",
  "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
  "planner_profile": "local_ollama",
  "launch_mode": "direct",
  "local_model_route": "direct_local_ollama",
  "first_action_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
  "monday_runtime_entrypoint_command": "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-mission-20260401T080000Z",
  "rollback_command": "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start",
  "recommended_wait_minutes": 0,
  "needs_human_attention": false,
  "local_validation_snapshot_status": "fresh",
  "local_validation_summary_lines": [],
  "local_validation_action_lines": [],
  "can_launch": true,
  "block_reasons": [],
  "runtime_command_args": [
    "python3",
    "scripts/run_local_runtime_smoke.py",
    "--profile",
    "local_ollama"
  ],
  "source_artifacts": {
    "day_packet_path": "$VALIDATION_DIR/monday-local-operator-day-packet.json",
    "mission_packet_path": "$VALIDATION_DIR/monday-local-mission-packet.json",
    "handoff_report_path": "$VALIDATION_DIR/operator-handoff-report.json",
    "local_operator_report_path": "$VALIDATION_DIR/monday-local-operator-stack-report.json"
  }
}
JSON

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/mission.json" <<'JSON'
{
  "missionId": "monday-local-mission-20260401T080000Z",
  "objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile"
}
JSON

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/consumer-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:10:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T101000Z",
  "consumer_contract_ref": "contracts/planningops-local-operator-inbox-consumer-contract.md",
  "source_bridge_path": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json",
  "bridge_id": "monday-local-inbox-20260401T084500Z",
  "mode": "dry-run",
  "verdict": "pass",
  "reason_code": "dry_run",
  "consumer_status": "ready_to_launch",
  "artifact_paths": {
    "launch_request_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/launch-request.json",
    "mission_file_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/mission.json",
    "runtime_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/local-runtime-smoke.json",
    "report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/consumer-report.json"
  },
  "launch_request": $(cat "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/launch-request.json")
}
JSON

cp "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/launch-request.json" \
  "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json"
cp "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/mission.json" \
  "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/mission.json"

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/local-runtime-smoke.json" <<'JSON'
{
  "verdict": "pass",
  "reason_code": "ok"
}
JSON

cat >"$TMP_DIR/planner-runtime.json" <<'JSON'
{
  "profile": "local_ollama"
}
JSON

cat >"$TMP_DIR/runtime-profiles.json" <<'JSON'
{
  "profiles": [
    "local_ollama"
  ]
}
JSON

python3 - <<'PY' "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json" "$TMP_DIR/planner-runtime.json" "$TMP_DIR/runtime-profiles.json"
import json
import sys
from pathlib import Path

launch_request_path = Path(sys.argv[1])
planner_runtime_path = Path(sys.argv[2]).resolve()
runtime_profiles_path = Path(sys.argv[3]).resolve()
doc = json.loads(launch_request_path.read_text(encoding="utf-8"))
doc["runtime_command_args"] = [
    "python3",
    "scripts/run_local_runtime_smoke.py",
    "--profile",
    "local_ollama",
    "--planner-runtime-config",
    str(planner_runtime_path),
    "--runtime-profile-file",
    str(runtime_profiles_path),
]
doc["runtime_input_overrides"] = {
    "planner_runtime_config": str(planner_runtime_path),
    "runtime_profile_file": str(runtime_profiles_path),
}
launch_request_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/consumer-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:20:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T102000Z",
  "consumer_contract_ref": "contracts/planningops-local-operator-inbox-consumer-contract.md",
  "source_bridge_path": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json",
  "bridge_id": "monday-local-inbox-20260401T084500Z",
  "mode": "apply",
  "verdict": "pass",
  "reason_code": "ok",
  "consumer_status": "ready_to_launch",
  "artifact_paths": {
    "launch_request_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json",
    "mission_file_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/mission.json",
    "runtime_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/local-runtime-smoke.json",
    "report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/consumer-report.json"
  },
  "launch_request": $(cat "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json"),
  "execution": {
    "attempted": true,
    "command_args": $(python3 - <<'PY' "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/launch-request.json"
import json
import sys
from pathlib import Path
doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
print(json.dumps(doc["runtime_command_args"]))
PY
),
    "exit_code": 0,
    "stdout": "runtime ok",
    "stderr": ""
  },
  "runtime_report_summary": {
    "verdict": "pass",
    "reason_code": "ok",
    "report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T102000Z/local-runtime-smoke.json"
  }
}
JSON

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json" <<JSON
{
  "source_bridge_id": "monday-local-inbox-20260401T084500Z",
  "source_day_packet_id": "monday-local-day-20260401T083000Z",
  "source_mission_packet_id": "monday-local-mission-20260401T080000Z",
  "mission_objective": "Resolve [active/latest-gap] federated-ci-local -> federated-ci-local-20260301 domains=checkpoint,readiness,reconcile",
  "planner_profile": "local_ollama",
  "launch_mode": "direct",
  "local_model_route": "direct_local_ollama",
  "first_action_command": "python3 planningops/scripts/run_monday_local_operator_stack.py --execution-mode direct --direct-profile local_ollama --probe-endpoints on --run-id monday-local-mission-20260401T080000Z",
  "monday_runtime_entrypoint_command": "cd ../monday && python3 scripts/run_local_runtime_smoke.py --profile local_ollama --run-id monday-local-mission-20260401T080000Z",
  "rollback_command": "cd ../platform-provider-gateway && bash scripts/litellm_stack_launcher.sh --mode start",
  "recommended_wait_minutes": 5,
  "needs_human_attention": true,
  "local_validation_snapshot_status": "present",
  "local_validation_summary_lines": [
    "operator_handoff_report: freshness=stale promotability=blocked reasons=stamped_missing"
  ],
  "local_validation_action_lines": [
    "local-validation: repair operator_handoff_report (freshness=stale, promotability=blocked, reasons=stamped_missing)"
  ],
  "can_launch": false,
  "block_reasons": [
    "payload_status=blocked",
    "needs_human_attention",
    "local_validation_actions_present"
  ],
  "runtime_command_args": [
    "python3",
    "scripts/run_local_runtime_smoke.py",
    "--profile",
    "local_ollama"
  ],
  "source_artifacts": {
    "day_packet_path": "$VALIDATION_DIR/monday-local-operator-day-packet.json",
    "mission_packet_path": "$VALIDATION_DIR/monday-local-mission-packet.json",
    "handoff_report_path": "$VALIDATION_DIR/operator-handoff-report.json",
    "local_operator_report_path": "$VALIDATION_DIR/monday-local-operator-stack-report.json"
  }
}
JSON

cp "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T101000Z/mission.json" \
  "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/mission.json"

cat >"$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:30:00+00:00",
  "run_id": "planningops-local-inbox-consumer-20260401T103000Z",
  "consumer_contract_ref": "contracts/planningops-local-operator-inbox-consumer-contract.md",
  "source_bridge_path": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json",
  "bridge_id": "monday-local-inbox-20260401T084500Z",
  "mode": "apply",
  "verdict": "blocked",
  "reason_code": "launch_blocked",
  "consumer_status": "blocked",
  "artifact_paths": {
    "launch_request_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json",
    "mission_file_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/mission.json",
    "runtime_report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/local-runtime-smoke.json",
    "report_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json"
  },
  "launch_request": $(cat "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/launch-request.json"),
  "execution": {
    "attempted": false,
    "command_args": [
      "python3",
      "scripts/run_local_runtime_smoke.py",
      "--profile",
      "local_ollama"
    ]
  }
}
JSON

python3 "$QUERY_PATH" monday-consumer-report \
  --format json \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["run_id"] for record in records] == [
    "planningops-local-inbox-consumer-20260401T103000Z",
    "planningops-local-inbox-consumer-20260401T102000Z",
    "planningops-local-inbox-consumer-20260401T101000Z",
], records
blocked, passed_apply, dry_run = records
assert blocked["verdict"] == "blocked", blocked
assert blocked["consumer_status"] == "blocked", blocked
assert blocked["can_launch"] is False, blocked
assert blocked["execution_attempted"] is False, blocked
assert blocked["has_runtime_report"] is False, blocked
assert blocked["block_reasons"] == [
    "payload_status=blocked",
    "needs_human_attention",
    "local_validation_actions_present",
], blocked
assert blocked["monday_validation_snapshot_status"] == "missing", blocked
assert blocked["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", blocked
assert blocked["monday_validation_summary_lines"] == [], blocked
assert blocked["monday_validation_action_lines"] == [], blocked

assert passed_apply["verdict"] == "pass", passed_apply
assert passed_apply["mode"] == "apply", passed_apply
assert passed_apply["execution_attempted"] is True, passed_apply
assert passed_apply["execution_exit_code"] == 0, passed_apply
assert passed_apply["has_runtime_report"] is True, passed_apply
assert passed_apply["runtime_report_verdict"] == "pass", passed_apply
assert passed_apply["runtime_report_reason_code"] == "ok", passed_apply
assert passed_apply["has_runtime_input_overrides"] is True, passed_apply
assert passed_apply["override_kinds"] == [
    "planner_runtime_config",
    "runtime_profile_file",
], passed_apply
assert passed_apply["planner_runtime_config_path"].endswith("/planner-runtime.json"), passed_apply
assert passed_apply["runtime_profile_file_path"].endswith("/runtime-profiles.json"), passed_apply
assert passed_apply["monday_validation_snapshot_status"] == "missing", passed_apply
assert passed_apply["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", passed_apply
assert passed_apply["monday_validation_summary_lines"] == [], passed_apply
assert passed_apply["monday_validation_action_lines"] == [], passed_apply

assert dry_run["mode"] == "dry-run", dry_run
assert dry_run["verdict"] == "pass", dry_run
assert dry_run["reason_code"] == "dry_run", dry_run
assert dry_run["can_launch"] is True, dry_run
assert dry_run["execution_attempted"] is None, dry_run
assert dry_run["has_launch_request"] is True, dry_run
assert dry_run["has_mission_file"] is True, dry_run
assert dry_run["has_runtime_report"] is False, dry_run
assert dry_run["has_runtime_input_overrides"] is False, dry_run
assert dry_run["monday_validation_snapshot_status"] == "missing", dry_run
assert dry_run["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", dry_run
assert dry_run["monday_validation_summary_lines"] == [], dry_run
assert dry_run["monday_validation_action_lines"] == [], dry_run
PY

python3 "$QUERY_PATH" monday-consumer-report \
  --mode apply \
  --verdict pass \
  --has-runtime-overrides yes \
  --override-kind runtime_profile_file \
  --has-runtime-report yes \
  --execution-attempted yes \
  --format json \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_FILTERED_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_FILTERED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["run_id"] == "planningops-local-inbox-consumer-20260401T102000Z", record
assert record["runtime_report_verdict"] == "pass", record
assert record["reason_code"] == "ok", record
assert record["has_runtime_input_overrides"] is True, record
PY

python3 "$QUERY_PATH" monday-consumer-report \
  --consumer-status blocked \
  --can-launch no \
  --format json \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_BLOCKED_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_BLOCKED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", record
assert record["verdict"] == "blocked", record
assert record["execution_attempted"] is False, record
PY

python3 "$QUERY_PATH" monday-consumer-report \
  --has-runtime-overrides no \
  --format json \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_OVERRIDE_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_OVERRIDE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["run_id"] for record in records] == [
    "planningops-local-inbox-consumer-20260401T103000Z",
    "planningops-local-inbox-consumer-20260401T101000Z",
], records
assert all(record["has_runtime_input_overrides"] is False for record in records), records
PY

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-payload-bridge.schema.json" <<'JSON'
{
  "type": "object"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-consumer-report.schema.json" <<'JSON'
{
  "type": "object"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-payload-validation-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:40:00+00:00",
  "kind": "bridge",
  "artifact_path": "$VALIDATION_DIR/monday-local-operator-inbox-payload.json",
  "schema_path": "$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-payload-bridge.schema.json",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "verdict": "pass"
}
JSON

cat >"$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-consumer-report-validation-report.json" <<JSON
{
  "generated_at_utc": "2026-04-01T10:50:00+00:00",
  "kind": "consumer-report",
  "artifact_path": "$MONDAY_CONSUMER_DIR/planningops-local-inbox-consumer-20260401T103000Z/consumer-report.json",
  "schema_path": "$MONDAY_VALIDATION_DIR/planningops-local-operator-inbox-consumer-report.schema.json",
  "error_count": 2,
  "warning_count": 1,
  "errors": [
    "consumer contract ref mismatch",
    "schema validation failed: launch_request.source_bridge_id must match bridge_id"
  ],
  "warnings": [
    "runtime report path missing"
  ],
  "verdict": "fail"
}
JSON

python3 "$QUERY_PATH" monday-validation-report \
  --format json \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$MONDAY_VALIDATION_OUTPUT"

python3 - <<'PY' "$MONDAY_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["kind"] for record in records] == [
    "consumer-report",
    "bridge",
], records
consumer_report, bridge = records
assert consumer_report["verdict"] == "fail", consumer_report
assert consumer_report["error_count"] == 2, consumer_report
assert consumer_report["warning_count"] == 1, consumer_report
assert consumer_report["artifact_exists"] is True, consumer_report
assert consumer_report["schema_exists"] is True, consumer_report
assert "consumer contract ref mismatch" in consumer_report["errors"], consumer_report
assert bridge["verdict"] == "pass", bridge
assert bridge["error_count"] == 0, bridge
assert bridge["warning_count"] == 0, bridge
assert bridge["artifact_exists"] is True, bridge
assert bridge["schema_exists"] is True, bridge
PY

python3 "$QUERY_PATH" monday-validation-report \
  --kind consumer-report \
  --verdict fail \
  --has-errors yes \
  --has-message contract \
  --format json \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$MONDAY_VALIDATION_FAIL_OUTPUT"

python3 - <<'PY' "$MONDAY_VALIDATION_FAIL_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["kind"] == "consumer-report", record
assert record["verdict"] == "fail", record
assert record["error_count"] == 2, record
PY

python3 "$QUERY_PATH" monday-validation-report \
  --kind bridge \
  --verdict pass \
  --has-errors no \
  --has-warnings no \
  --artifact-exists yes \
  --schema-exists yes \
  --format json \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$MONDAY_VALIDATION_BRIDGE_OUTPUT"

python3 - <<'PY' "$MONDAY_VALIDATION_BRIDGE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["kind"] == "bridge", record
assert record["verdict"] == "pass", record
assert record["warning_count"] == 0, record
PY

python3 "$WRITE_MONDAY_VALIDATION_REPORT_MIRROR_PATH" \
  --validation-root "$VALIDATION_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$MONDAY_VALIDATION_MIRROR_WRITE_OUTPUT"

python3 - <<'PY' "$MONDAY_VALIDATION_MIRROR_WRITE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert [record["artifact_family"] for record in doc["records"]] == [
    "monday_local_inbox_bridge_schema_validation",
    "monday_local_inbox_consumer_schema_validation",
], doc
assert doc["records"][0]["report_verdict"] == "pass", doc
assert doc["records"][1]["report_verdict"] == "fail", doc
PY

python3 "$WRITE_LOCAL_INBOX_VALIDATION_MIRROR_PATH" \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$LOCAL_VALIDATION_MIRROR_WRITE_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_MIRROR_WRITE_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert doc["run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", doc
assert [record["artifact_family"] for record in doc["records"]] == [
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
], doc
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_WITH_CONSUMER_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_WITH_CONSUMER_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["artifact_family"] for record in records] == [
    "monday_local_operator_stack_report",
    "operator_handoff_report",
    "monday_local_mission_packet",
    "monday_local_operator_day_packet",
    "monday_local_operator_inbox_payload",
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
    "monday_local_inbox_bridge_schema_validation",
    "monday_local_inbox_consumer_schema_validation",
], records

launch_request = records[5]
runtime_report = records[6]
consumer_report = records[7]

assert launch_request["freshness_state"] == "fresh", launch_request
assert launch_request["promotability_status"] == "promotable", launch_request
assert launch_request["promoted_id"] == "planningops-local-inbox-consumer-20260401T103000Z", launch_request
assert launch_request["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
}, launch_request
assert launch_request["reasons"] == [], launch_request

assert runtime_report["freshness_state"] == "fresh", runtime_report
assert runtime_report["promotability_status"] == "blocked", runtime_report
assert runtime_report["promoted_id"] == "planningops-local-inbox-consumer-20260401T103000Z", runtime_report
assert runtime_report["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
    "monday_local_inbox_launch_request": "current",
}, runtime_report
assert runtime_report["reasons"] == ["source_artifact_missing"], runtime_report

assert consumer_report["freshness_state"] == "fresh", consumer_report
assert consumer_report["promotability_status"] == "promotable", consumer_report
assert consumer_report["promoted_id"] == "planningops-local-inbox-consumer-20260401T103000Z", consumer_report
assert consumer_report["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
    "monday_local_inbox_launch_request": "current",
    "monday_local_inbox_runtime_report": "current",
}, consumer_report
assert consumer_report["reasons"] == [], consumer_report
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_WITH_MONDAY_VALIDATION_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_WITH_MONDAY_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["artifact_family"] for record in records] == [
    "monday_local_operator_stack_report",
    "operator_handoff_report",
    "monday_local_mission_packet",
    "monday_local_operator_day_packet",
    "monday_local_operator_inbox_payload",
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
    "monday_local_inbox_bridge_schema_validation",
    "monday_local_inbox_consumer_schema_validation",
], records

bridge_validation = records[8]
consumer_validation = records[9]

assert bridge_validation["freshness_state"] == "fresh", bridge_validation
assert bridge_validation["promotability_status"] == "promotable", bridge_validation
assert bridge_validation["dependency_states"] == {
    "monday_local_operator_inbox_payload": "current",
}, bridge_validation
assert bridge_validation["reasons"] == [], bridge_validation

assert consumer_validation["freshness_state"] == "fresh", consumer_validation
assert consumer_validation["promotability_status"] == "blocked", consumer_validation
assert consumer_validation["dependency_states"] == {
    "monday_local_inbox_consumer_report": "current",
}, consumer_validation
assert consumer_validation["reasons"] == [
    "validation_verdict_fail",
    "validation_errors_present",
], consumer_validation
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --artifact-family monday_local_inbox_consumer_schema_validation \
  --promotability-status blocked \
  --has-reason validation_verdict_fail \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_MONDAY_VALIDATION_BLOCKED_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_MONDAY_VALIDATION_BLOCKED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["artifact_family"] == "monday_local_inbox_consumer_schema_validation", record
assert record["freshness_state"] == "fresh", record
assert record["promotability_status"] == "blocked", record
assert record["reasons"] == [
    "validation_verdict_fail",
    "validation_errors_present",
], record
PY

python3 "$QUERY_PATH" local-inbox-payload \
  --source-kind all \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_INBOX_PAYLOAD_WITH_MONDAY_VALIDATION_OUTPUT"

python3 - <<'PY' "$LOCAL_INBOX_PAYLOAD_WITH_MONDAY_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["bridge_id"] for record in records] == [
    "monday-local-inbox-20260401T084500Z",
    "monday-local-inbox-20260401T084500Z",
    "monday-local-inbox-20260331T235959Z",
], records

latest, stamped_current, stamped_old = records
for record in (latest, stamped_current):
    assert record["monday_validation_snapshot_status"] == "present", record
    assert record["monday_validation_snapshot_summary"] == "total=2 promotable=1 blocked=1 stale=0", record
    assert record["monday_validation_summary_lines"] == [
        "monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
        "monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
    ], record
    assert record["monday_validation_action_lines"] == [
        "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)"
    ], record
    assert record["cross_repo_validation_packet_report_id"] is None, record
    assert record["cross_repo_validation_packet_path"] is None, record

assert stamped_old["monday_validation_snapshot_status"] == "missing", stamped_old
assert stamped_old["monday_validation_snapshot_summary"] == "total=0 promotable=0 blocked=0 stale=0", stamped_old
assert stamped_old["monday_validation_summary_lines"] == [], stamped_old
assert stamped_old["monday_validation_action_lines"] == [], stamped_old
assert stamped_old["cross_repo_validation_packet_report_id"] is None, stamped_old
assert stamped_old["cross_repo_validation_packet_path"] is None, stamped_old
PY

python3 "$QUERY_PATH" monday-consumer-report \
  --format json \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_WITH_MONDAY_VALIDATION_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_WITH_MONDAY_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["run_id"] for record in records] == [
    "planningops-local-inbox-consumer-20260401T103000Z",
    "planningops-local-inbox-consumer-20260401T102000Z",
    "planningops-local-inbox-consumer-20260401T101000Z",
], records

blocked, passed_apply, dry_run = records

assert blocked["monday_validation_snapshot_status"] == "present", blocked
assert blocked["monday_validation_snapshot_summary"] == "total=2 promotable=1 blocked=1 stale=0", blocked
assert blocked["monday_validation_summary_lines"] == [
    "monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], blocked
assert blocked["monday_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)"
], blocked
assert blocked["cross_repo_validation_packet_report_id"] is None, blocked
assert blocked["cross_repo_validation_packet_path"] is None, blocked

for record in (passed_apply, dry_run):
    assert record["monday_validation_snapshot_status"] == "fresh", record
    assert record["monday_validation_snapshot_summary"] == "total=1 promotable=1 blocked=0 stale=0", record
    assert record["monday_validation_summary_lines"] == [
        "monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current"
    ], record
    assert record["monday_validation_action_lines"] == [], record
    assert record["cross_repo_validation_packet_report_id"] is None, record
    assert record["cross_repo_validation_packet_path"] is None, record
PY

python3 "$QUERY_PATH" handoff-report \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$HANDOFF_REPORT_WITH_MONDAY_VALIDATION_OUTPUT"

python3 - <<'PY' "$HANDOFF_REPORT_WITH_MONDAY_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["local_validation_snapshot_status"] == "present", record
assert record["local_validation_snapshot_summary"] == "total=10 promotable=5 blocked=5 stale=1", record
assert record["monday_validation_snapshot_status"] == "present", record
assert record["monday_validation_snapshot_summary"] == "total=2 promotable=1 blocked=1 stale=0", record
assert record["monday_validation_summary_lines"] == [
    "monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["monday_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
], record
assert record["cross_repo_validation_packet_report_id"] is None, record
assert record["cross_repo_validation_packet_path"] is None, record
assert record["local_validation_summary_lines"][-2:] == [
    "monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["local_validation_action_lines"][-1] == (
    "local-validation: repair monday_local_inbox_consumer_schema_validation "
    "(freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)"
), record
assert "### Monday Schema Validation" in record["markdown"], record
assert "snapshot summary: `total=2 promotable=1 blocked=1 stale=0`" in record["markdown"], record
assert "### Monday Schema Validation Actions" in record["markdown"], record
assert "### Cross-Repo Validation Packet" not in record["markdown"], record
PY

python3 "$QUERY_PATH" cross-repo-validation-report \
  --format json \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$CROSS_REPO_VALIDATION_REPORT_OUTPUT"

python3 - <<'PY' "$CROSS_REPO_VALIDATION_REPORT_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["cross_repo_snapshot_status"] == "present", record
assert record["cross_repo_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", record
assert [item["artifact_family"] for item in record["cross_repo_validation_records"]] == [
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
    "monday_local_inbox_bridge_schema_validation",
    "monday_local_inbox_consumer_schema_validation",
], record
assert record["cross_repo_summary_lines"] == [
    "monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    "monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["cross_repo_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
], record
assert record["monday_source_validation_status"] == "attention", record
assert record["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", record
assert record["monday_validation_report_lines"] == [
    "consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
    "bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
], record
assert record["monday_validation_report_action_lines"] == [
    "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
], record
assert record["latest_payload_bridge_id"] == "monday-local-inbox-20260401T084500Z", record
assert record["latest_payload_status"] == "blocked", record
assert record["latest_payload_monday_validation_snapshot_status"] == "present", record
assert record["latest_consumer_run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", record
assert record["latest_consumer_mode"] == "apply", record
assert record["latest_consumer_verdict"] == "blocked", record
assert record["latest_consumer_status"] == "blocked", record
assert record["latest_consumer_monday_validation_snapshot_status"] == "present", record
assert "### Cross-Repo Mirror Validation" in record["markdown"], record
assert "### Monday Source Validation Reports" in record["markdown"], record
assert "### Monday Source Validation Actions" in record["markdown"], record
PY

python3 "$QUERY_PATH" write-cross-repo-validation-report \
  --report-id cross-repo-validation-20260401T110000Z \
  --output "$CROSS_REPO_VALIDATION_WRITE_OUTPUT" \
  --format json \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$CROSS_REPO_VALIDATION_WRITE_STDOUT"

python3 - <<'PY' "$CROSS_REPO_VALIDATION_WRITE_STDOUT" "$CROSS_REPO_VALIDATION_WRITE_OUTPUT" "$VALIDATION_DIR"
import json
import sys
from pathlib import Path

stdout_doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
output_doc = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
validation_dir = Path(sys.argv[3]).resolve()
latest_path = validation_dir / "cross-repo-validation-report.json"
stamped_path = validation_dir / "cross-repo-validation-20260401T110000Z-cross-repo-validation-report.json"
latest_doc = json.loads(latest_path.read_text(encoding="utf-8"))
stamped_doc = json.loads(stamped_path.read_text(encoding="utf-8"))

for doc in (stdout_doc, output_doc, latest_doc, stamped_doc):
    assert doc["report_id"] == "cross-repo-validation-20260401T110000Z", doc
    assert doc["contract_ref"] == "planningops/contracts/cross-repo-validation-report-contract.md", doc
    assert doc["artifact_paths"]["latest_report_path"] == str(latest_path.resolve()), doc
    assert doc["artifact_paths"]["stamped_report_path"] == str(stamped_path.resolve()), doc
    assert doc["record"]["cross_repo_snapshot_status"] == "present", doc
    assert doc["record"]["cross_repo_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", doc
    assert doc["record"]["monday_source_validation_status"] == "attention", doc
    assert doc["record"]["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", doc
    assert doc["record"]["latest_payload_bridge_id"] == "monday-local-inbox-20260401T084500Z", doc
    assert doc["record"]["latest_consumer_run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", doc
    assert doc["record"]["cross_repo_action_lines"] == [
        "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
        "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
    ], doc
PY

python3 "$QUERY_PATH" cross-repo-validation-packet \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$CROSS_REPO_VALIDATION_PACKET_OUTPUT"

python3 - <<'PY' "$CROSS_REPO_VALIDATION_PACKET_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["report_id"] == "cross-repo-validation-20260401T110000Z", record
assert record["source_kind"] == "latest", record
assert record["report_path"].endswith("/cross-repo-validation-report.json"), record
assert record["contract_ref"] == "planningops/contracts/cross-repo-validation-report-contract.md", record
assert record["cross_repo_snapshot_status"] == "present", record
assert record["cross_repo_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", record
assert record["monday_source_validation_status"] == "attention", record
assert record["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", record
assert record["cross_repo_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
], record
assert record["latest_report_path"].endswith("/cross-repo-validation-report.json"), record
assert record["stamped_report_path"].endswith(
    "/cross-repo-validation-20260401T110000Z-cross-repo-validation-report.json"
), record
assert "### Cross-Repo Mirror Validation" in record["markdown"], record
PY

python3 "$QUERY_PATH" cross-repo-validation-packet \
  --report-id cross-repo-validation-20260401T110000Z \
  --source-kind stamped \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$CROSS_REPO_VALIDATION_PACKET_STAMPED_OUTPUT"

python3 - <<'PY' "$CROSS_REPO_VALIDATION_PACKET_STAMPED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["report_id"] == "cross-repo-validation-20260401T110000Z", record
assert record["source_kind"] == "stamped", record
assert record["report_path"].endswith(
    "/cross-repo-validation-20260401T110000Z-cross-repo-validation-report.json"
), record
assert record["cross_repo_snapshot_status"] == "present", record
assert record["monday_source_validation_status"] == "attention", record
assert record["latest_payload_bridge_id"] == "monday-local-inbox-20260401T084500Z", record
assert record["latest_consumer_run_id"] == "planningops-local-inbox-consumer-20260401T103000Z", record
PY

python3 "$QUERY_PATH" handoff-report \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$HANDOFF_REPORT_WITH_CROSS_REPO_PACKET_OUTPUT"

python3 - <<'PY' "$HANDOFF_REPORT_WITH_CROSS_REPO_PACKET_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["cross_repo_validation_snapshot_status"] == "present", record
assert record["cross_repo_validation_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", record
assert record["monday_source_validation_status"] == "attention", record
assert record["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", record
assert record["cross_repo_validation_action_line"] == (
    "local-validation: repair monday_local_inbox_runtime_report "
    "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
), record
assert record["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    "mirror: monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["monday_source_validation_report_lines"] == [
    "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
    "source: bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
], record
assert record["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
    "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
], record
assert record["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", record
assert record["cross_repo_validation_packet_path"].endswith("/cross-repo-validation-report.json"), record
assert "### Cross-Repo Validation" in record["markdown"], record
assert "snapshot summary: `total=5 promotable=3 blocked=2 stale=0`" in record["markdown"], record
assert "monday source validation summary: `total=2 pass=1 fail=1 errors=2 warnings=1`" in record["markdown"], record
assert "### Cross-Repo Validation Packet" in record["markdown"], record
assert "### Cross-Repo Validation Details" in record["markdown"], record
assert "### Cross-Repo Validation Actions" in record["markdown"], record
assert "detail packet report id: `cross-repo-validation-20260401T110000Z`" in record["markdown"], record
assert "detail packet path: `" in record["markdown"], record
assert "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing" in record["markdown"], record
assert "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes" in record["markdown"], record
assert "1. local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)" in record["markdown"], record
PY

python3 "$QUERY_PATH" local-inbox-payload \
  --source-kind all \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_INBOX_PAYLOAD_WITH_CROSS_REPO_PACKET_OUTPUT"

python3 - <<'PY' "$LOCAL_INBOX_PAYLOAD_WITH_CROSS_REPO_PACKET_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
latest, stamped_current, stamped_old = records

for record in (latest, stamped_current):
    assert record["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", record
    assert record["cross_repo_validation_packet_path"].endswith("/cross-repo-validation-report.json"), record
    assert record["cross_repo_validation_detail_lines"] == [
        "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
        "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
        "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
        "mirror: monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
        "mirror: monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
    ], record
    assert record["monday_source_validation_report_lines"] == [
        "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
        "source: bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
    ], record
    assert record["cross_repo_validation_action_lines"] == [
        "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
        "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
        "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
    ], record

assert stamped_old["cross_repo_validation_packet_report_id"] is None, stamped_old
assert stamped_old["cross_repo_validation_packet_path"] is None, stamped_old
assert stamped_old["cross_repo_validation_detail_lines"] == [], stamped_old
assert stamped_old["monday_source_validation_report_lines"] == [], stamped_old
assert stamped_old["cross_repo_validation_action_lines"] == [], stamped_old
PY

python3 "$QUERY_PATH" local-inbox-payload \
  --source-kind latest \
  --limit 1 \
  --format markdown \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_INBOX_PAYLOAD_WITH_CROSS_REPO_PACKET_MARKDOWN_OUTPUT"

python3 - <<'PY' "$LOCAL_INBOX_PAYLOAD_WITH_CROSS_REPO_PACKET_MARKDOWN_OUTPUT"
from pathlib import Path
import sys

markdown = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "### Cross-Repo Validation Details: `monday-local-inbox-20260401T084500Z`" in markdown, markdown
assert "detail packet report id: `cross-repo-validation-20260401T110000Z`" in markdown, markdown
assert "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing" in markdown, markdown
assert "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes" in markdown, markdown
assert "### Cross-Repo Validation Actions: `monday-local-inbox-20260401T084500Z`" in markdown, markdown
assert "1. local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)" in markdown, markdown
PY

python3 "$QUERY_PATH" monday-consumer-report \
  --format json \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_WITH_CROSS_REPO_PACKET_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_WITH_CROSS_REPO_PACKET_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
blocked, passed_apply, dry_run = records

assert blocked["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", blocked
assert blocked["cross_repo_validation_packet_path"].endswith("/cross-repo-validation-report.json"), blocked
assert blocked["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    "mirror: monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], blocked
assert blocked["monday_source_validation_report_lines"] == [
    "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
    "source: bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
], blocked
assert blocked["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
    "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
], blocked

for record in (passed_apply, dry_run):
    assert record["cross_repo_validation_packet_report_id"] is None, record
    assert record["cross_repo_validation_packet_path"] is None, record
    assert record["cross_repo_validation_detail_lines"] == [], record
    assert record["monday_source_validation_report_lines"] == [], record
    assert record["cross_repo_validation_action_lines"] == [], record
PY

python3 "$QUERY_PATH" monday-consumer-report \
  --verdict blocked \
  --limit 1 \
  --format markdown \
  --validation-root "$VALIDATION_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" >"$MONDAY_CONSUMER_WITH_CROSS_REPO_PACKET_MARKDOWN_OUTPUT"

python3 - <<'PY' "$MONDAY_CONSUMER_WITH_CROSS_REPO_PACKET_MARKDOWN_OUTPUT"
from pathlib import Path
import sys

markdown = Path(sys.argv[1]).read_text(encoding="utf-8")
assert "### Cross-Repo Validation Details: `planningops-local-inbox-consumer-20260401T103000Z`" in markdown, markdown
assert "detail packet report id: `cross-repo-validation-20260401T110000Z`" in markdown, markdown
assert "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing" in markdown, markdown
assert "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes" in markdown, markdown
assert "### Cross-Repo Validation Actions: `planningops-local-inbox-consumer-20260401T103000Z`" in markdown, markdown
assert "1. local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)" in markdown, markdown
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_WITH_CROSS_REPO_REPORT_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_WITH_CROSS_REPO_REPORT_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert [record["artifact_family"] for record in records] == [
    "monday_local_operator_stack_report",
    "operator_handoff_report",
    "monday_local_mission_packet",
    "monday_local_operator_day_packet",
    "monday_local_operator_inbox_payload",
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
    "monday_local_inbox_bridge_schema_validation",
    "monday_local_inbox_consumer_schema_validation",
    "cross_repo_validation_report",
], records

cross_repo_report = records[10]
assert cross_repo_report["freshness_state"] == "fresh", cross_repo_report
assert cross_repo_report["promotability_status"] == "promotable", cross_repo_report
assert cross_repo_report["promoted_id"] == "cross-repo-validation-20260401T110000Z", cross_repo_report
assert cross_repo_report["dependency_states"] == {
    "monday_local_inbox_launch_request": "current",
    "monday_local_inbox_runtime_report": "current",
    "monday_local_inbox_consumer_report": "current",
    "monday_local_inbox_bridge_schema_validation": "current",
    "monday_local_inbox_consumer_schema_validation": "current",
}, cross_repo_report
assert cross_repo_report["reasons"] == [], cross_repo_report
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --artifact-family cross_repo_validation_report \
  --promotability-status promotable \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_CROSS_REPO_REPORT_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_CROSS_REPO_REPORT_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["artifact_family"] == "cross_repo_validation_report", record
assert record["freshness_state"] == "fresh", record
assert record["promotability_status"] == "promotable", record
assert record["reasons"] == [], record
PY

python3 "$QUERY_PATH" triage-feed \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_FEED_WITH_CROSS_REPO_VALIDATION_OUTPUT"

python3 - <<'PY' "$TRIAGE_FEED_WITH_CROSS_REPO_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["cross_repo_validation_snapshot_status"] == "present", record
assert record["cross_repo_validation_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", record
assert record["monday_source_validation_status"] == "attention", record
assert record["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", record
assert record["cross_repo_validation_action_line"] == (
    "local-validation: repair monday_local_inbox_runtime_report "
    "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
), record
assert record["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    "mirror: monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["monday_source_validation_report_lines"] == [
    "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
    "source: bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
], record
assert record["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
    "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
], record
assert record["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", record
assert record["cross_repo_validation_packet_path"].endswith("/cross-repo-validation-report.json"), record
PY

python3 "$QUERY_PATH" triage-brief \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_BRIEF_WITH_CROSS_REPO_VALIDATION_OUTPUT"

python3 - <<'PY' "$TRIAGE_BRIEF_WITH_CROSS_REPO_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["cross_repo_validation_snapshot_status"] == "present", record
assert record["cross_repo_validation_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", record
assert record["monday_source_validation_status"] == "attention", record
assert record["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", record
assert record["cross_repo_validation_action_line"] == (
    "local-validation: repair monday_local_inbox_runtime_report "
    "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
), record
assert record["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    "mirror: monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["monday_source_validation_report_lines"] == [
    "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
    "source: bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
], record
assert record["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
    "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
], record
assert record["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", record
assert record["cross_repo_validation_packet_path"].endswith("/cross-repo-validation-report.json"), record
PY

python3 "$QUERY_PATH" triage-report \
  --format json \
  --ci-root "$CI_DIR" \
  --validation-root "$VALIDATION_DIR" \
  --conformance-root "$CONFORMANCE_DIR" \
  --local-root "$LOCAL_OPERATOR_DIR" \
  --consumer-root "$MONDAY_CONSUMER_DIR" \
  --monday-validation-root "$MONDAY_VALIDATION_DIR" >"$TRIAGE_REPORT_WITH_CROSS_REPO_VALIDATION_OUTPUT"

python3 - <<'PY' "$TRIAGE_REPORT_WITH_CROSS_REPO_VALIDATION_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
record = doc["record"]
assert record["cross_repo_validation_snapshot_status"] == "present", record
assert record["cross_repo_validation_snapshot_summary"] == "total=5 promotable=3 blocked=2 stale=0", record
assert record["monday_source_validation_status"] == "attention", record
assert record["monday_source_validation_summary"] == "total=2 pass=1 fail=1 errors=2 warnings=1", record
assert record["cross_repo_validation_action_line"] == (
    "local-validation: repair monday_local_inbox_runtime_report "
    "(freshness=fresh, promotability=blocked, reasons=source_artifact_missing)"
), record
assert record["cross_repo_validation_detail_lines"] == [
    "mirror: monday_local_inbox_launch_request: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current",
    "mirror: monday_local_inbox_consumer_report: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current,monday_local_inbox_launch_request=current,monday_local_inbox_runtime_report=current",
    "mirror: monday_local_inbox_bridge_schema_validation: freshness=fresh promotability=promotable dependencies=monday_local_operator_inbox_payload=current",
    "mirror: monday_local_inbox_consumer_schema_validation: freshness=fresh promotability=blocked reasons=validation_verdict_fail,validation_errors_present dependencies=monday_local_inbox_consumer_report=current",
], record
assert record["monday_source_validation_report_lines"] == [
    "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes",
    "source: bridge: verdict=pass errors=0 warnings=0 artifact_exists=yes schema_exists=yes",
], record
assert record["cross_repo_validation_action_lines"] == [
    "local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)",
    "local-validation: repair monday_local_inbox_consumer_schema_validation (freshness=fresh, promotability=blocked, reasons=validation_verdict_fail,validation_errors_present)",
    "monday-validation: inspect consumer-report source report (verdict=fail, errors=2, warnings=1)",
], record
assert record["cross_repo_validation_packet_report_id"] == "cross-repo-validation-20260401T110000Z", record
assert record["cross_repo_validation_packet_path"].endswith("/cross-repo-validation-report.json"), record
assert "### Cross-Repo Validation" in record["markdown"], record
assert "snapshot summary: `total=5 promotable=3 blocked=2 stale=0`" in record["markdown"], record
assert "monday source validation summary: `total=2 pass=1 fail=1 errors=2 warnings=1`" in record["markdown"], record
assert "### Cross-Repo Validation Details" in record["markdown"], record
assert "### Cross-Repo Validation Actions" in record["markdown"], record
assert "mirror: monday_local_inbox_runtime_report: freshness=fresh promotability=blocked reasons=source_artifact_missing" in record["markdown"], record
assert "source: consumer-report: verdict=fail errors=2 warnings=1 artifact_exists=yes schema_exists=yes" in record["markdown"], record
assert "1. local-validation: repair monday_local_inbox_runtime_report (freshness=fresh, promotability=blocked, reasons=source_artifact_missing)" in record["markdown"], record
assert "detail packet report id: `cross-repo-validation-20260401T110000Z`" in record["markdown"], record
assert "detail packet path: `" in record["markdown"], record
PY

python3 "$QUERY_PATH" local-validation-freshness \
  --artifact-family monday_local_inbox_runtime_report \
  --promotability-status blocked \
  --has-reason source_artifact_missing \
  --format json \
  --validation-root "$VALIDATION_DIR" >"$LOCAL_VALIDATION_RUNTIME_BLOCKED_OUTPUT"

python3 - <<'PY' "$LOCAL_VALIDATION_RUNTIME_BLOCKED_OUTPUT"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
records = doc["records"]
assert len(records) == 1, records
record = records[0]
assert record["artifact_family"] == "monday_local_inbox_runtime_report", record
assert record["freshness_state"] == "fresh", record
assert record["promotability_status"] == "blocked", record
assert record["reasons"] == ["source_artifact_missing"], record
PY

echo "query federated ci artifacts ok"
