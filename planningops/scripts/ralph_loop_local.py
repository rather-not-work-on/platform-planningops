#!/usr/bin/env python3

import argparse
import json
from pathlib import Path
import sys
from datetime import datetime, timezone

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from worker_executor import WorkerExecutionPolicy, execute_worker_command


def utc_now():
    return datetime.now(timezone.utc)


def write_json(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def append_ndjson(path: Path, data: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(data, ensure_ascii=True) + "\n")


def render_template(value: str, context: dict):
    try:
        return value.format(**context)
    except KeyError as exc:
        missing = exc.args[0]
        raise ValueError(f"worker policy template references missing key: {missing}") from exc


def resolve_worker_command(issue_number: int, mode: str, loop_id: str, runtime_ctx: dict):
    worker_policy = runtime_ctx.get("worker_policy") or {"kind": "parser_diff_dry_run"}
    if not isinstance(worker_policy, dict):
        raise ValueError("worker policy must be object")
    kind = str(worker_policy.get("kind") or "parser_diff_dry_run")
    template_ctx = {
        "issue_number": issue_number,
        "mode": mode,
        "loop_id": loop_id,
        "task_key": runtime_ctx.get("task_key", ""),
        "runtime_profile": runtime_ctx.get("selected_profile", ""),
    }

    if kind == "parser_diff_dry_run":
        command = [
            "python3",
            "planningops/scripts/parser_diff_dry_run.py",
            "--run-id",
            loop_id,
            "--mode",
            mode,
        ]
        return {"kind": kind, "command": command}

    if kind == "python_script":
        script = worker_policy.get("script")
        if not script:
            raise ValueError("worker policy kind=python_script requires 'script'")
        args = worker_policy.get("args") or []
        if not isinstance(args, list):
            raise ValueError("worker policy 'args' must be list")
        rendered = [render_template(str(token), template_ctx) for token in args]
        command = ["python3", render_template(str(script), template_ctx)] + rendered
        return {"kind": kind, "command": command}

    if kind == "shell":
        command_template = worker_policy.get("command")
        if not command_template:
            raise ValueError("worker policy kind=shell requires 'command'")
        command = ["bash", "-lc", render_template(str(command_template), template_ctx)]
        return {"kind": kind, "command": command}

    raise ValueError(f"unknown worker policy kind: {kind}")


def load_runtime_context(profile_file: Path, task_key: str):
    if not profile_file.exists():
        raise ValueError(f"runtime profile file not found: {profile_file}")

    doc = json.loads(profile_file.read_text(encoding="utf-8"))
    profiles = doc.get("profiles", {})
    if not profiles:
        raise ValueError("runtime profile file has no 'profiles' map")

    active_profile = doc.get("active_profile", "local")
    overrides = doc.get("task_overrides", {})

    default_override = overrides.get("default", {})
    task_override = overrides.get(task_key, {})

    selected_profile = task_override.get("runtime_profile") or default_override.get("runtime_profile") or active_profile
    profile_payload = profiles.get(selected_profile)
    if not profile_payload:
        raise ValueError(f"runtime profile '{selected_profile}' is not defined")

    provider_policy = task_override.get("provider_policy") or default_override.get("provider_policy") or {}
    worker_policy = task_override.get("worker_policy") or default_override.get("worker_policy") or profile_payload.get("worker_policy")
    if worker_policy is None:
        worker_policy = {"kind": "parser_diff_dry_run"}

    return {
        "profile_file": str(profile_file),
        "task_key": task_key,
        "selected_profile": selected_profile,
        "profile": profile_payload,
        "provider_policy": provider_policy,
        "worker_policy": worker_policy,
    }


def parse_int(value, field_name: str, minimum: int):
    try:
        parsed = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} must be integer") from exc
    if parsed < minimum:
        if minimum == 0:
            raise ValueError(f"{field_name} must be >= 0")
        raise ValueError(f"{field_name} must be positive integer")
    return parsed


def load_worker_task_pack_report(report_path: str | None):
    if not report_path:
        return {}
    doc_path = Path(report_path)
    if not doc_path.exists():
        raise ValueError(f"worker task-pack report not found: {doc_path}")
    doc = json.loads(doc_path.read_text(encoding="utf-8"))
    if not isinstance(doc, dict):
        raise ValueError("worker task-pack report must be object")
    return doc


def resolve_worker_execution_policy(runtime_ctx: dict, max_attempts: int, worker_task_pack_report: str | None):
    provider_policy = runtime_ctx.get("provider_policy") or {}
    max_retries = parse_int(provider_policy.get("max_retries", 0), "provider_policy.max_retries", 0)
    timeout_ms = parse_int(provider_policy.get("timeout_ms", 60000), "provider_policy.timeout_ms", 1)
    source = "runtime_context.provider_policy"

    report_doc = load_worker_task_pack_report(worker_task_pack_report)
    if report_doc:
        worker_pack = report_doc.get("worker_task_pack")
        if not isinstance(worker_pack, dict):
            raise ValueError("worker task-pack report missing worker_task_pack object")
        retry_policy = worker_pack.get("retry_policy")
        if not isinstance(retry_policy, dict):
            raise ValueError("worker task-pack missing retry_policy object")
        max_retries = parse_int(retry_policy.get("max_retries"), "worker_task_pack.retry_policy.max_retries", 0)
        timeout_ms = parse_int(worker_pack.get("timeout_ms"), "worker_task_pack.timeout_ms", 1)
        source = "worker_task_pack.report"

    policy = WorkerExecutionPolicy(
        max_retries=max_retries,
        timeout_ms=timeout_ms,
        max_attempts=parse_int(max_attempts, "max_attempts", 0),
    )
    policy.validate()
    return {
        "policy": policy,
        "source": source,
    }


def main():
    parser = argparse.ArgumentParser(description="Local Ralph Loop harness")
    parser.add_argument("--issue-number", type=int, required=True)
    parser.add_argument("--mode", choices=["dry-run", "apply"], default="dry-run")
    parser.add_argument(
        "--ecp-ref",
        default="planningops/templates/ecp-template.md",
        help="ECP reference path",
    )
    parser.add_argument(
        "--runtime-profile-file",
        default="planningops/config/runtime-profiles.json",
        help="Runtime profile catalog path",
    )
    parser.add_argument(
        "--task-key",
        default=None,
        help="Task key for per-task runtime override (default: issue-<issue-number>)",
    )
    parser.add_argument(
        "--max-attempts",
        type=int,
        default=3,
        help="Attempt-budget cap for this worker execution.",
    )
    parser.add_argument(
        "--worker-task-pack-report",
        default=None,
        help="Optional validated worker task-pack report path (takes priority over runtime provider policy).",
    )
    args = parser.parse_args()

    now = utc_now()
    date_str = now.strftime("%Y-%m-%d")
    loop_id = f"loop-{now.strftime('%Y%m%dT%H%M%SZ')}-issue-{args.issue_number}"

    base = Path(f"planningops/artifacts/loops/{date_str}/{loop_id}")
    intake_path = base / "intake-check.json"
    simulation_path = base / "simulation-report.md"
    verification_path = base / "verification-report.json"
    patch_summary_path = base / "patch-summary.md"
    transition_log_path = Path(f"planningops/artifacts/transition-log/{date_str}.ndjson")

    # Step 1: intake
    if args.issue_number <= 0:
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "intake",
                "executed_at_utc": now.isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-intake-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "Todo",
                "to_state": "Blocked",
                "transition_reason": "context.missing_input",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": now.isoformat(),
                "replanning_flag": True,
            },
        )
        print("loop failed at intake: missing_input")
        return 1

    task_key = args.task_key or f"issue-{args.issue_number}"
    try:
        runtime_ctx = load_runtime_context(Path(args.runtime_profile_file), task_key)
    except ValueError as exc:
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "runtime_context",
                "error": str(exc),
                "executed_at_utc": now.isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-runtime-context-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "Todo",
                "to_state": "Blocked",
                "transition_reason": "context.invalid_runtime_profile",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": now.isoformat(),
                "replanning_flag": True,
            },
        )
        print(f"loop failed at runtime context: {exc}")
        return 1

    try:
        execution_policy_doc = resolve_worker_execution_policy(
            runtime_ctx=runtime_ctx,
            max_attempts=args.max_attempts,
            worker_task_pack_report=args.worker_task_pack_report,
        )
    except ValueError as exc:
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "execution_policy",
                "error": str(exc),
                "executed_at_utc": now.isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-execution-policy-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "Todo",
                "to_state": "Blocked",
                "transition_reason": "context.invalid_execution_policy",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": now.isoformat(),
                "replanning_flag": True,
            },
        )
        print(f"loop failed at execution policy: {exc}")
        return 1

    policy = execution_policy_doc["policy"]
    write_json(
        intake_path,
        {
            "issue_number": args.issue_number,
            "loop_id": loop_id,
            "mode": args.mode,
            "ecp_ref": args.ecp_ref,
            "runtime_context": runtime_ctx,
            "worker_execution_policy": {
                "source": execution_policy_doc["source"],
                "max_retries": policy.max_retries,
                "timeout_ms": policy.timeout_ms,
                "max_attempts": policy.max_attempts,
            },
            "checked_at_utc": now.isoformat(),
            "result": "ok",
        },
    )

    # Step 2: context load
    ecp_path = Path(args.ecp_ref)
    if not ecp_path.exists():
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "context_load",
                "executed_at_utc": utc_now().isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-context-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "In Progress",
                "to_state": "Blocked",
                "transition_reason": "context.missing_ecp",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": utc_now().isoformat(),
                "replanning_flag": True,
            },
        )
        print("loop failed at context load: missing ecp")
        return 1

    # Step 3: execute (worker policy command)
    try:
        worker_plan = resolve_worker_command(args.issue_number, args.mode, loop_id, runtime_ctx)
    except ValueError as exc:
        reason = "missing_input"
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "execute",
                "error": str(exc),
                "executed_at_utc": utc_now().isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-worker-policy-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "In Progress",
                "to_state": "Blocked",
                "transition_reason": "context.invalid_worker_policy",
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": utc_now().isoformat(),
                "replanning_flag": True,
            },
        )
        print(f"loop failed at execute worker policy: {exc}")
        return 1

    execution_result = execute_worker_command(worker_plan["command"], policy)
    attempt_sections = []
    for row in execution_result["attempts"]:
        attempt_sections.extend(
            [
                f"### Attempt {row['attempt_index']}",
                f"- return_code: {row['return_code']}",
                f"- timed_out: {row['timed_out']}",
                f"- duration_ms: {row['duration_ms']}",
                "```text",
                row["stdout_tail"],
                row["stderr_tail"],
                "```",
                "",
            ]
        )

    simulation_path.parent.mkdir(parents=True, exist_ok=True)
    simulation_path.write_text(
        "\n".join(
            [
                f"# Simulation Report ({loop_id})",
                "",
                f"- mode: {args.mode}",
                f"- issue_number: {args.issue_number}",
                f"- task_key: {runtime_ctx['task_key']}",
                f"- runtime_profile: {runtime_ctx['selected_profile']}",
                f"- worker_policy_kind: {worker_plan['kind']}",
                f"- execute command: {' '.join(worker_plan['command'])}",
                f"- execution_policy_source: {execution_policy_doc['source']}",
                f"- max_retries: {policy.max_retries}",
                f"- timeout_ms: {policy.timeout_ms}",
                f"- max_attempts: {policy.max_attempts}",
                f"- attempts_allowed: {execution_result['attempts_allowed']}",
                f"- attempts_executed: {execution_result['attempts_executed']}",
                f"- execution_reason: {execution_result['reason_code']}",
                "",
                "## Attempt Logs",
                *attempt_sections,
            ]
        ),
        encoding="utf-8",
    )

    if execution_result["status"] != "pass":
        reason = execution_result["reason_code"]
        transition_reason = {
            "attempt_budget_exhausted": "runtime.attempt_budget_exhausted",
            "runtime_timeout_retries_exhausted": "runtime.execute_timeout",
            "runtime_error_retries_exhausted": "runtime.execute_error",
        }.get(reason, "runtime.execute_error")
        write_json(
            verification_path,
            {
                "issue_number": args.issue_number,
                "loop_id": loop_id,
                "verdict": "fail",
                "reason_code": reason,
                "stage": "execute",
                "worker_execution": execution_result,
                "executed_at_utc": utc_now().isoformat(),
            },
        )
        append_ndjson(
            transition_log_path,
            {
                "transition_id": f"{loop_id}-execute-fail",
                "run_id": loop_id,
                "card_id": args.issue_number,
                "from_state": "In Progress",
                "to_state": "Blocked",
                "transition_reason": transition_reason,
                "actor_type": "agent",
                "actor_id": "ralph-loop-local",
                "decided_at_utc": utc_now().isoformat(),
                "replanning_flag": True,
            },
        )
        print(f"loop failed at execute: {reason}")
        return 1

    # Step 4: verify
    summary_path = Path(f"planningops/artifacts/sync-summary/{loop_id}.json")
    verdict = "pass" if summary_path.exists() else "inconclusive"
    reason = "ok" if summary_path.exists() else "missing_artifact"

    write_json(
        verification_path,
        {
            "issue_number": args.issue_number,
            "loop_id": loop_id,
            "verdict": verdict,
            "reason_code": reason,
            "runtime_context": runtime_ctx,
            "worker_execution": execution_result,
            "worker_execution_policy": {
                "source": execution_policy_doc["source"],
                "max_retries": policy.max_retries,
                "timeout_ms": policy.timeout_ms,
                "max_attempts": policy.max_attempts,
            },
            "artifacts": {
                "intake_check": str(intake_path),
                "simulation_report": str(simulation_path),
                "verification_report": str(verification_path),
                "transition_log": str(transition_log_path),
                "sync_summary": str(summary_path),
            },
            "executed_at_utc": utc_now().isoformat(),
        },
    )

    # Step 5: report
    patch_summary_path.write_text(
        "\n".join(
            [
                f"# Patch Summary ({loop_id})",
                "",
                f"- issue_number: {args.issue_number}",
                f"- mode: {args.mode}",
                f"- task_key: {runtime_ctx['task_key']}",
                f"- runtime_profile: {runtime_ctx['selected_profile']}",
                f"- verdict: {verdict}",
                f"- reason_code: {reason}",
                "",
                "No code patch is applied by this local harness baseline."
                if args.mode == "dry-run"
                else "Apply mode executed pipeline and produced artifacts.",
            ]
        ),
        encoding="utf-8",
    )

    append_ndjson(
        transition_log_path,
        {
            "transition_id": f"{loop_id}-complete",
            "run_id": loop_id,
            "card_id": args.issue_number,
            "from_state": "In Progress",
            "to_state": "Done" if verdict == "pass" else "Blocked",
            "transition_reason": f"verification.{reason}",
            "actor_type": "agent",
            "actor_id": "ralph-loop-local",
            "decided_at_utc": utc_now().isoformat(),
            "replanning_flag": verdict != "pass",
        },
    )

    print(f"loop completed: verdict={verdict} reason={reason} loop_id={loop_id}")
    print(f"artifacts root: {base}")
    return 0 if verdict == "pass" else 2


if __name__ == "__main__":
    sys.exit(main())
