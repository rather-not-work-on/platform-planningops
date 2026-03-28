#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

report="$tmpdir/operator-report.json"
payload="$tmpdir/inbox-payload.json"
summary_md="$tmpdir/operator-summary.md"
validation="$tmpdir/operator-handoff-validation.json"
bundle="$tmpdir/operator-handoff-bundle.json"
bundle_validation="$tmpdir/operator-handoff-bundle-validation.json"
bundle_readiness="$tmpdir/operator-handoff-bundle-readiness.json"
bundle_readiness_validation="$tmpdir/operator-handoff-bundle-readiness-validation.json"
artifact="$tmpdir/wrapper.json"
resolved_from_artifact="$tmpdir/resolved-from-artifact.json"
resolved_from_ref="$tmpdir/resolved-from-ref.json"
conflicting_artifact="$tmpdir/conflicting-wrapper.json"
conflicting_stderr="$tmpdir/conflicting.stderr.log"

cat >"$report" <<'JSON'
{
  "generated_at_utc": "2026-03-20T01:02:03+00:00",
  "run_id": "supervisor-handoff-resolver-test",
  "summary_path": "/tmp/supervisor-summary.json",
  "cycle_report_path": null,
  "supervisor_verdict": "pass",
  "stop_reason": "converged",
  "status": "ok",
  "headline": "Supervisor run converged with live project data.",
  "priority_headline": "Supervisor run converged with live project data.",
  "operator_action": "none",
  "recommended_wait_minutes": 0,
  "retry_mode": "none",
  "allowed_modes": [],
  "blocked_modes": [],
  "needs_human_attention": false,
  "reason": "No cooldown or retry guidance required.",
  "guidance": {},
  "message_class_hint": "status_update",
  "handoff_contract_ref": "planningops/contracts/supervisor-operator-handoff-contract.md",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "/tmp/operator-priority-preview.json",
  "priority_display_packet_ref": "/tmp/operator-priority-display-packet.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER",
  "priority_summary_markdown": "## Priority\n- headline: Supervisor run converged with live project data."
}
JSON

cat >"$payload" <<JSON
{
  "generated_at_utc": "2026-03-20T01:02:04+00:00",
  "title": "[OK] Supervisor run converged with live project data.",
  "status": "ok",
  "headline": "Supervisor run converged with live project data.",
  "priority_headline": "Supervisor run converged with live project data.",
  "operator_action": "none",
  "recommended_wait_minutes": 0,
  "retry_mode": "none",
  "needs_human_attention": false,
  "attachments": [
    "$summary_md",
    "/tmp/supervisor-summary.json",
    "$validation",
    "$bundle",
    "$bundle_validation",
    "$bundle_readiness",
    "$bundle_readiness_validation"
  ],
  "body_markdown": "Status: ok\n\n## Priority\n- headline: Supervisor run converged with live project data.\n",
  "message_class_hint": "status_update",
  "handoff_contract_ref": "planningops/contracts/supervisor-operator-handoff-contract.md",
  "priority_summary_markdown": "## Priority\n- headline: Supervisor run converged with live project data.",
  "operator_handoff_validation_path": "HANDOFF_VALIDATION_PLACEHOLDER",
  "priority_preview_ref": "/tmp/operator-priority-preview.json",
  "priority_display_packet_ref": "/tmp/operator-priority-display-packet.json",
  "operator_handoff_bundle_path": "HANDOFF_BUNDLE_PLACEHOLDER",
  "operator_handoff_bundle_validation_path": "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER",
  "operator_handoff_bundle_readiness_path": "HANDOFF_BUNDLE_READINESS_PLACEHOLDER",
  "operator_handoff_bundle_readiness_validation_path": "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER"
}
JSON

cat >"$summary_md" <<MD
# Supervisor Operator Summary

- Status: ok
- Headline: Supervisor run converged with live project data.

## Priority
- headline: Supervisor run converged with live project data.

- Handoff Validation Path: HANDOFF_VALIDATION_PLACEHOLDER
- Handoff Bundle Path: HANDOFF_BUNDLE_PLACEHOLDER
- Handoff Bundle Validation Path: HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER
- Handoff Bundle Readiness Path: HANDOFF_BUNDLE_READINESS_PLACEHOLDER
- Handoff Bundle Readiness Validation Path: HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER
MD

python3 - <<'PY' "$report" "$payload" "$summary_md" "$validation" "$bundle" "$bundle_validation" "$bundle_readiness" "$bundle_readiness_validation"
from pathlib import Path
import sys

replacements = {
    "HANDOFF_VALIDATION_PLACEHOLDER": str(Path(sys.argv[4]).resolve()),
    "HANDOFF_BUNDLE_PLACEHOLDER": str(Path(sys.argv[5]).resolve()),
    "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER": str(Path(sys.argv[6]).resolve()),
    "HANDOFF_BUNDLE_READINESS_PLACEHOLDER": str(Path(sys.argv[7]).resolve()),
    "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER": str(Path(sys.argv[8]).resolve()),
}
for raw_path in sys.argv[1:4]:
    path = Path(raw_path)
    text = path.read_text(encoding="utf-8")
    for before, after in replacements.items():
        text = text.replace(before, after)
    path.write_text(text, encoding="utf-8")
PY

python3 planningops/scripts/validate_supervisor_operator_handoff.py \
  --operator-report "$report" \
  --inbox-payload "$payload" \
  --operator-summary "$summary_md" \
  --output "$validation" \
  --strict

cat >"$artifact" <<JSON
{
  "operator_handoff_validation_path": "$validation",
  "delegate_report": {
    "delivery_report": {
      "operatorHandoffValidationPath": "$validation"
    }
  }
}
JSON

python3 planningops/scripts/resolve_supervisor_operator_handoff_validation.py \
  --artifact-file "$artifact" \
  --output "$resolved_from_artifact" >/dev/null

python3 planningops/scripts/resolve_supervisor_operator_handoff_validation.py \
  --validation-report-path "$validation" \
  --output "$resolved_from_ref" >/dev/null

python3 - <<'PY' "$validation" "$resolved_from_artifact" "$resolved_from_ref"
import json
import sys
from pathlib import Path

canonical = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
from_artifact = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
from_ref = json.loads(Path(sys.argv[3]).read_text(encoding="utf-8"))

assert canonical["verdict"] == "pass", canonical
assert from_artifact["verdict"] == "pass", from_artifact
assert from_ref["verdict"] == "pass", from_ref

artifact_doc = dict(from_artifact)
artifact_doc.pop("resolved_operator_handoff_validation_path", None)
ref_doc = dict(from_ref)
ref_doc.pop("resolved_operator_handoff_validation_path", None)
assert artifact_doc == canonical, (artifact_doc, canonical)
assert ref_doc == canonical, (ref_doc, canonical)
PY

cat >"$conflicting_artifact" <<JSON
{
  "operator_handoff_validation_path": "$validation",
  "delegate_report": {
    "delivery_report": {
      "operatorHandoffValidationPath": "$tmpdir/conflicting-operator-handoff-validation.json"
    }
  }
}
JSON

if python3 planningops/scripts/resolve_supervisor_operator_handoff_validation.py \
  --artifact-file "$conflicting_artifact" \
  --output "$tmpdir/should-not-exist.json" >/dev/null 2>"$conflicting_stderr"; then
  echo "expected conflicting operator_handoff_validation_path values to fail" >&2
  exit 1
fi

grep -q "conflicting operator_handoff_validation_path values" "$conflicting_stderr"

echo "resolve supervisor operator handoff validation regression passed"
