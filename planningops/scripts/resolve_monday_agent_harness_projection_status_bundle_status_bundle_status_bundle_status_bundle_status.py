#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path

import validate_monday_agent_harness_projection as projection_validation


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATUS = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status.json"
)
DEFAULT_STATUS_VALIDATION = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.json"
)
DEFAULT_STATUS_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"
)
DEFAULT_BUNDLE_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/monday-agent-harness-projection-status-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Resolve the canonical monday harness projection "
            "status-bundle-status-bundle-status-bundle-status-bundle-status + validation pair."
        )
    )
    parser.add_argument("--artifact-file", default=None)
    parser.add_argument("--status-file", default=None)
    parser.add_argument("--status-validation-file", default=None)
    parser.add_argument("--status-schema", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--bundle-schema", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def resolve_doc_path(value: object, *, base: Path) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        path = (base / path).resolve()
    else:
        path = path.resolve()
    return path


def resolve_output_path(output: str | None) -> Path | None:
    if not output:
        return None
    output_path = Path(output)
    if not output_path.is_absolute():
        output_path = (WORKSPACE_ROOT / output_path).resolve()
    else:
        output_path = output_path.resolve()
    return output_path


def write_output(output_path: Path | None, doc: dict) -> Path | None:
    if output_path is None:
        return None
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return output_path


def validate_doc_schema(doc: dict, schema_path: Path, label: str) -> None:
    schema_doc = projection_validation.load_json(schema_path)
    errors = projection_validation.validate_schema(doc, schema_doc)
    if errors:
        raise SystemExit(f"invalid {label}: " + "; ".join(errors))


def is_status_doc(doc: dict) -> bool:
    return all(
        key in doc
        for key in (
            "bundle_status_bundle_status_bundle_status_bundle_output_path",
            "bundle_status_bundle_status_bundle_status_bundle_validation_output_path",
            "ready",
            "next_step",
        )
    )


def is_status_validation_doc(doc: dict) -> bool:
    return all(
        key in doc
        for key in (
            "bundle_status_bundle_status_bundle_status_bundle_status_path",
            "bundle_status_bundle_status_bundle_status_bundle_output_path",
            "bundle_status_bundle_status_bundle_status_bundle_validation_output_path",
            "output_path",
            "status_ready",
        )
    )


def build_bundle(
    *,
    status_path: Path,
    status_doc: dict,
    status_validation_path: Path,
    status_validation_doc: dict,
) -> dict:
    return {
        "bundle_status_bundle_status_bundle_status_bundle_status_path": str(status_path.resolve()),
        "bundle_status_bundle_status_bundle_status_bundle_validation_path": str(
            status_validation_path.resolve()
        ),
        "bundle_path": status_doc.get("bundle_path"),
        "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path": status_doc.get(
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path"
        ),
        "bundle_validation_output_path": status_doc.get("bundle_validation_output_path"),
        "bundle_status_bundle_status_bundle_status_path": status_doc.get(
            "bundle_status_bundle_status_bundle_status_path"
        ),
        "bundle_status_bundle_status_bundle_validation_path": status_doc.get(
            "bundle_status_bundle_status_bundle_validation_path"
        ),
        "bundle_status_bundle_status_path": status_doc.get("bundle_status_bundle_status_path"),
        "bundle_status_bundle_validation_path": status_doc.get("bundle_status_bundle_validation_path"),
        "bundle_status_path": status_doc.get("bundle_status_path"),
        "bundle_status_validation_path": status_doc.get("bundle_status_validation_path"),
        "projection_bundle_path": status_doc.get("projection_bundle_path"),
        "projection_validation_report_path": status_doc.get("projection_validation_report_path"),
        "status_path": status_doc.get("status_path"),
        "status_validation_path": status_doc.get("status_validation_path"),
        "mission_id": status_doc.get("mission_id"),
        "run_id": status_doc.get("run_id"),
        "session_id": status_doc.get("session_id"),
        "ready": status_doc.get("ready"),
        "next_step": status_doc.get("next_step"),
        "status_verdict": status_doc.get("verdict"),
        "status_validation_verdict": status_validation_doc.get("verdict"),
        "bundle_status_verdict": status_doc.get("status_verdict"),
        "bundle_status_validation_verdict": status_doc.get("status_validation_verdict"),
        "projection_validation_verdict": status_doc.get("projection_validation_verdict"),
        "projection_validation_state": status_doc.get("projection_validation_state"),
        "status_sidecar_validation_verdict": status_doc.get("status_sidecar_validation_verdict"),
        "bundle_validation_verdict": status_doc.get("bundle_validation_verdict"),
        "bundle_status_bundle_status_bundle_status_bundle_report": status_doc,
        "bundle_status_bundle_status_bundle_status_bundle_validation_report": status_validation_doc,
    }


def resolve_from_status(
    status_path: Path,
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
) -> dict:
    status_path = status_path.resolve()
    status_doc = projection_validation.load_json(status_path)
    validate_doc_schema(
        status_doc,
        status_schema_path,
        "monday harness projection status-bundle-status-bundle-status-bundle-status-bundle-status report",
    )

    if (
        resolve_doc_path(
            status_doc.get("bundle_status_bundle_status_bundle_status_bundle_output_path"),
            base=status_path.parent,
        )
        != status_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status report "
            "bundle_status_bundle_status_bundle_status_bundle_output_path must match the resolved status path"
        )

    status_validation_path = resolve_doc_path(
        status_doc.get("bundle_status_bundle_status_bundle_status_bundle_validation_output_path"),
        base=status_path.parent,
    )
    if status_validation_path is None:
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status report missing "
            "bundle_status_bundle_status_bundle_status_bundle_validation_output_path"
        )

    status_validation_doc = projection_validation.load_json(status_validation_path)
    validate_doc_schema(
        status_validation_doc,
        status_validation_schema_path,
        "monday harness projection status-bundle-status-bundle-status-bundle-status-bundle-status-validation report",
    )

    if (
        resolve_doc_path(
            status_validation_doc.get("bundle_status_bundle_status_bundle_status_bundle_status_path"),
            base=status_validation_path.parent,
        )
        != status_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "bundle_status_bundle_status_bundle_status_bundle_status_path must match the resolved status path"
        )
    if (
        resolve_doc_path(
            status_validation_doc.get("bundle_status_bundle_status_bundle_status_bundle_output_path"),
            base=status_validation_path.parent,
        )
        != status_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "bundle_status_bundle_status_bundle_status_bundle_output_path must match the resolved status path"
        )
    if (
        resolve_doc_path(status_validation_doc.get("output_path"), base=status_validation_path.parent)
        != status_validation_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "output_path must match the resolved validation path"
        )
    if (
        resolve_doc_path(
            status_validation_doc.get("bundle_status_bundle_status_bundle_status_bundle_validation_output_path"),
            base=status_validation_path.parent,
        )
        != status_validation_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "bundle_status_bundle_status_bundle_status_bundle_validation_output_path must match the resolved validation path"
        )
    for status_field, validation_field in (
        ("bundle_path", "bundle_path"),
        (
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path",
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path",
        ),
        ("bundle_validation_output_path", "bundle_validation_output_path"),
        ("bundle_status_bundle_status_bundle_status_path", "bundle_status_bundle_status_bundle_status_path"),
        (
            "bundle_status_bundle_status_bundle_validation_path",
            "bundle_status_bundle_status_bundle_validation_path",
        ),
        ("bundle_status_bundle_status_path", "bundle_status_bundle_status_path"),
        ("bundle_status_bundle_validation_path", "bundle_status_bundle_validation_path"),
        ("bundle_status_path", "bundle_status_path"),
        ("bundle_status_validation_path", "bundle_status_validation_path"),
        ("projection_bundle_path", "projection_bundle_path"),
        ("projection_validation_report_path", "projection_validation_report_path"),
        ("status_path", "status_path"),
        ("status_validation_path", "status_validation_path"),
        ("mission_id", "mission_id"),
        ("run_id", "run_id"),
        ("session_id", "session_id"),
        ("verdict", "status_verdict"),
        ("ready", "status_ready"),
        ("next_step", "status_next_step"),
        ("status_verdict", "bundle_status_verdict"),
        ("status_validation_verdict", "bundle_status_validation_verdict"),
        ("projection_validation_verdict", "projection_validation_verdict"),
        ("projection_validation_state", "projection_validation_state"),
        ("status_sidecar_validation_verdict", "status_sidecar_validation_verdict"),
        ("bundle_validation_verdict", "bundle_validation_verdict"),
    ):
        if status_doc.get(status_field) != status_validation_doc.get(validation_field):
            raise SystemExit(
                "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
                f"{validation_field} must match status {status_field}"
            )

    return build_bundle(
        status_path=status_path,
        status_doc=status_doc,
        status_validation_path=status_validation_path,
        status_validation_doc=status_validation_doc,
    )


def resolve_from_status_validation(
    status_validation_path: Path,
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
) -> dict:
    status_validation_path = status_validation_path.resolve()
    status_validation_doc = projection_validation.load_json(status_validation_path)
    validate_doc_schema(
        status_validation_doc,
        status_validation_schema_path,
        "monday harness projection status-bundle-status-bundle-status-bundle-status-bundle-status-validation report",
    )

    if (
        resolve_doc_path(
            status_validation_doc.get("bundle_status_bundle_status_bundle_status_bundle_validation_output_path"),
            base=status_validation_path.parent,
        )
        != status_validation_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "bundle_status_bundle_status_bundle_status_bundle_validation_output_path must match the resolved validation path"
        )
    if (
        resolve_doc_path(status_validation_doc.get("output_path"), base=status_validation_path.parent)
        != status_validation_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "output_path must match the resolved validation path"
        )

    status_path = resolve_doc_path(
        status_validation_doc.get("bundle_status_bundle_status_bundle_status_bundle_output_path"),
        base=status_validation_path.parent,
    )
    if status_path is None:
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report missing "
            "bundle_status_bundle_status_bundle_status_bundle_output_path"
        )
    if (
        resolve_doc_path(
            status_validation_doc.get("bundle_status_bundle_status_bundle_status_bundle_status_path"),
            base=status_validation_path.parent,
        )
        != status_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
            "bundle_status_bundle_status_bundle_status_bundle_status_path must match "
            "bundle_status_bundle_status_bundle_status_bundle_output_path"
        )

    status_doc = projection_validation.load_json(status_path)
    validate_doc_schema(
        status_doc,
        status_schema_path,
        "monday harness projection status-bundle-status-bundle-status-bundle-status-bundle-status report",
    )

    if (
        resolve_doc_path(
            status_doc.get("bundle_status_bundle_status_bundle_status_bundle_output_path"),
            base=status_path.parent,
        )
        != status_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status report "
            "bundle_status_bundle_status_bundle_status_bundle_output_path must match the resolved status path"
        )
    if (
        resolve_doc_path(
            status_doc.get("bundle_status_bundle_status_bundle_status_bundle_validation_output_path"),
            base=status_path.parent,
        )
        != status_validation_path
    ):
        raise SystemExit(
            "status-bundle-status-bundle-status-bundle-status-bundle-status report "
            "bundle_status_bundle_status_bundle_status_bundle_validation_output_path must match the resolved validation path"
        )
    for status_field, validation_field in (
        ("bundle_path", "bundle_path"),
        (
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path",
            "resolved_status_bundle_status_bundle_status_bundle_status_bundle_path",
        ),
        ("bundle_validation_output_path", "bundle_validation_output_path"),
        ("bundle_status_bundle_status_bundle_status_path", "bundle_status_bundle_status_bundle_status_path"),
        (
            "bundle_status_bundle_status_bundle_validation_path",
            "bundle_status_bundle_status_bundle_validation_path",
        ),
        ("bundle_status_bundle_status_path", "bundle_status_bundle_status_path"),
        ("bundle_status_bundle_validation_path", "bundle_status_bundle_validation_path"),
        ("bundle_status_path", "bundle_status_path"),
        ("bundle_status_validation_path", "bundle_status_validation_path"),
        ("projection_bundle_path", "projection_bundle_path"),
        ("projection_validation_report_path", "projection_validation_report_path"),
        ("status_path", "status_path"),
        ("status_validation_path", "status_validation_path"),
        ("mission_id", "mission_id"),
        ("run_id", "run_id"),
        ("session_id", "session_id"),
        ("verdict", "status_verdict"),
        ("ready", "status_ready"),
        ("next_step", "status_next_step"),
        ("status_verdict", "bundle_status_verdict"),
        ("status_validation_verdict", "bundle_status_validation_verdict"),
        ("projection_validation_verdict", "projection_validation_verdict"),
        ("projection_validation_state", "projection_validation_state"),
        ("status_sidecar_validation_verdict", "status_sidecar_validation_verdict"),
        ("bundle_validation_verdict", "bundle_validation_verdict"),
    ):
        if status_doc.get(status_field) != status_validation_doc.get(validation_field):
            raise SystemExit(
                "status-bundle-status-bundle-status-bundle-status-bundle-status-validation report "
                f"{validation_field} must match status {status_field}"
            )

    return build_bundle(
        status_path=status_path,
        status_doc=status_doc,
        status_validation_path=status_validation_path,
        status_validation_doc=status_validation_doc,
    )


def resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle(
    *,
    artifact_file: str | None,
    status_file: str | None,
    status_validation_file: str | None,
    status_schema: str,
    status_validation_schema: str,
    bundle_schema: str,
    output: str | None,
) -> dict:
    choices = [bool(artifact_file), bool(status_file), bool(status_validation_file)]
    if sum(choices) != 1:
        raise SystemExit("provide exactly one of --artifact-file, --status-file, or --status-validation-file")

    status_schema_path = Path(status_schema)
    if not status_schema_path.is_absolute():
        status_schema_path = (WORKSPACE_ROOT / status_schema_path).resolve()
    status_validation_schema_path = Path(status_validation_schema)
    if not status_validation_schema_path.is_absolute():
        status_validation_schema_path = (WORKSPACE_ROOT / status_validation_schema_path).resolve()
    bundle_schema_path = Path(bundle_schema)
    if not bundle_schema_path.is_absolute():
        bundle_schema_path = (WORKSPACE_ROOT / bundle_schema_path).resolve()

    if status_file:
        bundle = resolve_from_status(
            Path(status_file),
            status_schema_path=status_schema_path,
            status_validation_schema_path=status_validation_schema_path,
        )
    elif status_validation_file:
        bundle = resolve_from_status_validation(
            Path(status_validation_file),
            status_schema_path=status_schema_path,
            status_validation_schema_path=status_validation_schema_path,
        )
    else:
        artifact_path = Path(str(artifact_file or "")).resolve()
        artifact_doc = projection_validation.load_json(artifact_path)
        if is_status_doc(artifact_doc):
            bundle = resolve_from_status(
                artifact_path,
                status_schema_path=status_schema_path,
                status_validation_schema_path=status_validation_schema_path,
            )
        elif is_status_validation_doc(artifact_doc):
            bundle = resolve_from_status_validation(
                artifact_path,
                status_schema_path=status_schema_path,
                status_validation_schema_path=status_validation_schema_path,
            )
        else:
            raise SystemExit(
                "artifact must be a monday harness projection "
                "status-bundle-status-bundle-status-bundle-status-bundle-status report or validation report"
            )

    output_path = resolve_output_path(output)
    if output_path is not None:
        bundle = dict(bundle)
        bundle["resolved_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle_path"] = str(
            output_path.resolve()
        )
    validate_doc_schema(
        bundle,
        bundle_schema_path,
        "monday harness projection status-bundle-status-bundle-status-bundle-status-bundle-status bundle",
    )
    write_output(output_path, bundle)
    return bundle


def main() -> int:
    args = parse_args()
    bundle = resolve_status_bundle_status_bundle_status_bundle_status_bundle_status_bundle(
        artifact_file=args.artifact_file,
        status_file=args.status_file,
        status_validation_file=args.status_validation_file,
        status_schema=args.status_schema,
        status_validation_schema=args.status_validation_schema,
        bundle_schema=args.bundle_schema,
        output=args.output,
    )
    print(json.dumps(bundle, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
