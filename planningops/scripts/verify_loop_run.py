#!/usr/bin/env python3

import argparse
import json
from collections import Counter
from pathlib import Path
import sys
from datetime import datetime, timezone

REQUIRED_TRANSITION_KEYS = [
    "transition_id",
    "run_id",
    "card_id",
    "from_state",
    "to_state",
    "transition_reason",
    "actor_type",
    "actor_id",
    "decided_at_utc",
    "replanning_flag",
]

REQUIRED_LOOP_ARTIFACTS = [
    "intake-check.json",
    "simulation-report.md",
    "verification-report.json",
    "execution-attempts.json",
    "patch-summary.md",
]

ALLOWED_VERDICTS = {"pass", "fail", "inconclusive"}


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_ndjson(path: Path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        rows.append(json.loads(line))
    return rows


def append_error(errors, message: str):
    if message not in errors:
        errors.append(message)


def _resolve_ref(root_schema, ref):
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ValueError(f"unsupported schema ref: {ref}")
    cursor = root_schema
    for token in ref[2:].split("/"):
        cursor = cursor[token]
    return cursor


def _matches_type(value, type_name):
    if type_name == "object":
        return isinstance(value, dict)
    if type_name == "array":
        return isinstance(value, list)
    if type_name == "string":
        return isinstance(value, str)
    if type_name == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    if type_name == "boolean":
        return isinstance(value, bool)
    if type_name == "null":
        return value is None
    return True


def _type_includes(expected_type, type_name: str):
    if isinstance(expected_type, list):
        return type_name in expected_type
    return expected_type == type_name


def _is_valid_type(value, expected_type):
    if isinstance(expected_type, list):
        return any(_matches_type(value, t) for t in expected_type)
    return _matches_type(value, expected_type)


def _validate_schema_value(value, schema, root_schema, path: str, errors):
    if not isinstance(schema, dict):
        return

    if "$ref" in schema:
        schema = _resolve_ref(root_schema, schema["$ref"])

    expected_type = schema.get("type")
    if expected_type and not _is_valid_type(value, expected_type):
        append_error(errors, f"execution_attempts_schema: {path} expected type {expected_type}")
        return

    if "enum" in schema and value not in schema["enum"]:
        append_error(errors, f"execution_attempts_schema: {path} invalid enum value: {value}")

    if _type_includes(expected_type, "string") and isinstance(value, str):
        min_len = schema.get("minLength")
        if isinstance(min_len, int) and len(value) < min_len:
            append_error(errors, f"execution_attempts_schema: {path} minLength violation")
        pattern = schema.get("pattern")
        if pattern and not isinstance(pattern, str):
            append_error(errors, f"execution_attempts_schema: {path} invalid pattern")

    if _type_includes(expected_type, "integer") and isinstance(value, int) and not isinstance(value, bool):
        minimum = schema.get("minimum")
        if isinstance(minimum, int) and value < minimum:
            append_error(errors, f"execution_attempts_schema: {path} below minimum {minimum}")

    if _type_includes(expected_type, "array") and isinstance(value, list):
        min_items = schema.get("minItems")
        if isinstance(min_items, int) and len(value) < min_items:
            append_error(errors, f"execution_attempts_schema: {path} minItems violation")
        item_schema = schema.get("items")
        if isinstance(item_schema, dict):
            for idx, row in enumerate(value):
                _validate_schema_value(row, item_schema, root_schema, f"{path}[{idx}]", errors)

    if _type_includes(expected_type, "object") and isinstance(value, dict):
        required = schema.get("required", [])
        props = schema.get("properties", {})
        for key in required:
            if key not in value:
                append_error(errors, f"execution_attempts_schema: {path}.{key} is required")
        if schema.get("additionalProperties") is False:
            for key in value.keys():
                if key not in props:
                    append_error(errors, f"execution_attempts_schema: {path} unexpected key: {key}")
        for key, prop_schema in props.items():
            if key in value:
                _validate_schema_value(value[key], prop_schema, root_schema, f"{path}.{key}", errors)


def validate_schema(doc, schema_doc):
    errors = []
    if not isinstance(doc, dict):
        return ["execution_attempts_schema: document must be object"]
    if not isinstance(schema_doc, dict):
        return ["execution_attempts_schema: schema document must be object"]
    _validate_schema_value(doc, schema_doc, schema_doc, "$", errors)
    return errors


def validate_execution_attempt_semantics(evidence):
    errors = []
    if not isinstance(evidence, dict):
        return ["execution_attempts_semantics: evidence must be object"]

    attempts = evidence.get("attempts")
    if not isinstance(attempts, list):
        return ["execution_attempts_semantics: attempts must be list"]

    attempts_executed = evidence.get("attempts_executed")
    if not isinstance(attempts_executed, int):
        append_error(errors, "execution_attempts_semantics: attempts_executed must be integer")
    else:
        if attempts_executed != len(attempts):
            append_error(
                errors,
                "execution_attempts_semantics: attempts_executed must match attempts length",
            )

    attempts_allowed = evidence.get("attempts_allowed")
    if isinstance(attempts_allowed, int) and isinstance(attempts_executed, int):
        if attempts_executed > attempts_allowed:
            append_error(errors, "execution_attempts_semantics: attempts_executed exceeds attempts_allowed")

    retry_cap_attempts = evidence.get("retry_cap_attempts")
    if isinstance(retry_cap_attempts, int) and isinstance(attempts_allowed, int):
        if attempts_allowed > retry_cap_attempts:
            append_error(errors, "execution_attempts_semantics: attempts_allowed exceeds retry_cap_attempts")

    if attempts:
        last = attempts[-1]
        if not isinstance(last, dict):
            append_error(errors, "execution_attempts_semantics: final attempt must be object")
        else:
            status = evidence.get("status")
            if status == "pass":
                if last.get("timed_out") is True:
                    append_error(errors, "execution_attempts_semantics: pass status cannot end in timeout")
                if last.get("return_code") != 0:
                    append_error(errors, "execution_attempts_semantics: pass status requires return_code=0")

            timed_out = evidence.get("timed_out")
            if isinstance(timed_out, bool) and timed_out != bool(last.get("timed_out")):
                append_error(errors, "execution_attempts_semantics: timed_out must match final attempt")

            final_return_code = evidence.get("final_return_code")
            if final_return_code != last.get("return_code"):
                append_error(
                    errors,
                    "execution_attempts_semantics: final_return_code must match final attempt return_code",
                )

    return errors


def classify_reason(errors):
    if any(err.startswith("execution_attempts_schema:") or err.startswith("execution_attempts_semantics:") for err in errors):
        return "execution_attempt_evidence_invalid"
    if any(err.startswith("verdict_consistency:") for err in errors):
        return "verdict_consistency_error"
    return "schema_or_artifact_error"


def main():
    parser = argparse.ArgumentParser(description="Verify loop artifacts and transition-log schema")
    parser.add_argument("--loop-dir", required=True)
    parser.add_argument("--transition-log", required=True)
    parser.add_argument("--output", default="planningops/artifacts/verification/latest-verification.json")
    parser.add_argument("--project-payload", default="planningops/artifacts/verification/latest-project-payload.json")
    parser.add_argument(
        "--execution-attempts-schema",
        default="planningops/schemas/execution-attempts.schema.json",
        help="Schema used to validate execution-attempt evidence",
    )
    args = parser.parse_args()

    loop_dir = Path(args.loop_dir)
    transition_log = Path(args.transition_log)
    out_path = Path(args.output)
    payload_path = Path(args.project_payload)
    schema_path = Path(args.execution_attempts_schema)

    errors = []

    for name in REQUIRED_LOOP_ARTIFACTS:
        if not (loop_dir / name).exists():
            append_error(errors, f"missing artifact: {name}")

    if not transition_log.exists():
        append_error(errors, "missing transition log")
        rows = []
    else:
        try:
            rows = load_ndjson(transition_log)
        except Exception as exc:  # noqa: BLE001
            append_error(errors, f"transition log invalid: {exc}")
            rows = []
        for idx, row in enumerate(rows):
            if not isinstance(row, dict):
                append_error(errors, f"transition row[{idx}] must be object")
                continue
            for key in REQUIRED_TRANSITION_KEYS:
                if key not in row:
                    append_error(errors, f"transition row[{idx}] missing key: {key}")

    verification_doc = {}
    verification_path = loop_dir / "verification-report.json"
    if verification_path.exists():
        try:
            verification_doc = load_json(verification_path)
            if not isinstance(verification_doc, dict):
                append_error(errors, "verification report must be object")
                verification_doc = {}
        except Exception as exc:  # noqa: BLE001
            append_error(errors, f"verification report invalid: {exc}")
            verification_doc = {}

    execution_attempts_doc = {}
    execution_attempts_path = loop_dir / "execution-attempts.json"
    if execution_attempts_path.exists():
        try:
            execution_attempts_doc = load_json(execution_attempts_path)
        except Exception as exc:  # noqa: BLE001
            append_error(errors, f"execution attempts artifact invalid: {exc}")
            execution_attempts_doc = {}

    if not schema_path.exists():
        append_error(errors, f"missing execution-attempts schema: {schema_path}")
        schema_doc = {}
    else:
        try:
            schema_doc = load_json(schema_path)
        except Exception as exc:  # noqa: BLE001
            append_error(errors, f"execution-attempts schema invalid: {exc}")
            schema_doc = {}

    if execution_attempts_doc and schema_doc:
        for err in validate_schema(execution_attempts_doc, schema_doc):
            append_error(errors, err)
        for err in validate_execution_attempt_semantics(execution_attempts_doc):
            append_error(errors, err)
    else:
        append_error(errors, "execution_attempts_semantics: missing execution-attempt evidence")

    loop_report_verdict = str(verification_doc.get("verdict", "inconclusive"))
    loop_report_reason = str(verification_doc.get("reason_code", "unknown"))
    if loop_report_verdict not in ALLOWED_VERDICTS:
        append_error(errors, f"verdict_consistency: invalid loop verdict: {loop_report_verdict}")

    loop_worker_execution = verification_doc.get("worker_execution")
    if not isinstance(loop_worker_execution, dict):
        append_error(errors, "verdict_consistency: verification report missing worker_execution")
    elif execution_attempts_doc and loop_worker_execution != execution_attempts_doc:
        append_error(errors, "verdict_consistency: worker_execution mismatch with execution-attempt artifact")

    if loop_report_verdict == "pass":
        if loop_report_reason != "ok":
            append_error(errors, "verdict_consistency: pass verdict requires reason_code=ok")
        if execution_attempts_doc and execution_attempts_doc.get("status") != "pass":
            append_error(errors, "verdict_consistency: pass verdict requires execution status=pass")
        sync_summary_path = (
            verification_doc.get("artifacts", {}).get("sync_summary")
            if isinstance(verification_doc.get("artifacts"), dict)
            else None
        )
        if not sync_summary_path:
            append_error(errors, "verdict_consistency: pass verdict requires sync_summary artifact path")
        elif not Path(str(sync_summary_path)).exists():
            append_error(errors, "verdict_consistency: pass verdict requires existing sync_summary artifact")

    verdict = loop_report_verdict if loop_report_verdict in ALLOWED_VERDICTS else "fail"
    reason = loop_report_reason
    if errors:
        verdict = "fail"
        reason = classify_reason(errors)

    current_run_id = verification_doc.get("loop_id")
    current_card_id = verification_doc.get("issue_number")

    scoped_rows = rows
    if current_run_id:
        scoped_rows = [r for r in rows if r.get("run_id") == current_run_id]
    elif current_card_id is not None:
        scoped_rows = [r for r in rows if r.get("card_id") == current_card_id]

    reason_counts = Counter(row.get("transition_reason", "") for row in scoped_rows)
    repeated_reason_trigger = any(cnt >= 3 for cnt in reason_counts.values())
    replanning_flag_trigger = any(bool(row.get("replanning_flag")) for row in scoped_rows)
    inconclusive_trigger = verdict == "inconclusive"

    replanning_triggered = repeated_reason_trigger or replanning_flag_trigger or inconclusive_trigger

    result = {
        "executed_at_utc": datetime.now(timezone.utc).isoformat(),
        "loop_dir": str(loop_dir),
        "transition_log": str(transition_log),
        "execution_attempts_schema": str(schema_path),
        "verdict": verdict,
        "reason_code": reason,
        "loop_report": {
            "verdict": loop_report_verdict,
            "reason_code": loop_report_reason,
        },
        "errors": errors,
        "trigger_detection": {
            "scoped_row_count": len(scoped_rows),
            "repeated_reason_trigger": repeated_reason_trigger,
            "replanning_flag_trigger": replanning_flag_trigger,
            "inconclusive_trigger": inconclusive_trigger,
            "replanning_triggered": replanning_triggered,
        },
    }

    project_payload = {
        "status_update": "Done" if verdict == "pass" else "Blocked",
        "last_verdict": verdict,
        "reason_code": reason,
        "replanning_triggered": replanning_triggered,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(result, ensure_ascii=True, indent=2), encoding="utf-8")

    payload_path.parent.mkdir(parents=True, exist_ok=True)
    payload_path.write_text(json.dumps(project_payload, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"verification result: {out_path}")
    print(f"project payload: {payload_path}")
    print(f"verdict={verdict} reason={reason} replanning_triggered={replanning_triggered}")

    return 0 if verdict == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
