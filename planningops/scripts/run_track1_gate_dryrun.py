#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
VALIDATION_DIR = REPO_ROOT / "planningops" / "artifacts" / "validation"
DOCS_CHECK_CMD = [
    "bash",
    "docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh",
    "check",
    "--profile",
    "all",
]
SCHEMA_CHECK_CMD = [
    "python3",
    "planningops/scripts/validate_project_field_schema.py",
    "--fail-on-mismatch",
]

CHAIN_REPORT_PATH = VALIDATION_DIR / "track1-validation-chain-report.json"
KPI_PATH = VALIDATION_DIR / "track1-kpi-baseline.json"
DRYRUN_REPORT_PATH = VALIDATION_DIR / "track1-gate-dryrun-report.json"
TRANSITION_LOG_PATH = VALIDATION_DIR / "transition-log.ndjson"
SCHEMA_REPORT_PATH = VALIDATION_DIR / "project-field-schema-report.json"

KPI_THRESHOLDS = {
    "loop_success_rate": 0.80,
    "replan_without_evidence": 0,
    "schema_drift_recovery_time_p95_hours": 24,
}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(
        cmd,
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def read_json(path: Path):
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def ensure_validation_dir():
    VALIDATION_DIR.mkdir(parents=True, exist_ok=True)


def resolve_repo_path(raw_path: str) -> Path:
    p = Path(raw_path)
    if p.is_absolute():
        return p
    return REPO_ROOT / p


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT))
    except ValueError:
        return str(path)


def evaluate_kpi(kpi_path: Path):
    doc = read_json(kpi_path)
    metrics = doc.get("metrics", {})
    reasons = []

    loop_success_rate = metrics.get("loop_success_rate")
    if loop_success_rate is None:
        reasons.append("kpi.loop_success_rate.missing")
    elif loop_success_rate < KPI_THRESHOLDS["loop_success_rate"]:
        reasons.append("kpi.loop_success_rate.below_threshold")

    replan_wo_evidence = metrics.get("replan_without_evidence")
    if replan_wo_evidence is None:
        reasons.append("kpi.replan_without_evidence.missing")
    elif replan_wo_evidence > KPI_THRESHOLDS["replan_without_evidence"]:
        reasons.append("kpi.replan_without_evidence.above_threshold")

    drift_p95 = metrics.get("schema_drift_recovery_time_p95_hours")
    if drift_p95 is None:
        reasons.append("kpi.schema_drift_recovery_time_p95_hours.missing")
    elif drift_p95 > KPI_THRESHOLDS["schema_drift_recovery_time_p95_hours"]:
        reasons.append("kpi.schema_drift_recovery_time_p95_hours.above_threshold")

    pass_state = len(reasons) == 0
    missing_only = all(r.endswith(".missing") for r in reasons) if reasons else False
    return {
        "pass": pass_state,
        "missing_only": missing_only,
        "reasons": reasons,
        "metrics": metrics,
    }


def decide_verdict(docs_ok: bool, schema_ok: bool, kpi_eval: dict):
    reasons = []
    if not docs_ok:
        reasons.append("docs.check.failed")
    if not schema_ok:
        reasons.append("schema.check.failed")

    if reasons:
        return "fail", reasons + kpi_eval["reasons"]

    if not kpi_eval["pass"] and kpi_eval["missing_only"]:
        return "inconclusive", kpi_eval["reasons"]

    if not kpi_eval["pass"]:
        return "fail", kpi_eval["reasons"]

    return "pass", []


def check_transition_log_contract(entries):
    required = {
        "transition_id",
        "run_id",
        "card_id",
        "from_state",
        "to_state",
        "transition_reason",
        "actor_type",
        "actor_id",
        "loop_profile",
        "verdict",
        "decided_at_utc",
        "replanning_flag",
    }
    missing = []
    for idx, entry in enumerate(entries):
        for key in required:
            if key not in entry:
                missing.append({"entry_index": idx, "missing_key": key})
    return len(missing) == 0, missing


def write_transition_entries(new_entries):
    existing_entries = []
    if TRANSITION_LOG_PATH.exists():
        for line in TRANSITION_LOG_PATH.read_text(encoding="utf-8").splitlines():
            line = line.strip()
            if not line:
                continue
            obj = json.loads(line)
            if obj.get("template") is True:
                continue
            if "actor_type" not in obj:
                obj["actor_type"] = "agent"
            if "actor_id" not in obj:
                obj["actor_id"] = "track1-gate-dryrun-legacy"
            existing_entries.append(obj)

    all_entries = existing_entries + new_entries
    TRANSITION_LOG_PATH.write_text(
        "\n".join(json.dumps(e, ensure_ascii=True) for e in all_entries) + "\n",
        encoding="utf-8",
    )
    return all_entries


def main():
    parser = argparse.ArgumentParser(description="Run Track1 gate dry-run checks and persist reports")
    parser.add_argument(
        "--strict",
        action="store_true",
        help="Return non-zero when final verdict is not pass",
    )
    parser.add_argument(
        "--kpi-path",
        default=display_path(KPI_PATH),
        help="KPI baseline JSON path (repo-relative or absolute)",
    )
    args = parser.parse_args()
    kpi_path = resolve_repo_path(args.kpi_path)

    ensure_validation_dir()

    run_results = []
    transition_entries = []

    for idx in range(1, 3):
        docs_rc, docs_out, docs_err = run(DOCS_CHECK_CMD)
        schema_rc, schema_out, schema_err = run(SCHEMA_CHECK_CMD)

        schema_report = read_json(SCHEMA_REPORT_PATH)
        schema_violations = schema_report.get("violation_count")

        kpi_eval = evaluate_kpi(kpi_path)
        verdict, reasons = decide_verdict(docs_rc == 0, schema_rc == 0, kpi_eval)

        run_id = f"track1-gate-dryrun-{idx}"
        decided_at = now_utc()

        run_results.append(
            {
                "run_id": run_id,
                "executed_at_utc": decided_at,
                "checks": {
                    "docs_check": {
                        "command": " ".join(DOCS_CHECK_CMD),
                        "rc": docs_rc,
                        "pass": docs_rc == 0,
                        "stdout": docs_out,
                        "stderr": docs_err,
                    },
                    "schema_check": {
                        "command": " ".join(SCHEMA_CHECK_CMD),
                        "rc": schema_rc,
                        "pass": schema_rc == 0,
                        "stdout": schema_out,
                        "stderr": schema_err,
                        "violation_count": schema_violations,
                    },
                    "kpi_check": kpi_eval,
                },
                "verdict": verdict,
                "reasons": reasons,
            }
        )

        transition_entries.append(
            {
                "transition_id": f"track1-gate-dryrun-{idx}-{int(datetime.now(timezone.utc).timestamp())}",
                "run_id": run_id,
                "card_id": "track1-exit-gate",
                "from_state": "review-gate",
                "to_state": "review-gate" if verdict == "inconclusive" else ("done" if verdict == "pass" else "blocked"),
                "transition_reason": "gate.dryrun.verdict",
                "actor_type": "agent",
                "actor_id": "track1-gate-dryrun",
                "loop_profile": "L3 Implementation-TDD",
                "verdict": verdict,
                "decided_at_utc": decided_at,
                "replanning_flag": verdict in {"fail", "inconclusive"},
            }
        )

    all_transition_entries = write_transition_entries(transition_entries)
    transition_ok, transition_missing = check_transition_log_contract(all_transition_entries)

    final_verdict = run_results[-1]["verdict"]
    final_reasons = run_results[-1]["reasons"]
    final_kpi = run_results[-1]["checks"]["kpi_check"]

    chain_report = {
        "generated_at_utc": now_utc(),
        "template": False,
        "checks": {
            "uap_docs_profile_all": {
                "pass": run_results[-1]["checks"]["docs_check"]["pass"],
                "rc": run_results[-1]["checks"]["docs_check"]["rc"],
            },
            "project_field_schema_validation": {
                "pass": run_results[-1]["checks"]["schema_check"]["pass"],
                "rc": run_results[-1]["checks"]["schema_check"]["rc"],
                "violation_count": run_results[-1]["checks"]["schema_check"]["violation_count"],
            },
            "kpi_gate_validation": {
                "pass": final_kpi["pass"],
                "missing_only": final_kpi["missing_only"],
                "reasons": final_kpi["reasons"],
            },
            "transition_log_contract_validation": {
                "pass": transition_ok,
                "missing": transition_missing,
            },
        },
        "overall_gate_verdict": final_verdict,
        "verdict": final_verdict,
        "reasons": final_reasons,
        "verdict_source": "track1-gate-dryrun-report.json.final_verdict",
    }

    dryrun_report = {
        "generated_at_utc": now_utc(),
        "template": False,
        "runs": run_results,
        "reproducibility_match": (
            run_results[0]["verdict"] == run_results[1]["verdict"]
            and run_results[0]["reasons"] == run_results[1]["reasons"]
        ),
        "final_verdict": run_results[-1]["verdict"],
        "kpi_source_path": display_path(kpi_path),
    }

    CHAIN_REPORT_PATH.write_text(json.dumps(chain_report, ensure_ascii=True, indent=2), encoding="utf-8")
    DRYRUN_REPORT_PATH.write_text(json.dumps(dryrun_report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(json.dumps(dryrun_report, ensure_ascii=True, indent=2))
    if args.strict and final_verdict != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
