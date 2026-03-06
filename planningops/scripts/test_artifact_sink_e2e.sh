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

python3 - <<'PY' "$policy_path" "$tmp_dir"
import json
import sys
from pathlib import Path

repo_root = Path.cwd()
sys.path.insert(0, str(repo_root / "planningops/scripts"))
from artifact_sink import ArtifactSink  # noqa: E402

policy = Path(sys.argv[1])
tmp = Path(sys.argv[2])

local_sink = ArtifactSink(policy_path=policy, backend_override="local", local_cache_external=False)
local_sink.write_json("planningops/artifacts/loops/demo/run.json", {"verdict": "pass", "attempt": 1})
local_pointer = tmp / "pointers/loops/demo/run.json.pointer.json"
assert local_pointer.exists(), f"missing pointer: {local_pointer}"
doc = json.loads(local_pointer.read_text(encoding="utf-8"))
assert doc["backend"] == "local", doc
rehydrated_local = tmp / "rehydrated-local.json"
local_sink.rehydrate_from_pointer(local_pointer, rehydrated_local)
assert json.loads(rehydrated_local.read_text(encoding="utf-8"))["verdict"] == "pass"

s3_sink = ArtifactSink(policy_path=policy, backend_override="s3", local_cache_external=False)
s3_sink.write_text("planningops/artifacts/loops/demo/replay.ndjson", '{"event":"a"}\n', append=False)
s3_pointer = tmp / "pointers/loops/demo/replay.ndjson.pointer.json"
assert s3_pointer.exists(), f"missing s3 pointer: {s3_pointer}"
s3_doc = json.loads(s3_pointer.read_text(encoding="utf-8"))
assert s3_doc["backend"] == "s3", s3_doc
assert s3_doc["uri"].startswith("s3://"), s3_doc
rehydrated_s3 = tmp / "rehydrated-s3.ndjson"
s3_sink.rehydrate_from_pointer(s3_pointer, rehydrated_s3)
assert rehydrated_s3.read_text(encoding="utf-8").strip() == '{"event":"a"}'

print("artifact sink e2e test ok")
PY
