#!/usr/bin/env python3

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path


DEFAULT_OUTPUT = "planningops/artifacts/validation/memory-rehydrate-report.json"
DEFAULT_REHYDRATE_ROOT = "planningops/artifacts/rehydrate"


def now_utc():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def parse_frontmatter(text: str):
    if not text.startswith("---\n"):
        return {}, text
    lines = text.splitlines()
    meta = {}
    for idx in range(1, len(lines)):
        line = lines[idx]
        if line.strip() == "---":
            body = "\n".join(lines[idx + 1 :]).lstrip("\n")
            return meta, body
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        meta[key.strip()] = value.strip()
    return {}, text


def render_frontmatter(meta: dict, order: list[str], body: str):
    ordered_keys = []
    for key in order:
        if key in meta and key not in ordered_keys:
            ordered_keys.append(key)
    for key in meta:
        if key not in ordered_keys:
            ordered_keys.append(key)
    lines = ["---"]
    for key in ordered_keys:
        lines.append(f"{key}: {meta[key]}")
    lines.append("---")
    return "\n".join(lines) + "\n\n" + body.rstrip() + "\n"


def sha256_text(text: str):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def default_output_path(source_path: str):
    return str(Path(DEFAULT_REHYDRATE_ROOT) / Path(source_path))


def main():
    parser = argparse.ArgumentParser(description="Rehydrate archived memory records back into source-like documents")
    parser.add_argument("--root", default=".")
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--output-path", default=None)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--output", default=DEFAULT_OUTPUT)
    parser.add_argument("--strict", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = root / manifest_path
    report_path = Path(args.output)
    if not report_path.is_absolute():
        report_path = (Path.cwd() / report_path).resolve()

    if not manifest_path.exists():
        report = {
            "generated_at_utc": now_utc(),
            "mode": "dry-run" if args.dry_run else "apply",
            "manifest_path": str(manifest_path),
            "error_count": 1,
            "errors": [f"manifest path not found: {manifest_path}"],
            "verdict": "fail",
        }
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
        print(f"report written: {report_path}")
        print("error_count=1 verdict=fail")
        return 1 if args.strict else 0

    manifest = load_json(manifest_path)
    required_keys = [
        "archive_path",
        "source_path",
        "source_checksum_sha256",
        "source_frontmatter",
        "source_frontmatter_order",
    ]
    missing = [key for key in required_keys if key not in manifest]
    if missing:
        report = {
            "generated_at_utc": now_utc(),
            "mode": "dry-run" if args.dry_run else "apply",
            "manifest_path": str(manifest_path),
            "error_count": 1,
            "errors": [f"manifest missing required key(s): {', '.join(missing)}"],
            "verdict": "fail",
        }
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
        print(f"report written: {report_path}")
        print("error_count=1 verdict=fail")
        return 1 if args.strict else 0

    archive_path = root / manifest["archive_path"]
    if not archive_path.exists():
        raise SystemExit(f"archive path not found: {manifest['archive_path']}")

    output_path = Path(args.output_path) if args.output_path else root / default_output_path(manifest["source_path"])
    if not output_path.is_absolute():
        output_path = root / output_path

    archive_text = archive_path.read_text(encoding="utf-8")
    _, body = parse_frontmatter(archive_text)
    source_meta = dict(manifest.get("source_frontmatter") or {})
    source_order = list(manifest.get("source_frontmatter_order") or list(source_meta.keys()))
    restored_text = render_frontmatter(source_meta, source_order, body)
    restored_checksum = sha256_text(restored_text)
    checksum_match = restored_checksum == manifest.get("source_checksum_sha256")

    if not args.dry_run:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(restored_text, encoding="utf-8")

    report = {
        "generated_at_utc": now_utc(),
        "mode": "dry-run" if args.dry_run else "apply",
        "manifest_path": str(manifest_path),
        "archive_path": manifest["archive_path"],
        "source_path": manifest["source_path"],
        "output_path": str(output_path),
        "restored_checksum_sha256": restored_checksum,
        "source_checksum_sha256": manifest.get("source_checksum_sha256"),
        "checksum_match": checksum_match,
        "verdict": "pass" if checksum_match else "fail",
    }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")
    print(f"report written: {report_path}")
    print(f"checksum_match={str(checksum_match).lower()} verdict={report['verdict']}")
    if args.strict and not checksum_match:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
