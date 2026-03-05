#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_STOCK_POLICY_FILE = Path("planningops/config/backlog-stock-policy.json")
DEFAULT_OUTPUT_FILE = Path("planningops/artifacts/validation/backlog-stock-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(args):
    cp = subprocess.run(args, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path, default):
    if not path.exists():
        return default
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=True, indent=2), encoding="utf-8")


def parse_depends_on(issue_body: str):
    deps = set()
    for line in issue_body.splitlines():
        if "depends_on:" in line:
            deps.update(int(n) for n in re.findall(r"#(\d+)", line))
    return sorted(deps)


def parse_issue_ref_to_int(value):
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        stripped = value.strip()
        if stripped.isdigit():
            return int(stripped)
        match = re.match(r"#(\d+)$", stripped)
        if match:
            return int(match.group(1))
    return None


def normalize_replenishment_depends(depends_raw):
    if depends_raw is None:
        return None, "depends_on is required"
    if not isinstance(depends_raw, list):
        return None, "depends_on must be a list"

    normalized = []
    invalid = []
    for dep in depends_raw:
        parsed = parse_issue_ref_to_int(dep)
        if parsed is None:
            invalid.append(dep)
            continue
        normalized.append(parsed)
    if invalid:
        return None, f"depends_on contains invalid values: {invalid}"
    return sorted(set(normalized)), None


def normalize_acceptance_criteria(value):
    if not isinstance(value, list):
        return None, "acceptance_criteria must be a list"
    normalized = [str(x).strip() for x in value if str(x).strip()]
    if not normalized:
        return None, "acceptance_criteria must include at least one checklist item"
    return normalized, None


def normalize_evidence_refs(candidate):
    refs = candidate.get("evidence_refs")
    if refs is None and candidate.get("evidence_ref") is not None:
        refs = [candidate.get("evidence_ref")]
    if refs is None:
        return []
    if isinstance(refs, list):
        return [str(x).strip() for x in refs if str(x).strip()]
    if isinstance(refs, str) and refs.strip():
        return [refs.strip()]
    return []


def render_issue_body_baseline(candidate):
    depends = candidate.get("depends_on", [])
    depends_text = ", ".join(f"#{d}" for d in depends) if depends else "-"
    criteria_lines = "\n".join(f"- [ ] {row}" for row in candidate.get("acceptance_criteria", []))
    evidence_lines = "\n".join(f"- `{row}`" for row in candidate.get("evidence_refs", []))
    if not evidence_lines:
        evidence_lines = "- (none)"

    return "\n".join(
        [
            "## Context",
            "- evidence-backed follow-up candidate",
            "",
            "## Evidence",
            evidence_lines,
            "",
            "## Execution Order",
            "- execution_order: <TBD>",
            f"- depends_on: {depends_text}",
            "",
            "## Scope",
            "- Clarify/patch root cause with deterministic artifacts",
            "",
            "## Acceptance Criteria",
            criteria_lines,
        ]
    )


def validate_replenishment_candidates(candidates, requirements):
    require_evidence = bool(requirements.get("require_evidence_refs", True))
    require_depends = bool(requirements.get("require_depends_on_field", True))
    require_acceptance = bool(requirements.get("require_acceptance_criteria", True))

    normalized = []
    violations = []
    for idx, raw in enumerate(candidates):
        entry = raw if isinstance(raw, dict) else {}
        candidate_id = str(entry.get("candidate_id") or f"candidate-{idx + 1}")
        title = str(entry.get("title", "")).strip()
        evidence_refs = normalize_evidence_refs(entry)

        depends_on = []
        depends_error = None
        if require_depends or "depends_on" in entry:
            depends_on, depends_error = normalize_replenishment_depends(entry.get("depends_on"))

        acceptance_criteria = []
        acceptance_error = None
        if require_acceptance or "acceptance_criteria" in entry:
            acceptance_criteria, acceptance_error = normalize_acceptance_criteria(entry.get("acceptance_criteria"))

        errors = []
        if not title:
            errors.append("title is required")
        if require_evidence and not evidence_refs:
            errors.append("evidence_refs is required and must be non-empty")
        if depends_error:
            errors.append(depends_error)
        if acceptance_error:
            errors.append(acceptance_error)

        candidate = {
            "candidate_id": candidate_id,
            "title": title,
            "target_repo": str(entry.get("target_repo", "")).strip() or None,
            "depends_on": depends_on if isinstance(depends_on, list) else [],
            "acceptance_criteria": acceptance_criteria if isinstance(acceptance_criteria, list) else [],
            "evidence_refs": evidence_refs,
            "body_baseline": "",
        }
        if not errors:
            candidate["body_baseline"] = render_issue_body_baseline(candidate)

        normalized.append(candidate)
        if errors:
            violations.append(
                {
                    "index": idx,
                    "candidate_id": candidate_id,
                    "errors": errors,
                }
            )

    return {
        "candidate_count": len(candidates),
        "violation_count": len(violations),
        "violations": violations,
        "normalized_candidates": normalized,
    }


def normalize_item(raw):
    if not isinstance(raw, dict):
        return None

    # normalized row input
    if raw.get("issue_number") is not None and raw.get("issue_repo"):
        issue_number = parse_issue_ref_to_int(raw.get("issue_number"))
        if issue_number is None:
            return None
        return {
            "issue_number": issue_number,
            "issue_repo": str(raw.get("issue_repo")),
            "status": str(raw.get("status", "")),
            "workflow_state": str(raw.get("workflow_state", "")),
            "execution_order": int(raw.get("execution_order") or 0),
            "component": str(raw.get("component", "")),
            "initiative": str(raw.get("initiative", "")),
            "issue_body": str(raw.get("issue_body", "")),
            "open_dependency_count": raw.get("open_dependency_count"),
        }

    # gh project item-list shape
    content = raw.get("content", {})
    if content.get("type") != "Issue":
        return None
    issue_number = content.get("number")
    issue_repo = content.get("repository")
    if issue_number is None or not issue_repo:
        return None
    return {
        "issue_number": int(issue_number),
        "issue_repo": str(issue_repo),
        "status": str(raw.get("status", "")),
        "workflow_state": str(raw.get("workflow_state", "")),
        "execution_order": int(raw.get("execution_order") or 0),
        "component": str(raw.get("component", "")),
        "initiative": str(raw.get("initiative", "")),
        "issue_body": str(raw.get("issue_body", "")),
        "open_dependency_count": raw.get("open_dependency_count"),
    }


def issue_is_closed(issue_number: int, repo: str):
    rc, out, _ = run(["gh", "issue", "view", str(issue_number), "--repo", repo, "--json", "state", "--jq", ".state"])
    if rc != 0:
        return False, "issue_view_failed"
    return out.strip().upper() == "CLOSED", "ok"


def hydrate_issue_body(issue_repo: str, issue_number: int):
    rc, out, err = run(["gh", "issue", "view", str(issue_number), "--repo", issue_repo, "--json", "body", "--jq", ".body"])
    if rc != 0:
        return "", f"issue_body_fetch_failed:{err}"
    return out, "ok"


def hydrate_dependency_counts(rows, offline=False):
    closed_cache = {}
    diagnostics = []

    for row in rows:
        if isinstance(row.get("open_dependency_count"), int):
            row["depends_on"] = []
            row["dependency_status"] = "provided"
            continue

        issue_body = row.get("issue_body", "")
        if not issue_body:
            if offline:
                row["open_dependency_count"] = 999
                row["depends_on"] = []
                row["dependency_status"] = "offline_missing_issue_body"
                continue
            hydrated_body, status = hydrate_issue_body(row["issue_repo"], row["issue_number"])
            issue_body = hydrated_body
            diagnostics.append(
                {
                    "issue_number": row["issue_number"],
                    "issue_repo": row["issue_repo"],
                    "event": "hydrate_issue_body",
                    "status": status,
                }
            )
        row["issue_body"] = issue_body

        deps = parse_depends_on(issue_body)
        row["depends_on"] = deps
        if not deps:
            row["open_dependency_count"] = 0
            row["dependency_status"] = "clear"
            continue

        open_count = 0
        dep_errors = 0
        for dep in deps:
            key = (row["issue_repo"], dep)
            if key not in closed_cache:
                if offline:
                    closed_cache[key] = (False, "offline_dependency_unknown")
                else:
                    closed_cache[key] = issue_is_closed(dep, row["issue_repo"])
            closed, reason = closed_cache[key]
            if not closed:
                open_count += 1
            if reason != "ok":
                dep_errors += 1

        row["open_dependency_count"] = open_count
        if dep_errors:
            row["dependency_status"] = "dependency_state_unknown"
        elif open_count == 0:
            row["dependency_status"] = "clear"
        else:
            row["dependency_status"] = "blocked"
    return diagnostics


def row_matches_rule(row, rule):
    statuses = set(rule.get("statuses") or [])
    if statuses and row.get("status") not in statuses:
        return False

    workflow_states = set(rule.get("workflow_states") or [])
    if workflow_states and row.get("workflow_state") not in workflow_states:
        return False

    components = set(rule.get("components") or [])
    if components and row.get("component") not in components:
        return False

    dependency_mode = str(rule.get("dependency_mode", "any"))
    open_count = int(row.get("open_dependency_count") or 0)
    if dependency_mode == "all_closed" and open_count != 0:
        return False
    if dependency_mode == "has_open" and open_count <= 0:
        return False

    return True


def evaluate_stock(rows, policy):
    queue_classes = policy.get("queue_classes") or []
    stock_rows = []
    breaches = []
    class_rows = {}
    for queue_class in queue_classes:
        name = str(queue_class.get("name", "")).strip()
        rule = queue_class.get("rule") or {}
        min_stock = int(queue_class.get("min_stock") or 0)

        matched = [row for row in rows if row_matches_rule(row, rule)]
        matched_sorted = sorted(matched, key=lambda x: (x.get("execution_order", 0), x.get("issue_number", 0)))
        class_rows[name] = matched_sorted

        row = {
            "name": name,
            "min_stock": min_stock,
            "actual_stock": len(matched_sorted),
            "met": len(matched_sorted) >= min_stock,
            "issue_refs": [
                {
                    "issue_number": m.get("issue_number"),
                    "issue_repo": m.get("issue_repo"),
                    "execution_order": m.get("execution_order"),
                    "open_dependency_count": m.get("open_dependency_count"),
                }
                for m in matched_sorted
            ],
        }
        stock_rows.append(row)
        if not row["met"]:
            breaches.append(
                {
                    "queue_class": name,
                    "min_stock": min_stock,
                    "actual_stock": len(matched_sorted),
                    "shortage": min_stock - len(matched_sorted),
                }
            )

    return {
        "stock_rows": stock_rows,
        "breach_count": len(breaches),
        "breaches": breaches,
        "class_rows": class_rows,
    }


def select_high_value_ready(class_rows):
    ready_rows = class_rows.get("ready_now", [])
    if not ready_rows:
        return None
    selected = sorted(ready_rows, key=lambda x: (x.get("execution_order", 0), x.get("issue_number", 0)))[0]
    return {
        "issue_number": selected.get("issue_number"),
        "issue_repo": selected.get("issue_repo"),
        "execution_order": selected.get("execution_order"),
        "workflow_state": selected.get("workflow_state"),
        "reason": "high_value_ready_first",
    }


def fetch_project_items(owner: str, project_num: int, limit: int):
    rc, out, err = run(
        [
            "gh",
            "project",
            "item-list",
            str(project_num),
            "--owner",
            owner,
            "--limit",
            str(limit),
            "--format",
            "json",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to fetch project item-list: {err}")
    doc = json.loads(out)
    return doc.get("items", [])


def validate_policy(policy):
    errors = []
    if not isinstance(policy, dict):
        return ["stock policy must be object"]
    queue_classes = policy.get("queue_classes")
    if not isinstance(queue_classes, list) or not queue_classes:
        errors.append("queue_classes must be non-empty list")
    else:
        seen = set()
        for idx, queue_class in enumerate(queue_classes):
            if not isinstance(queue_class, dict):
                errors.append(f"queue_classes[{idx}] must be object")
                continue
            name = str(queue_class.get("name", "")).strip()
            if not name:
                errors.append(f"queue_classes[{idx}].name is required")
            elif name in seen:
                errors.append(f"duplicate queue class name: {name}")
            seen.add(name)
            min_stock = queue_class.get("min_stock")
            if not isinstance(min_stock, int) or min_stock < 0:
                errors.append(f"queue_classes[{idx}].min_stock must be non-negative integer")
            if not isinstance(queue_class.get("rule"), dict):
                errors.append(f"queue_classes[{idx}].rule must be object")
    req = policy.get("candidate_requirements")
    if not isinstance(req, dict):
        errors.append("candidate_requirements must be object")
    return errors


def parse_args():
    parser = argparse.ArgumentParser(description="Backlog stock and replenishment quality gate")
    parser.add_argument("--owner", default="rather-not-work-on")
    parser.add_argument("--project-num", type=int, default=2)
    parser.add_argument("--initiative", default="unified-personal-agent-platform")
    parser.add_argument("--items-file", default=None, help="Optional item snapshot JSON file")
    parser.add_argument("--stock-policy-file", default=str(DEFAULT_STOCK_POLICY_FILE))
    parser.add_argument("--candidate-file", default=None, help="Optional replenishment candidate JSON file")
    parser.add_argument("--offline", action="store_true", help="Do not fetch issue body/dependency state via gh API")
    parser.add_argument("--report-only", action="store_true", help="Always exit 0; report verdict only")
    parser.add_argument("--limit", type=int, default=200)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT_FILE))
    return parser.parse_args()


def main():
    args = parse_args()

    policy_path = Path(args.stock_policy_file)
    policy = load_json(policy_path, {})
    policy_errors = validate_policy(policy)
    if policy_errors:
        report = {
            "generated_at_utc": now_utc(),
            "verdict": "fail",
            "reason_code": "invalid_stock_policy",
            "stock_policy_file": str(policy_path),
            "policy_errors": policy_errors,
        }
        save_json(Path(args.output), report)
        print(f"report written: {args.output}")
        print("verdict=fail reason=invalid_stock_policy")
        return 0 if args.report_only else 1

    if args.items_file:
        raw_items = load_json(Path(args.items_file), [])
    else:
        raw_items = fetch_project_items(args.owner, args.project_num, args.limit)

    rows = []
    for raw in raw_items:
        normalized = normalize_item(raw)
        if not normalized:
            continue
        if normalized.get("initiative") and normalized.get("initiative") != args.initiative:
            continue
        rows.append(normalized)

    dependency_diagnostics = hydrate_dependency_counts(rows, offline=args.offline)
    stock = evaluate_stock(rows, policy)
    high_value_ready = select_high_value_ready(stock["class_rows"])

    candidates = []
    if args.candidate_file:
        candidate_payload = load_json(Path(args.candidate_file), {})
        if isinstance(candidate_payload, dict) and isinstance(candidate_payload.get("candidates"), list):
            candidates = candidate_payload.get("candidates")
        elif isinstance(candidate_payload, list):
            candidates = candidate_payload
    candidate_requirements = policy.get("candidate_requirements") or {}
    candidate_validation = validate_replenishment_candidates(candidates, candidate_requirements)

    breaches = stock["breaches"]
    candidate_violations = candidate_validation["violations"]
    verdict = "pass" if not breaches and not candidate_violations else "fail"
    reason_code = "ok" if verdict == "pass" else "stock_or_candidate_gate_failed"

    report = {
        "generated_at_utc": now_utc(),
        "verdict": verdict,
        "reason_code": reason_code,
        "policy_file": str(policy_path),
        "initiative": args.initiative,
        "project": {
            "owner": args.owner,
            "project_num": args.project_num,
        },
        "selection_policy": {
            "name": "high_value_ready_first",
            "source_queue_class": "ready_now",
            "selected": high_value_ready,
        },
        "stock": {
            "evaluated_items": len(rows),
            "rows": stock["stock_rows"],
            "breach_count": stock["breach_count"],
            "breaches": breaches,
        },
        "candidate_validation": candidate_validation,
        "dependency_diagnostics": dependency_diagnostics,
    }
    save_json(Path(args.output), report)
    print(f"report written: {args.output}")
    print(
        "verdict={verdict} stock_breaches={stock_breaches} candidate_violations={candidate_violations}".format(
            verdict=verdict,
            stock_breaches=len(breaches),
            candidate_violations=len(candidate_violations),
        )
    )
    return 0 if args.report_only or verdict == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
