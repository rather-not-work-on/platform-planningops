#!/usr/bin/env python3

from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
import re
import sys


SCRIPTS_ROOT = Path(__file__).resolve().parents[2]
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from planning_context import parse_metadata


HIGH_VALUE_READY_STATES = {"ready-contract", "ready-implementation"}
EXECUTION_KIND_EXECUTABLE = "executable"
EXECUTION_KIND_INVENTORY = "inventory"
EXECUTION_KIND_ALIASES = {
    "executable": EXECUTION_KIND_EXECUTABLE,
    "execute": EXECUTION_KIND_EXECUTABLE,
    "real": EXECUTION_KIND_EXECUTABLE,
    "inventory": EXECUTION_KIND_INVENTORY,
    "inventory_only": EXECUTION_KIND_INVENTORY,
    "stock_seed": EXECUTION_KIND_INVENTORY,
    "seed": EXECUTION_KIND_INVENTORY,
}


def parse_depends_on(issue_body: str):
    deps = set()
    for line in issue_body.splitlines():
        if "depends_on:" in line:
            deps.update(int(n) for n in re.findall(r"#(\d+)", line))
    return sorted(deps)


def normalize_execution_kind(raw: str | None, default: str = EXECUTION_KIND_EXECUTABLE):
    if raw is None:
        return default, None
    value = str(raw).strip().strip("`")
    if not value:
        return default, None
    key = re.sub(r"[\s-]+", "_", value.lower())
    mapped = EXECUTION_KIND_ALIASES.get(key)
    if mapped:
        return mapped, None
    return None, f"unsupported execution_kind: {value}"


def parse_execution_kind(issue_body: str, default: str = EXECUTION_KIND_EXECUTABLE):
    metadata = parse_metadata(issue_body, keys=["execution_kind"])
    raw_value = metadata.get("execution_kind")
    if raw_value is None:
        return default
    parsed, error = normalize_execution_kind(raw_value, default=default)
    return parsed or default


def is_executable_execution_kind(execution_kind: str):
    normalized, _ = normalize_execution_kind(execution_kind, default=EXECUTION_KIND_EXECUTABLE)
    return normalized == EXECUTION_KIND_EXECUTABLE


def parse_plan_item_id(issue_body: str):
    metadata = parse_metadata(issue_body, keys=["plan_item_id"])
    value = (metadata.get("plan_item_id") or "").strip()
    return value or None


def parse_bool_token(raw: str):
    v = raw.strip().lower()
    if v in {"1", "true", "yes", "y", "on"}:
        return True
    if v in {"0", "false", "no", "n", "off"}:
        return False
    return None


def parse_selector_hints(issue_body: str):
    simulation_required = False
    uncertainty_level = None
    for line in issue_body.splitlines():
        m_sim = re.match(r"\s*simulation_required\s*:\s*(\S+)\s*$", line, re.IGNORECASE)
        if m_sim:
            parsed = parse_bool_token(m_sim.group(1))
            if parsed is not None:
                simulation_required = parsed
            continue

        m_unc = re.match(r"\s*uncertainty_level\s*:\s*(\S+)\s*$", line, re.IGNORECASE)
        if m_unc:
            raw = m_unc.group(1).strip().lower()
            if raw in {"low", "medium", "high", "critical"}:
                uncertainty_level = raw
    return {
        "simulation_required": simulation_required,
        "uncertainty_level": uncertainty_level,
    }


def parse_blueprint_refs(issue_body: str):
    required_keys = [
        "interface_contract_refs",
        "package_topology_ref",
        "dependency_manifest_ref",
        "file_plan_ref",
    ]
    refs = {}
    for key in required_keys:
        refs[key] = None
        for line in issue_body.splitlines():
            m = re.match(rf"\s*{key}\s*:\s*(.+)\s*$", line, re.IGNORECASE)
            if not m:
                continue
            value = m.group(1).strip()
            if value:
                refs[key] = value
            break

    missing = [k for k in required_keys if not refs.get(k)]
    return {
        "refs": refs,
        "missing": missing,
        "complete": len(missing) == 0,
    }


def normalize_candidates(items, allowed_workflow_states, high_value_ready_states=None):
    ready_states = high_value_ready_states or HIGH_VALUE_READY_STATES
    candidates = []
    for it in items:
        content = it.get("content", {})
        if content.get("type") != "Issue":
            continue
        if it.get("status") != "Todo":
            continue

        workflow_state = it.get("workflow_state")
        if workflow_state not in allowed_workflow_states:
            continue

        issue_repo = content.get("repository")
        number = content.get("number")
        if not issue_repo or not number:
            continue

        target_repo = it.get("target_repo") or issue_repo
        order = it.get("execution_order") or 0
        execution_kind, _ = normalize_execution_kind(it.get("execution_kind"), default=EXECUTION_KIND_EXECUTABLE)
        if not is_executable_execution_kind(execution_kind):
            continue
        candidates.append(
            {
                "item": it,
                "number": number,
                "order": order,
                "status": it.get("status"),
                "initiative": it.get("initiative"),
                "component": it.get("component"),
                "loop_profile": it.get("loop_profile"),
                "workflow_state": workflow_state,
                "issue_repo": issue_repo,
                "target_repo": target_repo,
                "execution_kind": execution_kind,
            }
        )

    candidates.sort(
        key=lambda x: (
            0 if x.get("workflow_state") in ready_states else 1,
            x["order"],
            x["number"],
        )
    )
    return candidates


def build_selection_trace(candidates, selected, attempts, allowed_workflow_states, high_value_ready_states=None, default_attempt_budget=None):
    ready_states = high_value_ready_states or HIGH_VALUE_READY_STATES
    selected_ref = None
    if selected is not None:
        selected_ref = {
            "number": selected.get("number"),
            "order": selected.get("order"),
            "status": selected.get("status"),
            "workflow_state": selected.get("workflow_state"),
            "issue_repo": selected.get("issue_repo"),
            "target_repo": selected.get("target_repo"),
            "component": selected.get("component"),
            "loop_profile": selected.get("loop_profile"),
            "initiative": selected.get("initiative"),
            "plan_item_id": selected.get("plan_item_id"),
            "execution_kind": selected.get("execution_kind", EXECUTION_KIND_EXECUTABLE),
            "depends_on": selected.get("deps", []),
            "attempt_budget": selected.get("attempt_budget", default_attempt_budget or {}),
            "simulation_required": selected.get("simulation_required", False),
            "uncertainty_level": selected.get("uncertainty_level"),
            "blueprint_refs": selected.get("blueprint_refs", {}),
            "blueprint_complete": selected.get("blueprint_complete", True),
        }

    return {
        "selection_policy": {
            "name": "high_value_ready_first",
            "ready_workflow_states": sorted(ready_states),
            "tie_breaker": ["execution_order_asc", "issue_number_asc"],
        },
        "allowed_workflow_states": sorted(allowed_workflow_states),
        "candidate_count": len(candidates),
        "candidates": [
            {
                "number": c.get("number"),
                "order": c.get("order"),
                "status": c.get("status"),
                "workflow_state": c.get("workflow_state"),
                "issue_repo": c.get("issue_repo"),
                "target_repo": c.get("target_repo"),
                "component": c.get("component"),
                "loop_profile": c.get("loop_profile"),
                "initiative": c.get("initiative"),
                "plan_item_id": c.get("plan_item_id"),
                "execution_kind": c.get("execution_kind", EXECUTION_KIND_EXECUTABLE),
                "simulation_required": c.get("simulation_required", False),
                "uncertainty_level": c.get("uncertainty_level"),
                "blueprint_refs": c.get("blueprint_refs", {}),
                "blueprint_complete": c.get("blueprint_complete", True),
            }
            for c in candidates
        ],
        "attempts": attempts,
        "selected": selected_ref,
    }


def build_replenishment_candidates(
    issue_num: int,
    payload: dict,
    selected: dict,
    verification_path: Path,
    payload_path: Path,
    watchdog_path: Path,
    replan_decision_path: Path | None,
):
    verdict = str(payload.get("last_verdict", "")).lower()
    reason_code = str(payload.get("reason_code", "")).strip() or "unknown_reason"
    trigger = bool(payload.get("replanning_triggered")) or bool(payload.get("auto_paused"))
    if verdict not in {"fail", "inconclusive"} and not trigger:
        return []

    evidence_refs = [str(verification_path), str(payload_path), str(watchdog_path)]
    if replan_decision_path:
        evidence_refs.append(str(replan_decision_path))

    target_repo = selected.get("target_repo") or selected.get("issue_repo") or ""
    candidate = {
        "candidate_id": f"issue-{issue_num}-follow-up",
        "title": f"Recovery follow-up for issue #{issue_num} ({reason_code})",
        "target_repo": target_repo,
        "execution_kind": EXECUTION_KIND_EXECUTABLE,
        "depends_on": [issue_num],
        "acceptance_criteria": [
            f"Root cause for `{reason_code}` is documented with evidence.",
            "Contract/plan references are updated before resuming implementation.",
            "A rerun exits escalation state without repeating the previous trigger.",
        ],
        "evidence_refs": evidence_refs,
        "generated_from": {
            "issue_number": issue_num,
            "verdict": verdict,
            "reason_code": reason_code,
        },
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    return [candidate]


def ensure_text_field(run_fn, owner: str, project_num: int, field_name: str):
    rc, out, err = run_fn(["gh", "project", "field-list", str(project_num), "--owner", owner, "--format", "json"])
    if rc != 0:
        raise RuntimeError(f"failed field-list: {err}")
    doc = json.loads(out)
    for f in doc.get("fields", []):
        if f.get("name") == field_name:
            return f.get("id")

    rc2, out2, err2 = run_fn(
        [
            "gh",
            "project",
            "field-create",
            str(project_num),
            "--owner",
            owner,
            "--name",
            field_name,
            "--data-type",
            "TEXT",
            "--format",
            "json",
            "--jq",
            ".id",
        ]
    )
    if rc2 != 0:
        raise RuntimeError(f"failed field-create {field_name}: {err2}")
    return out2.strip()


def ensure_single_select_field(run_fn, owner: str, project_num: int, field_name: str, option_names):
    rc, out, err = run_fn(["gh", "project", "field-list", str(project_num), "--owner", owner, "--format", "json"])
    if rc != 0:
        raise RuntimeError(f"failed field-list: {err}")
    doc = json.loads(out)
    for f in doc.get("fields", []):
        if f.get("name") != field_name:
            continue
        options = {o.get("name"): o.get("id") for o in (f.get("options") or []) if o.get("name") and o.get("id")}
        missing = [opt for opt in option_names if opt not in options]
        if missing:
            raise RuntimeError(f"field '{field_name}' missing options: {missing}")
        return f.get("id"), options

    rc2, out2, err2 = run_fn(
        [
            "gh",
            "project",
            "field-create",
            str(project_num),
            "--owner",
            owner,
            "--name",
            field_name,
            "--data-type",
            "SINGLE_SELECT",
            "--single-select-options",
            ",".join(option_names),
            "--format",
            "json",
        ]
    )
    if rc2 != 0:
        raise RuntimeError(f"failed field-create {field_name}: {err2}")
    field_doc = json.loads(out2)
    options = {o.get("name"): o.get("id") for o in (field_doc.get("options") or []) if o.get("name") and o.get("id")}
    return field_doc.get("id"), options


def determine_loop_profile(selected: dict, payload: dict, control_repo: str):
    if payload.get("replanning_triggered"):
        return "L5 Recovery-Replan"

    workflow_state = selected.get("workflow_state")
    target_repo = selected.get("target_repo") or selected.get("issue_repo")
    if workflow_state == "ready-contract":
        simulation_required = bool(selected.get("simulation_required")) or bool(payload.get("simulation_required"))
        uncertainty_level = str(selected.get("uncertainty_level") or payload.get("uncertainty_level") or "").lower()
        if simulation_required or uncertainty_level in {"medium", "high", "critical"}:
            return "L2 Simulation"
        return "L1 Contract-Clarification"
    if workflow_state == "ready-implementation":
        if target_repo and target_repo != control_repo:
            return "L4 Integration-Reconcile"
        return "L3 Implementation-TDD"
    if workflow_state == "blocked":
        return "L5 Recovery-Replan"
    return "L1 Contract-Clarification"
