#!/usr/bin/env bash
set -euo pipefail

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

policy_path="$tmp_dir/policy.json"
cat > "$policy_path" <<JSON
{
  "policy_version": 1,
  "default_external_backend": "local",
  "pointer_manifest_root": "$tmp_dir/pointers",
  "tiers": {
    "git_canonical": ["planningops/artifacts/validation/**"],
    "git_optional": [],
    "external_only": ["planningops/artifacts/loops/**"]
  },
  "backends": {
    "local": {"kind": "local", "base_path": "$tmp_dir/external-local"},
    "s3": {"kind": "s3_mock", "bucket": "demo-bucket", "prefix": "planningops", "mock_base_path": "$tmp_dir/external-s3"},
    "oci": {"kind": "oci_mock", "namespace": "demo-ns", "bucket": "demo-bucket", "prefix": "planningops", "mock_base_path": "$tmp_dir/external-oci"}
  }
}
JSON

actual_summary="$tmp_dir/artifact-sink-e2e.test.json"

python3 - <<'PY' "$policy_path" "$tmp_dir" "$actual_summary"
import json
import sys
from pathlib import Path

repo_root = Path.cwd()
sys.path.insert(0, str(repo_root / "planningops/scripts"))
from artifact_sink import ArtifactSink  # noqa: E402

policy = Path(sys.argv[1])
tmp = Path(sys.argv[2])
summary_path = Path(sys.argv[3])

local_sink = ArtifactSink(policy_path=policy, backend_override="local", local_cache_external=False)
local_sink.write_json("planningops/artifacts/loops/demo/run.json", {"verdict": "pass", "attempt": 1})
local_pointer = tmp / "pointers/loops/demo/run.json.pointer.json"
rehydrated_local = tmp / "rehydrated-local.json"
local_sink.rehydrate_from_pointer(local_pointer, rehydrated_local)

s3_sink = ArtifactSink(policy_path=policy, backend_override="s3", local_cache_external=False)
s3_sink.write_text("planningops/artifacts/loops/demo/replay.ndjson", '{"event":"a"}\n', append=False)
s3_pointer = tmp / "pointers/loops/demo/replay.ndjson.pointer.json"
rehydrated_s3 = tmp / "rehydrated-s3.ndjson"
s3_sink.rehydrate_from_pointer(s3_pointer, rehydrated_s3)


def normalize_pointer(doc):
    normalized = json.loads(json.dumps(doc))
    normalized["generated_at_utc"] = "__GENERATED_AT__"
    normalized["policy_path"] = "__POLICY_PATH__"
    normalized["backend_target_path"] = "__BACKEND_TARGET_PATH__"
    if normalized.get("backend") == "local":
        normalized["uri"] = "__URI__"
    return normalized


summary = {
    "summary_version": 1,
    "local_pointer": normalize_pointer(json.loads(local_pointer.read_text(encoding="utf-8"))),
    "s3_pointer": normalize_pointer(json.loads(s3_pointer.read_text(encoding="utf-8"))),
    "rehydrated_local": json.loads(rehydrated_local.read_text(encoding="utf-8")),
    "rehydrated_s3": rehydrated_s3.read_text(encoding="utf-8"),
}

summary_path.write_text(json.dumps(summary, ensure_ascii=True, indent=2), encoding="utf-8")
PY

python3 - <<'PY' "$actual_summary" "planningops/artifacts/validation/artifact-sink-e2e.test.json"
import json
import sys
from pathlib import Path

actual = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expected = json.loads(Path(sys.argv[2]).read_text(encoding="utf-8"))
assert actual == expected, (actual, expected)
print("artifact sink e2e artifact lane ok")
PY
