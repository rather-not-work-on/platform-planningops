#!/usr/bin/env python3

import argparse
import hashlib
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_ARCHIVE_ROOT = "docs/archive"
DEFAULT_MANIFEST_ROOT = "planningops/archive-manifest"
DEFAULT_OUTPUT = "planningops/artifacts/validation/memory-archive-report.json"


def now_utc():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def parse_frontmatter(text: str):
    if not text.startswith("---\n"):
        return {}, [], text
    lines = text.splitlines()
    meta = {}
    order = []
    idx = 1
    for idx in range(1, len(lines)):
        line = lines[idx]
        if line.strip() == "---":
            body = "\n".join(lines[idx + 1 :]).lstrip("\n")
            return meta, order, body
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip()
        order.append(key.strip())
    return {}, [], text


def render_frontmatter(meta: dict, body: str, preferred_order: list[str] | None = None):
    ordered_keys = []
    preferred = preferred_order or [
        "title",
        "type",
        "date",
        "updated",
        "initiative",
        "lifecycle",
        "status",
        "summary",
        "topic",
        "memory_tier",
        "compacted_into",
        "archive_ref",
    ]
    for key in preferred:
        if key in meta:
            ordered_keys.append(key)
    for key in meta:
        if key not in ordered_keys:
            ordered_keys.append(key)
    frontmatter = ["---"]
    for key in ordered_keys:
        frontmatter.append(f"{key}: {meta[key]}")
    frontmatter.append("---")
    return "\n".join(frontmatter) + "\n\n" + body.rstrip() + "\n"


def is_repo_relative(path_text: str):
    text = str(path_text or "").strip()
    return bool(text) and not text.startswith("/") and ".." not in Path(text).parts


def default_archive_path(source_rel: str):
    rel = Path(source_rel)
    rel_parts = rel.parts
    if rel_parts and rel_parts[0] == "docs":
        rel = Path(*rel_parts[1:])
    return str(Path(DEFAULT_ARCHIVE_ROOT) / rel)


def default_manifest_path(source_rel: str):
    rel = Path(source_rel)
    return str(Path(DEFAULT_MANIFEST_ROOT) / rel.with_suffix(".json"))


def sha256_text(text: str):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def main():
    parser = argparse.ArgumentParser(description="Archive a memory document and emit a deterministic pointer manifest")
    parser.add_argument("--root", default=".")
    parser.add_argument("--source", required=True, help="repo-root-relative source markdown path")
    parser.add_argument("--compacted-into", required=True, help="repo-root-relative retained summary/canonical path")
    parser.add_argument("--archive-path", default=None, help="repo-root-relative archive markdown path")
    parser.add_argument("--manifest-path", default=None, help="repo-root-relative manifest json path")
    parser.add_argument("--archived-at", default=None, help="override archived_at_utc (ISO-8601)")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output", default=DEFAULT_OUTPUT)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    errors = []
    root = Path(args.root).resolve()
    source_rel = str(Path(args.source).as_posix())
    compacted_into = str(Path(args.compacted_into).as_posix())

    if not is_repo_relative(source_rel):
        errors.append("source must be repo-root-relative")
    if not is_repo_relative(compacted_into):
        errors.append("compacted_into must be repo-root-relative")

    source_path = root / source_rel
    compacted_path = root / compacted_into
    archive_rel = args.archive_path or default_archive_path(source_rel)
    manifest_rel = args.manifest_path or default_manifest_path(source_rel)

    if not is_repo_relative(archive_rel):
        errors.append("archive_path must be repo-root-relative")
    if not is_repo_relative(manifest_rel):
        errors.append("manifest_path must be repo-root-relative")
    if archive_rel == source_rel:
        errors.append("archive_path must differ from source")
    if not archive_rel.startswith(f"{DEFAULT_ARCHIVE_ROOT}/"):
        errors.append(f"archive_path must stay under {DEFAULT_ARCHIVE_ROOT}/")
    if not manifest_rel.startswith(f"{DEFAULT_MANIFEST_ROOT}/"):
        errors.append(f"manifest_path must stay under {DEFAULT_MANIFEST_ROOT}/")
    if errors:
        report = {
            "generated_at_utc": now_utc(),
            "mode": "dry-run" if args.dry_run else "apply",
            "source_path": source_rel,
            "archive_path": archive_rel,
            "manifest_path": manifest_rel,
            "error_count": len(errors),
            "errors": errors,
            "verdict": "fail",
        }
        output_path = (Path.cwd() / args.output).resolve()
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
        print(f"report written: {output_path}")
        print(f"error_count={len(errors)} verdict=fail")
        return 1 if args.strict else 0

    if not source_path.exists():
        raise SystemExit(f"source not found: {source_rel}")
    if not compacted_path.exists():
        raise SystemExit(f"compacted target not found: {compacted_into}")

    source_text = source_path.read_text(encoding="utf-8")
    source_meta, source_order, body = parse_frontmatter(source_text)
    meta = dict(source_meta)
    archive_ref = manifest_rel
    meta.pop("expires_on", None)
    meta["memory_tier"] = "L2"
    meta["compacted_into"] = compacted_into
    meta["archive_ref"] = archive_ref
    if not meta.get("status"):
        meta["status"] = "archived"

    archived_order = [key for key in source_order if key != "expires_on"]
    for key in ["memory_tier", "compacted_into", "archive_ref"]:
        if key not in archived_order:
            archived_order.append(key)
    archived_text = render_frontmatter(meta, body, preferred_order=archived_order)
    archived_at = args.archived_at or now_utc()
    archive_path = root / archive_rel
    manifest_path = root / manifest_rel

    manifest = {
        "manifest_version": 1,
        "archived_at_utc": archived_at,
        "source_path": source_rel,
        "archive_path": archive_rel,
        "manifest_path": manifest_rel,
        "archive_ref": archive_ref,
        "compacted_into": compacted_into,
        "memory_tier": "L2",
        "initiative": source_meta.get("initiative", ""),
        "source_frontmatter": source_meta,
        "source_frontmatter_order": source_order,
        "source_checksum_sha256": sha256_text(source_text),
        "archive_checksum_sha256": sha256_text(archived_text),
    }

    if not args.dry_run:
        archive_path.parent.mkdir(parents=True, exist_ok=True)
        archive_path.write_text(archived_text, encoding="utf-8")
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    report = {
        "generated_at_utc": now_utc(),
        "mode": "dry-run" if args.dry_run else "apply",
        "source_path": source_rel,
        "archive_path": archive_rel,
        "manifest_path": manifest_rel,
        "error_count": 0,
        "errors": [],
        "manifest": manifest,
        "verdict": "pass",
    }

    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = (Path.cwd() / output_path).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(f"report written: {output_path}")
    print(f"archive_path={archive_rel} manifest_path={manifest_rel} verdict=pass")
    return 0


if __name__ == "__main__":
    sys.exit(main())
