#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir"
import importlib.util
import json
import sys
from pathlib import Path


td_path = Path(sys.argv[1])
module_path = Path("planningops/scripts/run_track1_gate_dryrun.py")
spec = importlib.util.spec_from_file_location("run_track1_gate_dryrun", module_path)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

mod.VALIDATION_DIR = td_path / "validation"
mod.CHAIN_REPORT_PATH = mod.VALIDATION_DIR / "track1-validation-chain-report.json"
mod.DRYRUN_REPORT_PATH = mod.VALIDATION_DIR / "track1-gate-dryrun-report.json"
mod.TRANSITION_LOG_PATH = mod.VALIDATION_DIR / "transition-log.ndjson"
mod.SCHEMA_REPORT_PATH = mod.VALIDATION_DIR / "project-field-schema-report.json"

timestamps = iter(
    [
        "2026-03-28T00:00:01+00:00",
        "2026-03-28T00:00:02+00:00",
        "2026-03-28T00:00:03+00:00",
        "2026-03-28T00:00:04+00:00",
    ]
)
mod.now_utc = lambda: next(timestamps)
mod.run = lambda cmd: (0, "ok", "")
mod.read_json = lambda path: {"violation_count": 0} if path == mod.SCHEMA_REPORT_PATH else {}
mod.evaluate_kpi = lambda _path: {
    "pass": True,
    "missing_only": False,
    "reasons": [],
    "metrics": {
        "loop_success_rate": 0.95,
        "replan_without_evidence": 0,
        "schema_drift_recovery_time_p95_hours": 8,
    },
}

sys.argv = ["run_track1_gate_dryrun.py"]
rc = mod.main()
assert rc == 0, rc

transition_entries = [
    json.loads(line)
    for line in mod.TRANSITION_LOG_PATH.read_text(encoding="utf-8").splitlines()
    if line.strip()
]
assert len(transition_entries) == 2, transition_entries
assert all(entry["transition_reason"] == "gate.dryrun.verdict" for entry in transition_entries), transition_entries
assert all(entry["verdict"] == "pass" for entry in transition_entries), transition_entries
PY

python3 - <<'PY' \
  "$tmpdir/validation/track1-validation-chain-report.json" \
  "planningops/artifacts/validation/track1-validation-chain-report.sample.json" \
  "$tmpdir/validation/track1-gate-dryrun-report.json" \
  "planningops/artifacts/validation/track1-gate-dryrun-report.sample.json"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


def normalize_chain(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    return normalized


def normalize_dryrun(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    for run in normalized["runs"]:
        run["executed_at_utc"] = "__EXECUTED_AT__"
    return normalized


actual_chain = normalize_chain(load(sys.argv[1]))
expected_chain = normalize_chain(load(sys.argv[2]))
actual_dryrun = normalize_dryrun(load(sys.argv[3]))
expected_dryrun = normalize_dryrun(load(sys.argv[4]))

assert actual_chain == expected_chain, (actual_chain, expected_chain)
assert actual_dryrun == expected_dryrun, (actual_dryrun, expected_dryrun)
print("track1 gate dryrun artifact lane ok")
PY
