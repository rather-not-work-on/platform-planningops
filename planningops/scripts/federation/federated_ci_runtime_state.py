#!/usr/bin/env python3

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import json
import re
from typing import Any


DETERMINISTIC_RULE = (
    "contract-conformance->contract, "
    "provider-profile/provider-gateway-ready/o11y-replay->infra, "
    "runtime-handoff/runtime-operations-ready->runtime, "
    "federated-conformance->federation, "
    "loop-guardrails->policy"
)

RUN_ID_DATE_RE = re.compile(r"^\d{8}(?:T\d{6}Z)?$")
RUN_ID_RERUN_RE = re.compile(r"^rerun\d+$")
SUMMARY_REQUIRED_KEYS = ("run_id", "started_at_utc", "required_checks", "checks")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path, default: dict[str, Any] | None = None) -> dict[str, Any]:
    if not path.exists():
        return {} if default is None else dict(default)
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")


def is_summary_document(doc: dict[str, Any]) -> bool:
    return (
        isinstance(doc, dict)
        and isinstance(doc.get("run_id"), str)
        and isinstance(doc.get("checks"), list)
        and isinstance(doc.get("required_checks"), list)
    )


def infer_family_from_run_id(run_id: str) -> str:
    parts = [part for part in run_id.split("-") if part]
    while parts and (RUN_ID_RERUN_RE.match(parts[-1]) or RUN_ID_DATE_RE.match(parts[-1])):
        parts.pop()
    return "-".join(parts) if parts else run_id


def summary_timestamp(doc: dict[str, Any]) -> str:
    for key in ("generated_at_utc", "finished_at_utc", "started_at_utc"):
        value = doc.get(key)
        if isinstance(value, str) and value.strip():
            return value
    return ""


@dataclass(frozen=True)
class FederatedCIRunState:
    run_id: str
    started_at_utc: str
    required_checks: tuple[str, ...]
    checks: tuple[dict[str, Any], ...]

    def to_doc(self) -> dict[str, Any]:
        return {
            "run_id": self.run_id,
            "started_at_utc": self.started_at_utc,
            "required_checks": list(self.required_checks),
            "checks": [dict(check) for check in self.checks],
        }


@dataclass(frozen=True)
class FederatedCICheckpointReconcileState:
    run_id: str
    check_name: str | None
    restored: bool
    reasons: tuple[str, ...]
    reconcile_count: int
    restored_check_names: tuple[str, ...]

    @property
    def status(self) -> str:
        return "restored" if self.restored else "healthy"


@dataclass(frozen=True)
class FederatedCISummaryArtifactWritePlan:
    stamped_path: Path
    latest_path: Path
    stamped_validation_output: Path | None
    latest_validation_output: Path | None


def build_check_record(
    *,
    name: str,
    domain: str,
    exit_code: int,
    stdout_log: str,
    stderr_log: str,
    result: str | None = None,
) -> dict[str, Any]:
    check = {
        "name": name,
        "domain": domain,
        "exit_code": exit_code,
        "verdict": "pass" if exit_code == 0 else "fail",
        "stdout_log": stdout_log,
        "stderr_log": stderr_log,
    }
    if result is not None:
        check["result"] = result
    return check


def initialize_summary_doc(
    *,
    run_id: str,
    required_checks: list[str] | tuple[str, ...],
    started_at_utc: str | None = None,
) -> dict[str, Any]:
    return FederatedCIRunState(
        run_id=run_id,
        started_at_utc=started_at_utc or now_utc(),
        required_checks=tuple(required_checks),
        checks=(),
    ).to_doc()


def build_summary_artifact_write_plan(
    *,
    stamped_path: Path,
    latest_path: Path,
    stamped_validation_output: Path | None = None,
    latest_validation_output: Path | None = None,
) -> FederatedCISummaryArtifactWritePlan:
    return FederatedCISummaryArtifactWritePlan(
        stamped_path=stamped_path,
        latest_path=latest_path,
        stamped_validation_output=stamped_validation_output,
        latest_validation_output=latest_validation_output,
    )


def finalize_summary_doc(
    doc: dict[str, Any],
    *,
    status: str,
    shell_exit_code: int | None = None,
    generated_at_utc: str | None = None,
    finished_at_utc: str | None = None,
) -> dict[str, Any]:
    checks = list(doc.get("checks") or [])
    required_checks = list(doc.get("required_checks") or [])
    check_names = [str(check.get("name") or "") for check in checks]
    failures = [check for check in checks if check.get("verdict") == "fail"]
    missing_required = [name for name in required_checks if name not in check_names]

    finalized = dict(doc)
    finalized["generated_at_utc"] = generated_at_utc or now_utc()
    finalized["finished_at_utc"] = finished_at_utc or now_utc()
    finalized["overall_status"] = status
    finalized["check_count"] = len(checks)
    finalized["missing_required_checks"] = missing_required
    finalized["failure_classification"] = {
        "count": len(failures),
        "domains": sorted({failure.get("domain") for failure in failures}),
        "deterministic_rule": DETERMINISTIC_RULE,
    }
    finalized["verdict"] = (
        "pass"
        if status == "complete" and not failures and not missing_required
        else "fail"
    )
    if shell_exit_code is not None:
        finalized["shell_exit_code"] = shell_exit_code
    return finalized


def validate_checkpoint_doc(doc: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for key in SUMMARY_REQUIRED_KEYS:
        if key not in doc:
            errors.append(f"checkpoint missing required key: {key}")
    if not isinstance(doc.get("checks"), list):
        errors.append("checkpoint checks must be a list")
    if not isinstance(doc.get("required_checks"), list):
        errors.append("checkpoint required_checks must be a list")
    if not str(doc.get("run_id") or "").strip():
        errors.append("checkpoint run_id must be non-empty")
    if not str(doc.get("started_at_utc") or "").strip():
        errors.append("checkpoint started_at_utc must be non-empty")
    return errors


def build_reconcile_reasons(
    summary_doc: dict[str, Any] | None,
    checkpoint_doc: dict[str, Any],
) -> list[str]:
    if summary_doc is None:
        return ["summary_missing_or_invalid"]

    reasons: list[str] = []
    for key in SUMMARY_REQUIRED_KEYS:
        if key not in summary_doc:
            reasons.append(f"summary_missing_{key}")
    if reasons:
        return reasons

    if summary_doc["run_id"] != checkpoint_doc["run_id"]:
        reasons.append("summary_run_id_mismatch")
    if summary_doc["started_at_utc"] != checkpoint_doc["started_at_utc"]:
        reasons.append("summary_started_at_utc_mismatch")
    if list(summary_doc.get("required_checks") or []) != list(checkpoint_doc.get("required_checks") or []):
        reasons.append("summary_required_checks_mismatch")
    if len(list(summary_doc.get("checks") or [])) < len(list(checkpoint_doc.get("checks") or [])):
        reasons.append("summary_check_count_regressed")
    return reasons


def build_reconcile_state(
    summary_doc: dict[str, Any] | None,
    checkpoint_doc: dict[str, Any],
    *,
    previous_report_doc: dict[str, Any] | None = None,
    check_name: str | None = None,
) -> FederatedCICheckpointReconcileState:
    normalized_check_name = check_name if isinstance(check_name, str) and check_name.strip() else None
    reasons = tuple(build_reconcile_reasons(summary_doc, checkpoint_doc))
    restored = bool(reasons)

    restored_check_names: list[str] = []
    if (
        isinstance(previous_report_doc, dict)
        and previous_report_doc.get("run_id") == checkpoint_doc["run_id"]
        and isinstance(previous_report_doc.get("restored_check_names"), list)
    ):
        restored_check_names = [
            name
            for name in previous_report_doc["restored_check_names"]
            if isinstance(name, str) and name.strip()
        ]

    if restored and normalized_check_name is not None and normalized_check_name not in restored_check_names:
        restored_check_names.append(normalized_check_name)

    return FederatedCICheckpointReconcileState(
        run_id=str(checkpoint_doc["run_id"]),
        check_name=normalized_check_name,
        restored=restored,
        reasons=reasons,
        reconcile_count=len(restored_check_names),
        restored_check_names=tuple(restored_check_names),
    )


def build_reconcile_report(
    *,
    summary_path: Path,
    checkpoint_path: Path,
    output_path: Path | None,
    checkpoint_doc: dict[str, Any],
    summary_doc: dict[str, Any] | None,
    reconcile_state: FederatedCICheckpointReconcileState,
) -> dict[str, Any]:
    return {
        "generated_at_utc": now_utc(),
        "summary_path": str(summary_path.resolve()),
        "checkpoint_path": str(checkpoint_path.resolve()),
        "output_path": None if output_path is None else str(output_path.resolve()),
        "run_id": reconcile_state.run_id,
        "check_name": reconcile_state.check_name,
        "checkpoint_check_count": len(list(checkpoint_doc.get("checks") or [])),
        "summary_check_count": None if summary_doc is None else len(list(summary_doc.get("checks") or [])),
        "restored": reconcile_state.restored,
        "status": reconcile_state.status,
        "reasons": list(reconcile_state.reasons),
        "reconcile_count": reconcile_state.reconcile_count,
        "restored_check_names": list(reconcile_state.restored_check_names),
    }


def write_summary_artifacts(
    summary_doc: dict[str, Any],
    *,
    plan: FederatedCISummaryArtifactWritePlan,
    validator_module: Any,
    schema_path: Path,
) -> tuple[dict[str, Any], dict[str, Any]]:
    write_json(plan.stamped_path, summary_doc)
    write_json(plan.latest_path, summary_doc)

    schema_doc = validator_module.load_json(schema_path)
    stamped_report = validator_module.build_report(plan.stamped_path, schema_path, summary_doc, schema_doc)
    latest_report = validator_module.build_report(plan.latest_path, schema_path, summary_doc, schema_doc)

    if plan.stamped_validation_output is not None:
        validator_module.write_json(plan.stamped_validation_output, stamped_report)
    if plan.latest_validation_output is not None:
        validator_module.write_json(plan.latest_validation_output, latest_report)

    return stamped_report, latest_report
