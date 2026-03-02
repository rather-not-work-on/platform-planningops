#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKSPACE_DIR="$(cd "${ROOT_DIR}/.." && pwd)"
RUN_ID="${1:-federated-ci-$(date -u +%Y%m%dT%H%M%SZ)}"

OUT_DIR="${ROOT_DIR}/planningops/artifacts/ci"
mkdir -p "${OUT_DIR}"
LATEST_PATH="${OUT_DIR}/federated-ci-summary.json"
STAMPED_PATH="${OUT_DIR}/${RUN_ID}.json"

run_check() {
  local check_name="$1"
  local domain="$2"
  shift 2
  local cmd=("$@")
  local stdout_file="${OUT_DIR}/${RUN_ID}-${check_name}.stdout.log"
  local stderr_file="${OUT_DIR}/${RUN_ID}-${check_name}.stderr.log"

  set +e
  "${cmd[@]}" >"${stdout_file}" 2>"${stderr_file}"
  local rc=$?
  set -e

  python3 - <<PY
import json
from pathlib import Path
summary_path = Path("${OUT_DIR}/${RUN_ID}.tmp.json")
doc = {"checks": []}
if summary_path.exists():
    doc = json.loads(summary_path.read_text(encoding="utf-8"))
doc["checks"].append({
    "name": "${check_name}",
    "domain": "${domain}",
    "exit_code": ${rc},
    "verdict": "pass" if ${rc} == 0 else "fail",
    "stdout_log": "${stdout_file}",
    "stderr_log": "${stderr_file}",
})
summary_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")
PY
}

run_check "contract-conformance" "contract" \
  python3 "${ROOT_DIR}/planningops/scripts/cross_repo_conformance_check.py" --run-id "${RUN_ID}-contract"

run_check "provider-profile" "infra" \
  bash -lc "cd '${WORKSPACE_DIR}/platform-provider-gateway' && bash scripts/litellm_stack_launcher.sh --mode dry-run --profiles local,oracle_cloud --run-id '${RUN_ID}-provider'"

run_check "o11y-replay" "infra" \
  bash -lc "cd '${WORKSPACE_DIR}/platform-observability-gateway' && bash scripts/langfuse_stack_launcher.sh --mode dry-run --run-id '${RUN_ID}-o11y'"

run_check "runtime-handoff" "runtime" \
  bash -lc "cd '${WORKSPACE_DIR}/monday' && python3 scripts/integrate_planningops_handoff.py --run-id '${RUN_ID}-runtime' --idempotency artifacts/integration/${RUN_ID}-idempotency.json --transition-log artifacts/integration/${RUN_ID}-scheduler.ndjson"

run_check "loop-guardrails" "policy" \
  bash -lc "cd '${ROOT_DIR}' && python3 planningops/scripts/run_track1_gate_dryrun.py --kpi-path planningops/fixtures/track1-kpi-baseline-ci.json --strict && bash planningops/scripts/test_track1_gate_dryrun_contract.sh && bash planningops/scripts/test_bootstrap_two_track_backlog_contract.sh && bash planningops/scripts/test_issue_loop_runner_multi_repo_intake.sh && bash planningops/scripts/test_loop_checkpoint_resume.sh && bash planningops/scripts/test_lease_lock_watchdog.sh && bash planningops/scripts/test_escalation_gate.sh"

python3 - <<PY
import json
from datetime import datetime, timezone
from pathlib import Path

tmp_path = Path("${OUT_DIR}/${RUN_ID}.tmp.json")
doc = json.loads(tmp_path.read_text(encoding="utf-8"))
checks = doc.get("checks", [])
failures = [c for c in checks if c.get("verdict") == "fail"]
doc["generated_at_utc"] = datetime.now(timezone.utc).isoformat()
doc["run_id"] = "${RUN_ID}"
doc["required_checks"] = [
    "contract-conformance",
    "runtime-handoff",
    "o11y-replay",
    "provider-profile",
    "loop-guardrails",
]
doc["failure_classification"] = {
    "count": len(failures),
    "domains": sorted({f.get("domain") for f in failures}),
    "deterministic_rule": "contract-conformance->contract, provider-profile/o11y-replay->infra, runtime-handoff->runtime, loop-guardrails->policy",
}
doc["verdict"] = "pass" if not failures else "fail"

for out in ["${LATEST_PATH}", "${STAMPED_PATH}"]:
    Path(out).write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")
tmp_path.unlink(missing_ok=True)

print(f"federated summary written: ${STAMPED_PATH}")
print(f"federated summary written: ${LATEST_PATH}")
print(f"verdict={doc['verdict']} failure_count={len(failures)}")
PY
