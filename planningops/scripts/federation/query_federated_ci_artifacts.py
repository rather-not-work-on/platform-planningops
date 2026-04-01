#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
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


@dataclass(frozen=True)
class SummaryRecord:
    run_id: str
    family: str
    source_kind: str
    summary_path: str
    timestamp_utc: str
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


def build_summary_record(
    *,
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
    return SummaryRecord(
        run_id=run_id,
        family=infer_family_from_run_id(run_id),
        source_kind=source_kind,
        summary_path=str(summary_path.resolve()),
        timestamp_utc=summary_timestamp(summary_doc),
        verdict=summary_doc.get("verdict"),
        overall_status=summary_doc.get("overall_status"),
        check_count=summary_doc.get("check_count"),
        shell_exit_code=summary_doc.get("shell_exit_code"),
        missing_required_checks=[str(name) for name in list(summary_doc.get("missing_required_checks") or [])],
        failure_domains=sorted(set(failures)),
        failed_checks=failed_checks,
        readiness_status=(
            str(raw_readiness_status)
            if isinstance(raw_readiness_status, str) and raw_readiness_status.strip()
            else ("unknown" if sidecars["readiness"].exists() else "missing")
        ),
        ready=raw_ready if isinstance(raw_ready, bool) else None,
        blocking_reasons=(
            [str(reason) for reason in list(readiness_doc.get("blocking_reasons") or [])]
            if isinstance(readiness_doc, dict)
            else []
        ),
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


def render_runs_table(records: list[SummaryRecord]) -> str:
    lines = [
        "family\trun_id\tsource\tverdict\treadiness\tfailed_checks\tstatus\tchecks\ttimestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.family,
                    record.run_id,
                    record.source_kind,
                    str(record.verdict or ""),
                    record.readiness_status,
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
        "| family | run_id | source | verdict | readiness | failed_checks | status | checks | timestamp |",
        "| --- | --- | --- | --- | --- | --- | --- | ---: | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | `{record.run_id}` | {record.source_kind} | "
            f"{record.verdict or ''} | {record.readiness_status} | "
            f"{', '.join(record.failed_checks)} | {record.overall_status or ''} | "
            f"{record.check_count if record.check_count is not None else ''} | {record.timestamp_utc} |"
        )
    return "\n".join(lines)


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
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ci_root = resolve_root(args.ci_root, DEFAULT_CI_ROOT)
    validation_root = resolve_root(args.validation_root, DEFAULT_VALIDATION_ROOT)
    conformance_root = resolve_root(args.conformance_root, DEFAULT_CONFORMANCE_ROOT)
    records = discover_summary_records(
        ci_root=ci_root,
        validation_root=validation_root,
        conformance_root=conformance_root,
    )

    if args.command == "runs":
        filtered = records
        if args.family:
            filtered = [record for record in filtered if record.family == args.family]
        if args.run_id_prefix:
            filtered = [record for record in filtered if record.run_id.startswith(args.run_id_prefix)]
        if args.source_kind != "all":
            filtered = [record for record in filtered if record.source_kind == args.source_kind]
        if args.verdict:
            filtered = [record for record in filtered if record.verdict == args.verdict]
        if args.status:
            filtered = [record for record in filtered if record.overall_status == args.status]
        if args.readiness_status:
            filtered = [record for record in filtered if record.readiness_status == args.readiness_status]
        if args.failed_check:
            filtered = [record for record in filtered if args.failed_check in record.failed_checks]
        filtered = filtered[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in filtered]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_runs_markdown(filtered))
            return 0
        print(render_runs_table(filtered))
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
