#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

readiness_path="$tmp_dir/federated-ci-summary-readiness.json"
report_path="$tmp_dir/federated-ci-summary-readiness-validation.json"

cat > "$readiness_path" <<'JSON'
{
  "generated_at_utc": "2026-03-19T00:02:00+00:00",
  "summary_path": "planningops/artifacts/ci/federated-ci-summary.json",
  "validation_report_path": "planningops/artifacts/validation/federated-ci-summary-validation.json",
  "summary_present": true,
  "validation_present": true,
  "summary_run_id": "readiness-contract-sample",
  "summary_generated_at_utc": "2026-03-19T00:01:00+00:00",
  "summary_verdict": "pass",
  "overall_status": "complete",
  "check_count": 6,
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

python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_readiness.py" \
  --readiness "$readiness_path" \
  --schema-file "$ROOT_DIR/schemas/federated-ci-summary-readiness.schema.json" \
  --output "$report_path" \
  --strict

python3 - <<'PY' "$report_path"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "pass", report
assert report["error_count"] == 0, report
assert report["readiness_generated_at_utc"] == "2026-03-19T00:02:00+00:00", report
assert report["readiness_summary_run_id"] == "readiness-contract-sample", report
assert report["readiness_status"] == "ready", report
assert report["readiness_ready"] is True, report
PY

python3 - <<'PY' "$readiness_path" "$tmp_dir/invalid-readiness.json"
import json
import sys
from pathlib import Path

doc = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
doc["ready"] = True
doc["readiness_status"] = "blocked"
doc["blocking_reasons"] = ["validation_stale"]
Path(sys.argv[2]).write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
PY

set +e
python3 "$ROOT_DIR/scripts/validate_federated_ci_summary_readiness.py" \
  --readiness "$tmp_dir/invalid-readiness.json" \
  --schema-file "$ROOT_DIR/schemas/federated-ci-summary-readiness.schema.json" \
  --output "$tmp_dir/invalid-readiness-validation.json" \
  --strict
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  echo "expected strict failure for invalid readiness report"
  exit 1
fi

python3 - <<'PY' "$tmp_dir/invalid-readiness-validation.json"
import json
import sys
from pathlib import Path

report = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
assert report["verdict"] == "fail", report
assert any("ready=true requires readiness_status=ready" in item for item in report["errors"]), report
assert any("ready=true requires no blocking_reasons" in item for item in report["errors"]), report
PY

python3 - <<'PY' "$ROOT_DIR/scripts/validate_federated_ci_summary_readiness.py" "$ROOT_DIR/.."
import importlib.util
import sys
from pathlib import Path

module_path = Path(sys.argv[1])
workspace_root = Path(sys.argv[2]).resolve()
spec = importlib.util.spec_from_file_location("validate_federated_ci_summary_readiness", module_path)
module = importlib.util.module_from_spec(spec)
assert spec is not None and spec.loader is not None
spec.loader.exec_module(module)
resolved = module.resolve_doc_path("planningops/artifacts/ci/federated-ci-summary.json")
assert resolved == (workspace_root / "planningops/artifacts/ci/federated-ci-summary.json").resolve(), resolved
PY

echo "validate federated ci summary readiness ok"
