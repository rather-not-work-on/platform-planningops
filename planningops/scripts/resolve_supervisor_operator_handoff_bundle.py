#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from resolve_supervisor_operator_handoff_validation import (
    find_embedded_validation_paths,
    load_validation_report,
    resolve_validation_path,
)
from validate_supervisor_operator_handoff import load_json, validate_schema


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
MONDAY_ROOT = WORKSPACE_ROOT.parent / "monday"
MONDAY_SCRIPTS = MONDAY_ROOT / "scripts"
DEFAULT_SCHEMA = WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-bundle.schema.json"

if str(MONDAY_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(MONDAY_SCRIPTS))

from export_operator_priority_display_packet import load_embedded_display_packet_from_artifact  # noqa: E402
from local_outbox_dispatch_common import (  # noqa: E402
    ensure_runtime_artifact_boundary,
    repo_relative as monday_repo_relative,
    resolve_embedded_operator_handoff_bundle_sidecar_paths,
    resolve_operator_handoff_validation_path,
    resolve_path as monday_resolve_path,
)
from resolve_operator_priority_display_packet import resolve_priority_display_packet  # noqa: E402
from resolve_operator_priority_preview import (  # noqa: E402
    load_embedded_preview_from_artifact,
    load_preview_from_ref,
    resolve_priority_preview,
)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def parse_args():
    parser = argparse.ArgumentParser(
        description="Resolve the canonical handoff validation, priority preview, and priority display packet bundle from a monday artifact"
    )
    parser.add_argument("--artifact-file", required=True)
    parser.add_argument("--schema", default=str(DEFAULT_SCHEMA))
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def append_unique(items: list[str], message: str) -> None:
    if message not in items:
        items.append(message)


def write_output(output: str | None, doc: dict) -> Path | None:
    if not output:
        return None
    output_path = Path(output)
    if not output_path.is_absolute():
        output_path = (WORKSPACE_ROOT / output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return output_path


def normalize_monday_ref(ref: str) -> str:
    resolved = ensure_runtime_artifact_boundary(monday_resolve_path(ref, root=MONDAY_ROOT), root=MONDAY_ROOT)
    return monday_repo_relative(resolved, MONDAY_ROOT)


def normalize_validation_path(value: object, *, base: Path) -> str | None:
    text = str(value or "").strip()
    if not text or text == "-":
        return None
    path = Path(text)
    if not path.is_absolute():
        path = (base / path).resolve()
    else:
        path = path.resolve()
    return str(path)


def validate_bundle(bundle: dict, *, schema_path: Path) -> None:
    schema_doc = load_json(schema_path)
    errors = validate_schema(bundle, schema_doc)
    if errors:
        raise SystemExit("invalid supervisor operator handoff bundle: " + "; ".join(errors))


def resolve_validation_report_from_artifact(artifact_doc: dict, *, artifact_path: Path) -> tuple[Path, dict]:
    validation_path = resolve_validation_path(*find_embedded_validation_paths(artifact_doc))
    if validation_path is None:
        raise SystemExit("artifact does not carry operator_handoff_validation_path")
    return load_validation_report(
        validation_path,
        base=artifact_path.parent,
        schema_path=WORKSPACE_ROOT / "planningops/schemas/supervisor-operator-handoff-validation.schema.json",
    )


def resolve_preview_from_artifact(artifact_doc: dict, *, artifact_path: Path) -> tuple[Path, dict]:
    embedded_preview = load_embedded_preview_from_artifact(artifact_doc, root=MONDAY_ROOT)
    if embedded_preview is not None:
        return embedded_preview

    embedded_display_packet = load_embedded_display_packet_from_artifact(artifact_doc, root=MONDAY_ROOT)
    if embedded_display_packet is not None:
        _display_packet_path, display_packet = embedded_display_packet
        preview_ref = str(display_packet.get("priority_preview_ref") or "").strip()
        if preview_ref:
            return load_preview_from_ref(preview_ref, root=MONDAY_ROOT)

    output_path, preview = resolve_priority_preview(
        artifact_file=str(artifact_path),
        preview_ref=None,
        output=None,
        root=MONDAY_ROOT,
    )
    if output_path is None:
        raise SystemExit("unable to resolve priority preview path")
    return ensure_runtime_artifact_boundary(output_path, root=MONDAY_ROOT), preview


def resolve_display_packet_from_artifact(artifact_doc: dict, *, artifact_path: Path) -> tuple[Path, dict]:
    embedded_display_packet = load_embedded_display_packet_from_artifact(artifact_doc, root=MONDAY_ROOT)
    if embedded_display_packet is not None:
        return embedded_display_packet

    output_path, display_packet = resolve_priority_display_packet(
        artifact_file=str(artifact_path),
        display_packet_ref=None,
        output=None,
        root=MONDAY_ROOT,
    )
    if output_path is None:
        raise SystemExit("unable to resolve priority display packet path")
    return ensure_runtime_artifact_boundary(output_path, root=MONDAY_ROOT), display_packet


def require_matching_value(*, preview: dict, display_packet: dict, field: str, errors: list[str]) -> None:
    preview_value = str(preview.get(field) or "").strip()
    display_value = str(display_packet.get(field) or "").strip()
    if preview_value and display_value and preview_value != display_value:
        append_unique(errors, f"priority display packet {field} does not match resolved priority preview")


def resolve_handoff_bundle(*, artifact_file: str, schema_path: str | None, output: str | None) -> tuple[Path | None, dict]:
    resolved_schema_path = Path(str(schema_path or DEFAULT_SCHEMA))
    if not resolved_schema_path.is_absolute():
        resolved_schema_path = (WORKSPACE_ROOT / resolved_schema_path).resolve()

    artifact_path = Path(artifact_file)
    if not artifact_path.is_absolute():
        artifact_path = (WORKSPACE_ROOT / artifact_path).resolve()
    else:
        artifact_path = artifact_path.resolve()
    artifact_doc = load_json(artifact_path)
    if not isinstance(artifact_doc, dict):
        raise SystemExit(f"artifact not found: {artifact_path}")

    validation_path, validation_doc = resolve_validation_report_from_artifact(artifact_doc, artifact_path=artifact_path)
    preview_path, preview_doc = resolve_preview_from_artifact(artifact_doc, artifact_path=artifact_path)
    display_packet_path, display_packet_doc = resolve_display_packet_from_artifact(artifact_doc, artifact_path=artifact_path)

    preview_ref = monday_repo_relative(preview_path, MONDAY_ROOT)
    display_packet_ref = monday_repo_relative(display_packet_path, MONDAY_ROOT)
    bundle_sidecar_paths = resolve_embedded_operator_handoff_bundle_sidecar_paths(
        artifact_doc,
        preview_doc,
        display_packet_doc,
    )

    errors: list[str] = []
    validation_value = resolve_operator_handoff_validation_path(
        str(validation_path),
        normalize_validation_path(preview_doc.get("operator_handoff_validation_path"), base=preview_path.parent),
        normalize_validation_path(display_packet_doc.get("operator_handoff_validation_path"), base=display_packet_path.parent),
    )
    if validation_value != str(validation_path):
        append_unique(errors, "resolved operator_handoff_validation_path does not match canonical validation report")

    display_packet_preview_ref = str(display_packet_doc.get("priority_preview_ref") or "").strip()
    if not display_packet_preview_ref:
        append_unique(errors, "priority display packet missing priority_preview_ref")
    elif normalize_monday_ref(display_packet_preview_ref) != preview_ref:
        append_unique(errors, "priority display packet priority_preview_ref does not match resolved priority preview ref")

    require_matching_value(preview=preview_doc, display_packet=display_packet_doc, field="priority_headline", errors=errors)
    require_matching_value(preview=preview_doc, display_packet=display_packet_doc, field="priority_cta_command", errors=errors)
    require_matching_value(preview=preview_doc, display_packet=display_packet_doc, field="priority_summary_markdown", errors=errors)

    if errors:
        raise SystemExit("; ".join(errors))

    bundle = {
        "generated_at_utc": now_utc(),
        "artifact_file": str(artifact_path),
        "operator_handoff_validation_path": str(validation_path),
        "priority_preview_ref": preview_ref,
        "priority_display_packet_ref": display_packet_ref,
        "operator_handoff_validation": validation_doc,
        "priority_preview": preview_doc,
        "priority_display_packet": display_packet_doc,
    }
    bundle.update(bundle_sidecar_paths)
    validate_bundle(bundle, schema_path=resolved_schema_path)
    output_path = write_output(output, bundle)
    return output_path, bundle


def main() -> int:
    args = parse_args()
    output_path, bundle = resolve_handoff_bundle(
        artifact_file=args.artifact_file,
        schema_path=args.schema,
        output=args.output,
    )
    if output_path is not None:
        bundle = dict(bundle)
        bundle["resolved_bundle_path"] = str(output_path)
    print(json.dumps(bundle, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
