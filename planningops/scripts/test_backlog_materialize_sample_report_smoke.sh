#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

contract_file="planningops/fixtures/backlog-materialization-sample-contract.json"
compile_output="$tmpdir/plan-compile-report.json"
label_output="$tmpdir/issue-label-backfill-report.json"
manifest_output="$tmpdir/program-manifest.json"
manifest_report="$tmpdir/program-manifest-report.json"
quality_output="$tmpdir/issue-quality-report.json"
projected_issues_output="$tmpdir/projected-issues.json"
materialize_output="$tmpdir/materialize-report.json"

python3 planningops/scripts/core/backlog/materialize.py \
  --contract-file "$contract_file" \
  --repo rather-not-work-on/platform-planningops \
  --initiative unified-personal-agent-platform \
  --compile-output "$compile_output" \
  --label-output "$label_output" \
  --manifest-output "$manifest_output" \
  --manifest-report "$manifest_report" \
  --quality-output "$quality_output" \
  --projected-issues-output "$projected_issues_output" \
  --output "$materialize_output"

python3 - <<'PY' \
  "$materialize_output" \
  "$compile_output" \
  "$label_output" \
  "$manifest_output" \
  "$manifest_report" \
  "$quality_output" \
  "$projected_issues_output"
import json
import sys
from pathlib import Path


def load(path_arg: str):
    return json.loads(Path(path_arg).read_text(encoding="utf-8"))


materialize_report = load(sys.argv[1])
compile_report = load(sys.argv[2])
label_report = load(sys.argv[3])
manifest = load(sys.argv[4])
manifest_report = load(sys.argv[5])
quality_report = load(sys.argv[6])
projected_issues = load(sys.argv[7])

assert materialize_report["verdict"] == "pass", materialize_report
assert materialize_report["mode"] == "dry-run", materialize_report
assert materialize_report["plan_id"] == "uap-backlog-wave26", materialize_report
assert materialize_report["projected_issue_count"] == 1, materialize_report
assert materialize_report["projected_issues_output"] == sys.argv[7], materialize_report
assert materialize_report["step_count"] == 4, materialize_report
assert [step["name"] for step in materialize_report["steps"]] == [
    "compile_plan_to_backlog",
    "backfill_issue_labels",
    "build_program_manifest",
    "validate_issue_quality",
], materialize_report["steps"]
assert all(step["verdict"] == "pass" for step in materialize_report["steps"]), materialize_report["steps"]

assert compile_report["verdict"] == "pass", compile_report
assert compile_report["mode"] == "dry-run", compile_report
assert compile_report["items_total"] == 1, compile_report
assert compile_report["issues_source"] == f"file:{sys.argv[7]}", compile_report
assert len(compile_report["results"]) == 1, compile_report
assert compile_report["results"][0]["plan_item_id"] == "A60", compile_report["results"][0]
assert compile_report["results"][0]["issue_number"] == 60, compile_report["results"][0]

assert len(projected_issues) == 1, projected_issues
assert projected_issues[0]["number"] == 60, projected_issues[0]
assert sorted(label["name"] for label in projected_issues[0]["labels"]) == [
    "area/planningops",
    "p2",
    "task",
    "type/hardening",
], projected_issues[0]

assert label_report["mode"] == "apply", label_report
assert label_report["issues_in_scope"] == 1, label_report
assert label_report["issues_applied"] == 1, label_report

assert manifest["item_count"] == 1, manifest
assert [row["plan_item_id"] for row in manifest["items"]] == ["A60"], manifest
assert manifest_report["verdict"] == "pass", manifest_report
assert manifest_report["item_count"] == 1, manifest_report

assert quality_report["verdict"] == "pass", quality_report
assert quality_report["issues_in_scope"] == 1, quality_report
assert quality_report["violation_count"] == 0, quality_report

print("backlog materialize sample report smoke ok")
PY
