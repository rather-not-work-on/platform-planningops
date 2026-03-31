#!/usr/bin/env python3

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
import json
from pathlib import Path
import sys
from typing import Any

from federated_ci_runtime_state import infer_family_from_run_id, is_summary_document, load_json, summary_timestamp


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
    has_summary_validation: bool
    has_readiness: bool
    has_readiness_validation: bool
    has_reconcile_report: bool
    has_reconcile_validation: bool
    has_conformance_contract: bool


def resolve_root(path_text: str, default: Path) -> Path:
    candidate = Path(path_text)
    if not candidate.is_absolute():
        candidate = (WORKSPACE_ROOT / candidate).resolve()
    return candidate if path_text else default


def source_kind_for_summary_path(path: Path) -> str:
    return "latest" if path.name == "federated-ci-summary.json" else "stamped"


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
    failures = [
        str(check.get("domain"))
        for check in list(summary_doc.get("checks") or [])
        if check.get("verdict") == "fail" and isinstance(check.get("domain"), str)
    ]
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
        "family\trun_id\tsource\tverdict\tstatus\tchecks\ttimestamp",
    ]
    for record in records:
        lines.append(
            "\t".join(
                [
                    record.family,
                    record.run_id,
                    record.source_kind,
                    str(record.verdict or ""),
                    str(record.overall_status or ""),
                    str(record.check_count if record.check_count is not None else ""),
                    record.timestamp_utc,
                ]
            )
        )
    return "\n".join(lines)


def render_runs_markdown(records: list[SummaryRecord]) -> str:
    lines = [
        "| family | run_id | source | verdict | status | checks | timestamp |",
        "| --- | --- | --- | --- | --- | ---: | --- |",
    ]
    for record in records:
        lines.append(
            f"| {record.family} | `{record.run_id}` | {record.source_kind} | "
            f"{record.verdict or ''} | {record.overall_status or ''} | "
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Query federated CI summary artifacts from planningops artifact roots")
    subparsers = parser.add_subparsers(dest="command", required=True)

    runs_parser = subparsers.add_parser("runs", help="list indexed federated CI summaries")
    runs_parser.add_argument("--family", default=None)
    runs_parser.add_argument("--run-id-prefix", default=None)
    runs_parser.add_argument("--verdict", choices=["pass", "fail"], default=None)
    runs_parser.add_argument("--status", choices=["complete", "interrupted"], default=None)
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
        if args.verdict:
            filtered = [record for record in filtered if record.verdict == args.verdict]
        if args.status:
            filtered = [record for record in filtered if record.overall_status == args.status]
        filtered = filtered[: args.limit]
        if args.format == "json":
            print(json.dumps({"records": [asdict(record) for record in filtered]}, ensure_ascii=True, indent=2))
            return 0
        if args.format == "markdown":
            print(render_runs_markdown(filtered))
            return 0
        print(render_runs_table(filtered))
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
