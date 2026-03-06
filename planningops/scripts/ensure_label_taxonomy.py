#!/usr/bin/env python3

import argparse
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path
import sys


DEFAULT_CONFIG = Path("planningops/config/federated-label-taxonomy.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/federated-label-taxonomy-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def run(cmd):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def list_labels(repo: str):
    rc, out, err = run(["gh", "label", "list", "--repo", repo, "--limit", "200", "--json", "name,color,description"])
    if rc != 0:
        raise RuntimeError(err or out)
    rows = json.loads(out)
    return {row.get("name"): row for row in rows if isinstance(row, dict) and row.get("name")}


def ensure_label(repo: str, label: dict, apply: bool):
    name = label["name"]
    color = label["color"]
    description = label.get("description") or ""
    if not apply:
        return {"action": "planned"}

    rc, out, err = run(
        [
            "gh",
            "label",
            "create",
            name,
            "--repo",
            repo,
            "--color",
            color,
            "--description",
            description,
        ]
    )
    if rc == 0:
        return {"action": "created"}

    conflict_markers = ["already exists", "name has already been taken", "422"]
    err_blob = f"{err}\n{out}".lower()
    if any(marker in err_blob for marker in conflict_markers):
        rc2, out2, err2 = run(
            [
                "gh",
                "label",
                "edit",
                name,
                "--repo",
                repo,
                "--color",
                color,
                "--description",
                description,
            ]
        )
        if rc2 == 0:
            return {"action": "updated"}
        raise RuntimeError(err2 or out2)

    raise RuntimeError(err or out)


def main():
    parser = argparse.ArgumentParser(description="Ensure federated label taxonomy across execution repos")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    cfg = load_json(Path(args.config))
    labels = [row for row in (cfg.get("labels") or []) if isinstance(row, dict) and row.get("name")]
    repos = [row for row in (cfg.get("repos") or []) if isinstance(row, dict) and row.get("repo")]

    if not labels or not repos:
        print("invalid config: labels and repos must be non-empty", file=sys.stderr)
        return 2

    report_rows = []
    errors = []
    missing_total = 0
    mismatch_total = 0

    for repo_row in repos:
        repo = repo_row["repo"]
        repo_result = {
            "repo": repo,
            "missing": [],
            "mismatched": [],
            "applied": [],
            "errors": [],
        }

        try:
            existing = list_labels(repo)
        except Exception as exc:  # noqa: BLE001
            message = str(exc)
            repo_result["errors"].append(message)
            errors.append({"repo": repo, "message": message})
            report_rows.append(repo_result)
            continue

        for label in labels:
            name = label["name"]
            desired_color = (label.get("color") or "").lower()
            desired_desc = label.get("description") or ""
            row = existing.get(name)
            if not row:
                repo_result["missing"].append(name)
                missing_total += 1
                try:
                    result = ensure_label(repo, label, args.apply)
                    if args.apply:
                        repo_result["applied"].append({"name": name, "action": result["action"]})
                except Exception as exc:  # noqa: BLE001
                    message = f"{name}: {exc}"
                    repo_result["errors"].append(message)
                    errors.append({"repo": repo, "message": message})
                continue

            current_color = (row.get("color") or "").lower()
            current_desc = row.get("description") or ""
            if current_color != desired_color or current_desc != desired_desc:
                repo_result["mismatched"].append(
                    {
                        "name": name,
                        "current_color": current_color,
                        "desired_color": desired_color,
                        "current_description": current_desc,
                        "desired_description": desired_desc,
                    }
                )
                mismatch_total += 1
                if args.apply:
                    try:
                        result = ensure_label(repo, label, args.apply)
                        repo_result["applied"].append({"name": name, "action": result["action"]})
                    except Exception as exc:  # noqa: BLE001
                        message = f"{name}: {exc}"
                        repo_result["errors"].append(message)
                        errors.append({"repo": repo, "message": message})

        report_rows.append(repo_result)

    unresolved_missing = 0 if args.apply else missing_total
    unresolved_mismatches = 0 if args.apply else mismatch_total
    verdict = "pass" if unresolved_missing == 0 and unresolved_mismatches == 0 and len(errors) == 0 else "fail"

    report = {
        "generated_at_utc": now_utc(),
        "mode": "apply" if args.apply else "dry-run",
        "config_path": str(Path(args.config)),
        "repo_count": len(repos),
        "label_catalog_count": len(labels),
        "missing_count": missing_total,
        "mismatch_count": mismatch_total,
        "error_count": len(errors),
        "results": report_rows,
        "verdict": verdict,
    }

    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {out}")
    print(
        f"repo_count={report['repo_count']} missing_count={report['missing_count']} "
        f"mismatch_count={report['mismatch_count']} error_count={report['error_count']} verdict={report['verdict']}"
    )

    if args.strict and verdict != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
