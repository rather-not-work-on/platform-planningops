#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

READINESS="${TMP_DIR}/handoff-bundle-readiness.json"
REPORT="${TMP_DIR}/handoff-bundle-readiness-validation.json"
BROKEN="${TMP_DIR}/handoff-bundle-readiness-broken.json"
BROKEN_REPORT="${TMP_DIR}/handoff-bundle-readiness-broken-validation.json"
HANDOFF_BUNDLE="${TMP_DIR}/operator-handoff-bundle.json"
HANDOFF_BUNDLE_VALIDATION="${TMP_DIR}/operator-handoff-bundle-validation.json"
HANDOFF_BUNDLE_READINESS="${TMP_DIR}/operator-handoff-bundle-readiness.json"
HANDOFF_BUNDLE_READINESS_VALIDATION="${TMP_DIR}/operator-handoff-bundle-readiness-validation.json"

cat >"${READINESS}" <<'JSON'
{
  "generated_at_utc": "2026-03-20T00:00:00Z",
  "source_kind": "artifact",
  "artifact_file": "/tmp/supervisor-wrapper.json",
  "bundle_path": null,
  "validation_report_path": "/tmp/handoff-bundle-validation.json",
  "bundle_generated_at_utc": "2026-03-20T00:00:01Z",
  "validation_generated_at_utc": "2026-03-20T00:00:02Z",
  "bundle_validation_verdict": "pass",
  "operator_handoff_validation_verdict": "pass",
  "operator_handoff_bundle_path": "__HANDOFF_BUNDLE__",
  "operator_handoff_bundle_validation_path": "__HANDOFF_BUNDLE_VALIDATION__",
  "operator_handoff_bundle_readiness_path": "__HANDOFF_BUNDLE_READINESS__",
  "operator_handoff_bundle_readiness_validation_path": "__HANDOFF_BUNDLE_READINESS_VALIDATION__",
  "priority_preview_ref": "runtime-artifacts/messaging/operator-priority-previews/sample.json",
  "priority_display_packet_ref": "runtime-artifacts/messaging/operator-priority-displays/sample.json",
  "priority_headline": "Readiness headline.",
  "priority_cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "display_title": "Readiness headline.",
  "cta_command": "python3 planningops/scripts/doctor_federated_ci_summary.py --require-pass",
  "error_count": 0,
  "warning_count": 0,
  "errors": [],
  "warnings": [],
  "ready": true,
  "readiness_status": "ready",
  "blocking_reasons": [],
  "next_step": "none"
}
JSON

python3 - <<'PY' "${READINESS}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE_READINESS}" "${HANDOFF_BUNDLE_READINESS_VALIDATION}"
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = text.replace("__HANDOFF_BUNDLE__", str(Path(sys.argv[2]).resolve()))
text = text.replace("__HANDOFF_BUNDLE_VALIDATION__", str(Path(sys.argv[3]).resolve()))
text = text.replace("__HANDOFF_BUNDLE_READINESS__", str(Path(sys.argv[4]).resolve()))
text = text.replace("__HANDOFF_BUNDLE_READINESS_VALIDATION__", str(Path(sys.argv[5]).resolve()))
path.write_text(text, encoding="utf-8")
PY

python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "${READINESS}" \
  --output "${REPORT}" \
  --strict >/dev/null

python3 - <<'PY' "${REPORT}" "${HANDOFF_BUNDLE}" "${HANDOFF_BUNDLE_VALIDATION}" "${HANDOFF_BUNDLE_READINESS}" "${HANDOFF_BUNDLE_READINESS_VALIDATION}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["readiness_status"] == "ready", report
assert report["readiness_ready"] is True, report
assert Path(report["operator_handoff_bundle_path"]).resolve() == Path(sys.argv[2]).resolve(), report
assert Path(report["operator_handoff_bundle_validation_path"]).resolve() == Path(sys.argv[3]).resolve(), report
assert Path(report["operator_handoff_bundle_readiness_path"]).resolve() == Path(sys.argv[4]).resolve(), report
assert Path(report["operator_handoff_bundle_readiness_validation_path"]).resolve() == Path(sys.argv[5]).resolve(), report
PY

python3 - <<'PY' "${READINESS}" "${BROKEN}"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = True
doc["readiness_status"] = "blocked"
doc["blocking_reasons"] = ["bundle_validation_fail"]
doc["next_step"] = "python3 planningops/scripts/validate_supervisor_operator_handoff_bundle.py --artifact-file /tmp/supervisor-wrapper.json --output <handoff-bundle-validation.json> --strict"
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

if python3 "${ROOT_DIR}/planningops/scripts/validate_supervisor_operator_handoff_bundle_readiness.py" \
  --readiness "${BROKEN}" \
  --output "${BROKEN_REPORT}" \
  --strict >/dev/null 2>&1; then
  echo "expected readiness validator to fail on inconsistent ready state" >&2
  exit 1
fi

python3 - <<'PY' "${BROKEN_REPORT}"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("ready=true requires readiness_status=ready" in error for error in report["errors"]), report
PY

echo "validate supervisor operator handoff bundle readiness ok"
