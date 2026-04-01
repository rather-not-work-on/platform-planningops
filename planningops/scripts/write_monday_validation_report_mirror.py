#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_VALIDATION_ROOT = WORKSPACE_ROOT / "planningops/artifacts/validation"
DEFAULT_MONDAY_VALIDATION_ROOT = WORKSPACE_ROOT.parent / "monday" / "runtime-artifacts/validation"
CONTRACT_REF = "planningops/contracts/monday-validation-report-mirror-contract.md"

MIRROR_CONFIGS = {
    "bridge": {
        "artifact_family": "monday_local_inbox_bridge_schema_validation",
        "latest_filename": "monday-local-inbox-bridge-schema-validation.json",
        "dependency_paths": {
            "monday_local_operator_inbox_payload": "monday-local-operator-inbox-payload.json",
        },
    },
    "consumer-report": {
        "artifact_family": "monday_local_inbox_consumer_schema_validation",
        "latest_filename": "monday-local-inbox-consumer-schema-validation.json",
        "dependency_paths": {
            "monday_local_inbox_consumer_report": "monday-local-inbox-consumer-report.json",
        },
    },
}


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_path(raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path.resolve()
    return (WORKSPACE_ROOT / path).resolve()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def load_optional_json(path: Path) -> dict | None:
    try:
        return load_json(path)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None


def write_json(path: Path, doc: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def is_validation_report_document(doc: dict) -> bool:
    return (
        isinstance(doc.get("generated_at_utc"), str)
        and doc.get("kind") in MIRROR_CONFIGS
        and isinstance(doc.get("artifact_path"), str)
        and isinstance(doc.get("schema_path"), str)
        and isinstance(doc.get("error_count"), int)
        and isinstance(doc.get("warning_count"), int)
        and isinstance(doc.get("errors"), list)
        and isinstance(doc.get("warnings"), list)
        and isinstance(doc.get("verdict"), str)
    )


def timestamp_slug(raw_timestamp: str) -> str:
    text = raw_timestamp.strip()
    if not text:
        return "unknown"
    cleaned = text.replace("-", "").replace(":", "").replace("+00:00", "Z").replace("+0000", "Z")
    cleaned = cleaned.replace(".", "").replace("T", "T")
    return "".join(ch for ch in cleaned if ch.isalnum())


def discover_latest_reports_by_kind(monday_validation_root: Path) -> dict[str, tuple[Path, dict]]:
    candidates: dict[str, list[tuple[str, str, Path, dict]]] = {kind: [] for kind in MIRROR_CONFIGS}
    if not monday_validation_root.exists():
        return {}
    for path in monday_validation_root.glob("*.json"):
        if any(part.startswith(".") or part.startswith("._") for part in path.parts):
            continue
        doc = load_optional_json(path)
        if doc is None or not is_validation_report_document(doc):
            continue
        kind = str(doc.get("kind"))
        generated_at_utc = str(doc.get("generated_at_utc") or "").strip()
        candidates[kind].append((generated_at_utc, str(path.resolve()), path.resolve(), doc))

    latest_by_kind: dict[str, tuple[Path, dict]] = {}
    for kind, items in candidates.items():
        if not items:
            continue
        items.sort(key=lambda item: (item[0], item[1]), reverse=True)
        latest_by_kind[kind] = (items[0][2], items[0][3])
    return latest_by_kind


def build_mirror_doc(
    *,
    validation_root: Path,
    kind: str,
    source_report_path: Path,
    source_report_doc: dict,
) -> tuple[dict, Path, Path]:
    config = MIRROR_CONFIGS[kind]
    generated_at_utc = str(source_report_doc.get("generated_at_utc") or "").strip()
    report_id = f"monday-validation-{kind.replace('-', '-')}-{timestamp_slug(generated_at_utc)}"
    latest_mirror_path = validation_root / config["latest_filename"]
    stamped_mirror_path = validation_root / f"{report_id}-{config['latest_filename']}"

    source_artifact_path = resolve_path(str(source_report_doc.get("artifact_path")))
    source_schema_path = resolve_path(str(source_report_doc.get("schema_path")))
    dependency_paths = {
        family: str((validation_root / filename).resolve())
        for family, filename in config["dependency_paths"].items()
    }
    doc = {
        "generated_at_utc": now_utc(),
        "report_id": report_id,
        "artifact_family": config["artifact_family"],
        "artifact_kind": "validation",
        "contract_ref": CONTRACT_REF,
        "artifact_paths": {
            "latest_mirror_path": str(latest_mirror_path.resolve()),
            "stamped_mirror_path": str(stamped_mirror_path.resolve()),
            "source_report_path": str(source_report_path.resolve()),
        },
        "mirror": {
            "source_report_present": bool(source_report_path.exists()),
            "report_kind": kind,
            "report_verdict": str(source_report_doc.get("verdict") or "").strip() or None,
            "error_count": int(source_report_doc.get("error_count") or 0),
            "warning_count": int(source_report_doc.get("warning_count") or 0),
            "artifact_exists": source_artifact_path.exists(),
            "schema_exists": source_schema_path.exists(),
            "validation_dependency_paths": dependency_paths,
            "payload": source_report_doc,
        },
    }
    return doc, latest_mirror_path, stamped_mirror_path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Mirror monday-owned inbox schema validation reports into planningops validation."
    )
    parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    parser.add_argument("--monday-validation-root", default=str(DEFAULT_MONDAY_VALIDATION_ROOT))
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    validation_root = resolve_path(args.validation_root)
    monday_validation_root = resolve_path(args.monday_validation_root)
    output_path = None if args.output is None else resolve_path(args.output)

    if not (WORKSPACE_ROOT / CONTRACT_REF).exists():
        raise SystemExit(f"validation mirror contract missing: {CONTRACT_REF}")

    latest_by_kind = discover_latest_reports_by_kind(monday_validation_root)
    if not latest_by_kind:
        raise SystemExit(f"monday validation reports not found under {monday_validation_root}")

    result_records: list[dict] = []
    for kind in ("bridge", "consumer-report"):
        selected = latest_by_kind.get(kind)
        if selected is None:
            continue
        source_report_path, source_report_doc = selected
        doc, latest_mirror_path, stamped_mirror_path = build_mirror_doc(
            validation_root=validation_root,
            kind=kind,
            source_report_path=source_report_path,
            source_report_doc=source_report_doc,
        )
        write_json(latest_mirror_path, doc)
        write_json(stamped_mirror_path, doc)
        result_records.append(
            {
                "artifact_family": doc["artifact_family"],
                "report_id": doc["report_id"],
                "latest_mirror_path": str(latest_mirror_path.resolve()),
                "stamped_mirror_path": str(stamped_mirror_path.resolve()),
                "report_kind": kind,
                "report_verdict": doc["mirror"]["report_verdict"],
                "error_count": doc["mirror"]["error_count"],
                "warning_count": doc["mirror"]["warning_count"],
            }
        )

    if not result_records:
        raise SystemExit(f"no mirrorable monday validation reports found under {monday_validation_root}")

    result = {
        "generated_at_utc": now_utc(),
        "contract_ref": CONTRACT_REF,
        "records": result_records,
    }
    if output_path is not None:
        write_json(output_path, result)
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
