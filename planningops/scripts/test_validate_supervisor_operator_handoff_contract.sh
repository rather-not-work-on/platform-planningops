#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

report="$tmpdir/operator-report.json"
payload="$tmpdir/inbox-payload.json"
summary_md="$tmpdir/operator-summary.md"
validation="$tmpdir/handoff-validation.json"
bundle="$tmpdir/handoff-bundle.json"
bundle_validation="$tmpdir/handoff-bundle-validation.json"
bundle_readiness="$tmpdir/handoff-bundle-readiness.json"
bundle_readiness_validation="$tmpdir/handoff-bundle-readiness-validation.json"

cat >"$report" <<'JSON'
{
  "generated_at_utc": "2026-03-20T01:02:03+00:00",
  "run_id": "supervisor-handoff-validator-test",
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

python3 - <<'PY' "$report" "$validation" "$bundle" "$bundle_validation" "$bundle_readiness" "$bundle_readiness_validation"
from pathlib import Path
import sys

report_path = Path(sys.argv[1])
text = report_path.read_text(encoding="utf-8")
replacements = {
    "HANDOFF_VALIDATION_PLACEHOLDER": str(Path(sys.argv[2]).resolve()),
    "HANDOFF_BUNDLE_PLACEHOLDER": str(Path(sys.argv[3]).resolve()),
    "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER": str(Path(sys.argv[4]).resolve()),
    "HANDOFF_BUNDLE_READINESS_PLACEHOLDER": str(Path(sys.argv[5]).resolve()),
    "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER": str(Path(sys.argv[6]).resolve()),
}
for before, after in replacements.items():
    text = text.replace(before, after)
report_path.write_text(text, encoding="utf-8")
PY

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

python3 - <<'PY' "$payload" "$summary_md" "$validation" "$bundle" "$bundle_validation" "$bundle_readiness" "$bundle_readiness_validation"
from pathlib import Path
import sys

replacements = {
    "HANDOFF_VALIDATION_PLACEHOLDER": str(Path(sys.argv[3]).resolve()),
    "HANDOFF_BUNDLE_PLACEHOLDER": str(Path(sys.argv[4]).resolve()),
    "HANDOFF_BUNDLE_VALIDATION_PLACEHOLDER": str(Path(sys.argv[5]).resolve()),
    "HANDOFF_BUNDLE_READINESS_PLACEHOLDER": str(Path(sys.argv[6]).resolve()),
    "HANDOFF_BUNDLE_READINESS_VALIDATION_PLACEHOLDER": str(Path(sys.argv[7]).resolve()),
}
for raw_path in sys.argv[1:3]:
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

python3 - <<'PY' "$validation" "$validation" "$bundle" "$bundle_validation" "$bundle_readiness" "$bundle_readiness_validation"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert doc["verdict"] == "pass", doc
assert doc["error_count"] == 0, doc
assert Path(doc["operator_handoff_validation_path"]).resolve() == Path(sys.argv[2]).resolve(), doc
assert Path(doc["operator_handoff_bundle_path"]).resolve() == Path(sys.argv[3]).resolve(), doc
assert Path(doc["operator_handoff_bundle_validation_path"]).resolve() == Path(sys.argv[4]).resolve(), doc
assert Path(doc["operator_handoff_bundle_readiness_path"]).resolve() == Path(sys.argv[5]).resolve(), doc
assert Path(doc["operator_handoff_bundle_readiness_validation_path"]).resolve() == Path(sys.argv[6]).resolve(), doc
assert doc["priority_preview_ref"] == "/tmp/operator-priority-preview.json", doc
assert doc["priority_display_packet_ref"] == "/tmp/operator-priority-display-packet.json", doc
PY

python3 - <<'PY' "$payload"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
doc = json.loads(path.read_text(encoding="utf-8"))
doc["priority_headline"] = "Mismatched CTA headline"
path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 planningops/scripts/validate_supervisor_operator_handoff.py \
  --operator-report "$report" \
  --inbox-payload "$payload" \
  --operator-summary "$summary_md" \
  --output "$validation" \
  --strict >/dev/null 2>&1; then
  echo "expected validator to fail on mismatched priority_headline" >&2
  exit 1
fi

python3 - <<'PY' "$validation"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert doc["verdict"] == "fail", doc
assert "priority_headline must match operator-report.priority_headline" in doc["errors"], doc
PY

echo "validate supervisor operator handoff contract ok"
