#!/usr/bin/env python3

from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

SCRIPTS_ROOT = Path(__file__).resolve().parent
if str(SCRIPTS_ROOT) not in sys.path:
    sys.path.insert(0, str(SCRIPTS_ROOT))

from planning_context import parse_metadata


DEFAULT_POLICY = Path("planningops/config/inventory-issue-lifecycle-policy.json")
DEFAULT_ARCHIVE_OUTPUT = Path("planningops/artifacts/validation/inventory-issue-archive-report.json")
DEFAULT_REHYDRATE_OUTPUT = Path("planningops/artifacts/validation/inventory-issue-rehydrate-report.json")
DEFAULT_AUDIT_OUTPUT = Path("planningops/artifacts/validation/inventory-issue-lifecycle-report.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path: Path, doc: dict):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")


def sha256_text(text: str):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def run(cmd: list[str]):
    cp = subprocess.run(cmd, capture_output=True, text=True)
    return cp.returncode, cp.stdout.strip(), cp.stderr.strip()


def is_repo_relative(path_text: str):
    text = str(path_text or "").strip()
    return bool(text) and not text.startswith("/") and ".." not in Path(text).parts


def normalize_repo_path(value: str):
    return value.strip().replace("\\", "/")


def parse_issue_ref(issue_ref: str):
    match = re.match(r"^([^#\s]+/[^#\s]+)#(\d+)$", str(issue_ref or "").strip())
    if not match:
        raise ValueError(f"invalid issue ref: {issue_ref} (expected owner/repo#number)")
    return match.group(1), int(match.group(2))


def normalize_issue_state(issue: dict):
    return str(issue.get("state") or "OPEN").strip().upper()


def parse_created_at(issue: dict):
    raw = str(issue.get("createdAt") or "").strip()
    if not raw:
        return None
    try:
        if raw.endswith("Z"):
            raw = raw.replace("Z", "+00:00")
        return datetime.fromisoformat(raw)
    except ValueError:
        return None


def fetch_issue(issue_ref: str):
    repo, number = parse_issue_ref(issue_ref)
    rc, out, err = run(
        [
            "gh",
            "issue",
            "view",
            str(number),
            "--repo",
            repo,
            "--json",
            "number,title,body,url,state,createdAt,updatedAt,closedAt",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to fetch issue {issue_ref}: {err}")
    doc = json.loads(out)
    doc["repo"] = repo
    return doc


def render_frontmatter(meta: dict, body: str):
    lines = ["---"]
    for key, value in meta.items():
        if isinstance(value, list):
            lines.append(f"{key}:")
            for item in value:
                lines.append(f"  - {item}")
        else:
            lines.append(f"{key}: {value}")
    lines.append("---")
    return "\n".join(lines) + "\n\n" + body.rstrip() + "\n"


def build_archive_markdown(issue: dict, metadata: dict, archive_ref: str, compacted_into: str, archived_at: str):
    issue_ref = f"{issue['repo']}#{issue['number']}"
    title = issue.get("title") or f"Inventory Issue #{issue['number']}"
    tags = ["inventory-issue", "github-issue", "planningops"]
    body = "\n".join(
        [
            f"# Archived Inventory Issue #{issue['number']}",
            "",
            "## Archive Summary",
            f"- source issue: `{issue_ref}`",
            f"- source url: `{issue.get('url') or ''}`",
            f"- original workflow_state: `{metadata.get('workflow_state', '')}`",
            f"- execution_kind: `{metadata.get('execution_kind', '')}`",
            f"- archived_at_utc: `{archived_at}`",
            f"- compacted_into: `{compacted_into}`",
            f"- archive_ref: `{archive_ref}`",
            "",
            "## Original Issue Body",
            "```markdown",
            (issue.get("body") or "").rstrip(),
            "```",
            "",
        ]
    )
    frontmatter = {
        "doc_id": f"inventory-issue-{issue['number']}",
        "title": f"Archived Inventory Issue #{issue['number']}: {title}",
        "doc_type": "memory",
        "domain": "planningops",
        "status": "archived",
        "date": archived_at[:10],
        "updated": archived_at[:10],
        "initiative": metadata.get("initiative", "unified-personal-agent-platform"),
        "tags": tags,
        "summary": f"Archived inventory-only backlog record copied from {issue_ref}.",
        "memory_tier": "L2",
        "archive_ref": archive_ref,
        "compacted_into": compacted_into,
        "source_issue_ref": issue_ref,
        "source_issue_url": issue.get("url") or "",
        "inventory_lifecycle": "archived",
    }
    return render_frontmatter(frontmatter, body)


def upsert_metadata_line(lines: list[str], key: str, value: str):
    rendered = f"- {key}: `{value}`"
    pattern = re.compile(rf"^(?:-\s*)?{re.escape(key)}:\s*.*$")
    for idx, line in enumerate(lines):
        if pattern.match(line):
            lines[idx] = rendered
            return

    context_start = None
    insert_at = None
    for idx, line in enumerate(lines):
        if line.strip() == "## Planning Context":
            context_start = idx
            continue
        if context_start is None:
            continue
        if idx > context_start and line.startswith("## "):
            insert_at = idx
            break
    if context_start is None:
        lines.extend(["## Planning Context", rendered, ""])
        return
    if insert_at is None:
        insert_at = len(lines)
    lines.insert(insert_at, rendered)


def render_archived_issue_body(issue_body: str, compacted_into: str, archive_ref: str):
    lines = (issue_body or "").splitlines()
    for key, value in [
        ("workflow_state", "done"),
        ("execution_kind", "inventory"),
        ("inventory_lifecycle", "archived"),
        ("compacted_into", compacted_into),
        ("archive_ref", archive_ref),
    ]:
        upsert_metadata_line(lines, key, value)
    return "\n".join(lines).rstrip() + "\n"


def issue_archive_paths(policy: dict, repo: str, number: int):
    archive_root = policy["archive_root"]
    manifest_root = policy["manifest_root"]
    return (
        f"{archive_root}/{repo}/issue-{number}.md",
        f"{manifest_root}/{repo}/issue-{number}.json",
    )


def validate_archive_manifest(root: Path, manifest: dict, errors: list[str]):
    required = [
        "manifest_version",
        "archived_at_utc",
        "source_issue_ref",
        "source_repo",
        "source_issue_number",
        "source_issue_title",
        "source_issue_state",
        "source_issue_url",
        "source_issue_body",
        "source_body_checksum_sha256",
        "archive_path",
        "manifest_path",
        "archive_ref",
        "compacted_into",
        "archive_checksum_sha256",
    ]
    for key in required:
        if key not in manifest:
            errors.append(f"manifest missing key: {key}")
    archive_path = manifest.get("archive_path") or ""
    manifest_path = manifest.get("manifest_path") or ""
    compacted_into = manifest.get("compacted_into") or ""
    if archive_path and not is_repo_relative(archive_path):
        errors.append("manifest archive_path must be repo-root-relative")
    if manifest_path and not is_repo_relative(manifest_path):
        errors.append("manifest manifest_path must be repo-root-relative")
    if compacted_into and not is_repo_relative(compacted_into):
        errors.append("manifest compacted_into must be repo-root-relative")
    if compacted_into and not (root / compacted_into).exists():
        errors.append(f"manifest compacted_into target missing: {compacted_into}")


def archive_command(args):
    root = Path(args.root).resolve()
    policy = load_json(Path(args.policy))
    issue = load_json(Path(args.issue_json)) if args.issue_json else fetch_issue(args.issue_ref)
    repo = issue.get("repo")
    if not repo:
        issue_ref = args.issue_ref or ""
        repo, _ = parse_issue_ref(issue_ref)
        issue["repo"] = repo
    metadata = parse_metadata(
        issue.get("body") or "",
        keys=["initiative", "workflow_state", "execution_kind", "inventory_lifecycle", "plan_item_id"],
    )
    if metadata.get("execution_kind") != policy.get("inventory_execution_kind", "inventory"):
        raise SystemExit("archive source issue must declare execution_kind=inventory")

    compacted_into = normalize_repo_path(args.compacted_into)
    if not is_repo_relative(compacted_into):
        raise SystemExit("compacted_into must be repo-root-relative")
    if not (root / compacted_into).exists():
        raise SystemExit(f"compacted_into target not found: {compacted_into}")

    issue_number = int(issue["number"])
    archive_rel, manifest_rel = issue_archive_paths(policy, issue["repo"], issue_number)
    archive_rel = normalize_repo_path(args.archive_path or archive_rel)
    manifest_rel = normalize_repo_path(args.manifest_path or manifest_rel)
    archived_at = args.archived_at or now_utc()

    if not archive_rel.startswith(f"{policy['archive_root']}/"):
        raise SystemExit(f"archive_path must stay under {policy['archive_root']}/")
    if not manifest_rel.startswith(f"{policy['manifest_root']}/"):
        raise SystemExit(f"manifest_path must stay under {policy['manifest_root']}/")

    archive_ref = manifest_rel
    archive_text = build_archive_markdown(issue, metadata, archive_ref, compacted_into, archived_at)
    archived_issue_body = render_archived_issue_body(issue.get("body") or "", compacted_into, archive_ref)
    manifest = {
        "manifest_version": 1,
        "archived_at_utc": archived_at,
        "source_issue_ref": f"{issue['repo']}#{issue_number}",
        "source_repo": issue["repo"],
        "source_issue_number": issue_number,
        "source_issue_title": issue.get("title") or "",
        "source_issue_state": normalize_issue_state(issue),
        "source_issue_url": issue.get("url") or "",
        "source_issue_body": issue.get("body") or "",
        "source_body_checksum_sha256": sha256_text(issue.get("body") or ""),
        "source_metadata": metadata,
        "archive_path": archive_rel,
        "manifest_path": manifest_rel,
        "archive_ref": archive_ref,
        "compacted_into": compacted_into,
        "archive_checksum_sha256": sha256_text(archive_text),
        "archived_issue_body": archived_issue_body,
        "archived_issue_body_checksum_sha256": sha256_text(archived_issue_body),
    }
    errors = []
    validate_archive_manifest(root, manifest, errors)

    if not args.dry_run and not errors:
        archive_path = root / archive_rel
        manifest_path = root / manifest_rel
        archive_path.parent.mkdir(parents=True, exist_ok=True)
        archive_path.write_text(archive_text, encoding="utf-8")
        write_json(manifest_path, manifest)

    report = {
        "generated_at_utc": now_utc(),
        "mode": "dry-run" if args.dry_run else "apply",
        "issue_ref": manifest["source_issue_ref"],
        "archive_path": archive_rel,
        "manifest_path": manifest_rel,
        "compacted_into": compacted_into,
        "error_count": len(errors),
        "errors": errors,
        "manifest": manifest,
        "verdict": "pass" if not errors else "fail",
    }
    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = root / output_path
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"issue_ref={manifest['source_issue_ref']} verdict={report['verdict']}")
    return 1 if args.strict and errors else 0


def rehydrate_command(args):
    root = Path(args.root).resolve()
    policy = load_json(Path(args.policy))
    manifest_path = Path(args.manifest)
    if not manifest_path.is_absolute():
        manifest_path = root / manifest_path
    manifest = load_json(manifest_path)
    errors = []
    validate_archive_manifest(root, manifest, errors)
    archive_path = root / manifest.get("archive_path", "")
    if not archive_path.exists():
        errors.append(f"archive path missing: {manifest.get('archive_path', '')}")
    output_path = Path(args.output_path) if args.output_path else root / (
        f"{policy['rehydrate_root']}/{manifest.get('source_repo', '')}/issue-{manifest.get('source_issue_number', '')}.json"
    )
    if not output_path.is_absolute():
        output_path = root / output_path

    restored = {
        "repo": manifest.get("source_repo"),
        "number": manifest.get("source_issue_number"),
        "title": manifest.get("source_issue_title"),
        "url": manifest.get("source_issue_url"),
        "state": manifest.get("source_issue_state"),
        "body": manifest.get("source_issue_body"),
    }
    checksum_match = sha256_text(restored["body"] or "") == manifest.get("source_body_checksum_sha256")
    if not checksum_match:
        errors.append("rehydrated body checksum mismatch")

    if not args.dry_run and not errors:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(restored, ensure_ascii=True, indent=2) + "\n", encoding="utf-8")

    report = {
        "generated_at_utc": now_utc(),
        "mode": "dry-run" if args.dry_run else "apply",
        "manifest_path": str(manifest_path.relative_to(root)),
        "output_path": str(output_path.relative_to(root)) if output_path.is_relative_to(root) else str(output_path),
        "checksum_match": checksum_match,
        "error_count": len(errors),
        "errors": errors,
        "verdict": "pass" if not errors else "fail",
    }
    report_path = Path(args.output)
    if not report_path.is_absolute():
        report_path = root / report_path
    write_json(report_path, report)
    print(f"report written: {report_path}")
    print(f"checksum_match={str(checksum_match).lower()} verdict={report['verdict']}")
    return 1 if args.strict and errors else 0


def load_issues_for_audit(args, policy: dict):
    if args.issues_file:
        issues = load_json(Path(args.issues_file))
        if isinstance(issues, dict):
            issues = [issues]
        for issue in issues:
            issue.setdefault("repo", args.repo or policy["repo"])
        return issues
    if args.issue_number is not None:
        return [fetch_issue(f"{args.repo or policy['repo']}#{args.issue_number}")]
    repo = args.repo or policy["repo"]
    rc, out, err = run(
        [
            "gh",
            "issue",
            "list",
            "--repo",
            repo,
            "--state",
            "all",
            "--limit",
            "200",
            "--json",
            "number,title,body,url,state,createdAt,updatedAt,closedAt",
        ]
    )
    if rc != 0:
        raise RuntimeError(f"failed to list issues for audit: {err}")
    issues = json.loads(out)
    for issue in issues:
        issue["repo"] = repo
    return issues


def audit_inventory_issue(root: Path, issue: dict, policy: dict):
    metadata = parse_metadata(
        issue.get("body") or "",
        keys=[
            "workflow_state",
            "execution_kind",
            "inventory_lifecycle",
            "archive_ref",
            "compacted_into",
            "initiative",
        ],
    )
    if metadata.get("execution_kind") != policy.get("inventory_execution_kind", "inventory"):
        return None

    violations = []
    issue_state = normalize_issue_state(issue)
    created_at = parse_created_at(issue)
    open_cfg = policy["open_inventory"]
    archived_cfg = policy["archived_inventory"]

    if issue_state == open_cfg["required_issue_state"]:
        if metadata.get("workflow_state") not in set(open_cfg["allowed_workflow_states"]):
            violations.append(
                f"open inventory workflow_state must be one of {open_cfg['allowed_workflow_states']} (actual={metadata.get('workflow_state', '')})"
            )
        if metadata.get("inventory_lifecycle") != open_cfg["required_inventory_lifecycle"]:
            violations.append(
                f"open inventory must declare inventory_lifecycle={open_cfg['required_inventory_lifecycle']}"
            )
        if open_cfg.get("forbid_archive_ref") and metadata.get("archive_ref"):
            violations.append("open inventory must not declare archive_ref")
        if open_cfg.get("forbid_compacted_into") and metadata.get("compacted_into"):
            violations.append("open inventory must not declare compacted_into")
        if created_at is not None:
            age_days = max((datetime.now(timezone.utc) - created_at.astimezone(timezone.utc)).days, 0)
            if age_days > int(open_cfg["max_open_days"]):
                violations.append(
                    f"open inventory age exceeds max_open_days={open_cfg['max_open_days']} (actual={age_days})"
                )
    else:
        if issue_state != archived_cfg["required_issue_state"]:
            violations.append(
                f"inventory issue must be {open_cfg['required_issue_state']} or {archived_cfg['required_issue_state']} (actual={issue_state})"
            )
        if metadata.get("workflow_state") != archived_cfg["required_workflow_state"]:
            violations.append(
                f"archived inventory workflow_state must be {archived_cfg['required_workflow_state']}"
            )
        if metadata.get("inventory_lifecycle") != archived_cfg["required_inventory_lifecycle"]:
            violations.append(
                f"archived inventory must declare inventory_lifecycle={archived_cfg['required_inventory_lifecycle']}"
            )
        archive_ref = metadata.get("archive_ref", "")
        compacted_into = metadata.get("compacted_into", "")
        if archived_cfg.get("require_archive_ref") and not archive_ref:
            violations.append("archived inventory must declare archive_ref")
        if archived_cfg.get("require_compacted_into") and not compacted_into:
            violations.append("archived inventory must declare compacted_into")
        manifest_path = root / archive_ref if archive_ref else None
        if archive_ref:
            if not is_repo_relative(archive_ref):
                violations.append("archive_ref must be repo-root-relative")
            elif not manifest_path.exists():
                violations.append(f"archive_ref not found: {archive_ref}")
            else:
                manifest = load_json(manifest_path)
                manifest_errors = []
                validate_archive_manifest(root, manifest, manifest_errors)
                if manifest.get("source_issue_ref") != f"{issue['repo']}#{issue['number']}":
                    manifest_errors.append("manifest source_issue_ref mismatch")
                if manifest.get("source_body_checksum_sha256") != sha256_text(manifest.get("source_issue_body") or ""):
                    manifest_errors.append("manifest source body checksum mismatch")
                for error in manifest_errors:
                    violations.append(f"manifest invalid: {error}")
        if compacted_into:
            if not is_repo_relative(compacted_into):
                violations.append("compacted_into must be repo-root-relative")
            elif not (root / compacted_into).exists():
                violations.append(f"compacted_into target missing: {compacted_into}")

    return {
        "issue_ref": f"{issue['repo']}#{issue['number']}",
        "title": issue.get("title") or "",
        "state": issue_state,
        "metadata": metadata,
        "violation_count": len(violations),
        "violations": violations,
    }


def audit_command(args):
    root = Path(args.root).resolve()
    policy = load_json(Path(args.policy))
    issues = load_issues_for_audit(args, policy)
    rows = []
    for issue in issues:
        row = audit_inventory_issue(root, issue, policy)
        if row is not None:
            rows.append(row)
    violations = [row for row in rows if row["violation_count"] > 0]
    report = {
        "generated_at_utc": now_utc(),
        "repo": args.repo or policy["repo"],
        "issues_scanned": len(issues),
        "inventory_issues": len(rows),
        "violation_count": len(violations),
        "violations": violations,
        "verdict": "pass" if not violations else "fail",
    }
    output_path = Path(args.output)
    if not output_path.is_absolute():
        output_path = root / output_path
    write_json(output_path, report)
    print(f"report written: {output_path}")
    print(f"inventory_issues={report['inventory_issues']} violation_count={report['violation_count']} verdict={report['verdict']}")
    return 1 if args.strict and violations else 0


def build_parser():
    parser = argparse.ArgumentParser(description="Manage inventory-only issue lifecycle archive and audit flows")
    subparsers = parser.add_subparsers(dest="command", required=True)

    archive = subparsers.add_parser("archive")
    archive.add_argument("--root", default=".")
    archive.add_argument("--policy", default=str(DEFAULT_POLICY))
    archive_group = archive.add_mutually_exclusive_group(required=True)
    archive_group.add_argument("--issue-ref")
    archive_group.add_argument("--issue-json")
    archive.add_argument("--compacted-into", required=True)
    archive.add_argument("--archive-path")
    archive.add_argument("--manifest-path")
    archive.add_argument("--archived-at")
    archive.add_argument("--dry-run", action="store_true")
    archive.add_argument("--output", default=str(DEFAULT_ARCHIVE_OUTPUT))
    archive.add_argument("--strict", action="store_true")

    rehydrate = subparsers.add_parser("rehydrate")
    rehydrate.add_argument("--root", default=".")
    rehydrate.add_argument("--policy", default=str(DEFAULT_POLICY))
    rehydrate.add_argument("--manifest", required=True)
    rehydrate.add_argument("--output-path")
    rehydrate.add_argument("--dry-run", action="store_true")
    rehydrate.add_argument("--output", default=str(DEFAULT_REHYDRATE_OUTPUT))
    rehydrate.add_argument("--strict", action="store_true")

    audit = subparsers.add_parser("audit")
    audit.add_argument("--root", default=".")
    audit.add_argument("--policy", default=str(DEFAULT_POLICY))
    audit.add_argument("--repo")
    audit.add_argument("--issue-number", type=int)
    audit.add_argument("--issues-file")
    audit.add_argument("--output", default=str(DEFAULT_AUDIT_OUTPUT))
    audit.add_argument("--strict", action="store_true")

    return parser


def main():
    parser = build_parser()
    args = parser.parse_args()
    if args.command == "archive":
        return archive_command(args)
    if args.command == "rehydrate":
        return rehydrate_command(args)
    if args.command == "audit":
        return audit_command(args)
    parser.error(f"unsupported command: {args.command}")


if __name__ == "__main__":
    sys.exit(main())
