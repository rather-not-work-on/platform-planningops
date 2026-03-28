#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

from resolve_supervisor_operator_handoff_bundle import (
    MONDAY_ROOT,
    WORKSPACE_ROOT,
    resolve_handoff_bundle,
)
from validate_supervisor_operator_handoff import load_json, validate_schema, write_json


DEFAULT_BUNDLE_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-bundle.schema.json"
DEFAULT_REPORT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-bundle-validation.schema.json"
DEFAULT_OUTPUT = WORKSPACE_ROOT / "planningops/artifacts/validation/supervisor-operator-handoff-bundle-validation.json"
HANDOFF_VALIDATION_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-validation.schema.json"
PREVIEW_SCHEMA = MONDAY_ROOT / "contracts/runtime-operator-priority-preview.schema.json"
DISPLAY_PACKET_SCHEMA = MONDAY_ROOT / "contracts/runtime-operator-priority-display-packet.schema.json"
HANDOFF_BUNDLE_SIDECAR_FIELDS = (
    "operator_handoff_bundle_path",
    "operator_handoff_bundle_validation_path",
    "operator_handoff_bundle_readiness_path",
    "operator_handoff_bundle_readiness_validation_path",
)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_args():
    parser = argparse.ArgumentParser(description="Validate a canonical supervisor operator handoff bundle")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--bundle-file")
    group.add_argument("--artifact-file")
    parser.add_argument("--bundle-schema", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--validation-schema", default=str(DEFAULT_REPORT_SCHEMA))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args()


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def resolve_path(value: str | None, *, base: Path = WORKSPACE_ROOT) -> Path | None:
    text = str(value or "").strip()
    if not text:
        return None
    path = Path(text)
    if not path.is_absolute():
        path = (base / path).resolve()
    else:
        path = path.resolve()
    return path


def normalize_path_text(value: object, *, base: Path) -> str | None:
    text = str(value or "").strip()
    if not text or text == "-":
        return None
    resolved = resolve_path(text, base=base)
    return str(resolved) if resolved is not None else None


def prefixed_errors(prefix: str, errors: list[str]) -> list[str]:
    return [f"{prefix}: {error}" for error in errors]


def validate_nested_schema(doc: object, schema_path: Path, label: str, errors: list[str]) -> None:
    if not isinstance(doc, dict):
        append_unique(errors, f"{label} must be an object")
        return
    schema_doc = load_json(schema_path)
    for error in validate_schema(doc, schema_doc):
        append_unique(errors, f"{label}: {error}")


def normalize_preview_doc(doc: dict) -> dict:
    normalized = dict(doc)
    base = MONDAY_ROOT
    normalized["operator_handoff_validation_path"] = normalize_path_text(
        normalized.get("operator_handoff_validation_path"),
        base=base,
    )
    if not normalized["operator_handoff_validation_path"]:
        normalized.pop("operator_handoff_validation_path", None)
    for field in HANDOFF_BUNDLE_SIDECAR_FIELDS:
        normalized[field] = normalize_path_text(normalized.get(field), base=base)
        if not normalized[field]:
            normalized.pop(field, None)
    return normalized


def normalize_display_packet_doc(doc: dict) -> dict:
    normalized = dict(doc)
    base = MONDAY_ROOT
    normalized["operator_handoff_validation_path"] = normalize_path_text(
        normalized.get("operator_handoff_validation_path"),
        base=base,
    )
    if not normalized["operator_handoff_validation_path"]:
        normalized.pop("operator_handoff_validation_path", None)
    for field in HANDOFF_BUNDLE_SIDECAR_FIELDS:
        normalized[field] = normalize_path_text(normalized.get(field), base=base)
        if not normalized[field]:
            normalized.pop(field, None)
    return normalized


def compare_docs(label: str, actual: dict, expected: dict, errors: list[str]) -> None:
    if actual != expected:
        append_unique(errors, f"{label} does not match canonical bundle resolution")


def validate_bundle_semantics(bundle: dict, canonical_bundle: dict | None, errors: list[str]) -> None:
    artifact_path = resolve_path(str(bundle.get("artifact_file") or ""))
    validation_path = normalize_path_text(bundle.get("operator_handoff_validation_path"), base=WORKSPACE_ROOT)
    preview_ref = str(bundle.get("priority_preview_ref") or "").strip()
    display_packet_ref = str(bundle.get("priority_display_packet_ref") or "").strip()
    preview_doc = bundle.get("priority_preview")
    display_packet_doc = bundle.get("priority_display_packet")
    validation_doc = bundle.get("operator_handoff_validation")
    normalized_bundle_sidecars = {
        field: normalize_path_text(bundle.get(field), base=WORKSPACE_ROOT)
        for field in HANDOFF_BUNDLE_SIDECAR_FIELDS
    }

    if not artifact_path or not artifact_path.exists():
        append_unique(errors, "artifact_file must resolve to an existing file")
    if not validation_path:
        append_unique(errors, "operator_handoff_validation_path must be present")
    if not preview_ref:
        append_unique(errors, "priority_preview_ref must be present")
    if not display_packet_ref:
        append_unique(errors, "priority_display_packet_ref must be present")

    if isinstance(validation_doc, dict):
        if validation_doc.get("verdict") != "pass":
            append_unique(errors, "operator_handoff_validation.verdict must be pass")
    else:
        append_unique(errors, "operator_handoff_validation must be an object")

    if isinstance(preview_doc, dict):
        preview_validation_path = normalize_path_text(
            preview_doc.get("operator_handoff_validation_path"),
            base=MONDAY_ROOT,
        )
        if preview_validation_path and validation_path and preview_validation_path != validation_path:
            append_unique(errors, "priority_preview.operator_handoff_validation_path must match canonical validation path")
        for field, resolved in normalized_bundle_sidecars.items():
            if not resolved:
                append_unique(errors, f"{field} must be present")
                continue
            preview_value = normalize_path_text(preview_doc.get(field), base=MONDAY_ROOT)
            if preview_value != resolved:
                append_unique(errors, f"priority_preview.{field} must match canonical bundle sidecar path")
    else:
        append_unique(errors, "priority_preview must be an object")

    if isinstance(display_packet_doc, dict):
        display_validation_path = normalize_path_text(
            display_packet_doc.get("operator_handoff_validation_path"),
            base=MONDAY_ROOT,
        )
        if display_validation_path and validation_path and display_validation_path != validation_path:
            append_unique(
                errors,
                "priority_display_packet.operator_handoff_validation_path must match canonical validation path",
            )
        for field, resolved in normalized_bundle_sidecars.items():
            if not resolved:
                append_unique(errors, f"{field} must be present")
                continue
            display_value = normalize_path_text(display_packet_doc.get(field), base=MONDAY_ROOT)
            if display_value != resolved:
                append_unique(errors, f"priority_display_packet.{field} must match canonical bundle sidecar path")
        display_preview_ref = str(display_packet_doc.get("priority_preview_ref") or "").strip()
        if display_preview_ref and preview_ref and display_preview_ref != preview_ref:
            append_unique(errors, "priority_display_packet.priority_preview_ref must match canonical preview ref")
        preview_headline = str((preview_doc or {}).get("priority_headline") or "").strip()
        preview_cta = str((preview_doc or {}).get("priority_cta_command") or "").strip()
        preview_summary = str((preview_doc or {}).get("priority_summary_markdown") or "").strip()
        if preview_headline and str(display_packet_doc.get("display_title") or "").strip() != preview_headline:
            append_unique(errors, "priority_display_packet.display_title must match priority_preview.priority_headline")
        if preview_cta and str(display_packet_doc.get("cta_command") or "").strip() != preview_cta:
            append_unique(errors, "priority_display_packet.cta_command must match priority_preview.priority_cta_command")
        if preview_summary and str(display_packet_doc.get("display_markdown") or "").strip() != preview_summary:
            append_unique(
                errors,
                "priority_display_packet.display_markdown must match priority_preview.priority_summary_markdown",
            )
    else:
        append_unique(errors, "priority_display_packet must be an object")

    if canonical_bundle is not None:
        for field in (
            "artifact_file",
            "operator_handoff_validation_path",
            "priority_preview_ref",
            "priority_display_packet_ref",
        ):
            if bundle.get(field) != canonical_bundle.get(field):
                append_unique(errors, f"{field} does not match canonical bundle resolution")

        if isinstance(validation_doc, dict) and validation_doc != canonical_bundle.get("operator_handoff_validation"):
            append_unique(errors, "operator_handoff_validation does not match canonical bundle resolution")

        if isinstance(preview_doc, dict):
            compare_docs(
                "priority_preview",
                normalize_preview_doc(preview_doc),
                normalize_preview_doc(canonical_bundle["priority_preview"]),
                errors,
            )

        if isinstance(display_packet_doc, dict):
            compare_docs(
                "priority_display_packet",
                normalize_display_packet_doc(display_packet_doc),
                normalize_display_packet_doc(canonical_bundle["priority_display_packet"]),
                errors,
            )


def build_report(
    *,
    bundle_path: Path | None,
    artifact_path: Path | None,
    bundle_doc: dict | None,
    bundle_schema_path: Path,
    validation_schema_path: Path,
    errors: list[str],
    warnings: list[str],
    output_path: Path | None,
) -> dict:
    bundle_doc = bundle_doc if isinstance(bundle_doc, dict) else {}
    validation_doc = bundle_doc.get("operator_handoff_validation")
    preview_doc = bundle_doc.get("priority_preview")
    display_packet_doc = bundle_doc.get("priority_display_packet")
    report = {
        "generated_at_utc": now_utc(),
        "bundle_path": str(bundle_path.resolve()) if bundle_path is not None else None,
        "artifact_file": str(artifact_path.resolve()) if artifact_path is not None else str(bundle_doc.get("artifact_file") or "") or None,
        "bundle_generated_at_utc": bundle_doc.get("generated_at_utc"),
        "bundle_schema_path": str(bundle_schema_path.resolve()),
        "validation_schema_path": str(validation_schema_path.resolve()),
        "operator_handoff_validation_path": bundle_doc.get("operator_handoff_validation_path"),
        "operator_handoff_validation_verdict": validation_doc.get("verdict") if isinstance(validation_doc, dict) else None,
        "operator_handoff_bundle_path": bundle_doc.get("operator_handoff_bundle_path"),
        "operator_handoff_bundle_validation_path": bundle_doc.get("operator_handoff_bundle_validation_path"),
        "operator_handoff_bundle_readiness_path": bundle_doc.get("operator_handoff_bundle_readiness_path"),
        "operator_handoff_bundle_readiness_validation_path": bundle_doc.get("operator_handoff_bundle_readiness_validation_path"),
        "priority_preview_ref": bundle_doc.get("priority_preview_ref"),
        "priority_preview_state": preview_doc.get("preview_state") if isinstance(preview_doc, dict) else None,
        "priority_display_packet_ref": bundle_doc.get("priority_display_packet_ref"),
        "priority_headline": preview_doc.get("priority_headline") if isinstance(preview_doc, dict) else None,
        "priority_cta_command": preview_doc.get("priority_cta_command") if isinstance(preview_doc, dict) else None,
        "display_title": display_packet_doc.get("display_title") if isinstance(display_packet_doc, dict) else None,
        "cta_command": display_packet_doc.get("cta_command") if isinstance(display_packet_doc, dict) else None,
        "error_count": len(errors),
        "warning_count": len(warnings),
        "errors": errors,
        "warnings": warnings,
        "verdict": "pass" if not errors else "fail",
    }
    if output_path is not None:
        report["resolved_bundle_validation_path"] = str(output_path.resolve())
    return report


def validate_handoff_bundle(
    *,
    bundle_file: str | None,
    artifact_file: str | None,
    bundle_schema_path: str | None,
    validation_schema_path: str | None,
    output: str | None,
) -> dict:
    resolved_bundle_schema_path = resolve_path(str(bundle_schema_path or DEFAULT_BUNDLE_SCHEMA))
    resolved_validation_schema_path = resolve_path(str(validation_schema_path or DEFAULT_REPORT_SCHEMA))
    output_path = resolve_path(output, base=WORKSPACE_ROOT) if output else None

    if resolved_bundle_schema_path is None or resolved_validation_schema_path is None:
        raise SystemExit("unable to resolve validator schema paths")

    errors: list[str] = []
    warnings: list[str] = []
    bundle_doc: dict | None = None
    bundle_path: Path | None = None
    artifact_path: Path | None = None
    canonical_bundle: dict | None = None

    if bundle_file:
        bundle_path = resolve_path(bundle_file, base=WORKSPACE_ROOT)
        if bundle_path is None or not bundle_path.exists():
            append_unique(errors, "bundle_file must resolve to an existing file")
        else:
            loaded_bundle = load_json(bundle_path)
            if not isinstance(loaded_bundle, dict):
                append_unique(errors, "bundle_file must contain a JSON object")
            else:
                bundle_doc = loaded_bundle
                artifact_path = resolve_path(str(bundle_doc.get("artifact_file") or ""), base=bundle_path.parent)
                bundle_schema_doc = load_json(resolved_bundle_schema_path)
                errors.extend(prefixed_errors("bundle schema", validate_schema(bundle_doc, bundle_schema_doc)))
    else:
        artifact_path = resolve_path(artifact_file, base=WORKSPACE_ROOT)
        if artifact_path is None or not artifact_path.exists():
            append_unique(errors, "artifact_file must resolve to an existing file")

    if artifact_path is not None and artifact_path.exists():
        try:
            _resolved_output, canonical_bundle = resolve_handoff_bundle(
                artifact_file=str(artifact_path),
                schema_path=str(resolved_bundle_schema_path),
                output=None,
            )
            if bundle_doc is None:
                bundle_doc = canonical_bundle
        except SystemExit as exc:
            append_unique(errors, f"canonical bundle resolution failed: {exc}")

    if isinstance(bundle_doc, dict):
        validate_nested_schema(bundle_doc.get("operator_handoff_validation"), HANDOFF_VALIDATION_SCHEMA, "operator_handoff_validation schema", errors)
        validate_nested_schema(bundle_doc.get("priority_preview"), PREVIEW_SCHEMA, "priority_preview schema", errors)
        validate_nested_schema(bundle_doc.get("priority_display_packet"), DISPLAY_PACKET_SCHEMA, "priority_display_packet schema", errors)
        validate_bundle_semantics(bundle_doc, canonical_bundle, errors)

    report = build_report(
        bundle_path=bundle_path,
        artifact_path=artifact_path,
        bundle_doc=bundle_doc,
        bundle_schema_path=resolved_bundle_schema_path,
        validation_schema_path=resolved_validation_schema_path,
        errors=errors,
        warnings=warnings,
        output_path=output_path,
    )
    report_schema_doc = load_json(resolved_validation_schema_path)
    report_schema_errors = validate_schema(report, report_schema_doc)
    if report_schema_errors:
        raise SystemExit("invalid supervisor operator handoff bundle validation report: " + "; ".join(report_schema_errors))
    if output_path is not None:
        write_json(output_path, report)
    return report


def main() -> int:
    args = parse_args()
    report = validate_handoff_bundle(
        bundle_file=args.bundle_file,
        artifact_file=args.artifact_file,
        bundle_schema_path=args.bundle_schema,
        validation_schema_path=args.validation_schema,
        output=args.output,
    )
    print(json.dumps(report, ensure_ascii=True, indent=2))
    if report["verdict"] != "pass" and args.strict:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
