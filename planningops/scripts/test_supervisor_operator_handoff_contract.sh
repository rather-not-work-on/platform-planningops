#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

run_id="supervisor-handoff-contract"
summary_path="$tmpdir/summary.json"
artifacts_root="$tmpdir/artifacts"
goal_registry="$tmpdir/goal-registry.json"
federated_summary="$tmpdir/federated-ci-summary.json"
federated_readiness="$tmpdir/federated-ci-summary-readiness.json"
federated_readiness_blocked="$tmpdir/federated-ci-summary-readiness-blocked.json"

cat >"$goal_registry" <<'JSON'
{
  "registry_version": 1,
  "active_goal_key": "goal-a",
  "goals": [
    {
      "goal_key": "goal-a",
      "title": "Goal A",
      "status": "active",
      "owner_repo": "rather-not-work-on/platform-planningops",
      "goal_brief_ref": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1-goal-brief.md",
      "execution_contract_file": "docs/workbench/unified-personal-agent-platform/plans/2026-03-13-goal-driven-autonomy-wave1.execution-contract.json",
      "completion_contract_refs": [
        "planningops/contracts/goal-completion-contract.md"
      ],
      "operator_channels": {
        "primary_operator_channel": {
          "kind": "slack_skill_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        },
        "terminal_notification_channel": {
          "kind": "email_cli",
          "execution_repo": "rather-not-work-on/monday",
          "adapter_contract_ref": "planningops/contracts/operator-channel-adapter-contract.md"
        }
      }
    }
  ]
}
JSON

cat >"$federated_readiness_blocked" <<JSON
{
  "generated_at_utc": "2026-03-19T11:42:14.545303+00:00",
  "summary_path": "$federated_summary",
  "validation_report_path": "/tmp/federated-ci-summary-validation.json",
  "summary_present": true,
  "validation_present": true,
  "summary_run_id": "federated-ci-runtime-gates-test",
  "summary_generated_at_utc": "2026-03-19T11:42:10.341286+00:00",
  "summary_verdict": "pass",
  "overall_status": "complete",
  "check_count": 7,
  "failed_checks": [],
  "missing_required_checks": [],
  "validation_verdict": "pass",
  "validation_state": "fresh",
  "ready": false,
  "readiness_status": "blocked",
  "blocking_reasons": ["runtime-operations-ready"],
  "next_step": "bash planningops/scripts/gate_federated_ci_summary.sh"
}
JSON

cat >"$federated_summary" <<'JSON'
{
  "run_id": "federated-ci-runtime-gates-test",
  "generated_at_utc": "2026-03-19T11:42:10.341286+00:00",
  "verdict": "pass",
  "overall_status": "complete",
  "check_count": 7
}
JSON

cat >"$federated_readiness" <<JSON
{
  "generated_at_utc": "2026-03-19T11:42:14.545303+00:00",
  "summary_path": "$federated_summary",
  "validation_report_path": "/tmp/federated-ci-summary-validation.json",
  "summary_present": true,
  "validation_present": true,
  "summary_run_id": "federated-ci-runtime-gates-test",
  "summary_generated_at_utc": "2026-03-19T11:42:10.341286+00:00",
  "summary_verdict": "pass",
  "overall_status": "complete",
  "check_count": 7,
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

python3 planningops/scripts/autonomous_supervisor_loop.py \
  --mode dry-run \
  --max-cycles 3 \
  --convergence-pass-streak 2 \
  --continue-on-experiment \
  --items-file planningops/fixtures/backlog-stock-items-sample.json \
  --offline \
  --active-goal-registry "$goal_registry" \
  --loop-result-sequence-file planningops/fixtures/supervisor-loop-sequence-sample.json \
  --federated-ci-summary "$federated_summary" \
  --federated-ci-summary-readiness "$federated_readiness" \
  --run-id "$run_id" \
  --artifacts-root "$artifacts_root" \
  --output "$summary_path" >/dev/null 2>&1 || true

operator_report="$artifacts_root/$run_id/operator-report.json"
operator_summary="$artifacts_root/$run_id/operator-summary.md"
inbox_payload="$artifacts_root/$run_id/inbox-payload.json"
operator_summary_last="${summary_path%.json}-operator-summary.md"
blocked_summary_path="$tmpdir/summary-blocked.json"
blocked_run_id="${run_id}-blocked"
blocked_operator_report="$artifacts_root/$blocked_run_id/operator-report.json"
blocked_operator_summary="$artifacts_root/$blocked_run_id/operator-summary.md"
blocked_inbox_payload="$artifacts_root/$blocked_run_id/inbox-payload.json"
blocked_operator_summary_last="${blocked_summary_path%.json}-operator-summary.md"

python3 planningops/scripts/autonomous_supervisor_loop.py \
  --mode dry-run \
  --max-cycles 3 \
  --convergence-pass-streak 2 \
  --continue-on-experiment \
  --items-file planningops/fixtures/backlog-stock-items-sample.json \
  --offline \
  --active-goal-registry "$goal_registry" \
  --loop-result-sequence-file planningops/fixtures/supervisor-loop-sequence-sample.json \
  --federated-ci-summary "$federated_summary" \
  --federated-ci-summary-readiness "$federated_readiness_blocked" \
  --run-id "$blocked_run_id" \
  --artifacts-root "$artifacts_root" \
  --output "$blocked_summary_path" >/dev/null 2>&1 || true

python3 - <<'PY' "$summary_path" "$operator_report" "$operator_summary" "$inbox_payload" "$blocked_summary_path" "$blocked_operator_report" "$blocked_operator_summary" "$blocked_inbox_payload"
import json
import sys
from pathlib import Path

summary_path = Path(sys.argv[1])
operator_report_path = Path(sys.argv[2])
operator_summary_path = Path(sys.argv[3])
inbox_payload_path = Path(sys.argv[4])
blocked_summary_path = Path(sys.argv[5])
blocked_operator_report_path = Path(sys.argv[6])
blocked_operator_summary_path = Path(sys.argv[7])
blocked_inbox_payload_path = Path(sys.argv[8])

summary = json.loads(summary_path.read_text(encoding="utf-8"))
operator_report = json.loads(operator_report_path.read_text(encoding="utf-8"))
inbox_payload = json.loads(inbox_payload_path.read_text(encoding="utf-8"))
operator_summary = operator_summary_path.read_text(encoding="utf-8")
blocked_summary = json.loads(blocked_summary_path.read_text(encoding="utf-8"))
blocked_operator_report = json.loads(blocked_operator_report_path.read_text(encoding="utf-8"))
blocked_inbox_payload = json.loads(blocked_inbox_payload_path.read_text(encoding="utf-8"))
blocked_operator_summary = blocked_operator_summary_path.read_text(encoding="utf-8")
contract_text = Path("planningops/contracts/supervisor-operator-handoff-contract.md").read_text(encoding="utf-8")

assert Path("planningops/contracts/supervisor-operator-handoff-contract.md").exists()
assert "priority_display_packet_ref" in contract_text, contract_text
assert "priority_preview_ref" in contract_text, contract_text
assert "operator_handoff_bundle_path" in contract_text, contract_text
assert "operator_handoff_bundle_validation_path" in contract_text, contract_text
assert "operator_handoff_bundle_readiness_path" in contract_text, contract_text
assert "operator_handoff_bundle_readiness_validation_path" in contract_text, contract_text
assert "resolve_supervisor_operator_handoff_bundle.py" in contract_text, contract_text
assert "validate_supervisor_operator_handoff_bundle.py" in contract_text, contract_text
assert "assess_supervisor_operator_handoff_bundle_readiness.py" in contract_text, contract_text
assert "validate_supervisor_operator_handoff_bundle_readiness.py" in contract_text, contract_text
assert "doctor_supervisor_operator_handoff_bundle.py" in contract_text, contract_text
assert "gate_supervisor_operator_handoff_bundle.sh" in contract_text, contract_text
assert "resolve_operator_priority_preview.py" in contract_text, contract_text
assert "resolve_operator_priority_display_packet.py" in contract_text, contract_text
assert "validate_supervisor_operator_handoff.py" in contract_text, contract_text
assert "supervisor-operator-report.schema.json" in contract_text, contract_text
assert "supervisor-inbox-payload.schema.json" in contract_text, contract_text
assert "operator-handoff-validation.json" in contract_text, contract_text
assert "must fail closed" in contract_text, contract_text
assert operator_report["run_id"] == summary["run_id"], operator_report
assert operator_report["handoff_contract_ref"] == "planningops/contracts/supervisor-operator-handoff-contract.md", operator_report
assert operator_report["message_class_hint"] in {"status_update", "decision_request", "blocked_report", "goal_completed"}, operator_report
assert operator_report["goal_key"], operator_report
assert operator_report["primary_operator_channel"]["kind"].startswith("slack_skill"), operator_report
assert operator_report["terminal_notification_channel"]["kind"].startswith("email"), operator_report
assert operator_report["federated_ci_summary"]["summary_run_id"] == "federated-ci-runtime-gates-test", operator_report
assert operator_report["federated_ci_summary"]["ready"] is True, operator_report
assert operator_report["federated_ci_summary"]["remediation_commands"] == [], operator_report
assert operator_report["priority_headline"] == operator_report["headline"], operator_report
assert operator_report["priority_preview_ref"] == summary["operator_priority_preview_last_path"], operator_report
assert operator_report["priority_display_packet_ref"] == summary["operator_priority_display_packet_last_path"], operator_report
assert operator_report["operator_handoff_bundle_path"] == summary["operator_handoff_bundle_last_path"], operator_report
assert operator_report["operator_handoff_bundle_validation_path"] == summary["operator_handoff_bundle_validation_last_path"], operator_report
assert operator_report["operator_handoff_bundle_readiness_path"] == summary["operator_handoff_bundle_readiness_last_path"], operator_report
assert operator_report["operator_handoff_bundle_readiness_validation_path"] == summary["operator_handoff_bundle_readiness_validation_last_path"], operator_report
assert "## Priority" in operator_report["priority_summary_markdown"], operator_report
assert summary["operator_handoff_validation_path"].endswith("operator-handoff-validation.json"), summary
assert summary["operator_handoff_validation_last_path"].endswith("-operator-handoff-validation.json"), summary
handoff_validation = json.loads(Path(summary["operator_handoff_validation_last_path"]).read_text(encoding="utf-8"))
assert handoff_validation["verdict"] == "pass", handoff_validation

assert inbox_payload["handoff_contract_ref"] == operator_report["handoff_contract_ref"], inbox_payload
assert inbox_payload["goal_key"] == operator_report["goal_key"], inbox_payload
assert inbox_payload["message_class_hint"] == operator_report["message_class_hint"], inbox_payload
assert inbox_payload["priority_headline"] == operator_report["priority_headline"], inbox_payload
assert inbox_payload["priority_summary_markdown"] == operator_report["priority_summary_markdown"], inbox_payload
assert inbox_payload["operator_handoff_validation_path"] == summary["operator_handoff_validation_last_path"], inbox_payload
assert inbox_payload["priority_preview_ref"] == summary["operator_priority_preview_last_path"], inbox_payload
assert inbox_payload["priority_display_packet_ref"] == summary["operator_priority_display_packet_last_path"], inbox_payload
assert inbox_payload["operator_handoff_bundle_path"] == summary["operator_handoff_bundle_last_path"], inbox_payload
assert inbox_payload["operator_handoff_bundle_validation_path"] == summary["operator_handoff_bundle_validation_last_path"], inbox_payload
assert inbox_payload["operator_handoff_bundle_readiness_path"] == summary["operator_handoff_bundle_readiness_last_path"], inbox_payload
assert inbox_payload["operator_handoff_bundle_readiness_validation_path"] == summary["operator_handoff_bundle_readiness_validation_last_path"], inbox_payload
assert any(str(attachment).endswith("summary-operator-summary.md") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary.json") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary-operator-handoff-validation.json") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary-operator-handoff-bundle.json") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary-operator-handoff-bundle-validation.json") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary-operator-handoff-bundle-readiness.json") for attachment in inbox_payload["attachments"]), inbox_payload
assert any(str(attachment).endswith("summary-operator-handoff-bundle-readiness-validation.json") for attachment in inbox_payload["attachments"]), inbox_payload
assert any("federated-ci-summary-readiness.json" in str(attachment) for attachment in inbox_payload["attachments"]), inbox_payload
assert any("federated-ci-summary-validation.json" in str(attachment) for attachment in inbox_payload["attachments"]), inbox_payload

assert "# Supervisor Operator Summary" in operator_summary, operator_summary
assert "Headline:" in operator_summary, operator_summary
assert "Handoff Validation Path:" in operator_summary, operator_summary
assert "summary-operator-handoff-validation.json" in operator_summary, operator_summary
assert "## Priority" in operator_summary, operator_summary
assert "## Federated CI" in operator_summary, operator_summary

assert blocked_operator_report["run_id"] == blocked_summary["run_id"], blocked_operator_report
assert blocked_operator_report["status"] == "degraded", blocked_operator_report
assert blocked_operator_report["operator_action"] == "inspect_federated_ci_gates", blocked_operator_report
assert blocked_operator_report["federated_ci_summary"]["ready"] is False, blocked_operator_report
assert blocked_operator_report["federated_ci_summary"]["readiness_status"] == "blocked", blocked_operator_report
assert blocked_operator_report["federated_ci_summary"]["remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], blocked_operator_report
assert blocked_operator_report["federated_ci_summary"]["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", blocked_operator_report
assert blocked_operator_report["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", blocked_operator_report
assert blocked_operator_report["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", blocked_operator_report
assert blocked_operator_report["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", blocked_operator_report
assert blocked_operator_report["priority_preview_ref"] == blocked_summary["operator_priority_preview_last_path"], blocked_operator_report
assert blocked_operator_report["priority_display_packet_ref"] == blocked_summary["operator_priority_display_packet_last_path"], blocked_operator_report
assert blocked_operator_report["operator_handoff_bundle_path"] == blocked_summary["operator_handoff_bundle_last_path"], blocked_operator_report
assert blocked_operator_report["operator_handoff_bundle_validation_path"] == blocked_summary["operator_handoff_bundle_validation_last_path"], blocked_operator_report
assert blocked_operator_report["operator_handoff_bundle_readiness_path"] == blocked_summary["operator_handoff_bundle_readiness_last_path"], blocked_operator_report
assert blocked_operator_report["operator_handoff_bundle_readiness_validation_path"] == blocked_summary["operator_handoff_bundle_readiness_validation_last_path"], blocked_operator_report
assert "`python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass`" in blocked_operator_report["priority_summary_markdown"], blocked_operator_report
assert "gate_federated_ci_summary.sh" in blocked_operator_report["reason"], blocked_operator_report
assert blocked_operator_report["guidance"]["federated_ci_remediation_commands"] == [
    "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
    "bash planningops/scripts/gate_federated_ci_summary.sh",
], blocked_operator_report
assert blocked_operator_report["guidance"]["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", blocked_operator_report
assert blocked_summary["operator_handoff_validation_path"].endswith("operator-handoff-validation.json"), blocked_summary
assert blocked_summary["operator_handoff_validation_last_path"].endswith("-operator-handoff-validation.json"), blocked_summary
blocked_handoff_validation = json.loads(Path(blocked_summary["operator_handoff_validation_last_path"]).read_text(encoding="utf-8"))
assert blocked_handoff_validation["verdict"] == "pass", blocked_handoff_validation
assert blocked_inbox_payload["status"] == "degraded", blocked_inbox_payload
assert blocked_inbox_payload["first_action_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", blocked_inbox_payload
assert blocked_inbox_payload["priority_headline"] == "Supervisor converged, but the latest federated runtime gate is blocked.", blocked_inbox_payload
assert blocked_inbox_payload["priority_cta_command"] == "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass", blocked_inbox_payload
assert blocked_inbox_payload["priority_summary_markdown"] == blocked_operator_report["priority_summary_markdown"], blocked_inbox_payload
assert blocked_inbox_payload["operator_handoff_validation_path"] == blocked_summary["operator_handoff_validation_last_path"], blocked_inbox_payload
assert blocked_inbox_payload["priority_preview_ref"] == blocked_summary["operator_priority_preview_last_path"], blocked_inbox_payload
assert blocked_inbox_payload["priority_display_packet_ref"] == blocked_summary["operator_priority_display_packet_last_path"], blocked_inbox_payload
assert blocked_inbox_payload["operator_handoff_bundle_path"] == blocked_summary["operator_handoff_bundle_last_path"], blocked_inbox_payload
assert blocked_inbox_payload["operator_handoff_bundle_validation_path"] == blocked_summary["operator_handoff_bundle_validation_last_path"], blocked_inbox_payload
assert blocked_inbox_payload["operator_handoff_bundle_readiness_path"] == blocked_summary["operator_handoff_bundle_readiness_last_path"], blocked_inbox_payload
assert blocked_inbox_payload["operator_handoff_bundle_readiness_validation_path"] == blocked_summary["operator_handoff_bundle_readiness_validation_last_path"], blocked_inbox_payload
assert "inspect_federated_ci_gates" in blocked_inbox_payload["body_markdown"], blocked_inbox_payload
assert "First Action:" in blocked_inbox_payload["body_markdown"], blocked_inbox_payload
assert "doctor_federated_ci_summary.py --require-pass" in blocked_inbox_payload["body_markdown"], blocked_inbox_payload
assert any(str(attachment).endswith("summary-blocked-operator-handoff-validation.json") for attachment in blocked_inbox_payload["attachments"]), blocked_inbox_payload
assert any(str(attachment).endswith("summary-blocked-operator-handoff-bundle.json") for attachment in blocked_inbox_payload["attachments"]), blocked_inbox_payload
assert any(str(attachment).endswith("summary-blocked-operator-handoff-bundle-validation.json") for attachment in blocked_inbox_payload["attachments"]), blocked_inbox_payload
assert any(str(attachment).endswith("summary-blocked-operator-handoff-bundle-readiness.json") for attachment in blocked_inbox_payload["attachments"]), blocked_inbox_payload
assert any(str(attachment).endswith("summary-blocked-operator-handoff-bundle-readiness-validation.json") for attachment in blocked_inbox_payload["attachments"]), blocked_inbox_payload
assert any("federated-ci-summary-validation.json" in str(attachment) for attachment in blocked_inbox_payload["attachments"]), blocked_inbox_payload
assert "## Federated CI" in blocked_operator_summary, blocked_operator_summary
assert "Handoff Validation Path:" in blocked_operator_summary, blocked_operator_summary
assert "summary-blocked-operator-handoff-validation.json" in blocked_operator_summary, blocked_operator_summary
assert "## Priority" in blocked_operator_summary, blocked_operator_summary
assert "## First Action" in blocked_operator_summary, blocked_operator_summary
assert "doctor_federated_ci_summary.py --require-pass" in blocked_operator_summary, blocked_operator_summary
PY

echo "supervisor operator handoff contract ok"
