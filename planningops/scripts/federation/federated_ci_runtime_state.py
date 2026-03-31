#!/usr/bin/env python3

from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import json
import re
from typing import Any


DETERMINISTIC_RULE = (
    "contract-conformance->contract, "
    "provider-profile/provider-gateway-ready/o11y-replay->infra, "
    "runtime-handoff/runtime-operations-ready->runtime, "
    "federated-conformance->federation, "
    "loop-guardrails->policy"
)

RUN_ID_DATE_RE = re.compile(r"^\d{8}(?:T\d{6}Z)?$")
RUN_ID_RERUN_RE = re.compile(r"^rerun\d+$")


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path, default: dict[str, Any] | None = None) -> dict[str, Any]:
    if not path.exists():
        return {} if default is None else dict(default)
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2), encoding="utf-8")


def is_summary_document(doc: dict[str, Any]) -> bool:
    return (
        isinstance(doc, dict)
        and isinstance(doc.get("run_id"), str)
        and isinstance(doc.get("checks"), list)
        and isinstance(doc.get("required_checks"), list)
    )


def infer_family_from_run_id(run_id: str) -> str:
    parts = [part for part in run_id.split("-") if part]
    while parts and (RUN_ID_RERUN_RE.match(parts[-1]) or RUN_ID_DATE_RE.match(parts[-1])):
        parts.pop()
    return "-".join(parts) if parts else run_id


def summary_timestamp(doc: dict[str, Any]) -> str:
    for key in ("generated_at_utc", "finished_at_utc", "started_at_utc"):
        value = doc.get(key)
        if isinstance(value, str) and value.strip():
            return value
    return ""


def build_check_record(
    *,
    name: str,
    domain: str,
    exit_code: int,
    stdout_log: str,
    stderr_log: str,
    result: str | None = None,
) -> dict[str, Any]:
    check = {
        "name": name,
        "domain": domain,
        "exit_code": exit_code,
        "verdict": "pass" if exit_code == 0 else "fail",
        "stdout_log": stdout_log,
        "stderr_log": stderr_log,
    }
    if result is not None:
        check["result"] = result
    return check


def finalize_summary_doc(
    doc: dict[str, Any],
    *,
    status: str,
    shell_exit_code: int | None = None,
    generated_at_utc: str | None = None,
    finished_at_utc: str | None = None,
) -> dict[str, Any]:
    checks = list(doc.get("checks") or [])
    required_checks = list(doc.get("required_checks") or [])
    check_names = [str(check.get("name") or "") for check in checks]
    failures = [check for check in checks if check.get("verdict") == "fail"]
    missing_required = [name for name in required_checks if name not in check_names]

    finalized = dict(doc)
    finalized["generated_at_utc"] = generated_at_utc or now_utc()
    finalized["finished_at_utc"] = finished_at_utc or now_utc()
    finalized["overall_status"] = status
    finalized["check_count"] = len(checks)
    finalized["missing_required_checks"] = missing_required
    finalized["failure_classification"] = {
        "count": len(failures),
        "domains": sorted({failure.get("domain") for failure in failures}),
        "deterministic_rule": DETERMINISTIC_RULE,
    }
    finalized["verdict"] = (
        "pass"
        if status == "complete" and not failures and not missing_required
        else "fail"
    )
    if shell_exit_code is not None:
        finalized["shell_exit_code"] = shell_exit_code
    return finalized
