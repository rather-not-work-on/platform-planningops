#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import json
from pathlib import Path
import sys
from typing import Any

from federated_ci_runtime_state import (
    build_reconcile_report,
    build_reconcile_state,
    infer_family_from_run_id,
    is_summary_document,
    load_json,
    summary_timestamp,
    validate_checkpoint_doc,
)


# /planningops/scripts/federation lives one level below the repo's planningops package.
WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CI_ROOT = WORKSPACE_ROOT / "planningops/artifacts/ci"
DEFAULT_VALIDATION_ROOT = WORKSPACE_ROOT / "planningops/artifacts/validation"
DEFAULT_CONFORMANCE_ROOT = WORKSPACE_ROOT / "planningops/artifacts/conformance"
DEFAULT_LOCAL_OPERATOR_STACK_ROOT = WORKSPACE_ROOT / "planningops/runtime-artifacts/local/monday-local-operator-stack"

LATEST_GAP_CHOICES = (
    "readiness_missing",
    "readiness_blocked",
    "failed_checks_present",
    "missing_required_checks",
    "reconcile_restored",
    "reconcile_unknown",
    "reconcile_artifact_missing",
    "reconcile_artifact_stale",
    "reconcile_validation_missing",
    "reconcile_validation_stale",
    "checkpoint_missing",
    "checkpoint_invalid",
)

LOCAL_OPERATOR_VERDICT_CHOICES = ("pass", "fail", "planned")
LOCAL_OPERATOR_READINESS_CHOICES = ("ready", "bootstrap_required", "blocked", "unknown")
LOCAL_OPERATOR_STEP_STATUS_CHOICES = ("pass", "fail", "planned", "skipped", "report_only", "unknown", "missing")


@dataclass(frozen=True)
class SummaryRecord:
    run_id: str
    family: str
    source_kind: str
    summary_path: str
    timestamp_utc: str
    health_status: str
    health_reasons: list[str]
    verdict: str | None
    overall_status: str | None
    check_count: int | None
    shell_exit_code: int | None
    missing_required_checks: list[str]
    failure_domains: list[str]
    failed_checks: list[str]
    readiness_status: str
    ready: bool | None
    blocking_reasons: list[str]
    reconcile_status: str
    reconcile_count: int | None
    reconcile_artifact_state: str
    reconcile_validation_verdict: str
    reconcile_validation_state: str
    checkpoint_state: str
    has_summary_validation: bool
    has_readiness: bool
    has_readiness_validation: bool
    has_reconcile_report: bool
    has_reconcile_validation: bool
    has_conformance_contract: bool


@dataclass(frozen=True)
class ReconcileStatusRecord:
    generated_at_utc: str
    timestamp_utc: str
    run_id: str
    family: str
    source_kind: str
    summary_path: str
    checkpoint_path: str
    checkpoint_state: str
    previous_report_path: str | None
    reconcile_validation_path: str | None
    check_name: str | None
    status: str
    restored: bool
    reasons: list[str]
    reconcile_count: int
    restored_check_names: list[str]
    reconcile_artifact_state: str
    reconcile_validation_verdict: str
    reconcile_validation_state: str
    checkpoint_check_count: int | None
    summary_check_count: int | None


@dataclass(frozen=True)
class HealthSummaryRecord:
    family: str
    run_count: int
    latest_run_id: str
    latest_run_source_kind: str
    latest_run_health_status: str
    latest_run_timestamp_utc: str
    latest_gap_status: str
    latest_gap_count: int
    latest_gap_reasons: list[str]
    healthy_count: int
    degraded_count: int
    blocked_count: int
    unknown_count: int
    latest_alert_run_id: str | None
    latest_alert_source_kind: str | None
    latest_alert_health_status: str | None
    latest_alert_timestamp_utc: str | None
    latest_alert_failed_checks: list[str]
    latest_alert_reasons: list[str]
    failure_domain_counts: dict[str, int]
    latest_failure_run_id: str | None
    latest_failure_source_kind: str | None
    latest_failure_health_status: str | None
    latest_failure_timestamp_utc: str | None
    latest_failure_domains: list[str]
    readiness_status_counts: dict[str, int]
    reconcile_artifact_state_counts: dict[str, int]
    reconcile_validation_state_counts: dict[str, int]


@dataclass(frozen=True)
class OperatorTriageRecord:
    family: str
    triage_status: str
    alert_alignment: str
    latest_run_id: str
    latest_run_source_kind: str
    latest_run_health_status: str
    latest_run_timestamp_utc: str
    latest_gap_status: str
    latest_gap_reasons: list[str]
    latest_gap_domains: list[str]
    latest_alert_run_id: str | None
    latest_alert_source_kind: str | None
    latest_alert_health_status: str | None
    latest_alert_timestamp_utc: str | None
    latest_alert_reasons: list[str]
    latest_alert_domains: list[str]
    latest_alert_failed_checks: list[str]
    latest_failure_run_id: str | None
    latest_failure_domains: list[str]


@dataclass(frozen=True)
class TriageSummaryRecord:
    triage_status: str
    family_count: int
    families: list[str]
    newest_family: str
    newest_run_id: str
    newest_run_source_kind: str
    newest_run_timestamp_utc: str
    alert_alignment_counts: dict[str, int]
    latest_gap_domain_counts: dict[str, int]
    latest_alert_domain_counts: dict[str, int]


@dataclass(frozen=True)
class TriageOverviewRecord:
    total_families: int
    triage_status_counts: dict[str, int]
    alert_alignment_counts: dict[str, int]
    latest_gap_domain_counts: dict[str, int]
    latest_alert_domain_counts: dict[str, int]
    newest_failing_family: str | None
    newest_failing_run_id: str | None
    newest_failing_source_kind: str | None
    newest_failing_triage_status: str | None
    newest_failing_timestamp_utc: str | None
    newest_failing_gap_domains: list[str]
    newest_failing_alert_domains: list[str]
    newest_recovered_family: str | None
    newest_recovered_run_id: str | None
    newest_recovered_source_kind: str | None
    newest_recovered_timestamp_utc: str | None


@dataclass(frozen=True)
class TriageTargetRecord:
    priority_bucket: str
    target_kind: str
    family: str
    triage_status: str
    alert_alignment: str
    latest_run_id: str
    latest_run_source_kind: str
    latest_run_health_status: str
    latest_run_timestamp_utc: str
    target_run_id: str
    target_source_kind: str
    target_health_status: str
    target_timestamp_utc: str
    target_domains: list[str]
    target_reasons: list[str]
    target_failed_checks: list[str]


@dataclass(frozen=True)
class TriageQueueRecord:
    priority_bucket: str
    target_count: int
    families: list[str]
    newest_target_family: str
    newest_target_run_id: str
    newest_target_source_kind: str
    newest_target_health_status: str
    newest_target_timestamp_utc: str
    newest_target_kind: str
    target_kind_counts: dict[str, int]
    target_domain_counts: dict[str, int]


@dataclass(frozen=True)
class TriageFeedRecord:
    source_kind: str
    target_limit: int
    overview: TriageOverviewRecord
    queue_records: list[TriageQueueRecord]
    target_records: list[TriageTargetRecord]
    local_operator_record: LocalOperatorStackRecord | None


@dataclass(frozen=True)
class TriageBriefRecord:
    source_kind: str
    target_limit: int
    attention_family_count: int
    active_family_count: int
    lagging_family_count: int
    clear_family_count: int
    newest_failing_family: str | None
    newest_failing_run_id: str | None
    newest_failing_triage_status: str | None
    newest_recovered_family: str | None
    newest_recovered_run_id: str | None
    local_operator_record: LocalOperatorStackRecord | None
    local_operator_summary: str | None
    local_operator_next_step: str | None
    queue_lines: list[str]
    target_lines: list[str]


@dataclass(frozen=True)
class TriageReportRecord:
    source_kind: str
    target_limit: int
    headline: str
    attention_summary: str
    newest_failing_summary: str
    newest_recovered_summary: str | None
    local_operator_record: LocalOperatorStackRecord | None
    local_operator_summary: str | None
    local_operator_next_step: str | None
    queue_lines: list[str]
    target_lines: list[str]
    markdown: str


@dataclass(frozen=True)
class HandoffReportRecord:
    source_kind: str
    target_limit: int
    headline: str
    attention_summary: str
    newest_failing_summary: str
    newest_recovered_summary: str | None
    local_operator_record: LocalOperatorStackRecord | None
    local_operator_summary: str | None
    local_operator_next_step: str | None
    queue_lines: list[str]
    target_lines: list[str]
    immediate_action_lines: list[str]
    markdown: str


@dataclass(frozen=True)
class LocalOperatorStackRecord:
    run_id: str
    report_path: str
    expected_detail_dir: str
    detail_dir: str | None
    has_detail_dir: bool
    generated_at_utc: str
    verdict: str | None
    reason_code: str | None
    execution_mode: str | None
    direct_profile: str | None
    dry_run: bool | None
    readiness_status: str
    readiness_step_status: str
    readiness_report_path: str | None
    stack_status: str
    stack_report_path: str | None
    direct_status: str
    direct_report_path: str | None
    recommended_next_steps: list[str]


def resolve_root(path_text: str, default: Path) -> Path:
    candidate = Path(path_text)
    if not candidate.is_absolute():
        candidate = (WORKSPACE_ROOT / candidate).resolve()
    return candidate if path_text else default


def resolve_optional_path(path_text: str | None) -> Path | None:
    if path_text is None:
        return None
    return resolve_root(path_text, WORKSPACE_ROOT)


def source_kind_for_summary_path(path: Path) -> str:
    return "latest" if path.name == "federated-ci-summary.json" else "stamped"


def load_optional_json(path: Path) -> dict[str, Any] | None:
    if not path.exists():
        return None
    try:
        return load_json(path)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None


def resolve_artifact_path(path_text: Any) -> Path | None:
    if not isinstance(path_text, str) or not path_text.strip():
        return None
    return Path(path_text).expanduser().resolve()


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def utc_timestamp_slug() -> str:
    return datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def write_json(path: Path, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def build_reconcile_validation_path(report_path: Path | None) -> Path | None:
    if report_path is None:
        return None
    return report_path.with_name(f"{report_path.stem}-validation.json")


def build_sidecar_paths(
    *,
    run_id: str,
    source_kind: str,
    validation_root: Path,
    conformance_root: Path,
) -> dict[str, Path]:
    if source_kind == "latest":
        prefix = "federated-ci-summary"
    else:
        prefix = f"{run_id}-summary"
    return {
        "summary_validation": validation_root / f"{prefix}-validation.json",
        "readiness": validation_root / f"{prefix}-readiness.json",
        "readiness_validation": validation_root / f"{prefix}-readiness-validation.json",
        "reconcile_report": validation_root / f"{prefix}-tmp-reconcile.json",
        "reconcile_validation": validation_root / f"{prefix}-tmp-reconcile-validation.json",
        "conformance_contract": conformance_root / f"{run_id}-contract.json",
    }


def build_runs_reconcile_fields(
    *,
    ci_root: Path,
    summary_path: Path,
    summary_doc: dict[str, Any],
    validation_root: Path,
    conformance_root: Path,
) -> dict[str, Any]:
    run_id = str(summary_doc["run_id"])
    source_kind = source_kind_for_summary_path(summary_path)
    sidecars = build_sidecar_paths(
        run_id=run_id,
        source_kind=source_kind,
        validation_root=validation_root,
        conformance_root=conformance_root,
    )
    checkpoint_path = (ci_root / f"{run_id}.checkpoint.json").resolve()
    if not checkpoint_path.exists():
        record = build_unknown_reconcile_status_record(
            summary_path=summary_path,
            checkpoint_path=checkpoint_path,
            previous_report_path=sidecars["reconcile_report"],
            reconcile_validation_path=sidecars["reconcile_validation"],
            run_id=run_id,
            source_kind=source_kind,
            timestamp_utc=summary_timestamp(summary_doc),
            checkpoint_state="missing",
            reasons=["checkpoint_missing"],
        )
    else:
        checkpoint_doc = load_optional_json(checkpoint_path)
        if checkpoint_doc is None:
            record = build_unknown_reconcile_status_record(
                summary_path=summary_path,
                checkpoint_path=checkpoint_path,
                previous_report_path=sidecars["reconcile_report"],
                reconcile_validation_path=sidecars["reconcile_validation"],
                run_id=run_id,
                source_kind=source_kind,
                timestamp_utc=summary_timestamp(summary_doc),
                checkpoint_state="invalid",
                reasons=["checkpoint_invalid_json"],
            )
        else:
            checkpoint_errors = validate_checkpoint_doc(checkpoint_doc)
            if checkpoint_errors:
                record = build_unknown_reconcile_status_record(
                    summary_path=summary_path,
                    checkpoint_path=checkpoint_path,
                    previous_report_path=sidecars["reconcile_report"],
                    reconcile_validation_path=sidecars["reconcile_validation"],
                    run_id=run_id,
                    source_kind=source_kind,
                    timestamp_utc=summary_timestamp(summary_doc),
                    checkpoint_state="invalid",
                    reasons=[f"checkpoint_invalid:{error}" for error in checkpoint_errors],
                )
            else:
                record = build_reconcile_status_record(
                    summary_path=summary_path,
                    checkpoint_path=checkpoint_path,
                    previous_report_path=sidecars["reconcile_report"],
                    reconcile_validation_path=sidecars["reconcile_validation"],
                    summary_doc=summary_doc,
                    checkpoint_doc=checkpoint_doc,
                    check_name=None,
                    source_kind=source_kind,
                )
    return {
        "reconcile_status": record.status,
        "reconcile_count": record.reconcile_count,
        "reconcile_artifact_state": record.reconcile_artifact_state,
        "reconcile_validation_verdict": record.reconcile_validation_verdict,
        "reconcile_validation_state": record.reconcile_validation_state,
        "checkpoint_state": record.checkpoint_state,
    }


def build_summary_record(
    *,
    ci_root: Path,
    summary_path: Path,
    summary_doc: dict[str, Any],
    validation_root: Path,
    conformance_root: Path,
) -> SummaryRecord:
    run_id = str(summary_doc["run_id"])
    source_kind = source_kind_for_summary_path(summary_path)
    sidecars = build_sidecar_paths(
        run_id=run_id,
        source_kind=source_kind,
        validation_root=validation_root,
        conformance_root=conformance_root,
    )
    failing_checks = [check for check in list(summary_doc.get("checks") or []) if check.get("verdict") == "fail"]
    failures = [str(check.get("domain")) for check in failing_checks if isinstance(check.get("domain"), str)]
    failed_checks = [str(check.get("name") or "unknown") for check in failing_checks]
    readiness_doc = load_optional_json(sidecars["readiness"])
    raw_readiness_status = readiness_doc.get("readiness_status") if isinstance(readiness_doc, dict) else None
    raw_ready = readiness_doc.get("ready") if isinstance(readiness_doc, dict) else None
    reconcile_fields = build_runs_reconcile_fields(
        ci_root=ci_root,
        summary_path=summary_path,
        summary_doc=summary_doc,
        validation_root=validation_root,
        conformance_root=conformance_root,
    )
    readiness_status = (
        str(raw_readiness_status)
        if isinstance(raw_readiness_status, str) and raw_readiness_status.strip()
        else ("unknown" if sidecars["readiness"].exists() else "missing")
    )
    health_status, health_reasons = build_summary_health_fields(
        verdict=summary_doc.get("verdict"),
        overall_status=summary_doc.get("overall_status"),
        missing_required_checks=[str(name) for name in list(summary_doc.get("missing_required_checks") or [])],
        failed_checks=failed_checks,
        readiness_status=readiness_status,
        reconcile_status=str(reconcile_fields["reconcile_status"]),
        reconcile_artifact_state=str(reconcile_fields["reconcile_artifact_state"]),
        reconcile_validation_state=str(reconcile_fields["reconcile_validation_state"]),
        checkpoint_state=str(reconcile_fields["checkpoint_state"]),
    )
    return SummaryRecord(
        run_id=run_id,
        family=infer_family_from_run_id(run_id),
        source_kind=source_kind,
        summary_path=str(summary_path.resolve()),
        timestamp_utc=summary_timestamp(summary_doc),
        health_status=health_status,
        health_reasons=health_reasons,
        verdict=summary_doc.get("verdict"),
        overall_status=summary_doc.get("overall_status"),
        check_count=summary_doc.get("check_count"),
        shell_exit_code=summary_doc.get("shell_exit_code"),
        missing_required_checks=[str(name) for name in list(summary_doc.get("missing_required_checks") or [])],
        failure_domains=sorted(set(failures)),
        failed_checks=failed_checks,
        readiness_status=readiness_status,
        ready=raw_ready if isinstance(raw_ready, bool) else None,
        blocking_reasons=(
            [str(reason) for reason in list(readiness_doc.get("blocking_reasons") or [])]
            if isinstance(readiness_doc, dict)
            else []
        ),
        reconcile_status=str(reconcile_fields["reconcile_status"]),
        reconcile_count=(
            int(reconcile_fields["reconcile_count"])
            if isinstance(reconcile_fields["reconcile_count"], int)
            else None
        ),
        reconcile_artifact_state=str(reconcile_fields["reconcile_artifact_state"]),
        reconcile_validation_verdict=str(reconcile_fields["reconcile_validation_verdict"]),
        reconcile_validation_state=str(reconcile_fields["reconcile_validation_state"]),
        checkpoint_state=str(reconcile_fields["checkpoint_state"]),
        has_summary_validation=sidecars["summary_validation"].exists(),
        has_readiness=sidecars["readiness"].exists(),
        has_readiness_validation=sidecars["readiness_validation"].exists(),
        has_reconcile_report=sidecars["reconcile_report"].exists(),
        has_reconcile_validation=sidecars["reconcile_validation"].exists(),
        has_conformance_contract=sidecars["conformance_contract"].exists(),
    )


def discover_summary_records(
    *,
    ci_root: Path,
    validation_root: Path,
    conformance_root: Path,
) -> list[SummaryRecord]:
    records: list[SummaryRecord] = []
    for path in sorted(ci_root.glob("*.json")):
        if (
            path.name.startswith(".")
            or path.name.endswith(".tmp.json")
            or path.name.endswith(".checkpoint.json")
        ):
            continue
        try:
            doc = load_json(path)
        except (UnicodeDecodeError, json.JSONDecodeError):
            continue
        if not is_summary_document(doc):
            continue
        records.append(
            build_summary_record(
                ci_root=ci_root,
                summary_path=path,
                summary_doc=doc,
                validation_root=validation_root,
                conformance_root=conformance_root,
            )
        )
    records.sort(
        key=lambda record: (
            record.timestamp_utc,
            record.run_id,
            1 if record.source_kind == "latest" else 0,
            record.summary_path,
        ),
        reverse=True,
    )
    return records


def is_local_operator_stack_document(doc: dict[str, Any]) -> bool:
    return (
        isinstance(doc.get("run_id"), str)
        and isinstance(doc.get("readiness"), dict)
        and isinstance(doc.get("stack_smoke"), dict)
        and isinstance(doc.get("direct_smoke"), dict)
    )


def extract_local_operator_status(raw_doc: Any) -> str:
    if not isinstance(raw_doc, dict):
        return "missing"
    raw_status = raw_doc.get("status")
    if isinstance(raw_status, str) and raw_status.strip():
        return raw_status
    return "unknown"


def normalize_artifact_path(path_text: Any) -> str | None:
    path = resolve_artifact_path(path_text)
    return None if path is None else str(path)


def build_local_operator_stack_record(*, local_root: Path, report_path: Path, report_doc: dict[str, Any]) -> LocalOperatorStackRecord:
    run_id = str(report_doc.get("run_id"))
    expected_detail_dir = (local_root / run_id).resolve()
    detail_dir = expected_detail_dir if expected_detail_dir.is_dir() else None
    readiness_doc = report_doc.get("readiness") if isinstance(report_doc.get("readiness"), dict) else {}
    readiness_step_doc = readiness_doc.get("step") if isinstance(readiness_doc.get("step"), dict) else None
    stack_doc = report_doc.get("stack_smoke") if isinstance(report_doc.get("stack_smoke"), dict) else {}
    direct_doc = report_doc.get("direct_smoke") if isinstance(report_doc.get("direct_smoke"), dict) else {}
    raw_readiness_status = readiness_doc.get("status") if isinstance(readiness_doc, dict) else None
    readiness_status = (
        str(raw_readiness_status)
        if isinstance(raw_readiness_status, str) and raw_readiness_status.strip()
        else "unknown"
    )
    return LocalOperatorStackRecord(
        run_id=run_id,
        report_path=str(report_path.resolve()),
        expected_detail_dir=str(expected_detail_dir),
        detail_dir=None if detail_dir is None else str(detail_dir),
        has_detail_dir=detail_dir is not None,
        generated_at_utc=str(report_doc.get("generated_at_utc") or ""),
        verdict=str(report_doc.get("verdict")) if isinstance(report_doc.get("verdict"), str) else None,
        reason_code=str(report_doc.get("reason_code")) if isinstance(report_doc.get("reason_code"), str) else None,
        execution_mode=str(report_doc.get("execution_mode")) if isinstance(report_doc.get("execution_mode"), str) else None,
        direct_profile=(
            str(report_doc.get("direct_profile"))
            if isinstance(report_doc.get("direct_profile"), str) and str(report_doc.get("direct_profile")).strip()
            else None
        ),
        dry_run=report_doc.get("dry_run") if isinstance(report_doc.get("dry_run"), bool) else None,
        readiness_status=readiness_status,
        readiness_step_status=extract_local_operator_status(readiness_step_doc),
        readiness_report_path=normalize_artifact_path(readiness_doc.get("report_path")),
        stack_status=extract_local_operator_status(stack_doc),
        stack_report_path=normalize_artifact_path(stack_doc.get("report_path")),
        direct_status=extract_local_operator_status(direct_doc),
        direct_report_path=normalize_artifact_path(direct_doc.get("report_path")),
        recommended_next_steps=[str(step) for step in list(report_doc.get("recommended_next_steps") or [])],
    )


def discover_local_operator_stack_records(*, local_root: Path) -> list[LocalOperatorStackRecord]:
    if not local_root.exists():
        return []
    records: list[LocalOperatorStackRecord] = []
    for path in sorted(local_root.glob("*.json")):
        if path.name.startswith(".") or path.name.startswith("._"):
            continue
        try:
            doc = load_json(path)
        except (UnicodeDecodeError, json.JSONDecodeError):
            continue
        if not is_local_operator_stack_document(doc):
            continue
        records.append(build_local_operator_stack_record(local_root=local_root, report_path=path, report_doc=doc))
    records.sort(
        key=lambda record: (
            record.generated_at_utc,
            record.run_id,
            record.report_path,
        ),
        reverse=True,
    )
    return records


def filter_local_operator_stack_records(
    *,
    records: list[LocalOperatorStackRecord],
    run_id_prefix: str | None = None,
    verdict: str | None = None,
    reason_code: str | None = None,
    execution_mode: str | None = None,
    direct_profile: str | None = None,
    readiness_status: str | None = None,
    readiness_step_status: str | None = None,
    stack_status: str | None = None,
    direct_status: str | None = None,
    has_detail_dir: str | None = None,
) -> list[LocalOperatorStackRecord]:
    filtered = records
    if run_id_prefix:
        filtered = [record for record in filtered if record.run_id.startswith(run_id_prefix)]
    if verdict:
        filtered = [record for record in filtered if record.verdict == verdict]
    if reason_code:
        filtered = [record for record in filtered if record.reason_code == reason_code]
    if execution_mode:
        filtered = [record for record in filtered if record.execution_mode == execution_mode]
    if direct_profile:
        filtered = [record for record in filtered if record.direct_profile == direct_profile]
    if readiness_status:
        filtered = [record for record in filtered if record.readiness_status == readiness_status]
    if readiness_step_status:
        filtered = [record for record in filtered if record.readiness_step_status == readiness_step_status]
    if stack_status:
        filtered = [record for record in filtered if record.stack_status == stack_status]
    if direct_status:
        filtered = [record for record in filtered if record.direct_status == direct_status]
    if has_detail_dir is not None:
        expected = has_detail_dir == "yes"
        filtered = [record for record in filtered if record.has_detail_dir is expected]
    return filtered


def render_local_operator_stack_table(records: list[LocalOperatorStackRecord]) -> str:
    lines = [
        "run_id\tverdict\treason_code\treadiness\treadiness_step\tstack\tdirect\texecution_mode\tdirect_profile\tdry_run\thas_detail_dir\tgenerated_at_utc",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.run_id,
                    str(record.verdict or ""),
                    str(record.reason_code or ""),
                    record.readiness_status,
                    record.readiness_step_status,
                    record.stack_status,
                    record.direct_status,
                    str(record.execution_mode or ""),
                    str(record.direct_profile or ""),
                    str(record.dry_run if record.dry_run is not None else ""),
                    "yes" if record.has_detail_dir else "no",
                    record.generated_at_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_local_operator_stack_markdown(records: list[LocalOperatorStackRecord]) -> str:
    lines = [
        "| run_id | verdict | reason_code | readiness | readiness_step | stack | direct | execution_mode | direct_profile | dry_run | detail_dir | generated_at_utc |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| `{record.run_id}` | {record.verdict or ''} | {record.reason_code or ''} | "
            f"{record.readiness_status} | {record.readiness_step_status} | {record.stack_status} | "
            f"{record.direct_status} | {record.execution_mode or ''} | {record.direct_profile or ''} | "
            f"{record.dry_run if record.dry_run is not None else ''} | "
            f"{'present' if record.has_detail_dir else 'missing'} | {record.generated_at_utc} |"
        )
    return "\n".join(lines)


def select_latest_local_operator_stack_record(
    records: list[LocalOperatorStackRecord],
) -> LocalOperatorStackRecord | None:
    if not records:
        return None
    executed_records = [record for record in records if record.verdict != "planned"]
    if executed_records:
        return executed_records[0]
    return records[0]


def build_local_operator_summary(record: LocalOperatorStackRecord | None) -> str | None:
    if record is None:
        return None
    return (
        f"{record.run_id} verdict={record.verdict or 'unknown'} "
        f"readiness={record.readiness_status} stack={record.stack_status} "
        f"direct={record.direct_status} mode={record.execution_mode or 'unknown'} "
        f"reason={record.reason_code or 'unknown'}"
    )


def build_local_operator_next_step(record: LocalOperatorStackRecord | None) -> str | None:
    if record is None or not record.recommended_next_steps:
        return None
    return record.recommended_next_steps[0]


def build_summary_health_fields(
    *,
    verdict: Any,
    overall_status: Any,
    missing_required_checks: list[str],
    failed_checks: list[str],
    readiness_status: str,
    reconcile_status: str,
    reconcile_artifact_state: str,
    reconcile_validation_state: str,
    checkpoint_state: str,
) -> tuple[str, list[str]]:
    unknown_reasons: list[str] = []
    if checkpoint_state != "present":
        unknown_reasons.append(f"checkpoint_{checkpoint_state}")
    if reconcile_status == "unknown":
        unknown_reasons.append("reconcile_unknown")
    if unknown_reasons:
        return "unknown", unknown_reasons

    blocked_reasons: list[str] = []
    if verdict == "fail":
        blocked_reasons.append("summary_verdict_fail")
    if isinstance(overall_status, str) and overall_status and overall_status != "complete":
        blocked_reasons.append(f"summary_status_{overall_status}")
    if missing_required_checks:
        blocked_reasons.append("missing_required_checks")
    if failed_checks:
        blocked_reasons.append("failed_checks_present")
    if readiness_status == "blocked":
        blocked_reasons.append("readiness_blocked")
    if blocked_reasons:
        return "blocked", blocked_reasons

    degraded_reasons: list[str] = []
    if readiness_status in {"missing", "unknown"}:
        degraded_reasons.append(f"readiness_{readiness_status}")
    if reconcile_status == "restored":
        degraded_reasons.append("reconcile_restored")
    if reconcile_artifact_state != "fresh":
        degraded_reasons.append(f"reconcile_artifact_{reconcile_artifact_state}")
    if reconcile_validation_state != "fresh":
        degraded_reasons.append(f"reconcile_validation_{reconcile_validation_state}")
    if degraded_reasons:
        return "degraded", degraded_reasons

    return "healthy", []


def filter_summary_records(
    *,
    records: list[SummaryRecord],
    family: str | None = None,
    run_id_prefix: str | None = None,
    source_kind: str = "all",
    verdict: str | None = None,
    status: str | None = None,
    readiness_status: str | None = None,
    health_status: str | None = None,
    reconcile_status: str | None = None,
    reconcile_artifact_state: str | None = None,
    reconcile_validation_state: str | None = None,
    checkpoint_state: str | None = None,
    failed_check: str | None = None,
) -> list[SummaryRecord]:
    filtered = records
    if family:
        filtered = [record for record in filtered if record.family == family]
    if run_id_prefix:
        filtered = [record for record in filtered if record.run_id.startswith(run_id_prefix)]
    if source_kind != "all":
        filtered = [record for record in filtered if record.source_kind == source_kind]
    if verdict:
        filtered = [record for record in filtered if record.verdict == verdict]
    if status:
        filtered = [record for record in filtered if record.overall_status == status]
    if readiness_status:
        filtered = [record for record in filtered if record.readiness_status == readiness_status]
    if health_status:
        filtered = [record for record in filtered if record.health_status == health_status]
    if reconcile_status:
        filtered = [record for record in filtered if record.reconcile_status == reconcile_status]
    if reconcile_artifact_state:
        filtered = [record for record in filtered if record.reconcile_artifact_state == reconcile_artifact_state]
    if reconcile_validation_state:
        filtered = [record for record in filtered if record.reconcile_validation_state == reconcile_validation_state]
    if checkpoint_state:
        filtered = [record for record in filtered if record.checkpoint_state == checkpoint_state]
    if failed_check:
        filtered = [record for record in filtered if failed_check in record.failed_checks]
    return filtered


def render_runs_table(records: list[SummaryRecord]) -> str:
    lines = [
        "family\trun_id\tsource\thealth\tverdict\treadiness\treconcile\tartifact_state\tcheckpoint\tfailed_checks\tstatus\tchecks\ttimestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.family,
                    record.run_id,
                    record.source_kind,
                    record.health_status,
                    str(record.verdict or ""),
                    record.readiness_status,
                    record.reconcile_status,
                    record.reconcile_artifact_state,
                    record.checkpoint_state,
                    ",".join(record.failed_checks),
                    str(record.overall_status or ""),
                    str(record.check_count if record.check_count is not None else ""),
                    record.timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_runs_markdown(records: list[SummaryRecord]) -> str:
    lines = [
        "| family | run_id | source | health | verdict | readiness | reconcile | artifact_state | checkpoint | failed_checks | status | checks | timestamp |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | `{record.run_id}` | {record.source_kind} | {record.health_status} | "
            f"{record.verdict or ''} | {record.readiness_status} | {record.reconcile_status} | "
            f"{record.reconcile_artifact_state} | {record.checkpoint_state} | "
            f"{', '.join(record.failed_checks)} | {record.overall_status or ''} | "
            f"{record.check_count if record.check_count is not None else ''} | {record.timestamp_utc} |"
        )
    return "\n".join(lines)


def render_health_scan_table(records: list[SummaryRecord]) -> str:
    lines = [
        "family\trun_id\tsource\thealth\tverdict\treadiness\treconcile\tartifact_state\tfailed_checks\thealth_reasons\ttimestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.family,
                    record.run_id,
                    record.source_kind,
                    record.health_status,
                    str(record.verdict or ""),
                    record.readiness_status,
                    record.reconcile_status,
                    record.reconcile_artifact_state,
                    ",".join(record.failed_checks),
                    ",".join(record.health_reasons),
                    record.timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_health_scan_markdown(records: list[SummaryRecord]) -> str:
    lines = [
        "| family | run_id | source | health | verdict | readiness | reconcile | artifact_state | failed_checks | health_reasons | timestamp |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | `{record.run_id}` | {record.source_kind} | {record.health_status} | "
            f"{record.verdict or ''} | {record.readiness_status} | {record.reconcile_status} | "
            f"{record.reconcile_artifact_state} | {', '.join(record.failed_checks)} | "
            f"{', '.join(record.health_reasons)} | {record.timestamp_utc} |"
        )
    return "\n".join(lines)


def build_latest_gap_reasons(record: SummaryRecord) -> list[str]:
    reasons: list[str] = []
    if record.readiness_status == "missing":
        reasons.append("readiness_missing")
    elif record.readiness_status == "blocked":
        reasons.append("readiness_blocked")
    if record.failed_checks:
        reasons.append("failed_checks_present")
    if record.missing_required_checks:
        reasons.append("missing_required_checks")
    if record.reconcile_status == "restored":
        reasons.append("reconcile_restored")
    elif record.reconcile_status == "unknown":
        reasons.append("reconcile_unknown")
    if record.reconcile_artifact_state == "missing":
        reasons.append("reconcile_artifact_missing")
    elif record.reconcile_artifact_state == "stale":
        reasons.append("reconcile_artifact_stale")
    if record.reconcile_validation_state == "missing":
        reasons.append("reconcile_validation_missing")
    elif record.reconcile_validation_state == "stale":
        reasons.append("reconcile_validation_stale")
    if record.checkpoint_state == "missing":
        reasons.append("checkpoint_missing")
    elif record.checkpoint_state == "invalid":
        reasons.append("checkpoint_invalid")
    return reasons


def build_latest_gap_domains(record: SummaryRecord, reasons: list[str]) -> list[str]:
    domains = set(record.failure_domains)
    if any(reason.startswith("readiness_") for reason in reasons):
        domains.add("readiness")
    if any(reason.startswith("reconcile_") for reason in reasons):
        domains.add("reconcile")
    if any(reason.startswith("checkpoint_") for reason in reasons):
        domains.add("checkpoint")
    if "missing_required_checks" in reasons:
        domains.add("required-checks")
    return sorted(domains)


def build_health_summary_records(
    *,
    records: list[SummaryRecord],
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> list[HealthSummaryRecord]:
    filtered = filter_summary_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    grouped: dict[str, list[SummaryRecord]] = {}
    for record in filtered:
        grouped.setdefault(record.family, []).append(record)

    summaries: list[HealthSummaryRecord] = []
    for family_name, family_records in grouped.items():
        latest_record = family_records[0]
        latest_gap_reasons = build_latest_gap_reasons(latest_record)
        latest_alert = next((record for record in family_records if record.health_status != "healthy"), None)
        latest_failure = next((record for record in family_records if record.failure_domains), None)
        domain_counts: dict[str, int] = {}
        readiness_counts: dict[str, int] = {}
        reconcile_artifact_counts: dict[str, int] = {}
        reconcile_validation_counts: dict[str, int] = {}
        for record in family_records:
            for domain in record.failure_domains:
                domain_counts[domain] = domain_counts.get(domain, 0) + 1
            readiness_counts[record.readiness_status] = readiness_counts.get(record.readiness_status, 0) + 1
            reconcile_artifact_counts[record.reconcile_artifact_state] = (
                reconcile_artifact_counts.get(record.reconcile_artifact_state, 0) + 1
            )
            reconcile_validation_counts[record.reconcile_validation_state] = (
                reconcile_validation_counts.get(record.reconcile_validation_state, 0) + 1
            )
        summaries.append(
            HealthSummaryRecord(
                family=family_name,
                run_count=len(family_records),
                latest_run_id=latest_record.run_id,
                latest_run_source_kind=latest_record.source_kind,
                latest_run_health_status=latest_record.health_status,
                latest_run_timestamp_utc=latest_record.timestamp_utc,
                latest_gap_status="clear" if not latest_gap_reasons else "attention",
                latest_gap_count=len(latest_gap_reasons),
                latest_gap_reasons=latest_gap_reasons,
                healthy_count=sum(1 for record in family_records if record.health_status == "healthy"),
                degraded_count=sum(1 for record in family_records if record.health_status == "degraded"),
                blocked_count=sum(1 for record in family_records if record.health_status == "blocked"),
                unknown_count=sum(1 for record in family_records if record.health_status == "unknown"),
                latest_alert_run_id=None if latest_alert is None else latest_alert.run_id,
                latest_alert_source_kind=None if latest_alert is None else latest_alert.source_kind,
                latest_alert_health_status=None if latest_alert is None else latest_alert.health_status,
                latest_alert_timestamp_utc=None if latest_alert is None else latest_alert.timestamp_utc,
                latest_alert_failed_checks=[] if latest_alert is None else latest_alert.failed_checks,
                latest_alert_reasons=[] if latest_alert is None else latest_alert.health_reasons,
                failure_domain_counts={key: domain_counts[key] for key in sorted(domain_counts)},
                latest_failure_run_id=None if latest_failure is None else latest_failure.run_id,
                latest_failure_source_kind=None if latest_failure is None else latest_failure.source_kind,
                latest_failure_health_status=None if latest_failure is None else latest_failure.health_status,
                latest_failure_timestamp_utc=None if latest_failure is None else latest_failure.timestamp_utc,
                latest_failure_domains=[] if latest_failure is None else latest_failure.failure_domains,
                readiness_status_counts={key: readiness_counts[key] for key in sorted(readiness_counts)},
                reconcile_artifact_state_counts={
                    key: reconcile_artifact_counts[key] for key in sorted(reconcile_artifact_counts)
                },
                reconcile_validation_state_counts={
                    key: reconcile_validation_counts[key] for key in sorted(reconcile_validation_counts)
                },
            )
        )
    summaries.sort(key=lambda record: (record.latest_run_timestamp_utc, record.family), reverse=True)
    return summaries


def render_health_summary_table(records: list[HealthSummaryRecord]) -> str:
    lines = [
        "family\truns\thealthy\tdegraded\tblocked\tunknown\tlatest_gap_status\tlatest_gap_count\tlatest_gap_reasons\treadiness_counts\treconcile_artifact_counts\treconcile_validation_counts\tdomain_counts\tlatest_run\tlatest_health\tlatest_alert_run\tlatest_alert_health\tlatest_failure_run\tlatest_failure_domains\tlatest_timestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.family,
                    str(record.run_count),
                    str(record.healthy_count),
                    str(record.degraded_count),
                    str(record.blocked_count),
                    str(record.unknown_count),
                    record.latest_gap_status,
                    str(record.latest_gap_count),
                    ",".join(record.latest_gap_reasons),
                    ",".join(f"{key}={value}" for key, value in record.readiness_status_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.reconcile_artifact_state_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.reconcile_validation_state_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.failure_domain_counts.items()),
                    record.latest_run_id,
                    record.latest_run_health_status,
                    record.latest_alert_run_id or "",
                    record.latest_alert_health_status or "",
                    record.latest_failure_run_id or "",
                    ",".join(record.latest_failure_domains),
                    record.latest_run_timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_health_summary_markdown(records: list[HealthSummaryRecord]) -> str:
    lines = [
        "| family | runs | healthy | degraded | blocked | unknown | latest_gap_status | latest_gap_count | latest_gap_reasons | readiness_counts | reconcile_artifact_counts | reconcile_validation_counts | domain_counts | latest_run | latest_health | latest_alert_run | latest_alert_health | latest_failure_run | latest_failure_domains | latest_timestamp |",
        "| --- | ---: | ---: | ---: | ---: | ---: | --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | {record.run_count} | {record.healthy_count} | {record.degraded_count} | "
            f"{record.blocked_count} | {record.unknown_count} | {record.latest_gap_status} | "
            f"{record.latest_gap_count} | {', '.join(record.latest_gap_reasons)} | "
            f"{', '.join(f'{key}={value}' for key, value in record.readiness_status_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.reconcile_artifact_state_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.reconcile_validation_state_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.failure_domain_counts.items())} | "
            f"`{record.latest_run_id}` | {record.latest_run_health_status} | `{record.latest_alert_run_id or ''}` | "
            f"{record.latest_alert_health_status or ''} | `{record.latest_failure_run_id or ''}` | "
            f"{', '.join(record.latest_failure_domains)} | "
            f"{record.latest_run_timestamp_utc} |"
        )
    return "\n".join(lines)


def build_operator_triage_records(
    *,
    records: list[SummaryRecord],
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> list[OperatorTriageRecord]:
    filtered = filter_summary_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    grouped: dict[str, list[SummaryRecord]] = {}
    for record in filtered:
        grouped.setdefault(record.family, []).append(record)

    triage_records: list[OperatorTriageRecord] = []
    for family_name, family_records in grouped.items():
        latest_record = family_records[0]
        latest_gap_reasons = build_latest_gap_reasons(latest_record)
        latest_gap_domains = build_latest_gap_domains(latest_record, latest_gap_reasons)
        latest_gap_status = "clear" if not latest_gap_reasons else "attention"
        latest_alert = next((record for record in family_records if record.health_status != "healthy"), None)
        latest_failure = next((record for record in family_records if record.failure_domains), None)
        if latest_alert is None:
            alert_alignment = "none"
            latest_alert_gap_reasons: list[str] = []
            latest_alert_domains: list[str] = []
        else:
            alert_alignment = (
                "current"
                if latest_alert.run_id == latest_record.run_id and latest_alert.source_kind == latest_record.source_kind
                else "lagging"
            )
            latest_alert_gap_reasons = build_latest_gap_reasons(latest_alert)
            latest_alert_domains = build_latest_gap_domains(latest_alert, latest_alert_gap_reasons)
        if latest_gap_status == "attention":
            triage_status = "active"
        elif alert_alignment == "lagging":
            triage_status = "lagging"
        else:
            triage_status = "clear"
        triage_records.append(
            OperatorTriageRecord(
                family=family_name,
                triage_status=triage_status,
                alert_alignment=alert_alignment,
                latest_run_id=latest_record.run_id,
                latest_run_source_kind=latest_record.source_kind,
                latest_run_health_status=latest_record.health_status,
                latest_run_timestamp_utc=latest_record.timestamp_utc,
                latest_gap_status=latest_gap_status,
                latest_gap_reasons=latest_gap_reasons,
                latest_gap_domains=latest_gap_domains,
                latest_alert_run_id=None if latest_alert is None else latest_alert.run_id,
                latest_alert_source_kind=None if latest_alert is None else latest_alert.source_kind,
                latest_alert_health_status=None if latest_alert is None else latest_alert.health_status,
                latest_alert_timestamp_utc=None if latest_alert is None else latest_alert.timestamp_utc,
                latest_alert_reasons=[] if latest_alert is None else latest_alert.health_reasons,
                latest_alert_domains=latest_alert_domains,
                latest_alert_failed_checks=[] if latest_alert is None else latest_alert.failed_checks,
                latest_failure_run_id=None if latest_failure is None else latest_failure.run_id,
                latest_failure_domains=[] if latest_failure is None else latest_failure.failure_domains,
            )
        )
    triage_records.sort(key=lambda record: (record.latest_run_timestamp_utc, record.family), reverse=True)
    return triage_records


def render_operator_triage_table(records: list[OperatorTriageRecord]) -> str:
    lines = [
        "family\ttriage_status\talert_alignment\tlatest_gap_status\tlatest_gap_domains\tlatest_gap_reasons\tlatest_run\tlatest_run_source\tlatest_run_health\tlatest_alert_run\tlatest_alert_source\tlatest_alert_health\tlatest_alert_domains\tlatest_alert_failed_checks\tlatest_failure_run\tlatest_failure_domains\tlatest_timestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.family,
                    record.triage_status,
                    record.alert_alignment,
                    record.latest_gap_status,
                    ",".join(record.latest_gap_domains),
                    ",".join(record.latest_gap_reasons),
                    record.latest_run_id,
                    record.latest_run_source_kind,
                    record.latest_run_health_status,
                    record.latest_alert_run_id or "",
                    record.latest_alert_source_kind or "",
                    record.latest_alert_health_status or "",
                    ",".join(record.latest_alert_domains),
                    ",".join(record.latest_alert_failed_checks),
                    record.latest_failure_run_id or "",
                    ",".join(record.latest_failure_domains),
                    record.latest_run_timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_operator_triage_markdown(records: list[OperatorTriageRecord]) -> str:
    lines = [
        "| family | triage_status | alert_alignment | latest_gap_status | latest_gap_domains | latest_gap_reasons | latest_run | latest_run_source | latest_run_health | latest_alert_run | latest_alert_source | latest_alert_health | latest_alert_domains | latest_alert_failed_checks | latest_failure_run | latest_failure_domains | latest_timestamp |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | {record.triage_status} | {record.alert_alignment} | {record.latest_gap_status} | "
            f"{', '.join(record.latest_gap_domains)} | {', '.join(record.latest_gap_reasons)} | "
            f"`{record.latest_run_id}` | {record.latest_run_source_kind} | {record.latest_run_health_status} | "
            f"`{record.latest_alert_run_id or ''}` | {record.latest_alert_source_kind or ''} | "
            f"{record.latest_alert_health_status or ''} | {', '.join(record.latest_alert_domains)} | "
            f"{', '.join(record.latest_alert_failed_checks)} | `{record.latest_failure_run_id or ''}` | "
            f"{', '.join(record.latest_failure_domains)} | {record.latest_run_timestamp_utc} |"
        )
    return "\n".join(lines)


def build_triage_summary_records(
    *,
    records: list[SummaryRecord],
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> list[TriageSummaryRecord]:
    triage_records = build_operator_triage_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    grouped: dict[str, list[OperatorTriageRecord]] = {}
    for record in triage_records:
        grouped.setdefault(record.triage_status, []).append(record)

    summaries: list[TriageSummaryRecord] = []
    for triage_status, bucket_records in grouped.items():
        newest = bucket_records[0]
        alert_alignment_counts: dict[str, int] = {}
        latest_gap_domain_counts: dict[str, int] = {}
        latest_alert_domain_counts: dict[str, int] = {}
        for record in bucket_records:
            alert_alignment_counts[record.alert_alignment] = alert_alignment_counts.get(record.alert_alignment, 0) + 1
            for domain in record.latest_gap_domains:
                latest_gap_domain_counts[domain] = latest_gap_domain_counts.get(domain, 0) + 1
            for domain in record.latest_alert_domains:
                latest_alert_domain_counts[domain] = latest_alert_domain_counts.get(domain, 0) + 1
        summaries.append(
            TriageSummaryRecord(
                triage_status=triage_status,
                family_count=len(bucket_records),
                families=[record.family for record in bucket_records],
                newest_family=newest.family,
                newest_run_id=newest.latest_run_id,
                newest_run_source_kind=newest.latest_run_source_kind,
                newest_run_timestamp_utc=newest.latest_run_timestamp_utc,
                alert_alignment_counts={key: alert_alignment_counts[key] for key in sorted(alert_alignment_counts)},
                latest_gap_domain_counts={key: latest_gap_domain_counts[key] for key in sorted(latest_gap_domain_counts)},
                latest_alert_domain_counts={key: latest_alert_domain_counts[key] for key in sorted(latest_alert_domain_counts)},
            )
        )
    summaries.sort(key=lambda record: (record.newest_run_timestamp_utc, record.triage_status), reverse=True)
    return summaries


def render_triage_summary_table(records: list[TriageSummaryRecord]) -> str:
    lines = [
        "triage_status\tfamily_count\tfamilies\tnewest_family\tnewest_run\tnewest_source\talert_alignment_counts\tlatest_gap_domain_counts\tlatest_alert_domain_counts\tnewest_timestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.triage_status,
                    str(record.family_count),
                    ",".join(record.families),
                    record.newest_family,
                    record.newest_run_id,
                    record.newest_run_source_kind,
                    ",".join(f"{key}={value}" for key, value in record.alert_alignment_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.latest_gap_domain_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.latest_alert_domain_counts.items()),
                    record.newest_run_timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_triage_summary_markdown(records: list[TriageSummaryRecord]) -> str:
    lines = [
        "| triage_status | family_count | families | newest_family | newest_run | newest_source | alert_alignment_counts | latest_gap_domain_counts | latest_alert_domain_counts | newest_timestamp |",
        "| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.triage_status} | {record.family_count} | {', '.join(record.families)} | "
            f"{record.newest_family} | `{record.newest_run_id}` | {record.newest_run_source_kind} | "
            f"{', '.join(f'{key}={value}' for key, value in record.alert_alignment_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.latest_gap_domain_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.latest_alert_domain_counts.items())} | "
            f"{record.newest_run_timestamp_utc} |"
        )
    return "\n".join(lines)


def build_triage_overview_record(
    *,
    records: list[SummaryRecord],
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> TriageOverviewRecord:
    triage_records = build_operator_triage_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    triage_status_counts: dict[str, int] = {}
    alert_alignment_counts: dict[str, int] = {}
    latest_gap_domain_counts: dict[str, int] = {}
    latest_alert_domain_counts: dict[str, int] = {}
    for record in triage_records:
        triage_status_counts[record.triage_status] = triage_status_counts.get(record.triage_status, 0) + 1
        alert_alignment_counts[record.alert_alignment] = alert_alignment_counts.get(record.alert_alignment, 0) + 1
        for domain in record.latest_gap_domains:
            latest_gap_domain_counts[domain] = latest_gap_domain_counts.get(domain, 0) + 1
        for domain in record.latest_alert_domains:
            latest_alert_domain_counts[domain] = latest_alert_domain_counts.get(domain, 0) + 1

    newest_failing = next((record for record in triage_records if record.triage_status in {"active", "lagging"}), None)
    newest_recovered = next((record for record in triage_records if record.triage_status == "clear"), None)

    return TriageOverviewRecord(
        total_families=len(triage_records),
        triage_status_counts={key: triage_status_counts[key] for key in sorted(triage_status_counts)},
        alert_alignment_counts={key: alert_alignment_counts[key] for key in sorted(alert_alignment_counts)},
        latest_gap_domain_counts={key: latest_gap_domain_counts[key] for key in sorted(latest_gap_domain_counts)},
        latest_alert_domain_counts={key: latest_alert_domain_counts[key] for key in sorted(latest_alert_domain_counts)},
        newest_failing_family=None if newest_failing is None else newest_failing.family,
        newest_failing_run_id=None if newest_failing is None else newest_failing.latest_run_id,
        newest_failing_source_kind=None if newest_failing is None else newest_failing.latest_run_source_kind,
        newest_failing_triage_status=None if newest_failing is None else newest_failing.triage_status,
        newest_failing_timestamp_utc=None if newest_failing is None else newest_failing.latest_run_timestamp_utc,
        newest_failing_gap_domains=[] if newest_failing is None else newest_failing.latest_gap_domains,
        newest_failing_alert_domains=[] if newest_failing is None else newest_failing.latest_alert_domains,
        newest_recovered_family=None if newest_recovered is None else newest_recovered.family,
        newest_recovered_run_id=None if newest_recovered is None else newest_recovered.latest_run_id,
        newest_recovered_source_kind=None if newest_recovered is None else newest_recovered.latest_run_source_kind,
        newest_recovered_timestamp_utc=None if newest_recovered is None else newest_recovered.latest_run_timestamp_utc,
    )


def render_triage_overview_table(record: TriageOverviewRecord) -> str:
    return "\n".join(
        [
            "total_families\ttriage_status_counts\talert_alignment_counts\tlatest_gap_domain_counts\tlatest_alert_domain_counts\tnewest_failing_family\tnewest_failing_run\tnewest_failing_source\tnewest_failing_status\tnewest_failing_gap_domains\tnewest_failing_alert_domains\tnewest_recovered_family\tnewest_recovered_run\tnewest_recovered_source",
            "\t".join(
                [
                    str(record.total_families),
                    ",".join(f"{key}={value}" for key, value in record.triage_status_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.alert_alignment_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.latest_gap_domain_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.latest_alert_domain_counts.items()),
                    record.newest_failing_family or "",
                    record.newest_failing_run_id or "",
                    record.newest_failing_source_kind or "",
                    record.newest_failing_triage_status or "",
                    ",".join(record.newest_failing_gap_domains),
                    ",".join(record.newest_failing_alert_domains),
                    record.newest_recovered_family or "",
                    record.newest_recovered_run_id or "",
                    record.newest_recovered_source_kind or "",
                ]
            ),
        ]
    )


def render_triage_overview_markdown(record: TriageOverviewRecord) -> str:
    return "\n".join(
        [
            "| total_families | triage_status_counts | alert_alignment_counts | latest_gap_domain_counts | latest_alert_domain_counts | newest_failing_family | newest_failing_run | newest_failing_source | newest_failing_status | newest_failing_gap_domains | newest_failing_alert_domains | newest_recovered_family | newest_recovered_run | newest_recovered_source |",
            "| ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
            f"| {record.total_families} | {', '.join(f'{key}={value}' for key, value in record.triage_status_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.alert_alignment_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.latest_gap_domain_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.latest_alert_domain_counts.items())} | "
            f"{record.newest_failing_family or ''} | `{record.newest_failing_run_id or ''}` | {record.newest_failing_source_kind or ''} | "
            f"{record.newest_failing_triage_status or ''} | {', '.join(record.newest_failing_gap_domains)} | "
            f"{', '.join(record.newest_failing_alert_domains)} | {record.newest_recovered_family or ''} | "
            f"`{record.newest_recovered_run_id or ''}` | {record.newest_recovered_source_kind or ''} |",
        ]
    )


def build_triage_target_records(
    *,
    records: list[SummaryRecord],
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> list[TriageTargetRecord]:
    triage_records = build_operator_triage_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    active_targets: list[TriageTargetRecord] = []
    lagging_targets: list[TriageTargetRecord] = []

    for record in triage_records:
        if record.triage_status == "clear":
            continue
        if record.triage_status == "active":
            target_record = TriageTargetRecord(
                priority_bucket="active",
                target_kind="latest-gap",
                family=record.family,
                triage_status=record.triage_status,
                alert_alignment=record.alert_alignment,
                latest_run_id=record.latest_run_id,
                latest_run_source_kind=record.latest_run_source_kind,
                latest_run_health_status=record.latest_run_health_status,
                latest_run_timestamp_utc=record.latest_run_timestamp_utc,
                target_run_id=record.latest_run_id,
                target_source_kind=record.latest_run_source_kind,
                target_health_status=record.latest_run_health_status,
                target_timestamp_utc=record.latest_run_timestamp_utc,
                target_domains=record.latest_gap_domains,
                target_reasons=record.latest_gap_reasons,
                target_failed_checks=record.latest_alert_failed_checks if record.alert_alignment == "current" else [],
            )
            active_targets.append(target_record)
            continue
        if record.latest_alert_run_id is None or record.latest_alert_source_kind is None or record.latest_alert_health_status is None:
            continue
        lagging_targets.append(
            TriageTargetRecord(
                priority_bucket="lagging",
                target_kind="latest-alert-follow-up",
                family=record.family,
                triage_status=record.triage_status,
                alert_alignment=record.alert_alignment,
                latest_run_id=record.latest_run_id,
                latest_run_source_kind=record.latest_run_source_kind,
                latest_run_health_status=record.latest_run_health_status,
                latest_run_timestamp_utc=record.latest_run_timestamp_utc,
                target_run_id=record.latest_alert_run_id,
                target_source_kind=record.latest_alert_source_kind,
                target_health_status=record.latest_alert_health_status,
                target_timestamp_utc=record.latest_alert_timestamp_utc or record.latest_run_timestamp_utc,
                target_domains=record.latest_alert_domains,
                target_reasons=record.latest_alert_reasons,
                target_failed_checks=record.latest_alert_failed_checks,
            )
        )
    return active_targets + lagging_targets


def render_triage_targets_table(records: list[TriageTargetRecord]) -> str:
    lines = [
        "priority_bucket\ttarget_kind\tfamily\ttriage_status\talert_alignment\ttarget_run\ttarget_source\ttarget_health\ttarget_domains\ttarget_reasons\ttarget_failed_checks\tlatest_run\tlatest_source\tlatest_health\tlatest_timestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.priority_bucket,
                    record.target_kind,
                    record.family,
                    record.triage_status,
                    record.alert_alignment,
                    record.target_run_id,
                    record.target_source_kind,
                    record.target_health_status,
                    ",".join(record.target_domains),
                    ",".join(record.target_reasons),
                    ",".join(record.target_failed_checks),
                    record.latest_run_id,
                    record.latest_run_source_kind,
                    record.latest_run_health_status,
                    record.latest_run_timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_triage_targets_markdown(records: list[TriageTargetRecord]) -> str:
    lines = [
        "| priority_bucket | target_kind | family | triage_status | alert_alignment | target_run | target_source | target_health | target_domains | target_reasons | target_failed_checks | latest_run | latest_source | latest_health | latest_timestamp |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.priority_bucket} | {record.target_kind} | {record.family} | {record.triage_status} | "
            f"{record.alert_alignment} | `{record.target_run_id}` | {record.target_source_kind} | "
            f"{record.target_health_status} | {', '.join(record.target_domains)} | "
            f"{', '.join(record.target_reasons)} | {', '.join(record.target_failed_checks)} | "
            f"`{record.latest_run_id}` | {record.latest_run_source_kind} | {record.latest_run_health_status} | "
            f"{record.latest_run_timestamp_utc} |"
        )
    return "\n".join(lines)


def build_triage_queue_records(
    *,
    records: list[SummaryRecord],
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> list[TriageQueueRecord]:
    target_records = build_triage_target_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    grouped: dict[str, list[TriageTargetRecord]] = {}
    for record in target_records:
        grouped.setdefault(record.priority_bucket, []).append(record)

    queue_records: list[TriageQueueRecord] = []
    for priority_bucket in ("active", "lagging"):
        bucket_records = grouped.get(priority_bucket, [])
        if not bucket_records:
            continue
        bucket_records = sorted(
            bucket_records,
            key=lambda record: (record.target_timestamp_utc, record.family),
            reverse=True,
        )
        newest = bucket_records[0]
        target_kind_counts: dict[str, int] = {}
        target_domain_counts: dict[str, int] = {}
        for record in bucket_records:
            target_kind_counts[record.target_kind] = target_kind_counts.get(record.target_kind, 0) + 1
            for domain in record.target_domains:
                target_domain_counts[domain] = target_domain_counts.get(domain, 0) + 1
        queue_records.append(
            TriageQueueRecord(
                priority_bucket=priority_bucket,
                target_count=len(bucket_records),
                families=[record.family for record in bucket_records],
                newest_target_family=newest.family,
                newest_target_run_id=newest.target_run_id,
                newest_target_source_kind=newest.target_source_kind,
                newest_target_health_status=newest.target_health_status,
                newest_target_timestamp_utc=newest.target_timestamp_utc,
                newest_target_kind=newest.target_kind,
                target_kind_counts={key: target_kind_counts[key] for key in sorted(target_kind_counts)},
                target_domain_counts={key: target_domain_counts[key] for key in sorted(target_domain_counts)},
            )
        )
    return queue_records


def render_triage_queue_table(records: list[TriageQueueRecord]) -> str:
    lines = [
        "priority_bucket\ttarget_count\tfamilies\tnewest_target_family\tnewest_target_run\tnewest_target_source\tnewest_target_health\tnewest_target_kind\ttarget_kind_counts\ttarget_domain_counts\tnewest_target_timestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.priority_bucket,
                    str(record.target_count),
                    ",".join(record.families),
                    record.newest_target_family,
                    record.newest_target_run_id,
                    record.newest_target_source_kind,
                    record.newest_target_health_status,
                    record.newest_target_kind,
                    ",".join(f"{key}={value}" for key, value in record.target_kind_counts.items()),
                    ",".join(f"{key}={value}" for key, value in record.target_domain_counts.items()),
                    record.newest_target_timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_triage_queue_markdown(records: list[TriageQueueRecord]) -> str:
    lines = [
        "| priority_bucket | target_count | families | newest_target_family | newest_target_run | newest_target_source | newest_target_health | newest_target_kind | target_kind_counts | target_domain_counts | newest_target_timestamp |",
        "| --- | ---: | --- | --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.priority_bucket} | {record.target_count} | {', '.join(record.families)} | "
            f"{record.newest_target_family} | `{record.newest_target_run_id}` | {record.newest_target_source_kind} | "
            f"{record.newest_target_health_status} | {record.newest_target_kind} | "
            f"{', '.join(f'{key}={value}' for key, value in record.target_kind_counts.items())} | "
            f"{', '.join(f'{key}={value}' for key, value in record.target_domain_counts.items())} | "
            f"{record.newest_target_timestamp_utc} |"
        )
    return "\n".join(lines)


def build_triage_feed_record(
    *,
    records: list[SummaryRecord],
    local_records: list[LocalOperatorStackRecord] | None,
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
    target_limit: int,
) -> TriageFeedRecord:
    overview = build_triage_overview_record(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    queue_records = build_triage_queue_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )
    target_records = build_triage_target_records(
        records=records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
    )[:target_limit]
    local_operator_record = None
    if family is None and run_id_prefix is None and local_records is not None:
        local_operator_record = select_latest_local_operator_stack_record(local_records)
    return TriageFeedRecord(
        source_kind=source_kind,
        target_limit=target_limit,
        overview=overview,
        queue_records=queue_records,
        target_records=target_records,
        local_operator_record=local_operator_record,
    )


def render_triage_feed_table(record: TriageFeedRecord) -> str:
    sections = [
        f"source_kind\t{record.source_kind}",
        f"target_limit\t{record.target_limit}",
        "overview",
        render_triage_overview_table(record.overview),
    ]
    if record.local_operator_record is not None:
        local_record = record.local_operator_record
        sections.extend(
            [
                "local_operator",
                (
                    "run_id\tverdict\treadiness\tstack\tdirect\texecution_mode\treason_code\tgenerated_at_utc\n"
                    f"{local_record.run_id}\t{local_record.verdict or ''}\t{local_record.readiness_status}\t"
                    f"{local_record.stack_status}\t{local_record.direct_status}\t"
                    f"{local_record.execution_mode or ''}\t{local_record.reason_code or ''}\t"
                    f"{local_record.generated_at_utc}"
                ),
            ]
        )
    sections.extend(
        [
        "queue",
        render_triage_queue_table(record.queue_records),
        "targets",
        render_triage_targets_table(record.target_records),
        ]
    )
    return "\n".join(sections)


def render_triage_feed_markdown(record: TriageFeedRecord) -> str:
    sections = [
        f"## Triage Feed\n\n- source_kind: `{record.source_kind}`\n- target_limit: `{record.target_limit}`",
        "### Overview\n\n" + render_triage_overview_markdown(record.overview),
    ]
    if record.local_operator_record is not None:
        local_record = record.local_operator_record
        local_lines = [
            "### Local Operator Stack",
            "",
            f"- run_id: `{local_record.run_id}`",
            f"- verdict: `{local_record.verdict or ''}`",
            f"- readiness: `{local_record.readiness_status}`",
            f"- stack/direct: `{local_record.stack_status}` / `{local_record.direct_status}`",
            f"- execution_mode: `{local_record.execution_mode or ''}`",
            f"- reason_code: `{local_record.reason_code or ''}`",
        ]
        if local_record.recommended_next_steps:
            local_lines.append(f"- next_step: {local_record.recommended_next_steps[0]}")
        sections.append("\n".join(local_lines))
    sections.extend(
        [
            "### Queue\n\n" + render_triage_queue_markdown(record.queue_records),
            "### Targets\n\n" + render_triage_targets_markdown(record.target_records),
        ]
    )
    return "\n\n".join(sections)


def build_triage_brief_record(
    *,
    records: list[SummaryRecord],
    local_records: list[LocalOperatorStackRecord] | None,
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
    target_limit: int,
) -> TriageBriefRecord:
    feed = build_triage_feed_record(
        records=records,
        local_records=local_records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
        target_limit=target_limit,
    )
    overview = feed.overview
    queue_lines = [
        (
            f"{queue.priority_bucket}: targets={queue.target_count} "
            f"newest={queue.newest_target_family}/{queue.newest_target_run_id} "
            f"domains={','.join(f'{key}={value}' for key, value in queue.target_domain_counts.items())}"
        )
        for queue in feed.queue_records
    ]
    target_lines = [
        (
            f"[{target.priority_bucket}/{target.target_kind}] "
            f"{target.family} -> {target.target_run_id} "
            f"domains={','.join(target.target_domains)}"
        )
        for target in feed.target_records
    ]
    return TriageBriefRecord(
        source_kind=source_kind,
        target_limit=target_limit,
        attention_family_count=overview.triage_status_counts.get("active", 0) + overview.triage_status_counts.get("lagging", 0),
        active_family_count=overview.triage_status_counts.get("active", 0),
        lagging_family_count=overview.triage_status_counts.get("lagging", 0),
        clear_family_count=overview.triage_status_counts.get("clear", 0),
        newest_failing_family=overview.newest_failing_family,
        newest_failing_run_id=overview.newest_failing_run_id,
        newest_failing_triage_status=overview.newest_failing_triage_status,
        newest_recovered_family=overview.newest_recovered_family,
        newest_recovered_run_id=overview.newest_recovered_run_id,
        local_operator_record=feed.local_operator_record,
        local_operator_summary=build_local_operator_summary(feed.local_operator_record),
        local_operator_next_step=build_local_operator_next_step(feed.local_operator_record),
        queue_lines=queue_lines,
        target_lines=target_lines,
    )


def render_triage_brief_table(record: TriageBriefRecord) -> str:
    sections = [
        f"source_kind\t{record.source_kind}",
        f"target_limit\t{record.target_limit}",
        (
            f"attention\tfamilies={record.attention_family_count},active={record.active_family_count},"
            f"lagging={record.lagging_family_count},clear={record.clear_family_count}"
        ),
        (
            f"newest_failing\t{record.newest_failing_family or ''}\t"
            f"{record.newest_failing_run_id or ''}\t{record.newest_failing_triage_status or ''}"
        ),
    ]
    if record.local_operator_summary is not None:
        sections.append(f"local_operator\t{record.local_operator_summary}")
    if record.local_operator_next_step is not None:
        sections.append(f"local_operator_next_step\t{record.local_operator_next_step}")
    sections.extend(["queue", *record.queue_lines, "targets", *record.target_lines])
    return "\n".join(sections)


def render_triage_brief_markdown(record: TriageBriefRecord) -> str:
    lines = [
        "## Triage Brief",
        f"- source_kind: `{record.source_kind}`",
        f"- top target window: `{record.target_limit}`",
        (
            f"- attention families: `{record.attention_family_count}` "
            f"(`active={record.active_family_count}`, `lagging={record.lagging_family_count}`, `clear={record.clear_family_count}`)"
        ),
        (
            f"- newest failing pointer: `{record.newest_failing_family or ''}` / "
            f"`{record.newest_failing_run_id or ''}` ({record.newest_failing_triage_status or 'none'})"
        ),
    ]
    if record.newest_recovered_family or record.newest_recovered_run_id:
        lines.append(
            f"- newest recovered pointer: `{record.newest_recovered_family or ''}` / `{record.newest_recovered_run_id or ''}`"
        )
    if record.local_operator_summary is not None:
        lines.append(f"- local operator: `{record.local_operator_summary}`")
    if record.local_operator_next_step is not None:
        lines.append(f"- local operator next step: {record.local_operator_next_step}")
    lines.append("")
    lines.append("### Queue")
    lines.extend(f"- {line}" for line in record.queue_lines)
    lines.append("")
    lines.append("### Top Targets")
    lines.extend(f"{index}. {line}" for index, line in enumerate(record.target_lines, start=1))
    return "\n".join(lines)


def build_triage_report_record(
    *,
    records: list[SummaryRecord],
    local_records: list[LocalOperatorStackRecord] | None,
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
    target_limit: int,
) -> TriageReportRecord:
    brief = build_triage_brief_record(
        records=records,
        local_records=local_records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
        target_limit=target_limit,
    )
    headline = f"Federated CI triage report: {brief.attention_family_count} attention families"
    attention_summary = (
        f"active={brief.active_family_count}, lagging={brief.lagging_family_count}, clear={brief.clear_family_count}"
    )
    newest_failing_summary = (
        f"{brief.newest_failing_family or 'none'} / {brief.newest_failing_run_id or 'none'} / "
        f"{brief.newest_failing_triage_status or 'none'}"
    )
    newest_recovered_summary = None
    if brief.newest_recovered_family or brief.newest_recovered_run_id:
        newest_recovered_summary = f"{brief.newest_recovered_family or 'none'} / {brief.newest_recovered_run_id or 'none'}"
    markdown_lines = [
        "## Federated CI Triage Report",
        "",
        "### Snapshot",
        f"- source_kind: `{brief.source_kind}`",
        f"- top target window: `{brief.target_limit}`",
        f"- attention families: `{brief.attention_family_count}` ({attention_summary})",
        f"- newest failing pointer: `{brief.newest_failing_family or ''}` / `{brief.newest_failing_run_id or ''}` ({brief.newest_failing_triage_status or 'none'})",
    ]
    if newest_recovered_summary is not None:
        markdown_lines.append(
            f"- newest recovered pointer: `{brief.newest_recovered_family or ''}` / `{brief.newest_recovered_run_id or ''}`"
        )
    if brief.local_operator_summary is not None:
        markdown_lines.append(f"- local operator: `{brief.local_operator_summary}`")
    if brief.local_operator_next_step is not None:
        markdown_lines.append(f"- local operator next step: {brief.local_operator_next_step}")
    markdown_lines.extend(
        [
            "",
            "### Queue",
            *[f"- {line}" for line in brief.queue_lines],
            "",
            "### Top Targets",
            *[f"{index}. {line}" for index, line in enumerate(brief.target_lines, start=1)],
        ]
    )
    return TriageReportRecord(
        source_kind=brief.source_kind,
        target_limit=brief.target_limit,
        headline=headline,
        attention_summary=attention_summary,
        newest_failing_summary=newest_failing_summary,
        newest_recovered_summary=newest_recovered_summary,
        local_operator_record=brief.local_operator_record,
        local_operator_summary=brief.local_operator_summary,
        local_operator_next_step=brief.local_operator_next_step,
        queue_lines=brief.queue_lines,
        target_lines=brief.target_lines,
        markdown="\n".join(markdown_lines),
    )


def render_triage_report_table(record: TriageReportRecord) -> str:
    sections = [
        f"headline\t{record.headline}",
        f"source_kind\t{record.source_kind}",
        f"target_limit\t{record.target_limit}",
        f"attention_summary\t{record.attention_summary}",
        f"newest_failing\t{record.newest_failing_summary}",
    ]
    if record.newest_recovered_summary is not None:
        sections.append(f"newest_recovered\t{record.newest_recovered_summary}")
    if record.local_operator_summary is not None:
        sections.append(f"local_operator\t{record.local_operator_summary}")
    if record.local_operator_next_step is not None:
        sections.append(f"local_operator_next_step\t{record.local_operator_next_step}")
    sections.extend(["queue", *record.queue_lines, "targets", *record.target_lines])
    return "\n".join(sections)


def render_triage_report_markdown(record: TriageReportRecord) -> str:
    return record.markdown


def build_handoff_report_record(
    *,
    records: list[SummaryRecord],
    local_records: list[LocalOperatorStackRecord] | None,
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
    target_limit: int,
) -> HandoffReportRecord:
    triage_report = build_triage_report_record(
        records=records,
        local_records=local_records,
        family=family,
        run_id_prefix=run_id_prefix,
        source_kind=source_kind,
        target_limit=target_limit,
    )
    headline = f"Operator handoff report: {triage_report.headline.removeprefix('Federated CI triage report: ')}"
    immediate_action_lines: list[str] = []
    if triage_report.local_operator_next_step is not None:
        immediate_action_lines.append(f"local-runtime: {triage_report.local_operator_next_step}")
    if triage_report.target_lines:
        immediate_action_lines.append(f"triage-target: {triage_report.target_lines[0]}")
    if len(triage_report.target_lines) > 1:
        immediate_action_lines.append(f"follow-up: {triage_report.target_lines[1]}")

    markdown_lines = [
        "## Operator Handoff Report",
        "",
        "### Snapshot",
        f"- headline: {headline}",
        f"- source_kind: `{triage_report.source_kind}`",
        f"- top target window: `{triage_report.target_limit}`",
        f"- attention families: `{triage_report.attention_summary}`",
        f"- newest failing pointer: {triage_report.newest_failing_summary}",
    ]
    if triage_report.newest_recovered_summary is not None:
        markdown_lines.append(f"- newest recovered pointer: {triage_report.newest_recovered_summary}")
    markdown_lines.extend(["", "### Local Runtime"])
    if triage_report.local_operator_summary is None:
        markdown_lines.append("- local operator: unavailable")
    else:
        markdown_lines.append(f"- local operator: `{triage_report.local_operator_summary}`")
    if triage_report.local_operator_next_step is not None:
        markdown_lines.append(f"- local operator next step: {triage_report.local_operator_next_step}")
    markdown_lines.extend(["", "### Queue", *[f"- {line}" for line in triage_report.queue_lines]])
    markdown_lines.extend(
        ["", "### Top Targets", *[f"{index}. {line}" for index, line in enumerate(triage_report.target_lines, start=1)]]
    )
    markdown_lines.extend(
        ["", "### Immediate Actions", *[f"{index}. {line}" for index, line in enumerate(immediate_action_lines, start=1)]]
    )
    return HandoffReportRecord(
        source_kind=triage_report.source_kind,
        target_limit=triage_report.target_limit,
        headline=headline,
        attention_summary=triage_report.attention_summary,
        newest_failing_summary=triage_report.newest_failing_summary,
        newest_recovered_summary=triage_report.newest_recovered_summary,
        local_operator_record=triage_report.local_operator_record,
        local_operator_summary=triage_report.local_operator_summary,
        local_operator_next_step=triage_report.local_operator_next_step,
        queue_lines=triage_report.queue_lines,
        target_lines=triage_report.target_lines,
        immediate_action_lines=immediate_action_lines,
        markdown="\n".join(markdown_lines),
    )


def render_handoff_report_table(record: HandoffReportRecord) -> str:
    sections = [
        f"headline\t{record.headline}",
        f"source_kind\t{record.source_kind}",
        f"target_limit\t{record.target_limit}",
        f"attention_summary\t{record.attention_summary}",
        f"newest_failing\t{record.newest_failing_summary}",
    ]
    if record.newest_recovered_summary is not None:
        sections.append(f"newest_recovered\t{record.newest_recovered_summary}")
    if record.local_operator_summary is not None:
        sections.append(f"local_operator\t{record.local_operator_summary}")
    if record.local_operator_next_step is not None:
        sections.append(f"local_operator_next_step\t{record.local_operator_next_step}")
    sections.extend(["queue", *record.queue_lines, "targets", *record.target_lines, "immediate_actions", *record.immediate_action_lines])
    return "\n".join(sections)


def render_handoff_report_markdown(record: HandoffReportRecord) -> str:
    return record.markdown


def build_handoff_artifact_document(
    *,
    record: HandoffReportRecord,
    report_id: str,
    latest_report_path: Path,
    stamped_report_path: Path,
    output_path: Path | None,
) -> dict[str, Any]:
    return {
        "generated_at_utc": now_utc(),
        "report_id": report_id,
        "artifact_paths": {
            "latest_report_path": str(latest_report_path.resolve()),
            "stamped_report_path": str(stamped_report_path.resolve()),
            "output_path": None if output_path is None else str(output_path.resolve()),
        },
        "record": asdict(record),
    }


def select_record(
    *,
    records: list[SummaryRecord],
    run_id: str,
    source_kind: str,
) -> SummaryRecord | None:
    matches = [record for record in records if record.run_id == run_id]
    if not matches:
        return None
    if source_kind != "auto":
        narrowed = [record for record in matches if record.source_kind == source_kind]
        return narrowed[0] if narrowed else None
    stamped = [record for record in matches if record.source_kind == "stamped"]
    return stamped[0] if stamped else matches[0]


def load_checks_payload(summary_path: Path) -> list[dict[str, Any]]:
    doc = load_json(summary_path)
    return list(doc.get("checks") or [])


def render_checks_table(record: SummaryRecord, checks: list[dict[str, Any]]) -> str:
    lines = [
        f"run_id={record.run_id}",
        f"source_kind={record.source_kind}",
        f"summary_path={record.summary_path}",
        "name\tdomain\tverdict\texit_code\tresult",
    ]
    for check in checks:
        lines.append(
            "\t".join(
                [
                    str(check.get("name") or ""),
                    str(check.get("domain") or ""),
                    str(check.get("verdict") or ""),
                    str(check.get("exit_code") if check.get("exit_code") is not None else ""),
                    str(check.get("result") or ""),
                ]
            )
        )
    return "\n".join(lines)


def reconcile_doc_matches_record(
    *,
    record: ReconcileStatusRecord,
    reconcile_doc: dict[str, Any] | None,
    reconcile_path: Path | None,
) -> bool:
    if reconcile_path is None or not isinstance(reconcile_doc, dict):
        return False
    if resolve_artifact_path(reconcile_doc.get("output_path")) != reconcile_path.resolve():
        return False
    if reconcile_doc.get("run_id") != record.run_id:
        return False
    if reconcile_doc.get("status") != record.status:
        return False
    if reconcile_doc.get("restored") != record.restored:
        return False
    reconcile_count = reconcile_doc.get("reconcile_count")
    restored_check_names = reconcile_doc.get("restored_check_names")
    if not isinstance(reconcile_count, int) or isinstance(reconcile_count, bool) or reconcile_count < 0:
        return False
    if not isinstance(restored_check_names, list):
        return False
    normalized_restored = [name for name in restored_check_names if isinstance(name, str) and name.strip()]
    if len(normalized_restored) != reconcile_count:
        return False
    if normalized_restored != record.restored_check_names:
        return False
    return True


def reconcile_validation_matches_record(
    *,
    reconcile_doc: dict[str, Any] | None,
    reconcile_validation_doc: dict[str, Any] | None,
    reconcile_path: Path | None,
) -> bool:
    if reconcile_path is None or not isinstance(reconcile_doc, dict) or not isinstance(reconcile_validation_doc, dict):
        return False
    if resolve_artifact_path(reconcile_validation_doc.get("reconcile_report_path")) != reconcile_path.resolve():
        return False
    if reconcile_validation_doc.get("reconcile_generated_at_utc") != reconcile_doc.get("generated_at_utc"):
        return False
    if reconcile_validation_doc.get("reconcile_run_id") != reconcile_doc.get("run_id"):
        return False
    if reconcile_validation_doc.get("reconcile_status") != reconcile_doc.get("status"):
        return False
    if reconcile_validation_doc.get("reconcile_restored") != reconcile_doc.get("restored"):
        return False
    if reconcile_validation_doc.get("reconcile_count") != reconcile_doc.get("reconcile_count"):
        return False
    return True


def build_reconcile_observed_state(
    *,
    record: ReconcileStatusRecord,
    reconcile_path: Path | None,
    reconcile_validation_path: Path | None,
    reconcile_doc: dict[str, Any] | None,
    reconcile_validation_doc: dict[str, Any] | None,
) -> tuple[str, str, str]:
    reconcile_artifact_state = (
        "fresh"
        if reconcile_doc_matches_record(record=record, reconcile_doc=reconcile_doc, reconcile_path=reconcile_path)
        else ("stale" if reconcile_path is not None and reconcile_path.exists() else "missing")
    )
    reconcile_validation_verdict = (
        str(reconcile_validation_doc.get("verdict") or "unknown")
        if isinstance(reconcile_validation_doc, dict)
        else ("unknown" if reconcile_validation_path is not None and reconcile_validation_path.exists() else "missing")
    )
    reconcile_validation_state = (
        "fresh"
        if reconcile_validation_matches_record(
            reconcile_doc=reconcile_doc,
            reconcile_validation_doc=reconcile_validation_doc,
            reconcile_path=reconcile_path,
        )
        else ("stale" if reconcile_validation_path is not None and reconcile_validation_path.exists() else "missing")
    )
    return reconcile_artifact_state, reconcile_validation_verdict, reconcile_validation_state


def render_reconcile_table(records: list[ReconcileStatusRecord]) -> str:
    return "\n".join(
        [
            "family\trun_id\tsource\tstatus\tartifact_state\tvalidation_state\tcheckpoint_state\trestored\treconcile_count\treasons\trestored_checks\ttimestamp",
            *[
                "\t".join(
                    [
                        record.family,
                        record.run_id,
                        record.source_kind,
                        record.status,
                        record.reconcile_artifact_state,
                        record.reconcile_validation_state,
                        record.checkpoint_state,
                        (
                            "true"
                            if record.restored is True
                            else ("false" if record.restored is False else "unknown")
                        ),
                        str(record.reconcile_count),
                        ",".join(record.reasons),
                        ",".join(record.restored_check_names),
                        record.timestamp_utc,
                    ]
                )
                for record in records
            ],
        ]
    )


def render_reconcile_markdown(record: ReconcileStatusRecord) -> str:
    lines = [
        f"# `{record.run_id}` reconcile status",
        "",
        f"- family: `{record.family}`",
        f"- source_kind: `{record.source_kind}`",
        f"- status: `{record.status}`",
        f"- restored: `{str(record.restored).lower()}`",
        f"- reconcile_artifact_state: `{record.reconcile_artifact_state}`",
        f"- reconcile_validation_state: `{record.reconcile_validation_state}`",
        f"- checkpoint_state: `{record.checkpoint_state}`",
        f"- reconcile_count: `{record.reconcile_count}`",
        f"- check_name: `{record.check_name or ''}`",
        f"- summary_path: `{record.summary_path}`",
        f"- checkpoint_path: `{record.checkpoint_path}`",
    ]
    if record.previous_report_path is not None:
        lines.append(f"- previous_report_path: `{record.previous_report_path}`")
    if record.reconcile_validation_path is not None:
        lines.append(f"- reconcile_validation_path: `{record.reconcile_validation_path}`")
    lines.extend(
        [
            "",
            "| reasons | restored_check_names | checkpoint_check_count | summary_check_count | validation_verdict | timestamp |",
            "| --- | --- | ---: | ---: | --- | --- |",
            (
                f"| {', '.join(record.reasons)} | {', '.join(record.restored_check_names)} | "
                f"{record.checkpoint_check_count if record.checkpoint_check_count is not None else ''} | "
                f"{record.summary_check_count if record.summary_check_count is not None else ''} | "
                f"{record.reconcile_validation_verdict} | {record.timestamp_utc} |"
            ),
        ]
    )
    return "\n".join(lines)


def render_reconcile_records_markdown(records: list[ReconcileStatusRecord]) -> str:
    lines = [
        "| family | run_id | source | status | artifact_state | validation_state | checkpoint_state | restored | reconcile_count | timestamp |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | `{record.run_id}` | {record.source_kind} | {record.status} | "
            f"{record.reconcile_artifact_state} | {record.reconcile_validation_state} | {record.checkpoint_state} | "
            f"{'true' if record.restored is True else ('false' if record.restored is False else 'unknown')} | "
            f"{record.reconcile_count} | {record.timestamp_utc} |"
        )
    return "\n".join(lines)


def build_reconcile_status_record(
    *,
    summary_path: Path,
    checkpoint_path: Path,
    previous_report_path: Path | None,
    reconcile_validation_path: Path | None,
    summary_doc: dict[str, Any] | None,
    checkpoint_doc: dict[str, Any],
    check_name: str | None,
    source_kind: str,
    checkpoint_state: str = "present",
) -> ReconcileStatusRecord:
    previous_doc = load_optional_json(previous_report_path) if previous_report_path is not None else None
    reconcile_validation_doc = (
        load_optional_json(reconcile_validation_path) if reconcile_validation_path is not None else None
    )
    reconcile_state = build_reconcile_state(
        summary_doc,
        checkpoint_doc,
        previous_report_doc=previous_doc,
        check_name=check_name,
    )
    report = build_reconcile_report(
        summary_path=summary_path,
        checkpoint_path=checkpoint_path,
        output_path=previous_report_path,
        checkpoint_doc=checkpoint_doc,
        summary_doc=summary_doc,
        reconcile_state=reconcile_state,
    )
    record = ReconcileStatusRecord(
        generated_at_utc=str(report["generated_at_utc"]),
        timestamp_utc=summary_timestamp(summary_doc or checkpoint_doc),
        run_id=str(report["run_id"]),
        family=infer_family_from_run_id(str(report["run_id"])),
        source_kind=source_kind,
        summary_path=str(report["summary_path"]),
        checkpoint_path=str(report["checkpoint_path"]),
        checkpoint_state=checkpoint_state,
        previous_report_path=None if previous_report_path is None else str(previous_report_path.resolve()),
        reconcile_validation_path=(
            None if reconcile_validation_path is None else str(reconcile_validation_path.resolve())
        ),
        check_name=report["check_name"],
        status=str(report["status"]),
        restored=bool(report["restored"]),
        reasons=[str(reason) for reason in list(report.get("reasons") or [])],
        reconcile_count=int(report["reconcile_count"]),
        restored_check_names=[str(name) for name in list(report.get("restored_check_names") or [])],
        reconcile_artifact_state="missing",
        reconcile_validation_verdict="missing",
        reconcile_validation_state="missing",
        checkpoint_check_count=int(report["checkpoint_check_count"]),
        summary_check_count=(
            int(report["summary_check_count"]) if isinstance(report.get("summary_check_count"), int) else None
        ),
    )
    (
        reconcile_artifact_state,
        reconcile_validation_verdict,
        reconcile_validation_state,
    ) = build_reconcile_observed_state(
        record=record,
        reconcile_path=previous_report_path,
        reconcile_validation_path=reconcile_validation_path,
        reconcile_doc=previous_doc,
        reconcile_validation_doc=reconcile_validation_doc,
    )
    return ReconcileStatusRecord(
        generated_at_utc=record.generated_at_utc,
        timestamp_utc=record.timestamp_utc,
        run_id=record.run_id,
        family=record.family,
        source_kind=record.source_kind,
        summary_path=record.summary_path,
        checkpoint_path=record.checkpoint_path,
        checkpoint_state=record.checkpoint_state,
        previous_report_path=record.previous_report_path,
        reconcile_validation_path=record.reconcile_validation_path,
        check_name=record.check_name,
        status=record.status,
        restored=record.restored,
        reasons=record.reasons,
        reconcile_count=record.reconcile_count,
        restored_check_names=record.restored_check_names,
        reconcile_artifact_state=reconcile_artifact_state,
        reconcile_validation_verdict=reconcile_validation_verdict,
        reconcile_validation_state=reconcile_validation_state,
        checkpoint_check_count=record.checkpoint_check_count,
        summary_check_count=record.summary_check_count,
    )


def build_unknown_reconcile_status_record(
    *,
    summary_path: Path,
    checkpoint_path: Path,
    previous_report_path: Path | None,
    reconcile_validation_path: Path | None,
    run_id: str,
    source_kind: str,
    timestamp_utc: str,
    checkpoint_state: str,
    reasons: list[str],
) -> ReconcileStatusRecord:
    previous_doc = load_optional_json(previous_report_path) if previous_report_path is not None else None
    reconcile_validation_doc = (
        load_optional_json(reconcile_validation_path) if reconcile_validation_path is not None else None
    )
    record = ReconcileStatusRecord(
        generated_at_utc="",
        timestamp_utc=timestamp_utc,
        run_id=run_id,
        family=infer_family_from_run_id(run_id),
        source_kind=source_kind,
        summary_path=str(summary_path.resolve()),
        checkpoint_path=str(checkpoint_path.resolve()),
        checkpoint_state=checkpoint_state,
        previous_report_path=None if previous_report_path is None else str(previous_report_path.resolve()),
        reconcile_validation_path=(
            None if reconcile_validation_path is None else str(reconcile_validation_path.resolve())
        ),
        check_name=None,
        status="unknown",
        restored=False,
        reasons=reasons,
        reconcile_count=(
            int(previous_doc["reconcile_count"])
            if isinstance(previous_doc, dict) and isinstance(previous_doc.get("reconcile_count"), int)
            else 0
        ),
        restored_check_names=(
            [str(name) for name in list(previous_doc.get("restored_check_names") or [])]
            if isinstance(previous_doc, dict)
            else []
        ),
        reconcile_artifact_state="missing",
        reconcile_validation_verdict="missing",
        reconcile_validation_state="missing",
        checkpoint_check_count=None,
        summary_check_count=None,
    )
    (
        reconcile_artifact_state,
        reconcile_validation_verdict,
        reconcile_validation_state,
    ) = build_reconcile_observed_state(
        record=record,
        reconcile_path=previous_report_path,
        reconcile_validation_path=reconcile_validation_path,
        reconcile_doc=previous_doc,
        reconcile_validation_doc=reconcile_validation_doc,
    )
    return ReconcileStatusRecord(
        generated_at_utc=record.generated_at_utc,
        timestamp_utc=record.timestamp_utc,
        run_id=record.run_id,
        family=record.family,
        source_kind=record.source_kind,
        summary_path=record.summary_path,
        checkpoint_path=record.checkpoint_path,
        checkpoint_state=record.checkpoint_state,
        previous_report_path=record.previous_report_path,
        reconcile_validation_path=record.reconcile_validation_path,
        check_name=record.check_name,
        status=record.status,
        restored=record.restored,
        reasons=record.reasons,
        reconcile_count=record.reconcile_count,
        restored_check_names=record.restored_check_names,
        reconcile_artifact_state=reconcile_artifact_state,
        reconcile_validation_verdict=reconcile_validation_verdict,
        reconcile_validation_state=reconcile_validation_state,
        checkpoint_check_count=record.checkpoint_check_count,
        summary_check_count=record.summary_check_count,
    )


def discover_reconcile_status_records(
    *,
    records: list[SummaryRecord],
    ci_root: Path,
    validation_root: Path,
    conformance_root: Path,
    family: str | None,
    run_id_prefix: str | None,
    source_kind: str,
) -> list[ReconcileStatusRecord]:
    del conformance_root

    filtered = records
    if family:
        filtered = [record for record in filtered if record.family == family]
    if run_id_prefix:
        filtered = [record for record in filtered if record.run_id.startswith(run_id_prefix)]
    if source_kind not in {"auto", "all"}:
        filtered = [record for record in filtered if record.source_kind == source_kind]

    reconcile_records: list[ReconcileStatusRecord] = []
    for summary_record in filtered:
        summary_path = Path(summary_record.summary_path)
        summary_doc = load_optional_json(summary_path)
        sidecars = build_sidecar_paths(
            run_id=summary_record.run_id,
            source_kind=summary_record.source_kind,
            validation_root=validation_root,
            conformance_root=DEFAULT_CONFORMANCE_ROOT,
        )
        previous_report_path = sidecars["reconcile_report"]
        reconcile_validation_path = sidecars["reconcile_validation"]
        checkpoint_path = (ci_root / f"{summary_record.run_id}.checkpoint.json").resolve()
        if not checkpoint_path.exists():
            reconcile_records.append(
                build_unknown_reconcile_status_record(
                    summary_path=summary_path,
                    checkpoint_path=checkpoint_path,
                    previous_report_path=previous_report_path,
                    reconcile_validation_path=reconcile_validation_path,
                    run_id=summary_record.run_id,
                    source_kind=summary_record.source_kind,
                    timestamp_utc=summary_record.timestamp_utc,
                    checkpoint_state="missing",
                    reasons=["checkpoint_missing"],
                )
            )
            continue
        checkpoint_doc = load_optional_json(checkpoint_path)
        if checkpoint_doc is None:
            reconcile_records.append(
                build_unknown_reconcile_status_record(
                    summary_path=summary_path,
                    checkpoint_path=checkpoint_path,
                    previous_report_path=previous_report_path,
                    reconcile_validation_path=reconcile_validation_path,
                    run_id=summary_record.run_id,
                    source_kind=summary_record.source_kind,
                    timestamp_utc=summary_record.timestamp_utc,
                    checkpoint_state="invalid",
                    reasons=["checkpoint_invalid_json"],
                )
            )
            continue
        checkpoint_errors = validate_checkpoint_doc(checkpoint_doc)
        if checkpoint_errors:
            reconcile_records.append(
                build_unknown_reconcile_status_record(
                    summary_path=summary_path,
                    checkpoint_path=checkpoint_path,
                    previous_report_path=previous_report_path,
                    reconcile_validation_path=reconcile_validation_path,
                    run_id=summary_record.run_id,
                    source_kind=summary_record.source_kind,
                    timestamp_utc=summary_record.timestamp_utc,
                    checkpoint_state="invalid",
                    reasons=[f"checkpoint_invalid:{error}" for error in checkpoint_errors],
                )
            )
            continue
        reconcile_records.append(
            build_reconcile_status_record(
                summary_path=summary_path,
                checkpoint_path=checkpoint_path,
                previous_report_path=previous_report_path,
                reconcile_validation_path=reconcile_validation_path,
                summary_doc=summary_doc,
                checkpoint_doc=checkpoint_doc,
                check_name=None,
                source_kind=summary_record.source_kind,
            )
        )
    return reconcile_records


def resolve_reconcile_status_record(
    *,
    args: argparse.Namespace,
    records: list[SummaryRecord],
    ci_root: Path,
    validation_root: Path,
    conformance_root: Path,
) -> ReconcileStatusRecord:
    source_kind = "stamped"
    summary_path: Path
    summary_doc: dict[str, Any] | None
    run_id: str | None = None

    if args.summary is not None:
        summary_path = resolve_root(args.summary, WORKSPACE_ROOT)
        summary_doc = load_optional_json(summary_path)
        source_kind = source_kind_for_summary_path(summary_path)
        if isinstance(summary_doc, dict) and is_summary_document(summary_doc):
            run_id = str(summary_doc["run_id"])
    else:
        selected_source_kind = args.source_kind if args.source_kind in {"stamped", "latest"} else "auto"
        record = select_record(records=records, run_id=args.run_id, source_kind=selected_source_kind)
        if record is None:
            raise ValueError(f"run not found: {args.run_id}")
        summary_path = Path(record.summary_path)
        summary_doc = load_optional_json(summary_path)
        run_id = record.run_id
        source_kind = record.source_kind

    if args.checkpoint is None and run_id is None:
        raise ValueError("checkpoint required when summary path does not contain a valid federated CI summary document")

    checkpoint_path = (
        resolve_optional_path(args.checkpoint)
        if args.checkpoint is not None
        else (ci_root / f"{run_id}.checkpoint.json").resolve()
    )
    if checkpoint_path is None or not checkpoint_path.exists():
        raise ValueError(f"checkpoint missing: {checkpoint_path}")
    checkpoint_doc = load_json(checkpoint_path)
    checkpoint_errors = validate_checkpoint_doc(checkpoint_doc)
    if checkpoint_errors:
        raise ValueError(f"invalid checkpoint: {checkpoint_errors}")
    if run_id is None:
        run_id = str(checkpoint_doc["run_id"])

    previous_report_path = resolve_optional_path(args.previous_report)
    if previous_report_path is None:
        previous_report_path = build_sidecar_paths(
            run_id=run_id,
            source_kind=source_kind,
            validation_root=validation_root,
            conformance_root=conformance_root,
        )["reconcile_report"]
    reconcile_validation_path = build_reconcile_validation_path(previous_report_path)

    return build_reconcile_status_record(
        summary_path=summary_path,
        checkpoint_path=checkpoint_path,
        previous_report_path=previous_report_path,
        reconcile_validation_path=reconcile_validation_path,
        summary_doc=summary_doc,
        checkpoint_doc=checkpoint_doc,
        check_name=args.check_name,
        source_kind=source_kind,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Query federated CI summary artifacts from planningops artifact roots")
    subparsers = parser.add_subparsers(dest="command", required=True)

    runs_parser = subparsers.add_parser("runs", help="list indexed federated CI summaries")
    runs_parser.add_argument("--family", default=None)
    runs_parser.add_argument("--run-id-prefix", default=None)
    runs_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="all")
    runs_parser.add_argument("--verdict", choices=["pass", "fail"], default=None)
    runs_parser.add_argument("--status", choices=["complete", "interrupted"], default=None)
    runs_parser.add_argument("--readiness-status", choices=["ready", "blocked", "missing", "unknown"], default=None)
    runs_parser.add_argument("--health-status", choices=["healthy", "degraded", "blocked", "unknown"], default=None)
    runs_parser.add_argument("--reconcile-status", choices=["healthy", "restored", "unknown"], default=None)
    runs_parser.add_argument("--reconcile-artifact-state", choices=["fresh", "stale", "missing"], default=None)
    runs_parser.add_argument("--reconcile-validation-state", choices=["fresh", "stale", "missing"], default=None)
    runs_parser.add_argument("--checkpoint-state", choices=["present", "missing", "invalid"], default=None)
    runs_parser.add_argument("--failed-check", default=None)
    runs_parser.add_argument("--limit", type=int, default=20)
    runs_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    runs_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    runs_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    runs_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    checks_parser = subparsers.add_parser("checks", help="show checks for one federated CI run id")
    checks_parser.add_argument("--run-id", required=True)
    checks_parser.add_argument("--source-kind", choices=["auto", "stamped", "latest"], default="auto")
    checks_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    checks_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    checks_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    checks_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    reconcile_parser = subparsers.add_parser(
        "reconcile-status",
        help="show tmp/checkpoint reconcile state for one federated CI run or explicit summary/checkpoint pair",
    )
    reconcile_parser.add_argument("--run-id", default=None)
    reconcile_parser.add_argument("--summary", default=None)
    reconcile_parser.add_argument("--family", default=None)
    reconcile_parser.add_argument("--run-id-prefix", default=None)
    reconcile_parser.add_argument("--checkpoint", default=None)
    reconcile_parser.add_argument("--previous-report", default=None)
    reconcile_parser.add_argument("--check-name", default=None)
    reconcile_parser.add_argument("--source-kind", choices=["auto", "all", "stamped", "latest"], default="auto")
    reconcile_parser.add_argument("--status", choices=["healthy", "restored", "unknown"], default=None)
    reconcile_parser.add_argument("--artifact-state", choices=["fresh", "stale", "missing"], default=None)
    reconcile_parser.add_argument("--validation-state", choices=["fresh", "stale", "missing"], default=None)
    reconcile_parser.add_argument("--checkpoint-state", choices=["present", "missing", "invalid"], default=None)
    reconcile_parser.add_argument("--limit", type=int, default=20)
    reconcile_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    reconcile_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    reconcile_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    reconcile_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    health_parser = subparsers.add_parser(
        "health-scan",
        help="show operator-oriented run health derived from verdict, readiness, and reconcile state",
    )
    health_parser.add_argument("--family", default=None)
    health_parser.add_argument("--run-id-prefix", default=None)
    health_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="all")
    health_parser.add_argument("--health-status", choices=["healthy", "degraded", "blocked", "unknown"], default=None)
    health_parser.add_argument("--readiness-status", choices=["ready", "blocked", "missing", "unknown"], default=None)
    health_parser.add_argument("--reconcile-status", choices=["healthy", "restored", "unknown"], default=None)
    health_parser.add_argument("--reconcile-artifact-state", choices=["fresh", "stale", "missing"], default=None)
    health_parser.add_argument("--checkpoint-state", choices=["present", "missing", "invalid"], default=None)
    health_parser.add_argument("--failed-check", default=None)
    health_parser.add_argument("--limit", type=int, default=20)
    health_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    health_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    health_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    health_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    health_summary_parser = subparsers.add_parser(
        "health-summary",
        help="show family-level health bucket counts and the newest alerting run for federated CI artifacts",
    )
    health_summary_parser.add_argument("--family", default=None)
    health_summary_parser.add_argument("--run-id-prefix", default=None)
    health_summary_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    health_summary_parser.add_argument(
        "--latest-health-status",
        choices=["healthy", "degraded", "blocked", "unknown"],
        default=None,
    )
    health_summary_parser.add_argument(
        "--has-health-status",
        choices=["healthy", "degraded", "blocked", "unknown"],
        default=None,
    )
    health_summary_parser.add_argument("--has-failure-domain", default=None)
    health_summary_parser.add_argument(
        "--has-readiness-status",
        choices=["ready", "blocked", "missing", "unknown"],
        default=None,
    )
    health_summary_parser.add_argument(
        "--has-reconcile-artifact-state",
        choices=["fresh", "stale", "missing"],
        default=None,
    )
    health_summary_parser.add_argument(
        "--has-reconcile-validation-state",
        choices=["fresh", "stale", "missing"],
        default=None,
    )
    health_summary_parser.add_argument(
        "--latest-gap-status",
        choices=["clear", "attention"],
        default=None,
    )
    health_summary_parser.add_argument(
        "--has-latest-gap",
        choices=LATEST_GAP_CHOICES,
        default=None,
    )
    health_summary_parser.add_argument("--limit", type=int, default=20)
    health_summary_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    health_summary_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    health_summary_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    health_summary_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    operator_triage_parser = subparsers.add_parser(
        "operator-triage",
        help="show family-level triage state comparing the latest gap against the latest alerting run",
    )
    operator_triage_parser.add_argument("--family", default=None)
    operator_triage_parser.add_argument("--run-id-prefix", default=None)
    operator_triage_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    operator_triage_parser.add_argument("--triage-status", choices=["clear", "active", "lagging"], default=None)
    operator_triage_parser.add_argument("--alert-alignment", choices=["none", "current", "lagging"], default=None)
    operator_triage_parser.add_argument("--latest-gap-status", choices=["clear", "attention"], default=None)
    operator_triage_parser.add_argument("--has-latest-gap-domain", default=None)
    operator_triage_parser.add_argument("--has-latest-alert-domain", default=None)
    operator_triage_parser.add_argument("--limit", type=int, default=20)
    operator_triage_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    operator_triage_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    operator_triage_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    operator_triage_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    triage_summary_parser = subparsers.add_parser(
        "triage-summary",
        help="show bucketed counts and newest families for operator triage statuses",
    )
    triage_summary_parser.add_argument("--family", default=None)
    triage_summary_parser.add_argument("--run-id-prefix", default=None)
    triage_summary_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_summary_parser.add_argument("--triage-status", choices=["clear", "active", "lagging"], default=None)
    triage_summary_parser.add_argument("--has-latest-gap-domain", default=None)
    triage_summary_parser.add_argument("--has-latest-alert-domain", default=None)
    triage_summary_parser.add_argument("--limit", type=int, default=20)
    triage_summary_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    triage_summary_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_summary_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_summary_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    triage_overview_parser = subparsers.add_parser(
        "triage-overview",
        help="show overall triage counts together with newest failing and recovered family pointers",
    )
    triage_overview_parser.add_argument("--family", default=None)
    triage_overview_parser.add_argument("--run-id-prefix", default=None)
    triage_overview_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_overview_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    triage_overview_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_overview_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_overview_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    triage_targets_parser = subparsers.add_parser(
        "triage-targets",
        help="show actionable triage targets with active gaps first and lagging alert follow-ups after",
    )
    triage_targets_parser.add_argument("--family", default=None)
    triage_targets_parser.add_argument("--run-id-prefix", default=None)
    triage_targets_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_targets_parser.add_argument("--triage-status", choices=["active", "lagging"], default=None)
    triage_targets_parser.add_argument("--has-target-domain", default=None)
    triage_targets_parser.add_argument("--limit", type=int, default=20)
    triage_targets_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    triage_targets_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_targets_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_targets_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    triage_queue_parser = subparsers.add_parser(
        "triage-queue",
        help="show bucketed triage target queues with newest target pointers and domain counts",
    )
    triage_queue_parser.add_argument("--family", default=None)
    triage_queue_parser.add_argument("--run-id-prefix", default=None)
    triage_queue_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_queue_parser.add_argument("--priority-bucket", choices=["active", "lagging"], default=None)
    triage_queue_parser.add_argument("--has-target-domain", default=None)
    triage_queue_parser.add_argument("--limit", type=int, default=20)
    triage_queue_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    triage_queue_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_queue_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_queue_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))

    triage_feed_parser = subparsers.add_parser(
        "triage-feed",
        help="show one operator snapshot that bundles overview, queue, and top triage targets",
    )
    triage_feed_parser.add_argument("--family", default=None)
    triage_feed_parser.add_argument("--run-id-prefix", default=None)
    triage_feed_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_feed_parser.add_argument("--target-limit", type=int, default=3)
    triage_feed_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    triage_feed_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_feed_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_feed_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))
    triage_feed_parser.add_argument("--local-root", default=str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT))

    triage_brief_parser = subparsers.add_parser(
        "triage-brief",
        help="show a concise operator summary derived from the triage feed surface",
    )
    triage_brief_parser.add_argument("--family", default=None)
    triage_brief_parser.add_argument("--run-id-prefix", default=None)
    triage_brief_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_brief_parser.add_argument("--target-limit", type=int, default=3)
    triage_brief_parser.add_argument("--format", choices=["table", "json", "markdown"], default="markdown")
    triage_brief_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_brief_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_brief_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))
    triage_brief_parser.add_argument("--local-root", default=str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT))

    triage_report_parser = subparsers.add_parser(
        "triage-report",
        help="show a fixed-format markdown report derived from the triage brief surface",
    )
    triage_report_parser.add_argument("--family", default=None)
    triage_report_parser.add_argument("--run-id-prefix", default=None)
    triage_report_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    triage_report_parser.add_argument("--target-limit", type=int, default=3)
    triage_report_parser.add_argument("--format", choices=["table", "json", "markdown"], default="markdown")
    triage_report_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    triage_report_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    triage_report_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))
    triage_report_parser.add_argument("--local-root", default=str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT))

    handoff_report_parser = subparsers.add_parser(
        "handoff-report",
        help="show a handoff-friendly operator report combining triage state and local runtime status",
    )
    handoff_report_parser.add_argument("--family", default=None)
    handoff_report_parser.add_argument("--run-id-prefix", default=None)
    handoff_report_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    handoff_report_parser.add_argument("--target-limit", type=int, default=3)
    handoff_report_parser.add_argument("--format", choices=["table", "json", "markdown"], default="markdown")
    handoff_report_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    handoff_report_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    handoff_report_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))
    handoff_report_parser.add_argument("--local-root", default=str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT))

    write_handoff_report_parser = subparsers.add_parser(
        "write-handoff-report",
        help="write a handoff-friendly operator report into latest + stamped validation artifacts",
    )
    write_handoff_report_parser.add_argument("--family", default=None)
    write_handoff_report_parser.add_argument("--run-id-prefix", default=None)
    write_handoff_report_parser.add_argument("--source-kind", choices=["all", "stamped", "latest"], default="stamped")
    write_handoff_report_parser.add_argument("--target-limit", type=int, default=3)
    write_handoff_report_parser.add_argument("--report-id", default=None)
    write_handoff_report_parser.add_argument("--output", default=None)
    write_handoff_report_parser.add_argument("--format", choices=["table", "json", "markdown"], default="json")
    write_handoff_report_parser.add_argument("--ci-root", default=str(DEFAULT_CI_ROOT))
    write_handoff_report_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    write_handoff_report_parser.add_argument("--conformance-root", default=str(DEFAULT_CONFORMANCE_ROOT))
    write_handoff_report_parser.add_argument("--local-root", default=str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT))

    local_operator_parser = subparsers.add_parser(
        "local-operator-stack",
        help="list planningops-owned monday local operator stack aggregate reports",
    )
    local_operator_parser.add_argument("--run-id-prefix", default=None)
    local_operator_parser.add_argument("--verdict", choices=LOCAL_OPERATOR_VERDICT_CHOICES, default=None)
    local_operator_parser.add_argument("--reason-code", default=None)
    local_operator_parser.add_argument("--execution-mode", choices=["stack", "direct", "both"], default=None)
    local_operator_parser.add_argument("--direct-profile", choices=["local_ollama", "local_lmstudio"], default=None)
    local_operator_parser.add_argument("--readiness-status", choices=LOCAL_OPERATOR_READINESS_CHOICES, default=None)
    local_operator_parser.add_argument("--readiness-step-status", choices=LOCAL_OPERATOR_STEP_STATUS_CHOICES, default=None)
    local_operator_parser.add_argument("--stack-status", choices=LOCAL_OPERATOR_STEP_STATUS_CHOICES, default=None)
    local_operator_parser.add_argument("--direct-status", choices=LOCAL_OPERATOR_STEP_STATUS_CHOICES, default=None)
    local_operator_parser.add_argument("--has-detail-dir", choices=["yes", "no"], default=None)
    local_operator_parser.add_argument("--limit", type=int, default=20)
    local_operator_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    local_operator_parser.add_argument("--local-root", default=str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    local_root = resolve_root(getattr(args, "local_root", str(DEFAULT_LOCAL_OPERATOR_STACK_ROOT)), DEFAULT_LOCAL_OPERATOR_STACK_ROOT)
    if args.command == "local-operator-stack":
        local_records = discover_local_operator_stack_records(local_root=local_root)
        local_records = filter_local_operator_stack_records(
            records=local_records,
            run_id_prefix=args.run_id_prefix,
            verdict=args.verdict,
            reason_code=args.reason_code,
            execution_mode=args.execution_mode,
            direct_profile=args.direct_profile,
            readiness_status=args.readiness_status,
            readiness_step_status=args.readiness_step_status,
            stack_status=args.stack_status,
            direct_status=args.direct_status,
            has_detail_dir=args.has_detail_dir,
        )
        local_records = local_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in local_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_local_operator_stack_markdown(local_records))
            return 0
        print(render_local_operator_stack_table(local_records))
        return 0

    ci_root = resolve_root(getattr(args, "ci_root", str(DEFAULT_CI_ROOT)), DEFAULT_CI_ROOT)
    validation_root = resolve_root(getattr(args, "validation_root", str(DEFAULT_VALIDATION_ROOT)), DEFAULT_VALIDATION_ROOT)
    conformance_root = resolve_root(getattr(args, "conformance_root", str(DEFAULT_CONFORMANCE_ROOT)), DEFAULT_CONFORMANCE_ROOT)
    records = discover_summary_records(
        ci_root=ci_root,
        validation_root=validation_root,
        conformance_root=conformance_root,
    )

    if args.command == "runs":
        filtered = filter_summary_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            verdict=args.verdict,
            status=args.status,
            readiness_status=args.readiness_status,
            health_status=args.health_status,
            reconcile_status=args.reconcile_status,
            reconcile_artifact_state=args.reconcile_artifact_state,
            reconcile_validation_state=args.reconcile_validation_state,
            checkpoint_state=args.checkpoint_state,
            failed_check=args.failed_check,
        )
        filtered = filtered[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in filtered]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_runs_markdown(filtered))
            return 0
        print(render_runs_table(filtered))
        return 0

    if args.command == "health-scan":
        filtered = filter_summary_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            readiness_status=args.readiness_status,
            health_status=args.health_status,
            reconcile_status=args.reconcile_status,
            reconcile_artifact_state=args.reconcile_artifact_state,
            checkpoint_state=args.checkpoint_state,
            failed_check=args.failed_check,
        )
        filtered = filtered[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in filtered]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_health_scan_markdown(filtered))
            return 0
        print(render_health_scan_table(filtered))
        return 0

    if args.command == "health-summary":
        summaries = build_health_summary_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
        )
        if args.latest_gap_status:
            summaries = [record for record in summaries if record.latest_gap_status == args.latest_gap_status]
        if args.has_latest_gap:
            summaries = [record for record in summaries if args.has_latest_gap in record.latest_gap_reasons]
        if args.latest_health_status:
            summaries = [record for record in summaries if record.latest_run_health_status == args.latest_health_status]
        if args.has_health_status:
            bucket_name = f"{args.has_health_status}_count"
            summaries = [record for record in summaries if getattr(record, bucket_name) > 0]
        if args.has_failure_domain:
            summaries = [
                record for record in summaries if record.failure_domain_counts.get(args.has_failure_domain, 0) > 0
            ]
        if args.has_readiness_status:
            summaries = [
                record for record in summaries if record.readiness_status_counts.get(args.has_readiness_status, 0) > 0
            ]
        if args.has_reconcile_artifact_state:
            summaries = [
                record
                for record in summaries
                if record.reconcile_artifact_state_counts.get(args.has_reconcile_artifact_state, 0) > 0
            ]
        if args.has_reconcile_validation_state:
            summaries = [
                record
                for record in summaries
                if record.reconcile_validation_state_counts.get(args.has_reconcile_validation_state, 0) > 0
            ]
        summaries = summaries[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in summaries]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_health_summary_markdown(summaries))
            return 0
        print(render_health_summary_table(summaries))
        return 0

    if args.command == "operator-triage":
        triage_records = build_operator_triage_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
        )
        if args.triage_status:
            triage_records = [record for record in triage_records if record.triage_status == args.triage_status]
        if args.alert_alignment:
            triage_records = [record for record in triage_records if record.alert_alignment == args.alert_alignment]
        if args.latest_gap_status:
            triage_records = [record for record in triage_records if record.latest_gap_status == args.latest_gap_status]
        if args.has_latest_gap_domain:
            triage_records = [
                record for record in triage_records if args.has_latest_gap_domain in record.latest_gap_domains
            ]
        if args.has_latest_alert_domain:
            triage_records = [
                record for record in triage_records if args.has_latest_alert_domain in record.latest_alert_domains
            ]
        triage_records = triage_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in triage_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_operator_triage_markdown(triage_records))
            return 0
        print(render_operator_triage_table(triage_records))
        return 0

    if args.command == "triage-summary":
        summaries = build_triage_summary_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
        )
        if args.triage_status:
            summaries = [record for record in summaries if record.triage_status == args.triage_status]
        if args.has_latest_gap_domain:
            summaries = [
                record
                for record in summaries
                if record.latest_gap_domain_counts.get(args.has_latest_gap_domain, 0) > 0
            ]
        if args.has_latest_alert_domain:
            summaries = [
                record
                for record in summaries
                if record.latest_alert_domain_counts.get(args.has_latest_alert_domain, 0) > 0
            ]
        summaries = summaries[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in summaries]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_summary_markdown(summaries))
            return 0
        print(render_triage_summary_table(summaries))
        return 0

    if args.command == "triage-overview":
        record = build_triage_overview_record(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
        )
        if args.format == "json":
            print(json.dumps({"record": asdict(record)}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_overview_markdown(record))
            return 0
        print(render_triage_overview_table(record))
        return 0

    if args.command == "triage-targets":
        target_records = build_triage_target_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
        )
        if args.triage_status:
            target_records = [record for record in target_records if record.triage_status == args.triage_status]
        if args.has_target_domain:
            target_records = [record for record in target_records if args.has_target_domain in record.target_domains]
        target_records = target_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in target_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_targets_markdown(target_records))
            return 0
        print(render_triage_targets_table(target_records))
        return 0

    if args.command == "triage-queue":
        queue_records = build_triage_queue_records(
            records=records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
        )
        if args.priority_bucket:
            queue_records = [record for record in queue_records if record.priority_bucket == args.priority_bucket]
        if args.has_target_domain:
            queue_records = [
                record for record in queue_records if record.target_domain_counts.get(args.has_target_domain, 0) > 0
            ]
        queue_records = queue_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in queue_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_queue_markdown(queue_records))
            return 0
        print(render_triage_queue_table(queue_records))
        return 0

    if args.command == "triage-feed":
        local_records = discover_local_operator_stack_records(local_root=local_root)
        record = build_triage_feed_record(
            records=records,
            local_records=local_records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            target_limit=args.target_limit,
        )
        if args.format == "json":
            print(json.dumps({"record": asdict(record)}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_feed_markdown(record))
            return 0
        print(render_triage_feed_table(record))
        return 0

    if args.command == "triage-brief":
        local_records = discover_local_operator_stack_records(local_root=local_root)
        record = build_triage_brief_record(
            records=records,
            local_records=local_records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            target_limit=args.target_limit,
        )
        if args.format == "json":
            print(json.dumps({"record": asdict(record)}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_brief_markdown(record))
            return 0
        print(render_triage_brief_table(record))
        return 0

    if args.command == "triage-report":
        local_records = discover_local_operator_stack_records(local_root=local_root)
        record = build_triage_report_record(
            records=records,
            local_records=local_records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            target_limit=args.target_limit,
        )
        if args.format == "json":
            print(json.dumps({"record": asdict(record)}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_triage_report_markdown(record))
            return 0
        print(render_triage_report_table(record))
        return 0

    if args.command == "handoff-report":
        local_records = discover_local_operator_stack_records(local_root=local_root)
        record = build_handoff_report_record(
            records=records,
            local_records=local_records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            target_limit=args.target_limit,
        )
        if args.format == "json":
            print(json.dumps({"record": asdict(record)}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_handoff_report_markdown(record))
            return 0
        print(render_handoff_report_table(record))
        return 0

    if args.command == "write-handoff-report":
        local_records = discover_local_operator_stack_records(local_root=local_root)
        record = build_handoff_report_record(
            records=records,
            local_records=local_records,
            family=args.family,
            run_id_prefix=args.run_id_prefix,
            source_kind=args.source_kind,
            target_limit=args.target_limit,
        )
        report_id = args.report_id or f"operator-handoff-{utc_timestamp_slug()}"
        latest_report_path = validation_root / "operator-handoff-report.json"
        stamped_report_path = validation_root / f"{report_id}-operator-handoff-report.json"
        output_path = resolve_optional_path(args.output)
        doc = build_handoff_artifact_document(
            record=record,
            report_id=report_id,
            latest_report_path=latest_report_path,
            stamped_report_path=stamped_report_path,
            output_path=output_path,
        )
        write_json(latest_report_path, doc)
        write_json(stamped_report_path, doc)
        if output_path is not None:
            write_json(output_path, doc)
        if args.format == "json":
            print(json.dumps(doc, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_handoff_report_markdown(record))
            return 0
        print(render_handoff_report_table(record))
        return 0

    if args.command == "reconcile-status":
        is_single_target = args.run_id is not None or args.summary is not None
        is_scan_target = args.family is not None or args.run_id_prefix is not None
        if is_single_target and is_scan_target:
            print("choose either single target flags (--run-id/--summary) or scan flags (--family/--run-id-prefix)", file=sys.stderr)
            return 1
        if not is_single_target and not is_scan_target:
            print("one of --run-id, --summary, --family, or --run-id-prefix is required", file=sys.stderr)
            return 1
        if is_scan_target:
            filtered = discover_reconcile_status_records(
                records=records,
                ci_root=ci_root,
                validation_root=validation_root,
                conformance_root=conformance_root,
                family=args.family,
                run_id_prefix=args.run_id_prefix,
                source_kind=args.source_kind,
            )
            if args.status:
                filtered = [record for record in filtered if record.status == args.status]
            if args.artifact_state:
                filtered = [record for record in filtered if record.reconcile_artifact_state == args.artifact_state]
            if args.validation_state:
                filtered = [record for record in filtered if record.reconcile_validation_state == args.validation_state]
            if args.checkpoint_state:
                filtered = [record for record in filtered if record.checkpoint_state == args.checkpoint_state]
            filtered = filtered[: args.limit]
            if args.format == "json":
                print(json.dumps({"records": [asdict(record) for record in filtered]}, ensure_ascii=True, indent=2))
                return 0
            if args.format == "markdown":
                print(render_reconcile_records_markdown(filtered))
                return 0
            print(render_reconcile_table(filtered))
            return 0
        try:
            record = resolve_reconcile_status_record(
                args=args,
                records=records,
                ci_root=ci_root,
                validation_root=validation_root,
                conformance_root=conformance_root,
            )
        except ValueError as exc:
            print(str(exc), file=sys.stderr)
            return 1
        if args.format == "json":
            print(json.dumps({"record": asdict(record)}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_reconcile_markdown(record))
            return 0
        print(render_reconcile_table([record]))
        return 0

    record = select_record(records=records, run_id=args.run_id, source_kind=args.source_kind)
    if record is None:
        print(f"run not found: {args.run_id}", file=sys.stderr)
        return 1
    checks = load_checks_payload(Path(record.summary_path))
    if args.format == "json":
        print(json.dumps({"record": asdict(record), "checks": checks}, ensure_ascii=True, indent=2))
        return 0
    if args.format == "markdown":
        lines = [
            f"# `{record.run_id}` checks",
            "",
            f"- source_kind: `{record.source_kind}`",
            f"- summary_path: `{record.summary_path}`",
            "",
            "| name | domain | verdict | exit_code | result |",
            "| --- | --- | --- | ---: | --- |",
        ]
        for check in checks:
            lines.append(
                f"| {check.get('name') or ''} | {check.get('domain') or ''} | "
                f"{check.get('verdict') or ''} | {check.get('exit_code') if check.get('exit_code') is not None else ''} | "
                f"{check.get('result') or ''} |"
            )
        print("\n".join(lines))
        return 0
    print(render_checks_table(record, checks))
    return 0


if __name__ == "__main__":
    sys.exit(main())
