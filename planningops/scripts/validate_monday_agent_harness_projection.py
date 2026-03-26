#!/usr/bin/env python3

from __future__ import annotations

import argparse
from datetime import datetime, timezone
from pathlib import Path

from validate_supervisor_operator_handoff import append_unique, load_json, validate_schema, write_json


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_MONDAY_ROOT = WORKSPACE_ROOT.parent / "monday"
DEFAULT_PROJECTION_ROOT = DEFAULT_MONDAY_ROOT / "runtime-artifacts/agent-harness"
DEFAULT_BUNDLE_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/monday-agent-harness-projection-bundle.schema.json"
DEFAULT_VALIDATION_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/monday-agent-harness-projection-validation.schema.json"
DEFAULT_BUNDLE_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-bundle.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/monday-agent-harness-projection-validation.json"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_cli_path(value: str | None, *, base: Path) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = (base / path).resolve()
    else:
        path = path.resolve()
    return path


def resolve_foreign_path(value: str | None, *, monday_root: Path) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = (monday_root / path).resolve()
    else:
        path = path.resolve()
    return path


def safe_load_json(path: Path, label: str, errors: list[str]) -> dict:
    if not path.exists():
        append_unique(errors, f"{label} file is missing: {path}")
        return {}
    try:
        doc = load_json(path)
    except Exception as exc:  # pragma: no cover - fail-closed guard
        append_unique(errors, f"{label} is not valid JSON: {exc}")
        return {}
    if not isinstance(doc, dict):
        append_unique(errors, f"{label} must be a JSON object")
        return {}
    return doc


def build_input_paths(args) -> dict[str, Path]:
    projection_root = resolve_cli_path(args.projection_root, base=WORKSPACE_ROOT)
    assert projection_root is not None
    return {
        "projection_root": projection_root,
        "monday_root": resolve_cli_path(args.monday_root, base=WORKSPACE_ROOT) or DEFAULT_MONDAY_ROOT,
        "completion_summary_path": resolve_cli_path(args.completion_summary, base=WORKSPACE_ROOT)
        or (projection_root / "completion-summary.json").resolve(),
        "readiness_projection_path": resolve_cli_path(args.readiness_projection, base=WORKSPACE_ROOT)
        or (projection_root / "readiness-projection.json").resolve(),
        "verification_projection_path": resolve_cli_path(args.verification_projection, base=WORKSPACE_ROOT)
        or (projection_root / "verification-projection.json").resolve(),
        "operator_handoff_summary_path": resolve_cli_path(args.operator_handoff_summary, base=WORKSPACE_ROOT)
        or (projection_root / "operator-handoff-summary.json").resolve(),
    }


def build_bundle_doc(paths: dict[str, Path]) -> tuple[dict, list[str]]:
    load_errors: list[str] = []
    projection_root = paths["projection_root"]
    if not projection_root.exists():
        append_unique(load_errors, f"projection root is missing: {projection_root}")

    bundle_doc = {
        "generated_at_utc": now_utc(),
        "projection_root": str(projection_root.resolve()),
        "monday_root": str(paths["monday_root"].resolve()),
        "completion_summary_path": str(paths["completion_summary_path"].resolve()),
        "readiness_projection_path": str(paths["readiness_projection_path"].resolve()),
        "verification_projection_path": str(paths["verification_projection_path"].resolve()),
        "operator_handoff_summary_path": str(paths["operator_handoff_summary_path"].resolve()),
        "completion_summary": safe_load_json(paths["completion_summary_path"], "completion_summary", load_errors),
        "readiness_projection": safe_load_json(paths["readiness_projection_path"], "readiness_projection", load_errors),
        "verification_projection": safe_load_json(paths["verification_projection_path"], "verification_projection", load_errors),
        "operator_handoff_summary": safe_load_json(paths["operator_handoff_summary_path"], "operator_handoff_summary", load_errors),
    }
    return bundle_doc, load_errors


def load_bundle_file(bundle_path: Path) -> tuple[dict, list[str]]:
    errors: list[str] = []
    if not bundle_path.exists():
        append_unique(errors, f"bundle file is missing: {bundle_path}")
        return {}, errors
    try:
        bundle_doc = load_json(bundle_path)
    except Exception as exc:  # pragma: no cover - fail-closed guard
        append_unique(errors, f"bundle file is not valid JSON: {exc}")
        return {}, errors
    if not isinstance(bundle_doc, dict):
        append_unique(errors, "bundle file must be a JSON object")
        return {}, errors
    return bundle_doc, errors


def resolve_bundle_context(args) -> tuple[dict, Path, Path, list[str]]:
    monday_root = resolve_cli_path(args.monday_root, base=WORKSPACE_ROOT) or DEFAULT_MONDAY_ROOT
    projection_root = resolve_cli_path(args.projection_root, base=WORKSPACE_ROOT) or DEFAULT_PROJECTION_ROOT
    bundle_file = resolve_cli_path(args.bundle_file, base=WORKSPACE_ROOT)
    if bundle_file is not None:
        bundle_doc, load_errors = load_bundle_file(bundle_file)
        bundle_projection_root = resolve_cli_path(bundle_doc.get("projection_root"), base=WORKSPACE_ROOT)
        bundle_monday_root = resolve_cli_path(bundle_doc.get("monday_root"), base=WORKSPACE_ROOT)
        return (
            bundle_doc,
            bundle_projection_root or projection_root,
            bundle_monday_root or monday_root,
            load_errors,
        )

    paths = build_input_paths(args)
    bundle_doc, load_errors = build_bundle_doc(paths)
    return bundle_doc, paths["projection_root"], paths["monday_root"], load_errors


def _validate_iso8601(value: str, field: str, errors: list[str]) -> None:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        append_unique(errors, f"{field} must be an ISO-8601 timestamp")


def _require_equal(errors: list[str], docs: list[tuple[str, dict]], field: str) -> str | None:
    values: list[str] = []
    for _label, doc in docs:
        value = doc.get(field)
        if isinstance(value, str) and value.strip():
            values.append(value.strip())
    unique_values = list(dict.fromkeys(values))
    if len(unique_values) > 1:
        append_unique(errors, f"{field} must match across all monday projection surfaces")
    return unique_values[0] if unique_values else None


def _path_like_ref(value: str) -> bool:
    return "/" in value or value.endswith(".json") or value.startswith(".")


def _normalized_path_refs(values: list[str], *, monday_root: Path) -> set[str]:
    resolved: set[str] = set()
    for value in values:
        if _path_like_ref(value):
            path = resolve_foreign_path(value, monday_root=monday_root)
            if path is not None:
                resolved.add(str(path))
    return resolved


def validate_semantics(bundle_doc: dict, *, monday_root: Path) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    completion_summary = bundle_doc.get("completion_summary") or {}
    readiness_projection = bundle_doc.get("readiness_projection") or {}
    verification_projection = bundle_doc.get("verification_projection") or {}
    operator_handoff_summary = bundle_doc.get("operator_handoff_summary") or {}

    docs = [
        ("completion_summary", completion_summary),
        ("readiness_projection", readiness_projection),
        ("verification_projection", verification_projection),
        ("operator_handoff_summary", operator_handoff_summary),
    ]

    for label, doc, field in (
        ("completion_summary", completion_summary, "completedAtUtc"),
        ("readiness_projection", readiness_projection, "generatedAtUtc"),
        ("verification_projection", verification_projection, "generatedAtUtc"),
        ("operator_handoff_summary", operator_handoff_summary, "generatedAtUtc"),
    ):
        value = doc.get(field)
        if isinstance(value, str):
            _validate_iso8601(value, f"{label}.{field}", errors)

    mission_id = _require_equal(errors, docs, "missionId")
    run_id = _require_equal(errors, docs, "runId")
    session_id = _require_equal(errors, docs, "sessionId")
    evidence_bundle_path = _require_equal(errors, docs, "evidenceBundlePath")
    final_status = completion_summary.get("finalStatus")
    readiness_status = readiness_projection.get("readinessStatus")
    verification_verdict = verification_projection.get("verificationVerdict")
    handoff_status = operator_handoff_summary.get("handoffStatus")

    if evidence_bundle_path:
        evidence_bundle = resolve_foreign_path(evidence_bundle_path, monday_root=monday_root)
        if evidence_bundle is None or not evidence_bundle.exists():
            append_unique(errors, "evidenceBundlePath must point to an existing monday sealed evidence artifact")
        elif evidence_bundle.name != "execution-evidence-bundle.json":
            append_unique(errors, "evidenceBundlePath must resolve to execution-evidence-bundle.json")

        required_evidence_refs = readiness_projection.get("requiredEvidenceRefs")
        if isinstance(required_evidence_refs, list):
            normalized = _normalized_path_refs(
                [value for value in required_evidence_refs if isinstance(value, str)],
                monday_root=monday_root,
            )
            if str(evidence_bundle) not in normalized:
                append_unique(errors, "readiness_projection.requiredEvidenceRefs must include evidenceBundlePath")

        verification_report_refs = verification_projection.get("verificationReportRefs")
        if isinstance(verification_report_refs, list):
            normalized = _normalized_path_refs(
                [value for value in verification_report_refs if isinstance(value, str)],
                monday_root=monday_root,
            )
            if str(evidence_bundle) not in normalized:
                append_unique(errors, "verification_projection.verificationReportRefs must include evidenceBundlePath")

    if completion_summary.get("verificationVerdict") != verification_verdict:
        append_unique(errors, "completion_summary.verificationVerdict must match verification_projection.verificationVerdict")
    if readiness_projection.get("verificationVerdict") != verification_verdict:
        append_unique(errors, "readiness_projection.verificationVerdict must match verification_projection.verificationVerdict")
    if operator_handoff_summary.get("verificationVerdict") != verification_verdict:
        append_unique(errors, "operator_handoff_summary.verificationVerdict must match verification_projection.verificationVerdict")

    blocking_conditions = readiness_projection.get("blockingConditions") or []
    if not isinstance(blocking_conditions, list):
        blocking_conditions = []
    failed_checks = verification_projection.get("failedChecks") or []
    if not isinstance(failed_checks, list):
        failed_checks = []
    blocking_question_set = operator_handoff_summary.get("blockingQuestionSet") or []
    if not isinstance(blocking_question_set, list):
        blocking_question_set = []

    if final_status == "succeeded":
        if verification_verdict != "pass":
            append_unique(errors, "completion_summary.finalStatus=succeeded requires verification_verdict=pass")
        if handoff_status != "not_required":
            append_unique(errors, "completion_summary.finalStatus=succeeded requires handoffStatus=not_required")
    elif final_status == "blocked":
        if verification_verdict != "blocked_fail":
            append_unique(errors, "completion_summary.finalStatus=blocked requires verification_verdict=blocked_fail")
        if handoff_status != "required":
            append_unique(errors, "completion_summary.finalStatus=blocked requires handoffStatus=required")

    if readiness_status == "ready":
        if final_status != "succeeded":
            append_unique(errors, "readinessStatus=ready requires finalStatus=succeeded")
        if verification_verdict != "pass":
            append_unique(errors, "readinessStatus=ready requires verification_verdict=pass")
        if handoff_status != "not_required":
            append_unique(errors, "readinessStatus=ready requires handoffStatus=not_required")
        if blocking_conditions:
            append_unique(errors, "readinessStatus=ready requires no blockingConditions")
    elif readiness_status == "blocked":
        if final_status != "blocked":
            append_unique(errors, "readinessStatus=blocked requires finalStatus=blocked")
        if verification_verdict != "blocked_fail":
            append_unique(errors, "readinessStatus=blocked requires verification_verdict=blocked_fail")
        if handoff_status != "required":
            append_unique(errors, "readinessStatus=blocked requires handoffStatus=required")
        if not blocking_conditions:
            append_unique(errors, "readinessStatus=blocked requires at least one blocking condition")
    elif readiness_status == "not_ready":
        if final_status == "blocked":
            append_unique(errors, "readinessStatus=not_ready must not be published for blocked runs")
        if verification_verdict != "pass":
            append_unique(errors, "readinessStatus=not_ready requires verification_verdict=pass")
        if handoff_status != "not_required":
            append_unique(errors, "readinessStatus=not_ready requires handoffStatus=not_required")
        if not blocking_conditions:
            append_unique(errors, "readinessStatus=not_ready requires at least one blocking condition")

    if verification_verdict == "pass" and failed_checks:
        append_unique(errors, "verification_projection.verificationVerdict=pass requires failedChecks=[]")

    if handoff_status == "required":
        if operator_handoff_summary.get("nextRequiredActor") == "none":
            append_unique(errors, "handoffStatus=required requires nextRequiredActor!=none")
        if operator_handoff_summary.get("recommendedNextStep") in (None, "", "none"):
            append_unique(errors, "handoffStatus=required requires a non-empty recommendedNextStep")
    elif handoff_status == "not_required":
        if operator_handoff_summary.get("nextRequiredActor") != "none":
            append_unique(errors, "handoffStatus=not_required requires nextRequiredActor=none")
        if operator_handoff_summary.get("recommendedNextStep") != "none":
            append_unique(errors, "handoffStatus=not_required requires recommendedNextStep=none")

    if operator_handoff_summary.get("handoffReason") == "missing_question_set" and not blocking_question_set:
        append_unique(errors, "handoffReason=missing_question_set requires a non-empty blockingQuestionSet")

    if mission_id is None:
        append_unique(errors, "missionId must be present across monday projection surfaces")
    if run_id is None:
        append_unique(errors, "runId must be present across monday projection surfaces")
    if session_id is None:
        append_unique(errors, "sessionId must be present across monday projection surfaces")

    return errors, warnings


def derive_next_step(report: dict, *, projection_root: Path) -> str:
    if report["verdict"] == "fail":
        return (
            "python3 planningops/scripts/validate_monday_agent_harness_projection.py "
            f"--projection-root {projection_root} --output <monday-agent-harness-projection-validation.json> --strict"
        )
    if report["ready"] is True:
        return "none"
    if report.get("readiness_status") == "blocked":
        return str(report.get("recommended_next_step") or "inspect monday blocked handoff and unblock the run")
    if report.get("readiness_status") == "not_ready":
        return "publish monday output artifacts and rerun projection validation"
    return "inspect monday projection publication and rerun validation"


def build_validation_report(
    bundle_doc: dict,
    *,
    projection_root: Path,
    monday_root: Path,
    bundle_schema_path: Path,
    validation_schema_path: Path,
    load_errors: list[str],
) -> dict:
    bundle_schema_doc = load_json(bundle_schema_path)
    validation_schema_doc = load_json(validation_schema_path)

    errors = list(load_errors)
    errors.extend(validate_schema(bundle_doc, bundle_schema_doc))
    semantic_errors, warnings = validate_semantics(bundle_doc, monday_root=monday_root)
    errors.extend(semantic_errors)

    completion_summary = bundle_doc.get("completion_summary") or {}
    readiness_projection = bundle_doc.get("readiness_projection") or {}
    verification_projection = bundle_doc.get("verification_projection") or {}
    operator_handoff_summary = bundle_doc.get("operator_handoff_summary") or {}

    evidence_bundle_path = completion_summary.get("evidenceBundlePath")
    evidence_bundle = resolve_foreign_path(evidence_bundle_path, monday_root=monday_root)
    report = {
        "generated_at_utc": now_utc(),
        "bundle_path": bundle_doc.get("bundle_path"),
        "projection_root": str(projection_root.resolve()),
        "monday_root": str(monday_root.resolve()),
        "completion_summary_path": bundle_doc.get("completion_summary_path"),
        "readiness_projection_path": bundle_doc.get("readiness_projection_path"),
        "verification_projection_path": bundle_doc.get("verification_projection_path"),
        "operator_handoff_summary_path": bundle_doc.get("operator_handoff_summary_path"),
        "schema_path": str(bundle_schema_path.resolve()),
        "validation_schema_path": str(validation_schema_path.resolve()),
        "mission_id": completion_summary.get("missionId"),
        "run_id": completion_summary.get("runId"),
        "session_id": completion_summary.get("sessionId"),
        "evidence_bundle_path": evidence_bundle_path,
        "evidence_bundle_exists": bool(evidence_bundle and evidence_bundle.exists()),
        "final_status": completion_summary.get("finalStatus"),
        "readiness_status": readiness_projection.get("readinessStatus"),
        "ready": False,
        "verification_verdict": verification_projection.get("verificationVerdict"),
        "handoff_status": operator_handoff_summary.get("handoffStatus"),
        "next_required_actor": operator_handoff_summary.get("nextRequiredActor"),
        "recommended_next_step": operator_handoff_summary.get("recommendedNextStep"),
        "blocking_conditions": list(readiness_projection.get("blockingConditions") or []),
        "failed_checks": list(verification_projection.get("failedChecks") or []),
        "repair_attempts": int(verification_projection.get("repairAttempts") or 0),
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }
    report["ready"] = report["verdict"] == "pass" and report.get("readiness_status") == "ready"
    report["next_step"] = derive_next_step(report, projection_root=projection_root)

    report_schema_errors = validate_schema(report, validation_schema_doc)
    if report_schema_errors:
        report["errors"] = report["errors"] + [f"validation report schema: {message}" for message in report_schema_errors]
        report["error_count"] = len(report["errors"])
        report["verdict"] = "fail"
        report["ready"] = False
        report["next_step"] = derive_next_step(report, projection_root=projection_root)
    return report


def parse_args():
    parser = argparse.ArgumentParser(description="Validate monday agent harness projection surfaces from planningops")
    parser.add_argument("--monday-root", default=str(DEFAULT_MONDAY_ROOT))
    parser.add_argument("--projection-root", default=str(DEFAULT_PROJECTION_ROOT))
    parser.add_argument("--bundle-file", default=None)
    parser.add_argument("--completion-summary", default=None)
    parser.add_argument("--readiness-projection", default=None)
    parser.add_argument("--verification-projection", default=None)
    parser.add_argument("--operator-handoff-summary", default=None)
    parser.add_argument("--schema-file", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--validation-schema-file", default=str(DEFAULT_VALIDATION_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    bundle_doc, projection_root, monday_root, load_errors = resolve_bundle_context(args)
    report = build_validation_report(
        bundle_doc,
        projection_root=projection_root,
        monday_root=monday_root,
        bundle_schema_path=Path(args.schema_file).resolve(),
        validation_schema_path=Path(args.validation_schema_file).resolve(),
        load_errors=load_errors,
    )
    output_path = Path(args.output).resolve()
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"verdict={report['verdict']} ready={report['ready']} error_count={report['error_count']}")
    return 0 if report["verdict"] == "pass" or not args.strict else 1


if __name__ == "__main__":
    raise SystemExit(main())
