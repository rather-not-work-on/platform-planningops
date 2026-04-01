#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path


WORKSPACE_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_VALIDATION_ROOT = WORKSPACE_ROOT / "planningops/artifacts/validation"
DEFAULT_CONSUMER_ROOT = WORKSPACE_ROOT.parent / "monday" / "runtime-artifacts/integration/planningops-local-operator-inbox"
CONTRACT_REF = "planningops/contracts/monday-local-inbox-validation-mirror-contract.md"


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def resolve_path(raw_path: str) -> Path:
    path = Path(raw_path)
    if path.is_absolute():
        return path.resolve()
    return (WORKSPACE_ROOT / path).resolve()


def load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def require_dict(value: object, label: str) -> dict:
    if not isinstance(value, dict):
        raise SystemExit(f"{label} must be a JSON object")
    return value


def require_string(value: object, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise SystemExit(f"{label} must be a non-empty string")
    return value.strip()


def normalize_string_list(values: object) -> list[str]:
    return [str(value) for value in list(values or []) if str(value).strip()]


def resolve_optional_artifact_path(raw_path: object) -> Path | None:
    if not isinstance(raw_path, str) or not raw_path.strip():
        return None
    return Path(raw_path).expanduser().resolve()


def load_optional_json(path: Path | None) -> dict | None:
    if path is None or not path.exists():
        return None
    try:
        return load_json(path)
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None


def discover_consumer_reports(consumer_root: Path) -> list[tuple[str, Path, dict]]:
    records: list[tuple[str, Path, dict]] = []
    if not consumer_root.exists():
        return records
    for path in sorted(consumer_root.glob("*/consumer-report.json")):
        if any(part.startswith(".") or part.startswith("._") for part in path.parts):
            continue
        doc = load_optional_json(path)
        if doc is None:
            continue
        run_id = str(doc.get("run_id") or "").strip()
        generated_at_utc = str(doc.get("generated_at_utc") or "").strip()
        if not run_id or not generated_at_utc:
            continue
        records.append((generated_at_utc, path.resolve(), doc))
    records.sort(key=lambda item: (item[0], str(item[1])), reverse=True)
    return records


def select_consumer_report(*, consumer_root: Path, run_id: str | None) -> tuple[Path, dict]:
    records = discover_consumer_reports(consumer_root)
    if not records:
        raise SystemExit(f"consumer reports not found under {consumer_root}")
    if run_id is None:
        return records[0][1], records[0][2]
    for _, path, doc in records:
        if str(doc.get("run_id") or "").strip() == run_id:
            return path, doc
    raise SystemExit(f"run_id not found under {consumer_root}: {run_id}")


def build_override_kinds(launch_request: dict) -> list[str]:
    runtime_input_overrides = (
        launch_request.get("runtime_input_overrides")
        if isinstance(launch_request.get("runtime_input_overrides"), dict)
        else {}
    )
    override_kinds: list[str] = []
    if isinstance(runtime_input_overrides.get("planner_runtime_config"), str) and runtime_input_overrides.get(
        "planner_runtime_config"
    ).strip():
        override_kinds.append("planner_runtime_config")
    if isinstance(runtime_input_overrides.get("runtime_profile_file"), str) and runtime_input_overrides.get(
        "runtime_profile_file"
    ).strip():
        override_kinds.append("runtime_profile_file")
    return override_kinds


def build_mirror_doc(
    *,
    validation_root: Path,
    run_id: str,
    artifact_family: str,
    artifact_kind: str,
    latest_filename: str,
    source_artifact_path: Path | None,
    source_launch_request_path: Path | None,
    source_runtime_report_path: Path | None,
    source_consumer_report_path: Path,
    bridge_id: str | None,
    mode: str | None,
    consumer_verdict: str | None,
    consumer_status: str | None,
    planner_profile: str | None,
    launch_mode: str | None,
    local_model_route: str | None,
    has_runtime_input_overrides: bool,
    override_kinds: list[str],
    validation_dependency_paths: dict[str, str],
    payload: dict | None,
) -> tuple[dict, Path, Path]:
    latest_mirror_path = validation_root / latest_filename
    stamped_mirror_path = validation_root / f"{run_id}-{latest_filename}"
    doc = {
        "generated_at_utc": now_utc(),
        "run_id": run_id,
        "artifact_family": artifact_family,
        "artifact_kind": artifact_kind,
        "contract_ref": CONTRACT_REF,
        "artifact_paths": {
            "latest_mirror_path": str(latest_mirror_path.resolve()),
            "stamped_mirror_path": str(stamped_mirror_path.resolve()),
            "source_artifact_path": None if source_artifact_path is None else str(source_artifact_path.resolve()),
            "source_launch_request_path": None
            if source_launch_request_path is None
            else str(source_launch_request_path.resolve()),
            "source_runtime_report_path": None
            if source_runtime_report_path is None
            else str(source_runtime_report_path.resolve()),
            "source_consumer_report_path": str(source_consumer_report_path.resolve()),
        },
        "mirror": {
            "source_artifact_present": bool(source_artifact_path is not None and source_artifact_path.exists()),
            "bridge_id": bridge_id,
            "mode": mode,
            "consumer_verdict": consumer_verdict,
            "consumer_status": consumer_status,
            "planner_profile": planner_profile,
            "launch_mode": launch_mode,
            "local_model_route": local_model_route,
            "has_runtime_input_overrides": has_runtime_input_overrides,
            "override_kinds": override_kinds,
            "validation_dependency_paths": validation_dependency_paths,
            "payload": payload,
        },
    }
    return doc, latest_mirror_path, stamped_mirror_path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Mirror monday local inbox launch/runtime/consumer artifacts into planningops validation."
    )
    parser.add_argument("--validation-root", default=str(DEFAULT_VALIDATION_ROOT))
    parser.add_argument("--consumer-root", default=str(DEFAULT_CONSUMER_ROOT))
    parser.add_argument("--run-id", default=None)
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    validation_root = resolve_path(args.validation_root)
    consumer_root = resolve_path(args.consumer_root)
    output_path = None if args.output is None else resolve_path(args.output)

    if not (WORKSPACE_ROOT / CONTRACT_REF).exists():
        raise SystemExit(f"validation mirror contract missing: {CONTRACT_REF}")

    consumer_report_path, consumer_report_doc = select_consumer_report(consumer_root=consumer_root, run_id=args.run_id)
    artifact_paths = require_dict(consumer_report_doc.get("artifact_paths"), "consumer report artifact paths")
    launch_request = require_dict(consumer_report_doc.get("launch_request"), "consumer launch request")

    run_id = require_string(consumer_report_doc.get("run_id"), "consumer report run_id")
    bridge_id = str(consumer_report_doc.get("bridge_id") or "").strip() or None
    mode = str(consumer_report_doc.get("mode") or "").strip() or None
    consumer_verdict = str(consumer_report_doc.get("verdict") or "").strip() or None
    consumer_status = str(consumer_report_doc.get("consumer_status") or "").strip() or None
    planner_profile = str(launch_request.get("planner_profile") or "").strip() or None
    launch_mode = str(launch_request.get("launch_mode") or "").strip() or None
    local_model_route = str(launch_request.get("local_model_route") or "").strip() or None
    override_kinds = build_override_kinds(launch_request)
    has_runtime_input_overrides = bool(override_kinds)

    launch_request_path = resolve_optional_artifact_path(artifact_paths.get("launch_request_path"))
    runtime_report_path = resolve_optional_artifact_path(artifact_paths.get("runtime_report_path"))
    consumer_payload_path = consumer_report_path.resolve()
    launch_request_payload = load_optional_json(launch_request_path)
    runtime_report_payload = load_optional_json(runtime_report_path)

    inbox_payload_latest_path = str((validation_root / "monday-local-operator-inbox-payload.json").resolve())
    launch_request_latest_path = str((validation_root / "monday-local-inbox-launch-request.json").resolve())
    runtime_report_latest_path = str((validation_root / "monday-local-inbox-runtime-report.json").resolve())

    launch_request_doc, launch_request_latest, launch_request_stamped = build_mirror_doc(
        validation_root=validation_root,
        run_id=run_id,
        artifact_family="monday_local_inbox_launch_request",
        artifact_kind="request",
        latest_filename="monday-local-inbox-launch-request.json",
        source_artifact_path=launch_request_path,
        source_launch_request_path=launch_request_path,
        source_runtime_report_path=runtime_report_path,
        source_consumer_report_path=consumer_payload_path,
        bridge_id=bridge_id,
        mode=mode,
        consumer_verdict=consumer_verdict,
        consumer_status=consumer_status,
        planner_profile=planner_profile,
        launch_mode=launch_mode,
        local_model_route=local_model_route,
        has_runtime_input_overrides=has_runtime_input_overrides,
        override_kinds=override_kinds,
        validation_dependency_paths={
            "monday_local_operator_inbox_payload": inbox_payload_latest_path,
        },
        payload=launch_request_payload,
    )
    runtime_report_doc, runtime_report_latest, runtime_report_stamped = build_mirror_doc(
        validation_root=validation_root,
        run_id=run_id,
        artifact_family="monday_local_inbox_runtime_report",
        artifact_kind="report",
        latest_filename="monday-local-inbox-runtime-report.json",
        source_artifact_path=runtime_report_path,
        source_launch_request_path=launch_request_path,
        source_runtime_report_path=runtime_report_path,
        source_consumer_report_path=consumer_payload_path,
        bridge_id=bridge_id,
        mode=mode,
        consumer_verdict=consumer_verdict,
        consumer_status=consumer_status,
        planner_profile=planner_profile,
        launch_mode=launch_mode,
        local_model_route=local_model_route,
        has_runtime_input_overrides=has_runtime_input_overrides,
        override_kinds=override_kinds,
        validation_dependency_paths={
            "monday_local_operator_inbox_payload": inbox_payload_latest_path,
            "monday_local_inbox_launch_request": launch_request_latest_path,
        },
        payload=runtime_report_payload,
    )
    consumer_report_doc_mirror, consumer_report_latest, consumer_report_stamped = build_mirror_doc(
        validation_root=validation_root,
        run_id=run_id,
        artifact_family="monday_local_inbox_consumer_report",
        artifact_kind="report",
        latest_filename="monday-local-inbox-consumer-report.json",
        source_artifact_path=consumer_payload_path,
        source_launch_request_path=launch_request_path,
        source_runtime_report_path=runtime_report_path,
        source_consumer_report_path=consumer_payload_path,
        bridge_id=bridge_id,
        mode=mode,
        consumer_verdict=consumer_verdict,
        consumer_status=consumer_status,
        planner_profile=planner_profile,
        launch_mode=launch_mode,
        local_model_route=local_model_route,
        has_runtime_input_overrides=has_runtime_input_overrides,
        override_kinds=override_kinds,
        validation_dependency_paths={
            "monday_local_operator_inbox_payload": inbox_payload_latest_path,
            "monday_local_inbox_launch_request": launch_request_latest_path,
            "monday_local_inbox_runtime_report": runtime_report_latest_path,
        },
        payload=consumer_report_doc,
    )

    for path, doc in (
        (launch_request_latest, launch_request_doc),
        (launch_request_stamped, launch_request_doc),
        (runtime_report_latest, runtime_report_doc),
        (runtime_report_stamped, runtime_report_doc),
        (consumer_report_latest, consumer_report_doc_mirror),
        (consumer_report_stamped, consumer_report_doc_mirror),
    ):
        write_json(path, doc)

    result = {
        "generated_at_utc": now_utc(),
        "run_id": run_id,
        "contract_ref": CONTRACT_REF,
        "records": [
            {
                "artifact_family": "monday_local_inbox_launch_request",
                "latest_mirror_path": str(launch_request_latest.resolve()),
                "stamped_mirror_path": str(launch_request_stamped.resolve()),
                "source_artifact_present": launch_request_doc["mirror"]["source_artifact_present"],
            },
            {
                "artifact_family": "monday_local_inbox_runtime_report",
                "latest_mirror_path": str(runtime_report_latest.resolve()),
                "stamped_mirror_path": str(runtime_report_stamped.resolve()),
                "source_artifact_present": runtime_report_doc["mirror"]["source_artifact_present"],
            },
            {
                "artifact_family": "monday_local_inbox_consumer_report",
                "latest_mirror_path": str(consumer_report_latest.resolve()),
                "stamped_mirror_path": str(consumer_report_stamped.resolve()),
                "source_artifact_present": consumer_report_doc_mirror["mirror"]["source_artifact_present"],
            },
        ],
    }
    if output_path is not None:
        write_json(output_path, result)
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
