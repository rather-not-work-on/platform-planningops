#!/usr/bin/env python3

import argparse
import fnmatch
import json
import re
import sys
from datetime import date, datetime, timezone
from pathlib import Path


DEFAULT_RULES = Path("planningops/config/memory-tier-rules.json")
DEFAULT_OUTPUT = Path("planningops/artifacts/validation/memory-compactor-check-report.json")
MARKDOWN_SUFFIXES = {".md", ".markdown"}
IGNORED_NAMES = {".DS_Store", "Thumbs.db"}
TOPIC_STOP_WORDS = {
    "audit",
    "audits",
    "brainstorm",
    "brainstorms",
    "hub",
    "hubs",
    "note",
    "notes",
    "packet",
    "packets",
    "plan",
    "plans",
    "report",
    "reports",
}


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def normalize_rel_path(path: Path, root: Path):
    return path.relative_to(root).as_posix()


def parse_frontmatter(text: str):
    if not text.startswith("---\n"):
        return {}
    result = {}
    lines = text.splitlines()
    for line in lines[1:]:
        if line.strip() == "---":
            return result
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        result[key.strip()] = value.strip()
    return {}


def parse_iso_date(raw_value: str | None):
    if not raw_value:
        return None
    value = str(raw_value).strip().strip("`")
    try:
        return date.fromisoformat(value)
    except ValueError:
        return None


def extract_filename_date(path: Path):
    match = re.match(r"^(\d{4}-\d{2}-\d{2})-", path.name)
    if not match:
        return None
    return parse_iso_date(match.group(1))


def normalize_topic(raw_value: str):
    value = str(raw_value or "").strip().lower()
    value = re.sub(r"^plan[:\s-]+", "", value)
    tokens = [token for token in re.split(r"[^a-z0-9]+", value) if token]
    while tokens and tokens[-1] in TOPIC_STOP_WORDS:
        tokens.pop()
    return "-".join(tokens)


def derive_topic(meta: dict, path: Path):
    if meta.get("topic"):
        return normalize_topic(meta["topic"])
    if meta.get("title"):
        topic = normalize_topic(meta["title"])
        if topic:
            return topic
    stem = re.sub(r"^\d{4}-\d{2}-\d{2}-", "", path.stem)
    return normalize_topic(stem)


def infer_tier(rel_path: str, meta: dict, rules: dict):
    explicit = str(meta.get("memory_tier") or "").strip()
    if explicit:
        return explicit
    for tier_name, tier_cfg in (rules.get("memory_tiers") or {}).items():
        for pattern in tier_cfg.get("default_roots", []):
            if fnmatch.fnmatch(rel_path, pattern):
                return tier_name
    return None


def iter_markdown_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part == ".git" for part in path.parts):
            continue
        if path.name.startswith("._") or path.name in IGNORED_NAMES:
            continue
        if path.suffix.lower() not in MARKDOWN_SUFFIXES:
            continue
        yield path


def pick_anchor_date(meta: dict, path: Path):
    for key in ["updated", "date"]:
        parsed = parse_iso_date(meta.get(key))
        if parsed:
            return parsed, key
    filename_date = extract_filename_date(path)
    if filename_date:
        return filename_date, "filename"
    return datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).date(), "mtime"


def stale_trigger_cfg(rules: dict):
    for row in rules.get("compaction_triggers", []):
        if row.get("code") == "stale_l0_uncompacted":
            return row
    return {}


def duplicate_trigger_cfg(rules: dict):
    for row in rules.get("compaction_triggers", []):
        if row.get("code") == "topic_compaction_required":
            return row
    return {}


def build_record(path: Path, root: Path, rules: dict, as_of: date):
    rel_path = normalize_rel_path(path, root)
    text = path.read_text(encoding="utf-8")
    meta = parse_frontmatter(text)
    tier = infer_tier(rel_path, meta, rules)
    anchor_date, anchor_source = pick_anchor_date(meta, path)
    expires_on = parse_iso_date(meta.get("expires_on"))
    compacted_into = str(meta.get("compacted_into") or "").strip()
    archive_ref = str(meta.get("archive_ref") or "").strip()
    topic = derive_topic(meta, path)
    age_days = max((as_of - anchor_date).days, 0)
    return {
        "path": rel_path,
        "memory_tier": tier,
        "type": meta.get("type", ""),
        "status": meta.get("status", ""),
        "topic": topic,
        "topic_compaction_scope": rel_path.startswith("docs/workbench/") or bool(meta.get("topic")),
        "anchor_date": anchor_date.isoformat(),
        "anchor_source": anchor_source,
        "age_days": age_days,
        "expires_on": expires_on.isoformat() if expires_on else None,
        "compacted_into": compacted_into,
        "archive_ref": archive_ref,
        "frontmatter_present": bool(meta),
    }


def detect_stale_l0(records: list[dict], rules: dict, as_of: date):
    trigger = stale_trigger_cfg(rules)
    max_age_days = int(trigger.get("max_age_days", 14))
    findings = []
    for row in records:
        if row["memory_tier"] != "L0":
            continue
        if row["compacted_into"]:
            continue
        expired = row["expires_on"] and as_of > date.fromisoformat(row["expires_on"])
        if expired or row["age_days"] > max_age_days:
            findings.append(
                {
                    "code": "stale_l0_uncompacted",
                    "path": row["path"],
                    "topic": row["topic"],
                    "age_days": row["age_days"],
                    "anchor_date": row["anchor_date"],
                    "anchor_source": row["anchor_source"],
                    "expires_on": row["expires_on"],
                }
            )
    return findings


def detect_duplicate_topics(records: list[dict], rules: dict):
    trigger = duplicate_trigger_cfg(rules)
    threshold = int(trigger.get("topic_threshold", 3))
    groups = {}
    for row in records:
        if row["memory_tier"] != "L0":
            continue
        if not row["topic_compaction_scope"]:
            continue
        if not row["topic"]:
            continue
        groups.setdefault(row["topic"], []).append(row)

    findings = []
    for topic, rows in sorted(groups.items()):
        if len(rows) < threshold:
            continue
        retained_targets = sorted({row["compacted_into"] for row in rows if row["compacted_into"]})
        if retained_targets:
            continue
        findings.append(
            {
                "code": "topic_compaction_required",
                "topic": topic,
                "record_count": len(rows),
                "paths": [row["path"] for row in rows],
            }
        )
    return findings


def detect_archive_linkage(records: list[dict], root: Path):
    findings = []
    index = {row["path"]: row for row in records}
    for row in records:
        if Path(row["path"]).name == "README.md":
            continue
        is_archive_record = row["path"].startswith("docs/archive/")
        if not is_archive_record and row["memory_tier"] != "L2":
            continue
        archive_ref = row.get("archive_ref") or ""
        if not archive_ref:
            findings.append(
                {
                    "code": "missing_archive_linkage",
                    "path": row["path"],
                    "reason": "archive_ref_missing",
                }
            )
            continue
        manifest_path = root / archive_ref
        if not manifest_path.exists():
            findings.append(
                {
                    "code": "missing_archive_linkage",
                    "path": row["path"],
                    "archive_ref": archive_ref,
                    "reason": "manifest_missing",
                }
            )
            continue
        try:
            manifest = load_json(manifest_path)
        except Exception as exc:  # noqa: BLE001
            findings.append(
                {
                    "code": "missing_archive_linkage",
                    "path": row["path"],
                    "archive_ref": archive_ref,
                    "reason": f"manifest_unreadable:{exc}",
                }
            )
            continue
        if manifest.get("archive_path") != row["path"]:
            findings.append(
                {
                    "code": "missing_archive_linkage",
                    "path": row["path"],
                    "archive_ref": archive_ref,
                    "reason": "archive_path_mismatch",
                }
            )
            continue
        if manifest.get("archive_ref") != archive_ref:
            findings.append(
                {
                    "code": "missing_archive_linkage",
                    "path": row["path"],
                    "archive_ref": archive_ref,
                    "reason": "archive_ref_mismatch",
                }
            )
            continue
        source_path = manifest.get("source_path")
        if source_path and source_path in index and index[source_path].get("compacted_into") not in {"", row["compacted_into"]}:
            findings.append(
                {
                    "code": "missing_archive_linkage",
                    "path": row["path"],
                    "archive_ref": archive_ref,
                    "reason": "compacted_target_mismatch",
                }
            )
    return findings


def main():
    parser = argparse.ArgumentParser(description="Memory compactor dry validator for L0/L1/L2 planning knowledge")
    parser.add_argument("--mode", choices=["check"], default="check")
    parser.add_argument("--root", default=".")
    parser.add_argument("--rules", default=str(DEFAULT_RULES))
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT))
    parser.add_argument("--as-of", default=None, help="YYYY-MM-DD override for deterministic checks")
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    rules_path = Path(args.rules).resolve()
    rules = load_json(rules_path)
    as_of = parse_iso_date(args.as_of) if args.as_of else datetime.now(timezone.utc).date()
    if as_of is None:
        raise SystemExit("--as-of must be YYYY-MM-DD")

    records = []
    errors = []
    for path in iter_markdown_files(root):
        try:
            records.append(build_record(path, root, rules, as_of))
        except Exception as exc:  # noqa: BLE001
            errors.append({"path": str(path), "error": str(exc)})

    stale_l0 = detect_stale_l0(records, rules, as_of)
    duplicate_topics = detect_duplicate_topics(records, rules)
    archive_linkage = detect_archive_linkage(records, root)
    trigger_count = len(stale_l0) + len(duplicate_topics) + len(archive_linkage)

    report = {
        "generated_at_utc": now_utc(),
        "mode": args.mode,
        "root": str(root),
        "rules_path": str(rules_path),
        "as_of": as_of.isoformat(),
        "record_count": len(records),
        "l0_record_count": sum(1 for row in records if row["memory_tier"] == "L0"),
        "trigger_count": trigger_count,
        "error_count": len(errors),
        "stale_l0_uncompacted": stale_l0,
        "topic_compaction_required": duplicate_topics,
        "missing_archive_linkage": archive_linkage,
        "errors": errors,
        "verdict": "pass" if trigger_count == 0 and not errors else "fail",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = (Path.cwd() / output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    print(f"report written: {output_path}")
    print(
        "record_count={record_count} l0_record_count={l0_record_count} trigger_count={trigger_count} error_count={error_count} verdict={verdict}".format(
            **report
        )
    )

    if args.strict and report["verdict"] != "pass":
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
