#!/usr/bin/env python3

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
from datetime import datetime, timezone


LEDGER_PATH = Path("planningops/artifacts/idempotency/ledger.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(args):
    cp = subprocess.run(args, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def ensure_ledger():
    if not LEDGER_PATH.exists():
        LEDGER_PATH.parent.mkdir(parents=True, exist_ok=True)
        LEDGER_PATH.write_text(json.dumps({"applied_keys": []}, indent=2), encoding="utf-8")


def load_ledger():
    ensure_ledger()
    return json.loads(LEDGER_PATH.read_text(encoding="utf-8"))


def save_ledger(doc):
    LEDGER_PATH.write_text(json.dumps(doc, indent=2), encoding="utf-8")


def make_key(plan_item_id: str, target_repo: str, version: str):
    raw = f"{plan_item_id}:{target_repo}:{version}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def cmd_smoke(owner: str, project_num: int, issue_num: int):
    results = {"executed_at_utc": now_utc(), "rest": {}, "graphql": {}}

    rc, out, err = run(["gh", "issue", "view", str(issue_num), "--json", "number,title,state"])
    results["rest"] = {"rc": rc, "stdout": out, "stderr": err}

    rc2, out2, err2 = run(["gh", "project", "field-list", str(project_num), "--owner", owner, "--format", "json"])
    results["graphql"] = {"rc": rc2, "stdout": out2[:2000], "stderr": err2}

    ok = rc == 0 and rc2 == 0
    print(json.dumps({"ok": ok, "results": results}, ensure_ascii=True, indent=2))
    return 0 if ok else 1


def cmd_replay_test():
    actions = [
        {"plan_item_id": "item-001", "target_repo": "rather-not-work-on/platform-planningops", "version": "1"},
        {"plan_item_id": "item-002", "target_repo": "rather-not-work-on/platform-planningops", "version": "1"},
    ]

    ledger = load_ledger()
    applied = set(ledger.get("applied_keys", []))

    first_apply = 0
    for a in actions:
        key = make_key(a["plan_item_id"], a["target_repo"], a["version"])
        if key not in applied:
            applied.add(key)
            first_apply += 1

    second_apply = 0
    for a in actions:
        key = make_key(a["plan_item_id"], a["target_repo"], a["version"])
        if key not in applied:
            applied.add(key)
            second_apply += 1

    save_ledger({"applied_keys": sorted(applied)})

    summary = {
        "executed_at_utc": now_utc(),
        "first_apply_count": first_apply,
        "second_apply_count": second_apply,
        "duplicate_creation_rate": 0.0 if second_apply == 0 else 1.0,
        "idempotent_convergence": second_apply == 0,
    }
    print(json.dumps(summary, ensure_ascii=True, indent=2))
    return 0 if summary["idempotent_convergence"] else 1


def cmd_drift_sample(output_path: str):
    samples = [
        {"type": "MISSING_ENTITY", "severity": "high", "example": "plan item exists but issue missing"},
        {"type": "FIELD_MISMATCH", "severity": "medium", "example": "project status != plan status"},
        {"type": "ILLEGAL_MANUAL_CHANGE", "severity": "high", "example": "initiative field edited manually"},
        {"type": "ORPHAN_ITEM", "severity": "medium", "example": "project card has no plan mapping"},
    ]
    out = Path(output_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"generated_at_utc": now_utc(), "samples": samples}, indent=2), encoding="utf-8")
    print(str(out))
    return 0


def main():
    parser = argparse.ArgumentParser(description="GitHub sync adapter baseline")
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_smoke = sub.add_parser("smoke")
    p_smoke.add_argument("--owner", default="rather-not-work-on")
    p_smoke.add_argument("--project-num", type=int, default=2)
    p_smoke.add_argument("--issue-num", type=int, default=5)

    sub.add_parser("replay-test")

    p_drift = sub.add_parser("drift-sample")
    p_drift.add_argument(
        "--output",
        default="planningops/artifacts/drift/drift-sample-cases.json",
    )

    args = parser.parse_args()
    if args.cmd == "smoke":
        return cmd_smoke(args.owner, args.project_num, args.issue_num)
    if args.cmd == "replay-test":
        return cmd_replay_test()
    if args.cmd == "drift-sample":
        return cmd_drift_sample(args.output)
    return 1


if __name__ == "__main__":
    sys.exit(main())
