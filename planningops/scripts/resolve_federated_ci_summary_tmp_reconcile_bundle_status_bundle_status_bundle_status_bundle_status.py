#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

from validate_supervisor_operator_handoff import load_json, validate_schema


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_STATUS_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status.schema.json"
)
DEFAULT_STATUS_VALIDATION_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-validation.schema.json"
)
DEFAULT_BUNDLE_SCHEMA = (
    WORKSPACE_ROOT
    / "planningops/schemas/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.schema.json"
)
DEFAULT_OUTPUT = (
    WORKSPACE_ROOT
    / "planningops/artifacts/validation/federated-ci-summary-tmp-reconcile-bundle-status-bundle-status-bundle-status-bundle-status-bundle.json"
)


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_doc_path(value: object, *, base: Path) -> Path | None:
    if not isinstance(value, str) or not value.strip():
        return None
    path = Path(value.strip())
    if not path.is_absolute():
        return (base / path).resolve()
    return path.resolve()


def resolve_output_path(output: str | None) -> Path | None:
    if not output:
        return None
    path = Path(output)
    if not path.is_absolute():
        return (WORKSPACE_ROOT / path).resolve()
    return path.resolve()


def write_output(output_path: Path | None, doc: dict) -> Path | None:
    if output_path is None:
        return None
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    return output_path


def validate_doc_schema(doc: dict, schema_path: Path, label: str) -> None:
    schema_doc = load_json(schema_path)
    errors = validate_schema(doc, schema_doc)
    if errors:
        raise SystemExit(f"invalid {label}: " + "; ".join(errors))


def is_status_doc(doc: dict) -> bool:
    return all(
        key in doc
        for key in (
            "output_path",
            "status_validation_output_path",
            "bundle_path",
            "validation_report_path",
            "run_id",
            "bundle_validation_state",
            "ready",
            "next_step",
        )
    )


def is_status_validation_doc(doc: dict) -> bool:
    return all(
        key in doc
        for key in (
            "status_path",
            "bundle_path",
            "bundle_validation_report_path",
            "output_path",
            "status_output_path",
            "status_validation_output_path",
            "status_run_id",
            "status_bundle_validation_state",
            "status_ready",
            "status_next_step",
        )
    )


def build_bundle(
    *,
    artifact_path: Path,
    status_path: Path,
    status_doc: dict,
    status_validation_path: Path,
    status_validation_doc: dict,
) -> dict:
    return {
        "generated_at_utc": now_utc(),
        "artifact_file": str(artifact_path.resolve()),
        "status_path": str(status_path.resolve()),
        "status_validation_path": str(status_validation_path.resolve()),
        "bundle_path": status_doc.get("bundle_path"),
        "bundle_validation_report_path": status_doc.get("validation_report_path"),
        "run_id": status_doc.get("run_id"),
        "reconcile_status": status_doc.get("reconcile_status"),
        "check_name": status_doc.get("check_name"),
        "reconcile_count": status_doc.get("reconcile_count"),
        "reconcile_validation_verdict": status_doc.get("reconcile_validation_verdict"),
        "bundle_validation_verdict": status_doc.get("bundle_validation_verdict"),
        "bundle_validation_state": status_doc.get("bundle_validation_state"),
        "ready": status_doc.get("ready"),
        "next_step": status_doc.get("next_step"),
        "status_report": status_doc,
        "status_validation_report": status_validation_doc,
    }


def resolve_from_status(
    artifact_path: Path,
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
) -> dict:
    status_path = artifact_path.resolve()
    status_doc = load_json(status_path)
    validate_doc_schema(
        status_doc,
        status_schema_path,
        "tmp-summary reconcile bundle status-bundle-status bundle status bundle status report",
    )

    embedded_status_path = resolve_doc_path(status_doc.get("output_path"), base=status_path.parent)
    if embedded_status_path != status_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status report output_path must match the resolved status path"
        )

    status_validation_path = resolve_doc_path(
        status_doc.get("status_validation_output_path"),
        base=status_path.parent,
    )
    if status_validation_path is None:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status report missing status_validation_output_path"
        )
    status_validation_doc = load_json(status_validation_path)
    validate_doc_schema(
        status_validation_doc,
        status_validation_schema_path,
        "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report",
    )

    if resolve_doc_path(status_validation_doc.get("status_path"), base=status_validation_path.parent) != status_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report status_path must match the resolved status path"
        )
    if resolve_doc_path(
        status_validation_doc.get("status_output_path"),
        base=status_validation_path.parent,
    ) != status_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report status_output_path must match the resolved status path"
        )
    if resolve_doc_path(status_validation_doc.get("output_path"), base=status_validation_path.parent) != status_validation_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report output_path must match the resolved status-validation path"
        )
    if resolve_doc_path(
        status_validation_doc.get("status_validation_output_path"),
        base=status_validation_path.parent,
    ) != status_validation_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report status_validation_output_path must match the resolved status-validation path"
        )
    if status_validation_doc.get("status_run_id") != status_doc.get("run_id"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status run_id"
        )
    if status_validation_doc.get("status_reconcile_status") != status_doc.get("reconcile_status"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status reconcile_status"
        )
    if status_validation_doc.get("status_check_name") != status_doc.get("check_name"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status check_name"
        )
    if status_validation_doc.get("status_reconcile_count") != status_doc.get("reconcile_count"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status reconcile_count"
        )
    if (
        status_validation_doc.get("status_reconcile_validation_verdict")
        != status_doc.get("reconcile_validation_verdict")
    ):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status reconcile_validation_verdict"
        )
    if status_validation_doc.get("status_bundle_validation_verdict") != status_doc.get("bundle_validation_verdict"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status bundle_validation_verdict"
        )
    if status_validation_doc.get("status_bundle_validation_state") != status_doc.get("bundle_validation_state"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status bundle_validation_state"
        )
    if status_validation_doc.get("status_ready") != status_doc.get("ready"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status ready"
        )
    if status_validation_doc.get("status_next_step") != status_doc.get("next_step"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status next_step"
        )

    return build_bundle(
        artifact_path=artifact_path,
        status_path=status_path,
        status_doc=status_doc,
        status_validation_path=status_validation_path,
        status_validation_doc=status_validation_doc,
    )


def resolve_from_status_validation(
    artifact_path: Path,
    *,
    status_schema_path: Path,
    status_validation_schema_path: Path,
) -> dict:
    status_validation_path = artifact_path.resolve()
    status_validation_doc = load_json(status_validation_path)
    validate_doc_schema(
        status_validation_doc,
        status_validation_schema_path,
        "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report",
    )

    if resolve_doc_path(
        status_validation_doc.get("status_validation_output_path"),
        base=status_validation_path.parent,
    ) != status_validation_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report status_validation_output_path must match the resolved status-validation path"
        )
    if resolve_doc_path(status_validation_doc.get("output_path"), base=status_validation_path.parent) != status_validation_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report output_path must match the resolved status-validation path"
        )

    status_path = resolve_doc_path(status_validation_doc.get("status_output_path"), base=status_validation_path.parent)
    if status_path is None:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report missing status_output_path"
        )
    if resolve_doc_path(status_validation_doc.get("status_path"), base=status_validation_path.parent) != status_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report status_path must match status_output_path"
        )

    status_doc = load_json(status_path)
    validate_doc_schema(
        status_doc,
        status_schema_path,
        "tmp-summary reconcile bundle status-bundle-status bundle status bundle status report",
    )

    if resolve_doc_path(status_doc.get("output_path"), base=status_path.parent) != status_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status report output_path must match the resolved status path"
        )
    if resolve_doc_path(
        status_doc.get("status_validation_output_path"),
        base=status_path.parent,
    ) != status_validation_path:
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status report status_validation_output_path must match the resolved status-validation path"
        )
    if status_validation_doc.get("status_run_id") != status_doc.get("run_id"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status run_id"
        )
    if status_validation_doc.get("status_reconcile_status") != status_doc.get("reconcile_status"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status reconcile_status"
        )
    if status_validation_doc.get("status_check_name") != status_doc.get("check_name"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status check_name"
        )
    if status_validation_doc.get("status_reconcile_count") != status_doc.get("reconcile_count"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status reconcile_count"
        )
    if (
        status_validation_doc.get("status_reconcile_validation_verdict")
        != status_doc.get("reconcile_validation_verdict")
    ):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status reconcile_validation_verdict"
        )
    if status_validation_doc.get("status_bundle_validation_verdict") != status_doc.get("bundle_validation_verdict"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status bundle_validation_verdict"
        )
    if status_validation_doc.get("status_bundle_validation_state") != status_doc.get("bundle_validation_state"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status bundle_validation_state"
        )
    if status_validation_doc.get("status_ready") != status_doc.get("ready"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status ready"
        )
    if status_validation_doc.get("status_next_step") != status_doc.get("next_step"):
        raise SystemExit(
            "tmp-summary reconcile bundle status-bundle-status bundle status bundle status-validation report must match status next_step"
        )

    return build_bundle(
        artifact_path=artifact_path,
        status_path=status_path,
        status_doc=status_doc,
        status_validation_path=status_validation_path,
        status_validation_doc=status_validation_doc,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve the canonical tmp-summary reconcile bundle status-bundle-status bundle status bundle status + status-validation pair from either artifact."
    )
    parser.add_argument("--artifact-file", required=True)
    parser.add_argument("--status-schema", default=str(DEFAULT_STATUS_SCHEMA))
    parser.add_argument("--status-validation-schema", default=str(DEFAULT_STATUS_VALIDATION_SCHEMA))
    parser.add_argument("--bundle-schema", default=str(DEFAULT_BUNDLE_SCHEMA))
    parser.add_argument("--output", default=None)
    return parser.parse_args()


def resolve_status_bundle_status_bundle_status_bundle_status(
    *,
    artifact_file: str,
    status_schema: str,
    status_validation_schema: str,
    bundle_schema: str,
    output: str | None,
) -> tuple[Path | None, dict]:
    artifact_path = Path(artifact_file)
    if not artifact_path.is_absolute():
        artifact_path = (WORKSPACE_ROOT / artifact_path).resolve()
    else:
        artifact_path = artifact_path.resolve()
    artifact_doc = load_json(artifact_path)

    status_schema_path = Path(status_schema)
    if not status_schema_path.is_absolute():
        status_schema_path = (WORKSPACE_ROOT / status_schema_path).resolve()
    else:
        status_schema_path = status_schema_path.resolve()
    status_validation_schema_path = Path(status_validation_schema)
    if not status_validation_schema_path.is_absolute():
        status_validation_schema_path = (WORKSPACE_ROOT / status_validation_schema_path).resolve()
    else:
        status_validation_schema_path = status_validation_schema_path.resolve()
    bundle_schema_path = Path(bundle_schema)
    if not bundle_schema_path.is_absolute():
        bundle_schema_path = (WORKSPACE_ROOT / bundle_schema_path).resolve()
    else:
        bundle_schema_path = bundle_schema_path.resolve()

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
            "artifact must be a tmp-summary reconcile bundle status-bundle-status bundle status bundle status report or status-validation report"
        )

    validate_doc_schema(
        bundle,
        bundle_schema_path,
        "tmp-summary reconcile bundle status-bundle-status bundle status bundle status bundle",
    )
    output_path = write_output(resolve_output_path(output), bundle)
    return output_path, bundle


def main() -> int:
    args = parse_args()
    output_path, bundle = resolve_status_bundle_status_bundle_status_bundle_status(
        artifact_file=args.artifact_file,
        status_schema=args.status_schema,
        status_validation_schema=args.status_validation_schema,
        bundle_schema=args.bundle_schema,
        output=args.output,
    )
    rendered = dict(bundle)
    if output_path is not None:
        rendered["output_path"] = str(output_path)
    print(json.dumps(rendered, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
