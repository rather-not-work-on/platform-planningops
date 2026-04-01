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
DEFAULT_MONDAY_CONSUMER_ROOT = WORKSPACE_ROOT.parent / "monday" / "runtime-artifacts/integration/planningops-local-operator-inbox"
DEFAULT_MONDAY_VALIDATION_ROOT = WORKSPACE_ROOT.parent / "monday" / "runtime-artifacts/validation"

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
LOCAL_INBOX_PAYLOAD_SOURCE_CHOICES = ("all", "latest", "stamped")
LOCAL_INBOX_PAYLOAD_STATUS_CHOICES = ("ready", "blocked")
MONDAY_CONSUMER_MODE_CHOICES = ("dry-run", "apply")
MONDAY_CONSUMER_VERDICT_CHOICES = ("pass", "fail", "blocked")
MONDAY_CONSUMER_STATUS_CHOICES = ("ready_to_launch", "blocked")
MONDAY_VALIDATION_KIND_CHOICES = ("bridge", "consumer-report")
MONDAY_VALIDATION_VERDICT_CHOICES = ("pass", "fail")
LOCAL_VALIDATION_FAMILY_CHOICES = (
    "monday_local_operator_stack_report",
    "operator_handoff_report",
    "monday_local_mission_packet",
    "monday_local_operator_day_packet",
    "monday_local_operator_inbox_payload",
    "monday_local_inbox_launch_request",
    "monday_local_inbox_runtime_report",
    "monday_local_inbox_consumer_report",
)
LOCAL_VALIDATION_FRESHNESS_CHOICES = ("fresh", "stale", "missing")
LOCAL_VALIDATION_PROMOTABILITY_CHOICES = ("promotable", "blocked")


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
    local_validation_snapshot_status: str
    local_validation_snapshot_summary: str
    local_validation_records: list[LocalValidationFreshnessRecord]
    local_validation_summary_lines: list[str]
    local_validation_action_lines: list[str]
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


@dataclass(frozen=True)
class LocalValidationFreshnessRecord:
    artifact_family: str
    artifact_kind: str
    promoted_id: str | None
    generated_at_utc: str | None
    freshness_state: str
    promotability_status: str
    latest_path: str
    stamped_path: str | None
    reasons: list[str]
    dependency_states: dict[str, str]


@dataclass(frozen=True)
class LocalInboxPayloadRecord:
    bridge_id: str
    source_kind: str
    payload_path: str
    generated_at_utc: str
    title: str | None
    status: str | None
    needs_human_attention: bool | None
    message_class_hint: str | None
    retry_mode: str | None
    operator_action: str | None
    planner_profile: str | None
    launch_mode: str | None
    local_model_route: str | None
    local_validation_snapshot_status: str | None
    day_packet_id: str | None
    mission_packet_id: str | None
    mission_objective: str | None
    first_action_command: str | None
    monday_runtime_entrypoint_command: str | None
    rollback_command: str | None
    attachment_count: int
    local_validation_action_lines: list[str]
    immediate_actions: list[str]
    queue_lines: list[str]
    target_lines: list[str]
    dependency_states: dict[str, str]


@dataclass(frozen=True)
class MondayConsumerReportRecord:
    run_id: str
    report_path: str
    generated_at_utc: str
    bridge_id: str | None
    mode: str | None
    verdict: str | None
    reason_code: str | None
    consumer_status: str | None
    can_launch: bool | None
    planner_profile: str | None
    launch_mode: str | None
    local_model_route: str | None
    local_validation_snapshot_status: str | None
    block_reasons: list[str]
    command_args: list[str]
    has_runtime_input_overrides: bool
    override_kinds: list[str]
    planner_runtime_config_path: str | None
    runtime_profile_file_path: str | None
    execution_attempted: bool | None
    execution_exit_code: int | None
    runtime_report_verdict: str | None
    runtime_report_reason_code: str | None
    has_launch_request: bool
    has_mission_file: bool
    has_runtime_report: bool


@dataclass(frozen=True)
class MondayValidationReportRecord:
    kind: str
    report_path: str
    generated_at_utc: str
    verdict: str | None
    error_count: int
    warning_count: int
    artifact_path: str | None
    schema_path: str | None
    artifact_exists: bool
    schema_exists: bool
    errors: list[str]
    warnings: list[str]


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


def normalize_optional_string(value: Any) -> str | None:
    if not isinstance(value, str):
        return None
    normalized = value.strip()
    return normalized or None


def normalize_string_list(values: Any) -> list[str]:
    return [str(value) for value in list(values or []) if str(value).strip()]


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


def resolve_nested_value(doc: dict[str, Any], *keys: str) -> Any:
    current: Any = doc
    for key in keys:
        if not isinstance(current, dict):
            return None
        current = current.get(key)
    return current


def resolve_nested_artifact_path(doc: dict[str, Any], *keys: str) -> Path | None:
    return resolve_artifact_path(resolve_nested_value(doc, *keys))


def source_kind_for_local_inbox_payload_path(path: Path) -> str:
    return "latest" if path.name == "monday-local-operator-inbox-payload.json" else "stamped"


def is_local_inbox_payload_document(doc: dict[str, Any]) -> bool:
    return isinstance(doc.get("bridge_id"), str) and isinstance(doc.get("payload"), dict)


def is_monday_consumer_report_document(doc: dict[str, Any]) -> bool:
    return (
        isinstance(doc.get("run_id"), str)
        and isinstance(doc.get("artifact_paths"), dict)
        and isinstance(doc.get("launch_request"), dict)
    )


def is_monday_validation_report_document(doc: dict[str, Any]) -> bool:
    return (
        doc.get("kind") in MONDAY_VALIDATION_KIND_CHOICES
        and isinstance(doc.get("artifact_path"), str)
        and isinstance(doc.get("schema_path"), str)
        and isinstance(doc.get("errors"), list)
        and isinstance(doc.get("warnings"), list)
    )


def build_local_validation_dependency_state(
    *,
    raw_path: Any,
    expected_path: Path,
) -> tuple[str, str | None]:
    resolved = resolve_artifact_path(raw_path)
    if resolved is None:
        return "missing", "dependency_path_missing"
    if not resolved.exists():
        return "missing", "dependency_missing"
    if resolved != expected_path.resolve():
        return "stale", "dependency_stale"
    return "current", None


def classify_local_validation_states(
    *,
    latest_path: Path,
    latest_doc: dict[str, Any] | None,
    stamped_path: Path | None,
    freshness_reasons: list[str],
    promotability_reasons: list[str],
    dependency_states: dict[str, str],
) -> tuple[str, str]:
    if latest_doc is None:
        if latest_path.exists():
            freshness_reasons.insert(0, "latest_invalid_json")
        else:
            freshness_reasons.insert(0, "latest_missing")
    elif stamped_path is None:
        freshness_reasons.append("stamped_path_missing")
    elif not stamped_path.exists():
        freshness_reasons.append("stamped_missing")

    freshness_state = "fresh"
    if any(reason in {"latest_missing", "latest_invalid_json"} for reason in freshness_reasons):
        freshness_state = "missing"
    elif freshness_reasons:
        freshness_state = "stale"

    promotability_status = "promotable"
    if freshness_state != "fresh" or promotability_reasons or any(
        state != "current" for state in dependency_states.values()
    ):
        promotability_status = "blocked"
    return freshness_state, promotability_status


def build_local_operator_validation_freshness_record(*, validation_root: Path) -> LocalValidationFreshnessRecord:
    latest_path = (validation_root / "monday-local-operator-stack-report.json").resolve()
    latest_doc = load_optional_json(latest_path)
    freshness_reasons: list[str] = []
    promotability_reasons: list[str] = []
    dependency_states: dict[str, str] = {}
    stamped_path: Path | None = None
    promoted_id: str | None = None
    generated_at_utc: str | None = None

    if latest_doc is not None:
        promoted_id = str(latest_doc.get("run_id") or "").strip() or None
        generated_at_utc = str(latest_doc.get("generated_at_utc") or "").strip() or None
        if promoted_id is None:
            promotability_reasons.append("missing_run_id")
        latest_report_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "validation_latest_report_path")
        stamped_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "validation_stamped_report_path")
        if latest_report_path != latest_path:
            freshness_reasons.append("latest_path_mismatch")
        if not isinstance(latest_doc.get("readiness"), dict):
            promotability_reasons.append("missing_readiness")
        if not isinstance(latest_doc.get("stack_smoke"), dict):
            promotability_reasons.append("missing_stack_smoke")
        if not isinstance(latest_doc.get("direct_smoke"), dict):
            promotability_reasons.append("missing_direct_smoke")
        if not isinstance(latest_doc.get("verdict"), str) or not str(latest_doc.get("verdict")).strip():
            promotability_reasons.append("missing_verdict")
        if not isinstance(latest_doc.get("reason_code"), str) or not str(latest_doc.get("reason_code")).strip():
            promotability_reasons.append("missing_reason_code")
        if stamped_path is not None and stamped_path.exists():
            stamped_doc = load_optional_json(stamped_path)
            if stamped_doc is None:
                freshness_reasons.append("stamped_invalid_json")
            else:
                if str(stamped_doc.get("run_id") or "").strip() != (promoted_id or ""):
                    freshness_reasons.append("stamped_run_id_mismatch")
                stamped_latest_path = resolve_nested_artifact_path(
                    stamped_doc, "artifact_paths", "validation_latest_report_path"
                )
                stamped_stamped_path = resolve_nested_artifact_path(
                    stamped_doc, "artifact_paths", "validation_stamped_report_path"
                )
                if stamped_latest_path != latest_path:
                    freshness_reasons.append("stamped_latest_path_mismatch")
                if stamped_stamped_path != stamped_path.resolve():
                    freshness_reasons.append("stamped_path_mismatch")

    freshness_state, promotability_status = classify_local_validation_states(
        latest_path=latest_path,
        latest_doc=latest_doc,
        stamped_path=stamped_path,
        freshness_reasons=freshness_reasons,
        promotability_reasons=promotability_reasons,
        dependency_states=dependency_states,
    )
    return LocalValidationFreshnessRecord(
        artifact_family="monday_local_operator_stack_report",
        artifact_kind="report",
        promoted_id=promoted_id,
        generated_at_utc=generated_at_utc,
        freshness_state=freshness_state,
        promotability_status=promotability_status,
        latest_path=str(latest_path),
        stamped_path=None if stamped_path is None else str(stamped_path.resolve()),
        reasons=freshness_reasons + promotability_reasons,
        dependency_states=dependency_states,
    )


def build_local_inbox_payload_record(
    *,
    validation_root: Path,
    payload_path: Path,
    payload_doc: dict[str, Any],
) -> LocalInboxPayloadRecord:
    payload = payload_doc.get("payload") if isinstance(payload_doc.get("payload"), dict) else {}
    source_artifacts = payload.get("source_artifacts") if isinstance(payload.get("source_artifacts"), dict) else {}
    dependency_states: dict[str, str] = {}
    dependency_states["monday_local_operator_day_packet"] = build_local_validation_dependency_state(
        raw_path=source_artifacts.get("day_packet_path"),
        expected_path=validation_root / "monday-local-operator-day-packet.json",
    )[0]
    dependency_states["monday_local_mission_packet"] = build_local_validation_dependency_state(
        raw_path=source_artifacts.get("mission_packet_path"),
        expected_path=validation_root / "monday-local-mission-packet.json",
    )[0]
    dependency_states["operator_handoff_report"] = build_local_validation_dependency_state(
        raw_path=source_artifacts.get("handoff_report_path"),
        expected_path=validation_root / "operator-handoff-report.json",
    )[0]
    dependency_states["monday_local_operator_stack_report"] = build_local_validation_dependency_state(
        raw_path=source_artifacts.get("local_operator_report_path"),
        expected_path=validation_root / "monday-local-operator-stack-report.json",
    )[0]
    return LocalInboxPayloadRecord(
        bridge_id=str(payload_doc.get("bridge_id")),
        source_kind=source_kind_for_local_inbox_payload_path(payload_path),
        payload_path=str(payload_path.resolve()),
        generated_at_utc=str(payload_doc.get("generated_at_utc") or ""),
        title=normalize_optional_string(payload.get("title")),
        status=normalize_optional_string(payload.get("status")),
        needs_human_attention=(
            payload.get("needs_human_attention") if isinstance(payload.get("needs_human_attention"), bool) else None
        ),
        message_class_hint=normalize_optional_string(payload.get("message_class_hint")),
        retry_mode=normalize_optional_string(payload.get("retry_mode")),
        operator_action=normalize_optional_string(payload.get("operator_action")),
        planner_profile=normalize_optional_string(payload.get("planner_profile")),
        launch_mode=normalize_optional_string(payload.get("launch_mode")),
        local_model_route=normalize_optional_string(payload.get("local_model_route")),
        local_validation_snapshot_status=normalize_optional_string(payload.get("local_validation_snapshot_status")),
        day_packet_id=normalize_optional_string(payload.get("day_packet_id")),
        mission_packet_id=normalize_optional_string(payload.get("mission_packet_id")),
        mission_objective=normalize_optional_string(payload.get("mission_objective")),
        first_action_command=normalize_optional_string(payload.get("first_action_command")),
        monday_runtime_entrypoint_command=normalize_optional_string(payload.get("monday_runtime_entrypoint_command")),
        rollback_command=normalize_optional_string(payload.get("rollback_command")),
        attachment_count=len(normalize_string_list(payload.get("attachments"))),
        local_validation_action_lines=normalize_string_list(payload.get("local_validation_action_lines")),
        immediate_actions=normalize_string_list(payload.get("immediate_actions")),
        queue_lines=normalize_string_list(payload.get("queue_lines")),
        target_lines=normalize_string_list(payload.get("target_lines")),
        dependency_states=dependency_states,
    )


def discover_local_inbox_payload_records(*, validation_root: Path) -> list[LocalInboxPayloadRecord]:
    paths: list[Path] = []
    latest_path = validation_root / "monday-local-operator-inbox-payload.json"
    if latest_path.exists():
        paths.append(latest_path)
    paths.extend(sorted(validation_root.glob("*-monday-local-operator-inbox-payload.json")))

    records: list[LocalInboxPayloadRecord] = []
    for path in paths:
        if path.name.startswith(".") or path.name.startswith("._"):
            continue
        try:
            doc = load_json(path)
        except (UnicodeDecodeError, json.JSONDecodeError):
            continue
        if not is_local_inbox_payload_document(doc):
            continue
        records.append(build_local_inbox_payload_record(validation_root=validation_root, payload_path=path, payload_doc=doc))
    records.sort(
        key=lambda record: (
            record.generated_at_utc,
            record.bridge_id,
            1 if record.source_kind == "latest" else 0,
            record.payload_path,
        ),
        reverse=True,
    )
    return records


def filter_local_inbox_payload_records(
    *,
    records: list[LocalInboxPayloadRecord],
    bridge_id_prefix: str | None = None,
    source_kind: str = "latest",
    status: str | None = None,
    message_class_hint: str | None = None,
    needs_human_attention: str | None = None,
    launch_mode: str | None = None,
    local_model_route: str | None = None,
    local_validation_snapshot_status: str | None = None,
    has_dependency_state: str | None = None,
) -> list[LocalInboxPayloadRecord]:
    filtered = records
    if bridge_id_prefix:
        filtered = [record for record in filtered if record.bridge_id.startswith(bridge_id_prefix)]
    if source_kind != "all":
        filtered = [record for record in filtered if record.source_kind == source_kind]
    if status:
        filtered = [record for record in filtered if record.status == status]
    if message_class_hint:
        filtered = [record for record in filtered if record.message_class_hint == message_class_hint]
    if needs_human_attention is not None:
        expected = needs_human_attention == "yes"
        filtered = [record for record in filtered if record.needs_human_attention is expected]
    if launch_mode:
        filtered = [record for record in filtered if record.launch_mode == launch_mode]
    if local_model_route:
        filtered = [record for record in filtered if record.local_model_route == local_model_route]
    if local_validation_snapshot_status:
        filtered = [
            record
            for record in filtered
            if record.local_validation_snapshot_status == local_validation_snapshot_status
        ]
    if has_dependency_state:
        filtered = [
            record
            for record in filtered
            if has_dependency_state in record.dependency_states.values()
        ]
    return filtered


def render_local_inbox_payload_table(records: list[LocalInboxPayloadRecord]) -> str:
    lines = [
        "bridge_id\tsource\tstatus\tattention\tmessage_class\tretry_mode\tplanner_profile\tlaunch_mode\tlocal_model_route\tvalidation_snapshot\tdependencies\timmediate_actions\ttargets\tattachments\tgenerated_at_utc",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.bridge_id,
                    record.source_kind,
                    str(record.status or ""),
                    (
                        ""
                        if record.needs_human_attention is None
                        else ("yes" if record.needs_human_attention else "no")
                    ),
                    str(record.message_class_hint or ""),
                    str(record.retry_mode or ""),
                    str(record.planner_profile or ""),
                    str(record.launch_mode or ""),
                    str(record.local_model_route or ""),
                    str(record.local_validation_snapshot_status or ""),
                    ",".join(f"{key}={value}" for key, value in record.dependency_states.items()),
                    str(len(record.immediate_actions)),
                    str(len(record.target_lines)),
                    str(record.attachment_count),
                    record.generated_at_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_local_inbox_payload_markdown(records: list[LocalInboxPayloadRecord]) -> str:
    lines = [
        "| bridge_id | source | status | attention | message_class | retry_mode | planner_profile | launch_mode | local_model_route | validation_snapshot | dependencies | immediate_actions | targets | attachments | generated_at_utc |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | ---: | ---: | --- |",
    ]
    for record in records:
        lines.append(
            f"| `{record.bridge_id}` | {record.source_kind} | {record.status or ''} | "
            f"{'' if record.needs_human_attention is None else ('yes' if record.needs_human_attention else 'no')} | "
            f"{record.message_class_hint or ''} | {record.retry_mode or ''} | {record.planner_profile or ''} | "
            f"{record.launch_mode or ''} | {record.local_model_route or ''} | "
            f"{record.local_validation_snapshot_status or ''} | "
            f"{', '.join(f'{key}={value}' for key, value in record.dependency_states.items())} | "
            f"{len(record.immediate_actions)} | {len(record.target_lines)} | {record.attachment_count} | "
            f"{record.generated_at_utc} |"
        )
    return "\n".join(lines)


def build_monday_consumer_report_record(
    *,
    report_path: Path,
    report_doc: dict[str, Any],
) -> MondayConsumerReportRecord:
    artifact_paths = report_doc.get("artifact_paths") if isinstance(report_doc.get("artifact_paths"), dict) else {}
    launch_request = report_doc.get("launch_request") if isinstance(report_doc.get("launch_request"), dict) else {}
    runtime_input_overrides = (
        launch_request.get("runtime_input_overrides") if isinstance(launch_request.get("runtime_input_overrides"), dict) else {}
    )
    execution = report_doc.get("execution") if isinstance(report_doc.get("execution"), dict) else {}
    runtime_report_summary = (
        report_doc.get("runtime_report_summary") if isinstance(report_doc.get("runtime_report_summary"), dict) else {}
    )
    launch_request_path = resolve_artifact_path(artifact_paths.get("launch_request_path"))
    mission_file_path = resolve_artifact_path(artifact_paths.get("mission_file_path"))
    runtime_report_path = resolve_artifact_path(artifact_paths.get("runtime_report_path"))
    execution_attempted = execution.get("attempted") if isinstance(execution.get("attempted"), bool) else None
    execution_exit_code = execution.get("exit_code") if isinstance(execution.get("exit_code"), int) else None
    planner_runtime_config_path = normalize_optional_string(runtime_input_overrides.get("planner_runtime_config"))
    runtime_profile_file_path = normalize_optional_string(runtime_input_overrides.get("runtime_profile_file"))
    override_kinds: list[str] = []
    if planner_runtime_config_path is not None:
        override_kinds.append("planner_runtime_config")
    if runtime_profile_file_path is not None:
        override_kinds.append("runtime_profile_file")
    return MondayConsumerReportRecord(
        run_id=str(report_doc.get("run_id")),
        report_path=str(report_path.resolve()),
        generated_at_utc=str(report_doc.get("generated_at_utc") or ""),
        bridge_id=normalize_optional_string(report_doc.get("bridge_id")),
        mode=normalize_optional_string(report_doc.get("mode")),
        verdict=normalize_optional_string(report_doc.get("verdict")),
        reason_code=normalize_optional_string(report_doc.get("reason_code")),
        consumer_status=normalize_optional_string(report_doc.get("consumer_status")),
        can_launch=launch_request.get("can_launch") if isinstance(launch_request.get("can_launch"), bool) else None,
        planner_profile=normalize_optional_string(launch_request.get("planner_profile")),
        launch_mode=normalize_optional_string(launch_request.get("launch_mode")),
        local_model_route=normalize_optional_string(launch_request.get("local_model_route")),
        local_validation_snapshot_status=normalize_optional_string(launch_request.get("local_validation_snapshot_status")),
        block_reasons=normalize_string_list(launch_request.get("block_reasons")),
        command_args=normalize_string_list(launch_request.get("runtime_command_args")),
        has_runtime_input_overrides=bool(override_kinds),
        override_kinds=override_kinds,
        planner_runtime_config_path=planner_runtime_config_path,
        runtime_profile_file_path=runtime_profile_file_path,
        execution_attempted=execution_attempted,
        execution_exit_code=execution_exit_code,
        runtime_report_verdict=normalize_optional_string(runtime_report_summary.get("verdict")),
        runtime_report_reason_code=normalize_optional_string(runtime_report_summary.get("reason_code")),
        has_launch_request=launch_request_path.exists() if launch_request_path is not None else False,
        has_mission_file=mission_file_path.exists() if mission_file_path is not None else False,
        has_runtime_report=runtime_report_path.exists() if runtime_report_path is not None else False,
    )


def discover_monday_consumer_report_records(*, consumer_root: Path) -> list[MondayConsumerReportRecord]:
    if not consumer_root.exists():
        return []
    records: list[MondayConsumerReportRecord] = []
    for path in sorted(consumer_root.glob("*/consumer-report.json")):
        if any(part.startswith(".") or part.startswith("._") for part in path.parts):
            continue
        try:
            doc = load_json(path)
        except (UnicodeDecodeError, json.JSONDecodeError):
            continue
        if not is_monday_consumer_report_document(doc):
            continue
        records.append(build_monday_consumer_report_record(report_path=path, report_doc=doc))
    records.sort(
        key=lambda record: (
            record.generated_at_utc,
            record.run_id,
            record.report_path,
        ),
        reverse=True,
    )
    return records


def filter_monday_consumer_report_records(
    *,
    records: list[MondayConsumerReportRecord],
    run_id_prefix: str | None = None,
    mode: str | None = None,
    verdict: str | None = None,
    reason_code: str | None = None,
    consumer_status: str | None = None,
    can_launch: str | None = None,
    planner_profile: str | None = None,
    launch_mode: str | None = None,
    local_model_route: str | None = None,
    has_runtime_input_overrides: str | None = None,
    override_kind: str | None = None,
    has_runtime_report: str | None = None,
    execution_attempted: str | None = None,
) -> list[MondayConsumerReportRecord]:
    filtered = records
    if run_id_prefix:
        filtered = [record for record in filtered if record.run_id.startswith(run_id_prefix)]
    if mode:
        filtered = [record for record in filtered if record.mode == mode]
    if verdict:
        filtered = [record for record in filtered if record.verdict == verdict]
    if reason_code:
        filtered = [record for record in filtered if record.reason_code == reason_code]
    if consumer_status:
        filtered = [record for record in filtered if record.consumer_status == consumer_status]
    if can_launch is not None:
        expected = can_launch == "yes"
        filtered = [record for record in filtered if record.can_launch is expected]
    if planner_profile:
        filtered = [record for record in filtered if record.planner_profile == planner_profile]
    if launch_mode:
        filtered = [record for record in filtered if record.launch_mode == launch_mode]
    if local_model_route:
        filtered = [record for record in filtered if record.local_model_route == local_model_route]
    if has_runtime_input_overrides is not None:
        expected = has_runtime_input_overrides == "yes"
        filtered = [record for record in filtered if record.has_runtime_input_overrides is expected]
    if override_kind:
        filtered = [record for record in filtered if override_kind in record.override_kinds]
    if has_runtime_report is not None:
        expected = has_runtime_report == "yes"
        filtered = [record for record in filtered if record.has_runtime_report is expected]
    if execution_attempted is not None:
        expected = execution_attempted == "yes"
        filtered = [record for record in filtered if record.execution_attempted is expected]
    return filtered


def render_monday_consumer_report_table(records: list[MondayConsumerReportRecord]) -> str:
    lines = [
        "run_id\tmode\tverdict\treason_code\tconsumer_status\tcan_launch\tplanner_profile\tlaunch_mode\tlocal_model_route\thas_runtime_overrides\toverride_kinds\texecution_attempted\texecution_exit_code\truntime_report_verdict\thas_runtime_report\tblock_reasons\tgenerated_at_utc",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.run_id,
                    str(record.mode or ""),
                    str(record.verdict or ""),
                    str(record.reason_code or ""),
                    str(record.consumer_status or ""),
                    "" if record.can_launch is None else ("yes" if record.can_launch else "no"),
                    str(record.planner_profile or ""),
                    str(record.launch_mode or ""),
                    str(record.local_model_route or ""),
                    "yes" if record.has_runtime_input_overrides else "no",
                    ",".join(record.override_kinds),
                    (
                        ""
                        if record.execution_attempted is None
                        else ("yes" if record.execution_attempted else "no")
                    ),
                    "" if record.execution_exit_code is None else str(record.execution_exit_code),
                    str(record.runtime_report_verdict or ""),
                    "yes" if record.has_runtime_report else "no",
                    ",".join(record.block_reasons),
                    record.generated_at_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_monday_consumer_report_markdown(records: list[MondayConsumerReportRecord]) -> str:
    lines = [
        "| run_id | mode | verdict | reason_code | consumer_status | can_launch | planner_profile | launch_mode | local_model_route | has_runtime_overrides | override_kinds | execution_attempted | execution_exit_code | runtime_report_verdict | has_runtime_report | block_reasons | generated_at_utc |",
        "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| `{record.run_id}` | {record.mode or ''} | {record.verdict or ''} | {record.reason_code or ''} | "
            f"{record.consumer_status or ''} | "
            f"{'' if record.can_launch is None else ('yes' if record.can_launch else 'no')} | "
            f"{record.planner_profile or ''} | {record.launch_mode or ''} | {record.local_model_route or ''} | "
            f"{'yes' if record.has_runtime_input_overrides else 'no'} | "
            f"{', '.join(record.override_kinds)} | "
            f"{'' if record.execution_attempted is None else ('yes' if record.execution_attempted else 'no')} | "
            f"{'' if record.execution_exit_code is None else record.execution_exit_code} | "
            f"{record.runtime_report_verdict or ''} | "
            f"{'yes' if record.has_runtime_report else 'no'} | "
            f"{', '.join(record.block_reasons)} | {record.generated_at_utc} |"
        )
    return "\n".join(lines)


def build_monday_validation_report_record(
    *,
    report_path: Path,
    report_doc: dict[str, Any],
) -> MondayValidationReportRecord:
    artifact_path = resolve_artifact_path(report_doc.get("artifact_path"))
    schema_path = resolve_artifact_path(report_doc.get("schema_path"))
    errors = normalize_string_list(report_doc.get("errors"))
    warnings = normalize_string_list(report_doc.get("warnings"))
    raw_error_count = report_doc.get("error_count")
    raw_warning_count = report_doc.get("warning_count")
    error_count = raw_error_count if isinstance(raw_error_count, int) else len(errors)
    warning_count = raw_warning_count if isinstance(raw_warning_count, int) else len(warnings)
    return MondayValidationReportRecord(
        kind=str(report_doc.get("kind")),
        report_path=str(report_path.resolve()),
        generated_at_utc=str(report_doc.get("generated_at_utc") or ""),
        verdict=normalize_optional_string(report_doc.get("verdict")),
        error_count=error_count,
        warning_count=warning_count,
        artifact_path=None if artifact_path is None else str(artifact_path),
        schema_path=None if schema_path is None else str(schema_path),
        artifact_exists=artifact_path.exists() if artifact_path is not None else False,
        schema_exists=schema_path.exists() if schema_path is not None else False,
        errors=errors,
        warnings=warnings,
    )


def discover_monday_validation_report_records(*, validation_root: Path) -> list[MondayValidationReportRecord]:
    if not validation_root.exists():
        return []
    records: list[MondayValidationReportRecord] = []
    for path in sorted(validation_root.glob("planningops-local-operator-inbox*-validation-report.json")):
        if any(part.startswith(".") or part.startswith("._") for part in path.parts):
            continue
        try:
            doc = load_json(path)
        except (UnicodeDecodeError, json.JSONDecodeError):
            continue
        if not is_monday_validation_report_document(doc):
            continue
        records.append(build_monday_validation_report_record(report_path=path, report_doc=doc))
    records.sort(
        key=lambda record: (
            record.generated_at_utc,
            record.kind,
            record.report_path,
        ),
        reverse=True,
    )
    return records


def filter_monday_validation_report_records(
    *,
    records: list[MondayValidationReportRecord],
    kind: str | None = None,
    verdict: str | None = None,
    has_errors: str | None = None,
    has_warnings: str | None = None,
    artifact_exists: str | None = None,
    schema_exists: str | None = None,
    has_message: str | None = None,
) -> list[MondayValidationReportRecord]:
    filtered = records
    if kind:
        filtered = [record for record in filtered if record.kind == kind]
    if verdict:
        filtered = [record for record in filtered if record.verdict == verdict]
    if has_errors is not None:
        expected = has_errors == "yes"
        filtered = [record for record in filtered if (record.error_count > 0) is expected]
    if has_warnings is not None:
        expected = has_warnings == "yes"
        filtered = [record for record in filtered if (record.warning_count > 0) is expected]
    if artifact_exists is not None:
        expected = artifact_exists == "yes"
        filtered = [record for record in filtered if record.artifact_exists is expected]
    if schema_exists is not None:
        expected = schema_exists == "yes"
        filtered = [record for record in filtered if record.schema_exists is expected]
    if has_message:
        needle = has_message.lower()
        filtered = [
            record
            for record in filtered
            if any(needle in message.lower() for message in [*record.errors, *record.warnings])
        ]
    return filtered


def render_monday_validation_report_table(records: list[MondayValidationReportRecord]) -> str:
    lines = [
        "kind\tverdict\terror_count\twarning_count\tartifact_exists\tschema_exists\treport_path\tartifact_path\tschema_path\tgenerated_at_utc",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.kind,
                    str(record.verdict or ""),
                    str(record.error_count),
                    str(record.warning_count),
                    "yes" if record.artifact_exists else "no",
                    "yes" if record.schema_exists else "no",
                    record.report_path,
                    str(record.artifact_path or ""),
                    str(record.schema_path or ""),
                    record.generated_at_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_monday_validation_report_markdown(records: list[MondayValidationReportRecord]) -> str:
    lines = [
        "| kind | verdict | error_count | warning_count | artifact_exists | schema_exists | report_path | artifact_path | schema_path | generated_at_utc |",
        "| --- | --- | ---: | ---: | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.kind} | {record.verdict or ''} | {record.error_count} | {record.warning_count} | "
            f"{'yes' if record.artifact_exists else 'no'} | {'yes' if record.schema_exists else 'no'} | "
            f"`{record.report_path}` | `{record.artifact_path or ''}` | `{record.schema_path or ''}` | {record.generated_at_utc} |"
        )
    return "\n".join(lines)


def build_handoff_validation_freshness_record(*, validation_root: Path) -> LocalValidationFreshnessRecord:
    latest_path = (validation_root / "operator-handoff-report.json").resolve()
    latest_doc = load_optional_json(latest_path)
    freshness_reasons: list[str] = []
    promotability_reasons: list[str] = []
    dependency_states: dict[str, str] = {}
    stamped_path: Path | None = None
    promoted_id: str | None = None
    generated_at_utc: str | None = None

    if latest_doc is not None:
        promoted_id = str(latest_doc.get("report_id") or "").strip() or None
        generated_at_utc = str(latest_doc.get("generated_at_utc") or "").strip() or None
        if promoted_id is None:
            promotability_reasons.append("missing_report_id")
        latest_report_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "latest_report_path")
        stamped_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "stamped_report_path")
        if latest_report_path != latest_path:
            freshness_reasons.append("latest_path_mismatch")
        record_doc = resolve_nested_value(latest_doc, "record")
        if not isinstance(record_doc, dict):
            promotability_reasons.append("missing_record")
        else:
            if not isinstance(record_doc.get("headline"), str) or not str(record_doc.get("headline")).strip():
                promotability_reasons.append("missing_headline")
            if not isinstance(record_doc.get("attention_summary"), str) or not str(record_doc.get("attention_summary")).strip():
                promotability_reasons.append("missing_attention_summary")
            action_lines = [str(line) for line in list(record_doc.get("immediate_action_lines") or []) if str(line).strip()]
            if not action_lines:
                promotability_reasons.append("missing_immediate_action_lines")
        if stamped_path is not None and stamped_path.exists():
            stamped_doc = load_optional_json(stamped_path)
            if stamped_doc is None:
                freshness_reasons.append("stamped_invalid_json")
            else:
                if str(stamped_doc.get("report_id") or "").strip() != (promoted_id or ""):
                    freshness_reasons.append("stamped_report_id_mismatch")
                stamped_latest_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "latest_report_path")
                stamped_stamped_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "stamped_report_path")
                if stamped_latest_path != latest_path:
                    freshness_reasons.append("stamped_latest_path_mismatch")
                if stamped_stamped_path != stamped_path.resolve():
                    freshness_reasons.append("stamped_path_mismatch")

    freshness_state, promotability_status = classify_local_validation_states(
        latest_path=latest_path,
        latest_doc=latest_doc,
        stamped_path=stamped_path,
        freshness_reasons=freshness_reasons,
        promotability_reasons=promotability_reasons,
        dependency_states=dependency_states,
    )
    return LocalValidationFreshnessRecord(
        artifact_family="operator_handoff_report",
        artifact_kind="report",
        promoted_id=promoted_id,
        generated_at_utc=generated_at_utc,
        freshness_state=freshness_state,
        promotability_status=promotability_status,
        latest_path=str(latest_path),
        stamped_path=None if stamped_path is None else str(stamped_path.resolve()),
        reasons=freshness_reasons + promotability_reasons,
        dependency_states=dependency_states,
    )


def build_mission_packet_validation_freshness_record(*, validation_root: Path) -> LocalValidationFreshnessRecord:
    latest_path = (validation_root / "monday-local-mission-packet.json").resolve()
    latest_doc = load_optional_json(latest_path)
    freshness_reasons: list[str] = []
    promotability_reasons: list[str] = []
    dependency_states: dict[str, str] = {}
    stamped_path: Path | None = None
    promoted_id: str | None = None
    generated_at_utc: str | None = None

    if latest_doc is not None:
        promoted_id = str(latest_doc.get("packet_id") or "").strip() or None
        generated_at_utc = str(latest_doc.get("generated_at_utc") or "").strip() or None
        if promoted_id is None:
            promotability_reasons.append("missing_packet_id")
        if not isinstance(latest_doc.get("contract_ref"), str) or not str(latest_doc.get("contract_ref")).strip():
            promotability_reasons.append("missing_contract_ref")
        latest_packet_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "latest_packet_path")
        stamped_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "stamped_packet_path")
        if latest_packet_path != latest_path:
            freshness_reasons.append("latest_path_mismatch")
        mission_packet = resolve_nested_value(latest_doc, "mission_packet")
        if not isinstance(mission_packet, dict):
            promotability_reasons.append("missing_mission_packet")
        else:
            required_strings = {
                "mission_objective": "missing_mission_objective",
                "preflight_command": "missing_preflight_command",
                "rollback_command": "missing_rollback_command",
                "planner_profile": "missing_planner_profile",
                "launch_mode": "missing_launch_mode",
                "local_model_route": "missing_local_model_route",
            }
            for field_name, reason in required_strings.items():
                value = mission_packet.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    promotability_reasons.append(reason)
            expected_outputs = [str(path) for path in list(mission_packet.get("expected_evidence_outputs") or []) if str(path).strip()]
            if not expected_outputs:
                promotability_reasons.append("missing_expected_evidence_outputs")
            source_artifacts = mission_packet.get("source_artifacts")
            if not isinstance(source_artifacts, dict):
                promotability_reasons.append("missing_source_artifacts")
            else:
                handoff_state, handoff_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("handoff_report_path"),
                    expected_path=validation_root / "operator-handoff-report.json",
                )
                local_state, local_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("local_operator_report_path"),
                    expected_path=validation_root / "monday-local-operator-stack-report.json",
                )
                dependency_states["operator_handoff_report"] = handoff_state
                dependency_states["monday_local_operator_stack_report"] = local_state
                if handoff_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_handoff_report_path")
                elif handoff_reason == "dependency_missing":
                    promotability_reasons.append("handoff_dependency_missing")
                elif handoff_reason == "dependency_stale":
                    promotability_reasons.append("handoff_dependency_stale")
                if local_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_local_operator_report_path")
                elif local_reason == "dependency_missing":
                    promotability_reasons.append("local_operator_dependency_missing")
                elif local_reason == "dependency_stale":
                    promotability_reasons.append("local_operator_dependency_stale")
        if stamped_path is not None and stamped_path.exists():
            stamped_doc = load_optional_json(stamped_path)
            if stamped_doc is None:
                freshness_reasons.append("stamped_invalid_json")
            else:
                if str(stamped_doc.get("packet_id") or "").strip() != (promoted_id or ""):
                    freshness_reasons.append("stamped_packet_id_mismatch")
                stamped_latest_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "latest_packet_path")
                stamped_stamped_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "stamped_packet_path")
                if stamped_latest_path != latest_path:
                    freshness_reasons.append("stamped_latest_path_mismatch")
                if stamped_stamped_path != stamped_path.resolve():
                    freshness_reasons.append("stamped_path_mismatch")

    freshness_state, promotability_status = classify_local_validation_states(
        latest_path=latest_path,
        latest_doc=latest_doc,
        stamped_path=stamped_path,
        freshness_reasons=freshness_reasons,
        promotability_reasons=promotability_reasons,
        dependency_states=dependency_states,
    )
    return LocalValidationFreshnessRecord(
        artifact_family="monday_local_mission_packet",
        artifact_kind="packet",
        promoted_id=promoted_id,
        generated_at_utc=generated_at_utc,
        freshness_state=freshness_state,
        promotability_status=promotability_status,
        latest_path=str(latest_path),
        stamped_path=None if stamped_path is None else str(stamped_path.resolve()),
        reasons=freshness_reasons + promotability_reasons,
        dependency_states=dependency_states,
    )


def build_day_packet_validation_freshness_record(*, validation_root: Path) -> LocalValidationFreshnessRecord:
    latest_path = (validation_root / "monday-local-operator-day-packet.json").resolve()
    latest_doc = load_optional_json(latest_path)
    freshness_reasons: list[str] = []
    promotability_reasons: list[str] = []
    dependency_states: dict[str, str] = {}
    stamped_path: Path | None = None
    promoted_id: str | None = None
    generated_at_utc: str | None = None

    if latest_doc is not None:
        promoted_id = str(latest_doc.get("day_packet_id") or "").strip() or None
        generated_at_utc = str(latest_doc.get("generated_at_utc") or "").strip() or None
        if promoted_id is None:
            promotability_reasons.append("missing_day_packet_id")
        if not isinstance(latest_doc.get("contract_ref"), str) or not str(latest_doc.get("contract_ref")).strip():
            promotability_reasons.append("missing_contract_ref")
        latest_packet_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "latest_packet_path")
        stamped_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "stamped_packet_path")
        if latest_packet_path != latest_path:
            freshness_reasons.append("latest_path_mismatch")
        day_packet = resolve_nested_value(latest_doc, "day_packet")
        if not isinstance(day_packet, dict):
            promotability_reasons.append("missing_day_packet")
        else:
            required_strings = {
                "headline": "missing_headline",
                "mission_objective": "missing_mission_objective",
                "planner_profile": "missing_planner_profile",
                "launch_mode": "missing_launch_mode",
                "local_model_route": "missing_local_model_route",
                "first_action_command": "missing_first_action_command",
                "monday_runtime_entrypoint_command": "missing_runtime_entrypoint_command",
                "rollback_command": "missing_rollback_command",
                "body_markdown": "missing_body_markdown",
                "local_validation_snapshot_status": "missing_local_validation_snapshot_status",
            }
            for field_name, reason in required_strings.items():
                value = day_packet.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    promotability_reasons.append(reason)
            attachments = [str(path) for path in list(day_packet.get("attachments") or []) if str(path).strip()]
            if not attachments:
                promotability_reasons.append("missing_attachments")
            source_artifacts = day_packet.get("source_artifacts")
            if not isinstance(source_artifacts, dict):
                promotability_reasons.append("missing_source_artifacts")
            else:
                mission_state, mission_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("mission_packet_path"),
                    expected_path=validation_root / "monday-local-mission-packet.json",
                )
                handoff_state, handoff_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("handoff_report_path"),
                    expected_path=validation_root / "operator-handoff-report.json",
                )
                local_state, local_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("local_operator_report_path"),
                    expected_path=validation_root / "monday-local-operator-stack-report.json",
                )
                dependency_states["monday_local_mission_packet"] = mission_state
                dependency_states["operator_handoff_report"] = handoff_state
                dependency_states["monday_local_operator_stack_report"] = local_state
                if mission_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_mission_packet_path")
                elif mission_reason == "dependency_missing":
                    promotability_reasons.append("mission_packet_dependency_missing")
                elif mission_reason == "dependency_stale":
                    promotability_reasons.append("mission_packet_dependency_stale")
                if handoff_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_handoff_report_path")
                elif handoff_reason == "dependency_missing":
                    promotability_reasons.append("handoff_dependency_missing")
                elif handoff_reason == "dependency_stale":
                    promotability_reasons.append("handoff_dependency_stale")
                if local_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_local_operator_report_path")
                elif local_reason == "dependency_missing":
                    promotability_reasons.append("local_operator_dependency_missing")
                elif local_reason == "dependency_stale":
                    promotability_reasons.append("local_operator_dependency_stale")
        if stamped_path is not None and stamped_path.exists():
            stamped_doc = load_optional_json(stamped_path)
            if stamped_doc is None:
                freshness_reasons.append("stamped_invalid_json")
            else:
                if str(stamped_doc.get("day_packet_id") or "").strip() != (promoted_id or ""):
                    freshness_reasons.append("stamped_day_packet_id_mismatch")
                stamped_latest_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "latest_packet_path")
                stamped_stamped_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "stamped_packet_path")
                if stamped_latest_path != latest_path:
                    freshness_reasons.append("stamped_latest_path_mismatch")
                if stamped_stamped_path != stamped_path.resolve():
                    freshness_reasons.append("stamped_path_mismatch")

    freshness_state, promotability_status = classify_local_validation_states(
        latest_path=latest_path,
        latest_doc=latest_doc,
        stamped_path=stamped_path,
        freshness_reasons=freshness_reasons,
        promotability_reasons=promotability_reasons,
        dependency_states=dependency_states,
    )
    return LocalValidationFreshnessRecord(
        artifact_family="monday_local_operator_day_packet",
        artifact_kind="packet",
        promoted_id=promoted_id,
        generated_at_utc=generated_at_utc,
        freshness_state=freshness_state,
        promotability_status=promotability_status,
        latest_path=str(latest_path),
        stamped_path=None if stamped_path is None else str(stamped_path.resolve()),
        reasons=freshness_reasons + promotability_reasons,
        dependency_states=dependency_states,
    )


def build_inbox_payload_validation_freshness_record(*, validation_root: Path) -> LocalValidationFreshnessRecord:
    latest_path = (validation_root / "monday-local-operator-inbox-payload.json").resolve()
    latest_doc = load_optional_json(latest_path)
    freshness_reasons: list[str] = []
    promotability_reasons: list[str] = []
    dependency_states: dict[str, str] = {}
    stamped_path: Path | None = None
    promoted_id: str | None = None
    generated_at_utc: str | None = None

    if latest_doc is not None:
        promoted_id = str(latest_doc.get("bridge_id") or "").strip() or None
        generated_at_utc = str(latest_doc.get("generated_at_utc") or "").strip() or None
        if promoted_id is None:
            promotability_reasons.append("missing_bridge_id")
        if not isinstance(latest_doc.get("contract_ref"), str) or not str(latest_doc.get("contract_ref")).strip():
            promotability_reasons.append("missing_contract_ref")
        latest_payload_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "latest_payload_path")
        stamped_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "stamped_payload_path")
        if latest_payload_path != latest_path:
            freshness_reasons.append("latest_path_mismatch")
        payload = resolve_nested_value(latest_doc, "payload")
        if not isinstance(payload, dict):
            promotability_reasons.append("missing_payload")
        else:
            required_strings = {
                "title": "missing_title",
                "status": "missing_status",
                "headline": "missing_headline",
                "priority_headline": "missing_priority_headline",
                "operator_action": "missing_operator_action",
                "retry_mode": "missing_retry_mode",
                "message_class_hint": "missing_message_class_hint",
                "planner_profile": "missing_planner_profile",
                "launch_mode": "missing_launch_mode",
                "local_model_route": "missing_local_model_route",
                "first_action_command": "missing_first_action_command",
                "monday_runtime_entrypoint_command": "missing_runtime_entrypoint_command",
                "rollback_command": "missing_rollback_command",
                "local_validation_snapshot_status": "missing_local_validation_snapshot_status",
                "body_markdown": "missing_body_markdown",
                "bridge_contract_ref": "missing_bridge_contract_ref",
            }
            for field_name, reason in required_strings.items():
                value = payload.get(field_name)
                if not isinstance(value, str) or not value.strip():
                    promotability_reasons.append(reason)
            if not isinstance(payload.get("recommended_wait_minutes"), int):
                promotability_reasons.append("missing_recommended_wait_minutes")
            if not isinstance(payload.get("needs_human_attention"), bool):
                promotability_reasons.append("missing_needs_human_attention")
            attachments = [str(path) for path in list(payload.get("attachments") or []) if str(path).strip()]
            if not attachments:
                promotability_reasons.append("missing_attachments")
            source_artifacts = payload.get("source_artifacts")
            if not isinstance(source_artifacts, dict):
                promotability_reasons.append("missing_source_artifacts")
            else:
                day_state, day_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("day_packet_path"),
                    expected_path=validation_root / "monday-local-operator-day-packet.json",
                )
                mission_state, mission_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("mission_packet_path"),
                    expected_path=validation_root / "monday-local-mission-packet.json",
                )
                handoff_state, handoff_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("handoff_report_path"),
                    expected_path=validation_root / "operator-handoff-report.json",
                )
                local_state, local_reason = build_local_validation_dependency_state(
                    raw_path=source_artifacts.get("local_operator_report_path"),
                    expected_path=validation_root / "monday-local-operator-stack-report.json",
                )
                dependency_states["monday_local_operator_day_packet"] = day_state
                dependency_states["monday_local_mission_packet"] = mission_state
                dependency_states["operator_handoff_report"] = handoff_state
                dependency_states["monday_local_operator_stack_report"] = local_state
                if day_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_day_packet_path")
                elif day_reason == "dependency_missing":
                    promotability_reasons.append("day_packet_dependency_missing")
                elif day_reason == "dependency_stale":
                    promotability_reasons.append("day_packet_dependency_stale")
                if mission_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_mission_packet_path")
                elif mission_reason == "dependency_missing":
                    promotability_reasons.append("mission_packet_dependency_missing")
                elif mission_reason == "dependency_stale":
                    promotability_reasons.append("mission_packet_dependency_stale")
                if handoff_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_handoff_report_path")
                elif handoff_reason == "dependency_missing":
                    promotability_reasons.append("handoff_dependency_missing")
                elif handoff_reason == "dependency_stale":
                    promotability_reasons.append("handoff_dependency_stale")
                if local_reason == "dependency_path_missing":
                    promotability_reasons.append("missing_local_operator_report_path")
                elif local_reason == "dependency_missing":
                    promotability_reasons.append("local_operator_dependency_missing")
                elif local_reason == "dependency_stale":
                    promotability_reasons.append("local_operator_dependency_stale")
        if stamped_path is not None and stamped_path.exists():
            stamped_doc = load_optional_json(stamped_path)
            if stamped_doc is None:
                freshness_reasons.append("stamped_invalid_json")
            else:
                if str(stamped_doc.get("bridge_id") or "").strip() != (promoted_id or ""):
                    freshness_reasons.append("stamped_bridge_id_mismatch")
                stamped_latest_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "latest_payload_path")
                stamped_stamped_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "stamped_payload_path")
                if stamped_latest_path != latest_path:
                    freshness_reasons.append("stamped_latest_path_mismatch")
                if stamped_stamped_path != stamped_path.resolve():
                    freshness_reasons.append("stamped_path_mismatch")

    freshness_state, promotability_status = classify_local_validation_states(
        latest_path=latest_path,
        latest_doc=latest_doc,
        stamped_path=stamped_path,
        freshness_reasons=freshness_reasons,
        promotability_reasons=promotability_reasons,
        dependency_states=dependency_states,
    )
    return LocalValidationFreshnessRecord(
        artifact_family="monday_local_operator_inbox_payload",
        artifact_kind="payload",
        promoted_id=promoted_id,
        generated_at_utc=generated_at_utc,
        freshness_state=freshness_state,
        promotability_status=promotability_status,
        latest_path=str(latest_path),
        stamped_path=None if stamped_path is None else str(stamped_path.resolve()),
        reasons=freshness_reasons + promotability_reasons,
        dependency_states=dependency_states,
    )


def has_promoted_local_validation_artifact(
    *,
    validation_root: Path,
    latest_filename: str,
    stamped_glob: str,
) -> bool:
    latest_path = validation_root / latest_filename
    if latest_path.exists():
        return True
    return any(path.is_file() for path in validation_root.glob(stamped_glob))


def build_monday_local_inbox_validation_freshness_record(
    *,
    validation_root: Path,
    artifact_family: str,
    artifact_kind: str,
    latest_filename: str,
    dependency_filenames: dict[str, str],
) -> LocalValidationFreshnessRecord:
    latest_path = (validation_root / latest_filename).resolve()
    latest_doc = load_optional_json(latest_path)
    freshness_reasons: list[str] = []
    promotability_reasons: list[str] = []
    dependency_states: dict[str, str] = {}
    stamped_path: Path | None = None
    promoted_id: str | None = None
    generated_at_utc: str | None = None

    if latest_doc is not None:
        promoted_id = normalize_optional_string(latest_doc.get("run_id"))
        generated_at_utc = normalize_optional_string(latest_doc.get("generated_at_utc"))
        if promoted_id is None:
            promotability_reasons.append("missing_run_id")
        if normalize_optional_string(latest_doc.get("artifact_family")) != artifact_family:
            promotability_reasons.append("artifact_family_mismatch")
        if normalize_optional_string(latest_doc.get("artifact_kind")) != artifact_kind:
            promotability_reasons.append("artifact_kind_mismatch")
        if normalize_optional_string(latest_doc.get("contract_ref")) is None:
            promotability_reasons.append("missing_contract_ref")

        latest_mirror_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "latest_mirror_path")
        stamped_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "stamped_mirror_path")
        source_artifact_path = resolve_nested_artifact_path(latest_doc, "artifact_paths", "source_artifact_path")
        if latest_mirror_path != latest_path:
            freshness_reasons.append("latest_path_mismatch")

        mirror = resolve_nested_value(latest_doc, "mirror")
        if not isinstance(mirror, dict):
            promotability_reasons.append("missing_mirror")
        else:
            source_artifact_present = mirror.get("source_artifact_present")
            if not isinstance(source_artifact_present, bool):
                promotability_reasons.append("missing_source_artifact_present")
            else:
                actual_source_exists = source_artifact_path.exists() if source_artifact_path is not None else False
                if source_artifact_path is None:
                    promotability_reasons.append("missing_source_artifact_path")
                elif source_artifact_present != actual_source_exists:
                    promotability_reasons.append("source_artifact_state_mismatch")
                if not actual_source_exists:
                    promotability_reasons.append("source_artifact_missing")
                if source_artifact_present and not isinstance(mirror.get("payload"), dict):
                    promotability_reasons.append("missing_payload")

            validation_dependency_paths = mirror.get("validation_dependency_paths")
            if dependency_filenames and not isinstance(validation_dependency_paths, dict):
                promotability_reasons.append("missing_validation_dependency_paths")
            elif isinstance(validation_dependency_paths, dict):
                for dependency_family, dependency_filename in dependency_filenames.items():
                    dependency_state, dependency_reason = build_local_validation_dependency_state(
                        raw_path=validation_dependency_paths.get(dependency_family),
                        expected_path=validation_root / dependency_filename,
                    )
                    dependency_states[dependency_family] = dependency_state
                    if dependency_reason == "dependency_path_missing":
                        promotability_reasons.append(f"missing_{dependency_family}_path")
                    elif dependency_reason == "dependency_missing":
                        promotability_reasons.append(f"{dependency_family}_dependency_missing")
                    elif dependency_reason == "dependency_stale":
                        promotability_reasons.append(f"{dependency_family}_dependency_stale")

        if stamped_path is not None and stamped_path.exists():
            stamped_doc = load_optional_json(stamped_path)
            if stamped_doc is None:
                freshness_reasons.append("stamped_invalid_json")
            else:
                if normalize_optional_string(stamped_doc.get("run_id")) != promoted_id:
                    freshness_reasons.append("stamped_run_id_mismatch")
                stamped_latest_path = resolve_nested_artifact_path(stamped_doc, "artifact_paths", "latest_mirror_path")
                stamped_stamped_path = resolve_nested_artifact_path(
                    stamped_doc,
                    "artifact_paths",
                    "stamped_mirror_path",
                )
                if stamped_latest_path != latest_path:
                    freshness_reasons.append("stamped_latest_path_mismatch")
                if stamped_stamped_path != stamped_path.resolve():
                    freshness_reasons.append("stamped_path_mismatch")

    freshness_state, promotability_status = classify_local_validation_states(
        latest_path=latest_path,
        latest_doc=latest_doc,
        stamped_path=stamped_path,
        freshness_reasons=freshness_reasons,
        promotability_reasons=promotability_reasons,
        dependency_states=dependency_states,
    )
    return LocalValidationFreshnessRecord(
        artifact_family=artifact_family,
        artifact_kind=artifact_kind,
        promoted_id=promoted_id,
        generated_at_utc=generated_at_utc,
        freshness_state=freshness_state,
        promotability_status=promotability_status,
        latest_path=str(latest_path),
        stamped_path=None if stamped_path is None else str(stamped_path.resolve()),
        reasons=freshness_reasons + promotability_reasons,
        dependency_states=dependency_states,
    )


def build_monday_local_inbox_launch_request_validation_freshness_record(
    *,
    validation_root: Path,
) -> LocalValidationFreshnessRecord:
    return build_monday_local_inbox_validation_freshness_record(
        validation_root=validation_root,
        artifact_family="monday_local_inbox_launch_request",
        artifact_kind="request",
        latest_filename="monday-local-inbox-launch-request.json",
        dependency_filenames={
            "monday_local_operator_inbox_payload": "monday-local-operator-inbox-payload.json",
        },
    )


def build_monday_local_inbox_runtime_report_validation_freshness_record(
    *,
    validation_root: Path,
) -> LocalValidationFreshnessRecord:
    return build_monday_local_inbox_validation_freshness_record(
        validation_root=validation_root,
        artifact_family="monday_local_inbox_runtime_report",
        artifact_kind="report",
        latest_filename="monday-local-inbox-runtime-report.json",
        dependency_filenames={
            "monday_local_operator_inbox_payload": "monday-local-operator-inbox-payload.json",
            "monday_local_inbox_launch_request": "monday-local-inbox-launch-request.json",
        },
    )


def build_monday_local_inbox_consumer_report_validation_freshness_record(
    *,
    validation_root: Path,
) -> LocalValidationFreshnessRecord:
    return build_monday_local_inbox_validation_freshness_record(
        validation_root=validation_root,
        artifact_family="monday_local_inbox_consumer_report",
        artifact_kind="report",
        latest_filename="monday-local-inbox-consumer-report.json",
        dependency_filenames={
            "monday_local_operator_inbox_payload": "monday-local-operator-inbox-payload.json",
            "monday_local_inbox_launch_request": "monday-local-inbox-launch-request.json",
            "monday_local_inbox_runtime_report": "monday-local-inbox-runtime-report.json",
        },
    )


def discover_local_validation_freshness_records(*, validation_root: Path) -> list[LocalValidationFreshnessRecord]:
    records = [
        build_local_operator_validation_freshness_record(validation_root=validation_root),
        build_handoff_validation_freshness_record(validation_root=validation_root),
        build_mission_packet_validation_freshness_record(validation_root=validation_root),
        build_day_packet_validation_freshness_record(validation_root=validation_root),
        build_inbox_payload_validation_freshness_record(validation_root=validation_root),
    ]
    if has_promoted_local_validation_artifact(
        validation_root=validation_root,
        latest_filename="monday-local-inbox-launch-request.json",
        stamped_glob="*-monday-local-inbox-launch-request.json",
    ):
        records.append(build_monday_local_inbox_launch_request_validation_freshness_record(validation_root=validation_root))
    if has_promoted_local_validation_artifact(
        validation_root=validation_root,
        latest_filename="monday-local-inbox-runtime-report.json",
        stamped_glob="*-monday-local-inbox-runtime-report.json",
    ):
        records.append(build_monday_local_inbox_runtime_report_validation_freshness_record(validation_root=validation_root))
    if has_promoted_local_validation_artifact(
        validation_root=validation_root,
        latest_filename="monday-local-inbox-consumer-report.json",
        stamped_glob="*-monday-local-inbox-consumer-report.json",
    ):
        records.append(build_monday_local_inbox_consumer_report_validation_freshness_record(validation_root=validation_root))
    return records


def filter_local_validation_freshness_records(
    *,
    records: list[LocalValidationFreshnessRecord],
    artifact_family: str | None = None,
    freshness_state: str | None = None,
    promotability_status: str | None = None,
    has_reason: str | None = None,
) -> list[LocalValidationFreshnessRecord]:
    filtered = records
    if artifact_family:
        filtered = [record for record in filtered if record.artifact_family == artifact_family]
    if freshness_state:
        filtered = [record for record in filtered if record.freshness_state == freshness_state]
    if promotability_status:
        filtered = [record for record in filtered if record.promotability_status == promotability_status]
    if has_reason:
        filtered = [record for record in filtered if has_reason in record.reasons]
    return filtered


def render_local_validation_freshness_table(records: list[LocalValidationFreshnessRecord]) -> str:
    lines = [
        "artifact_family\tartifact_kind\tpromoted_id\tfreshness\tpromotability\tdependency_states\treasons\tgenerated_at_utc\tlatest_path\tstamped_path",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.artifact_family,
                    record.artifact_kind,
                    str(record.promoted_id or ""),
                    record.freshness_state,
                    record.promotability_status,
                    ",".join(f"{key}={value}" for key, value in record.dependency_states.items()),
                    ",".join(record.reasons),
                    str(record.generated_at_utc or ""),
                    record.latest_path,
                    str(record.stamped_path or ""),
                ]
            )
        )
    return "\n".join(lines)


def render_local_validation_freshness_markdown(records: list[LocalValidationFreshnessRecord]) -> str:
    lines = [
        "| artifact_family | kind | promoted_id | freshness | promotability | dependency_states | reasons | generated_at_utc |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.artifact_family} | {record.artifact_kind} | `{record.promoted_id or ''}` | "
            f"{record.freshness_state} | {record.promotability_status} | "
            f"{', '.join(f'{key}={value}' for key, value in record.dependency_states.items())} | "
            f"{', '.join(record.reasons)} | {record.generated_at_utc or ''} |"
        )
    return "\n".join(lines)


def build_local_validation_summary_line(record: LocalValidationFreshnessRecord) -> str:
    line = (
        f"{record.artifact_family}: freshness={record.freshness_state} "
        f"promotability={record.promotability_status}"
    )
    if record.reasons:
        line = f"{line} reasons={','.join(record.reasons)}"
    if record.dependency_states:
        line = (
            f"{line} dependencies="
            f"{','.join(f'{key}={value}' for key, value in record.dependency_states.items())}"
        )
    return line


def build_local_validation_action_line(record: LocalValidationFreshnessRecord) -> str | None:
    if record.promotability_status == "promotable" and record.freshness_state == "fresh":
        return None
    return (
        f"local-validation: repair {record.artifact_family} "
        f"(freshness={record.freshness_state}, promotability={record.promotability_status}, "
        f"reasons={','.join(record.reasons) if record.reasons else 'none'})"
    )


def build_local_validation_snapshot(records: list[LocalValidationFreshnessRecord]) -> tuple[str, str]:
    if not records:
        return "missing", "total=0 promotable=0 blocked=0 stale=0"

    promotable_count = 0
    stale_count = 0
    for record in records:
        if record.promotability_status == "promotable":
            promotable_count += 1
        if record.freshness_state != "fresh":
            stale_count += 1

    blocked_count = len(records) - promotable_count
    snapshot_status = "fresh" if blocked_count == 0 and stale_count == 0 else "present"
    snapshot_summary = (
        f"total={len(records)} promotable={promotable_count} "
        f"blocked={blocked_count} stale={stale_count}"
    )
    return snapshot_status, snapshot_summary


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
    validation_root: Path,
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
    local_validation_records = discover_local_validation_freshness_records(validation_root=validation_root)
    local_validation_snapshot_status, local_validation_snapshot_summary = build_local_validation_snapshot(
        local_validation_records
    )
    local_validation_summary_lines = [build_local_validation_summary_line(record) for record in local_validation_records]
    local_validation_action_lines = [
        action
        for action in (build_local_validation_action_line(record) for record in local_validation_records)
        if action is not None
    ]
    headline = f"Operator handoff report: {triage_report.headline.removeprefix('Federated CI triage report: ')}"
    immediate_action_lines: list[str] = []
    if triage_report.local_operator_next_step is not None:
        immediate_action_lines.append(f"local-runtime: {triage_report.local_operator_next_step}")
    if local_validation_action_lines:
        immediate_action_lines.append(local_validation_action_lines[0])
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
    markdown_lines.extend(
        [
            "",
            "### Local Validation",
            f"- snapshot status: `{local_validation_snapshot_status}`",
            f"- snapshot summary: `{local_validation_snapshot_summary}`",
            *[f"- {line}" for line in local_validation_summary_lines],
        ]
    )
    if local_validation_action_lines:
        markdown_lines.extend(["", "### Local Validation Actions", *[f"{index}. {line}" for index, line in enumerate(local_validation_action_lines, start=1)]])
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
        local_validation_snapshot_status=local_validation_snapshot_status,
        local_validation_snapshot_summary=local_validation_snapshot_summary,
        local_validation_records=local_validation_records,
        local_validation_summary_lines=local_validation_summary_lines,
        local_validation_action_lines=local_validation_action_lines,
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
    sections.append(f"local_validation_snapshot_status\t{record.local_validation_snapshot_status}")
    sections.append(f"local_validation_snapshot_summary\t{record.local_validation_snapshot_summary}")
    sections.extend(["local_validation", *record.local_validation_summary_lines])
    if record.local_validation_action_lines:
        sections.extend(["local_validation_actions", *record.local_validation_action_lines])
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

    local_validation_parser = subparsers.add_parser(
        "local-validation-freshness",
        help="show freshness and promotability for promoted monday local validation artifacts",
    )
    local_validation_parser.add_argument("--artifact-family", choices=LOCAL_VALIDATION_FAMILY_CHOICES, default=None)
    local_validation_parser.add_argument("--freshness-state", choices=LOCAL_VALIDATION_FRESHNESS_CHOICES, default=None)
    local_validation_parser.add_argument(
        "--promotability-status",
        choices=LOCAL_VALIDATION_PROMOTABILITY_CHOICES,
        default=None,
    )
    local_validation_parser.add_argument("--has-reason", default=None)
    local_validation_parser.add_argument("--limit", type=int, default=20)
    local_validation_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    local_validation_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))

    local_inbox_payload_parser = subparsers.add_parser(
        "local-inbox-payload",
        help="list promoted monday local inbox payload bridge artifacts",
    )
    local_inbox_payload_parser.add_argument("--bridge-id-prefix", default=None)
    local_inbox_payload_parser.add_argument(
        "--source-kind",
        choices=LOCAL_INBOX_PAYLOAD_SOURCE_CHOICES,
        default="latest",
    )
    local_inbox_payload_parser.add_argument("--status", choices=LOCAL_INBOX_PAYLOAD_STATUS_CHOICES, default=None)
    local_inbox_payload_parser.add_argument("--message-class-hint", default=None)
    local_inbox_payload_parser.add_argument("--needs-human-attention", choices=["yes", "no"], default=None)
    local_inbox_payload_parser.add_argument("--launch-mode", default=None)
    local_inbox_payload_parser.add_argument("--local-model-route", default=None)
    local_inbox_payload_parser.add_argument("--local-validation-snapshot-status", default=None)
    local_inbox_payload_parser.add_argument("--has-dependency-state", choices=["current", "stale", "missing"], default=None)
    local_inbox_payload_parser.add_argument("--limit", type=int, default=20)
    local_inbox_payload_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    local_inbox_payload_parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))

    monday_consumer_parser = subparsers.add_parser(
        "monday-consumer-report",
        help="list monday-owned planningops local inbox consumer reports",
    )
    monday_consumer_parser.add_argument("--run-id-prefix", default=None)
    monday_consumer_parser.add_argument("--mode", choices=MONDAY_CONSUMER_MODE_CHOICES, default=None)
    monday_consumer_parser.add_argument("--verdict", choices=MONDAY_CONSUMER_VERDICT_CHOICES, default=None)
    monday_consumer_parser.add_argument("--reason-code", default=None)
    monday_consumer_parser.add_argument("--consumer-status", choices=MONDAY_CONSUMER_STATUS_CHOICES, default=None)
    monday_consumer_parser.add_argument("--can-launch", choices=["yes", "no"], default=None)
    monday_consumer_parser.add_argument("--planner-profile", default=None)
    monday_consumer_parser.add_argument("--launch-mode", default=None)
    monday_consumer_parser.add_argument("--local-model-route", default=None)
    monday_consumer_parser.add_argument("--has-runtime-overrides", choices=["yes", "no"], default=None)
    monday_consumer_parser.add_argument("--override-kind", choices=["planner_runtime_config", "runtime_profile_file"], default=None)
    monday_consumer_parser.add_argument("--has-runtime-report", choices=["yes", "no"], default=None)
    monday_consumer_parser.add_argument("--execution-attempted", choices=["yes", "no"], default=None)
    monday_consumer_parser.add_argument("--limit", type=int, default=20)
    monday_consumer_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    monday_consumer_parser.add_argument("--consumer-root", default=str(DEFAULT_MONDAY_CONSUMER_ROOT))

    monday_validation_parser = subparsers.add_parser(
        "monday-validation-report",
        help="list monday-owned inbox schema validation reports",
    )
    monday_validation_parser.add_argument("--kind", choices=MONDAY_VALIDATION_KIND_CHOICES, default=None)
    monday_validation_parser.add_argument("--verdict", choices=MONDAY_VALIDATION_VERDICT_CHOICES, default=None)
    monday_validation_parser.add_argument("--has-errors", choices=["yes", "no"], default=None)
    monday_validation_parser.add_argument("--has-warnings", choices=["yes", "no"], default=None)
    monday_validation_parser.add_argument("--artifact-exists", choices=["yes", "no"], default=None)
    monday_validation_parser.add_argument("--schema-exists", choices=["yes", "no"], default=None)
    monday_validation_parser.add_argument("--has-message", default=None)
    monday_validation_parser.add_argument("--limit", type=int, default=20)
    monday_validation_parser.add_argument("--format", choices=["table", "json", "markdown"], default="table")
    monday_validation_parser.add_argument("--monday-validation-root", default=str(DEFAULT_MONDAY_VALIDATION_ROOT))

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
    validation_root = resolve_root(getattr(args, "validation_root", str(DEFAULT_VALIDATION_ROOT)), DEFAULT_VALIDATION_ROOT)
    consumer_root = resolve_root(getattr(args, "consumer_root", str(DEFAULT_MONDAY_CONSUMER_ROOT)), DEFAULT_MONDAY_CONSUMER_ROOT)
    monday_validation_root = resolve_root(
        getattr(args, "monday_validation_root", str(DEFAULT_MONDAY_VALIDATION_ROOT)),
        DEFAULT_MONDAY_VALIDATION_ROOT,
    )
    if args.command == "local-validation-freshness":
        local_validation_records = discover_local_validation_freshness_records(validation_root=validation_root)
        local_validation_records = filter_local_validation_freshness_records(
            records=local_validation_records,
            artifact_family=args.artifact_family,
            freshness_state=args.freshness_state,
            promotability_status=args.promotability_status,
            has_reason=args.has_reason,
        )
        local_validation_records = local_validation_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in local_validation_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_local_validation_freshness_markdown(local_validation_records))
            return 0
        print(render_local_validation_freshness_table(local_validation_records))
        return 0

    if args.command == "local-inbox-payload":
        inbox_payload_records = discover_local_inbox_payload_records(validation_root=validation_root)
        inbox_payload_records = filter_local_inbox_payload_records(
            records=inbox_payload_records,
            bridge_id_prefix=args.bridge_id_prefix,
            source_kind=args.source_kind,
            status=args.status,
            message_class_hint=args.message_class_hint,
            needs_human_attention=args.needs_human_attention,
            launch_mode=args.launch_mode,
            local_model_route=args.local_model_route,
            local_validation_snapshot_status=args.local_validation_snapshot_status,
            has_dependency_state=args.has_dependency_state,
        )
        inbox_payload_records = inbox_payload_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in inbox_payload_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_local_inbox_payload_markdown(inbox_payload_records))
            return 0
        print(render_local_inbox_payload_table(inbox_payload_records))
        return 0

    if args.command == "monday-consumer-report":
        consumer_records = discover_monday_consumer_report_records(consumer_root=consumer_root)
        consumer_records = filter_monday_consumer_report_records(
            records=consumer_records,
            run_id_prefix=args.run_id_prefix,
            mode=args.mode,
            verdict=args.verdict,
            reason_code=args.reason_code,
            consumer_status=args.consumer_status,
            can_launch=args.can_launch,
            planner_profile=args.planner_profile,
            launch_mode=args.launch_mode,
            local_model_route=args.local_model_route,
            has_runtime_input_overrides=args.has_runtime_overrides,
            override_kind=args.override_kind,
            has_runtime_report=args.has_runtime_report,
            execution_attempted=args.execution_attempted,
        )
        consumer_records = consumer_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in consumer_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_monday_consumer_report_markdown(consumer_records))
            return 0
        print(render_monday_consumer_report_table(consumer_records))
        return 0

    if args.command == "monday-validation-report":
        validation_records = discover_monday_validation_report_records(validation_root=monday_validation_root)
        validation_records = filter_monday_validation_report_records(
            records=validation_records,
            kind=args.kind,
            verdict=args.verdict,
            has_errors=args.has_errors,
            has_warnings=args.has_warnings,
            artifact_exists=args.artifact_exists,
            schema_exists=args.schema_exists,
            has_message=args.has_message,
        )
        validation_records = validation_records[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in validation_records]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_monday_validation_report_markdown(validation_records))
            return 0
        print(render_monday_validation_report_table(validation_records))
        return 0

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
            validation_root=validation_root,
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
            validation_root=validation_root,
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
