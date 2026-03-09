#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from datetime import date, datetime, timezone
from fnmatch import fnmatch
from pathlib import Path
import sys

from path_filters import is_metadata_file


DEFAULT_CONFIG = Path("planningops/config/wrapper-deprecation-map.json")
DEFAULT_SCRIPT_ROLE_MAP = Path("planningops/config/script-role-map.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/deprecation/wrapper-deprecation-report.json")
ALLOWED_ROLES = {"core", "federation", "oneoff"}


def now_utc() -> str:
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def parse_day(raw: str | None) -> date | None:
    if not raw:
        return None
    return date.fromisoformat(str(raw))


def resolve_path(repo_root: Path, raw: str) -> Path:
    path = Path(raw)
    if path.is_absolute():
        return path
    return repo_root / path


def relative_posix(repo_root: Path, path: Path) -> str:
    absolute = path if path.is_absolute() else repo_root / path
    return absolute.relative_to(repo_root).as_posix()


def should_exclude(relative_path: str, exclude_globs: list[str]) -> bool:
    return any(fnmatch(relative_path, pattern) for pattern in exclude_globs)


def iter_scan_files(repo_root: Path, scan_roots: list[str], exclude_globs: list[str]):
    seen: set[str] = set()
    for raw_root in scan_roots:
        root = resolve_path(repo_root, raw_root)
        candidates = [root] if root.is_file() else sorted(root.rglob("*")) if root.is_dir() else []
        for path in candidates:
            if not path.is_file():
                continue
            if is_metadata_file(path):
                continue
            rel = relative_posix(repo_root, path)
            if rel in seen:
                continue
            if should_exclude(rel, exclude_globs):
                continue
            seen.add(rel)
            yield path, rel


def validate_entry(entry: dict):
    errors = []
    wrapper_path = entry.get("wrapper_path")
    target_path = entry.get("target_path")
    role = entry.get("role")
    warn_after = parse_day(entry.get("warn_after"))
    fail_after = parse_day(entry.get("fail_after"))
    if not wrapper_path:
        errors.append("wrapper_path is required")
    if not target_path:
        errors.append("target_path is required")
    if role not in ALLOWED_ROLES:
        errors.append(f"role must be one of {sorted(ALLOWED_ROLES)}")
    if warn_after is None:
        errors.append("warn_after is required")
    if fail_after is None:
        errors.append("fail_after is required")
    if warn_after and fail_after and fail_after <= warn_after:
        errors.append("fail_after must be later than warn_after")
    return errors


def collect_reference_findings(repo_root: Path, entry: dict, scan_roots: list[str], exclude_globs: list[str], current_day: date):
    wrapper_path = str(entry["wrapper_path"])
    warn_after = parse_day(entry.get("warn_after"))
    fail_after = parse_day(entry.get("fail_after"))
    if warn_after is None or current_day < warn_after:
        return []

    allowed_refs = {str(path) for path in entry.get("allowed_reference_paths", [])}
    findings = []
    for path, rel in iter_scan_files(repo_root, scan_roots, exclude_globs):
        if rel == wrapper_path or rel in allowed_refs:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except Exception:  # noqa: BLE001
            continue
        if wrapper_path not in text:
            continue
        line_numbers = [idx for idx, line in enumerate(text.splitlines(), start=1) if wrapper_path in line]
        severity = "error" if fail_after and current_day >= fail_after else "warning"
        findings.append(
            {
                "type": "DEPRECATED_WRAPPER_REFERENCE",
                "severity": severity,
                "wrapper_path": wrapper_path,
                "target_path": entry["target_path"],
                "file": rel,
                "line_numbers": line_numbers,
                "message": f"reference to compatibility wrapper `{wrapper_path}` should move to `{entry['target_path']}`",
            }
        )
    return findings


def main():
    parser = argparse.ArgumentParser(description="Validate compatibility wrapper lifecycle and references")
    parser.add_argument("--config", default=str(DEFAULT_CONFIG))
    parser.add_argument("--script-role-map", default=str(DEFAULT_SCRIPT_ROLE_MAP))
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--mode", choices=["warn", "fail"], default="warn")
    parser.add_argument("--current-date", default=None, help="YYYY-MM-DD for deterministic tests")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    config_path = resolve_path(repo_root, args.config)
    script_role_map_path = resolve_path(repo_root, args.script_role_map)
    output_path = resolve_path(repo_root, args.output)

    cfg = load_json(config_path)
    role_cfg = load_json(script_role_map_path)
    wrappers = cfg.get("wrappers", [])
    scan_roots = cfg.get("scan_roots", ["planningops", ".github", "README.md"])
    exclude_globs = cfg.get("exclude_globs", [])
    current_day = parse_day(args.current_date) or date.today()

    config_errors = []
    findings = []

    if not isinstance(wrappers, list) or not wrappers:
        config_errors.append({"type": "INVALID_WRAPPER_MAP", "message": "wrappers must be a non-empty list"})
        wrappers = []

    map_wrapper_paths = []
    for entry in wrappers:
        entry_errors = validate_entry(entry)
        if entry_errors:
            config_errors.append(
                {
                    "type": "INVALID_WRAPPER_ENTRY",
                    "wrapper_path": entry.get("wrapper_path", ""),
                    "errors": entry_errors,
                }
            )
            continue
        map_wrapper_paths.append(str(entry["wrapper_path"]))
        if not resolve_path(repo_root, entry["wrapper_path"]).is_file():
            config_errors.append(
                {
                    "type": "MISSING_WRAPPER_FILE",
                    "wrapper_path": entry["wrapper_path"],
                }
            )
        if not resolve_path(repo_root, entry["target_path"]).is_file():
            config_errors.append(
                {
                    "type": "MISSING_TARGET_FILE",
                    "target_path": entry["target_path"],
                }
            )
        findings.extend(collect_reference_findings(repo_root, entry, scan_roots, exclude_globs, current_day))

    compat_wrappers = role_cfg.get("compatibility_wrappers", {})
    role_wrapper_paths = {f"planningops/scripts/{name}" for name in compat_wrappers.keys()}
    map_wrapper_path_set = set(map_wrapper_paths)
    for wrapper_path in sorted(role_wrapper_paths - map_wrapper_path_set):
        config_errors.append(
            {
                "type": "WRAPPER_MISSING_FROM_DEPRECATION_MAP",
                "wrapper_path": wrapper_path,
            }
        )
    for wrapper_path in sorted(map_wrapper_path_set - role_wrapper_paths):
        config_errors.append(
            {
                "type": "DEPRECATION_MAP_WRAPPER_NOT_REGISTERED",
                "wrapper_path": wrapper_path,
            }
        )

    warning_count = sum(1 for finding in findings if finding.get("severity") == "warning")
    error_count = sum(1 for finding in findings if finding.get("severity") == "error") + len(config_errors)
    verdict = "pass"
    if error_count and args.mode == "fail":
        verdict = "fail"
    elif warning_count or error_count:
        verdict = "warn"

    report = {
        "generated_at_utc": now_utc(),
        "config_path": relative_posix(repo_root, config_path),
        "script_role_map_path": relative_posix(repo_root, script_role_map_path),
        "repo_root": str(repo_root),
        "mode": args.mode,
        "current_date": current_day.isoformat(),
        "verdict": verdict,
        "wrapper_count": len(wrappers),
        "config_error_count": len(config_errors),
        "warning_count": warning_count,
        "error_count": error_count,
        "config_errors": config_errors,
        "findings": findings,
    }

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2), encoding="utf-8")

    print(f"report written: {output_path}")
    print(
        f"config_error_count={report['config_error_count']} warning_count={report['warning_count']} "
        f"error_count={report['error_count']} verdict={report['verdict']}"
    )
    return 1 if verdict == "fail" else 0


if __name__ == "__main__":
    sys.exit(main())
