#!/usr/bin/env python3

import hashlib
import json
import os
from datetime import datetime, timezone
from fnmatch import fnmatch
from pathlib import Path


DEFAULT_POLICY_PATH = Path("planningops/config/artifact-storage-policy.json")


def now_utc():
    return datetime.now(timezone.utc).isoformat()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def bool_env(name: str, default: bool):
    raw = os.getenv(name)
    if raw is None:
        return default
    return str(raw).strip().lower() in {"1", "true", "yes", "on"}


class ArtifactSink:
    def __init__(self, policy_path: str | Path = DEFAULT_POLICY_PATH, backend_override: str | None = None, local_cache_external: bool | None = None):
        self.policy_path = Path(policy_path)
        self.policy = load_json(self.policy_path)
        self.policy_version = int(self.policy.get("policy_version", 0))
        configured_default = str(self.policy.get("default_external_backend", "local"))
        env_backend = os.getenv("PLANNINGOPS_ARTIFACT_SINK_BACKEND")
        self.backend = backend_override or env_backend or configured_default
        if local_cache_external is None:
            self.local_cache_external = bool_env("PLANNINGOPS_ARTIFACT_SINK_LOCAL_CACHE", True)
        else:
            self.local_cache_external = bool(local_cache_external)

        self.pointer_root = Path(str(self.policy.get("pointer_manifest_root", "planningops/artifacts/pointers")))
        self.tiers = self.policy.get("tiers", {}) if isinstance(self.policy.get("tiers"), dict) else {}
        self.backends = self.policy.get("backends", {}) if isinstance(self.policy.get("backends"), dict) else {}

    def tier_for_path(self, logical_path: str | Path):
        path = Path(logical_path).as_posix()
        for tier_name in ["external_only", "git_canonical", "git_optional"]:
            patterns = self.tiers.get(tier_name, [])
            if not isinstance(patterns, list):
                continue
            for pattern in patterns:
                if isinstance(pattern, str) and pattern and fnmatch(path, pattern):
                    return tier_name
        return "git_canonical"

    def _artifact_rel(self, logical_path: Path):
        root = Path("planningops/artifacts")
        logical = Path(logical_path)
        try:
            return logical.relative_to(root)
        except Exception:  # noqa: BLE001
            return None

    def _backend_target(self, logical_path: Path):
        rel = self._artifact_rel(logical_path)
        if rel is None:
            return logical_path, f"file://{logical_path.as_posix()}"

        cfg = self.backends.get(self.backend, {})
        kind = str(cfg.get("kind", "local"))
        if kind == "local":
            base = Path(str(cfg.get("base_path", "planningops/runtime-artifacts/local")))
            target = base / rel
            uri = f"file://{target.as_posix()}"
            return target, uri
        if kind == "s3_mock":
            base = Path(str(cfg.get("mock_base_path", "planningops/runtime-artifacts/s3-mock")))
            target = base / rel
            bucket = str(cfg.get("bucket", "planningops-artifacts-dev"))
            prefix = str(cfg.get("prefix", "planningops")).strip("/")
            uri = f"s3://{bucket}/{prefix}/{rel.as_posix()}"
            return target, uri
        if kind == "oci_mock":
            base = Path(str(cfg.get("mock_base_path", "planningops/runtime-artifacts/oci-mock")))
            target = base / rel
            namespace = str(cfg.get("namespace", "planningops-local"))
            bucket = str(cfg.get("bucket", "planningops-artifacts-dev"))
            prefix = str(cfg.get("prefix", "planningops")).strip("/")
            uri = f"oci://{namespace}/{bucket}/{prefix}/{rel.as_posix()}"
            return target, uri

        raise ValueError(f"unsupported artifact sink backend kind: {kind}")

    def _pointer_path(self, logical_path: Path):
        rel = self._artifact_rel(logical_path)
        if rel is None:
            return self.pointer_root / f"{logical_path.name}.pointer.json"
        return self.pointer_root / rel.parent / f"{rel.name}.pointer.json"

    def _write_local_bytes(self, path: Path, data: bytes, append: bool):
        path.parent.mkdir(parents=True, exist_ok=True)
        mode = "ab" if append else "wb"
        with path.open(mode) as f:
            f.write(data)

    def _write_pointer(self, logical_path: Path, backend_target: Path, uri: str, tier: str):
        pointer_path = self._pointer_path(logical_path)
        pointer_path.parent.mkdir(parents=True, exist_ok=True)
        digest = hashlib.sha256(backend_target.read_bytes()).hexdigest()
        pointer = {
            "generated_at_utc": now_utc(),
            "policy_path": str(self.policy_path),
            "policy_version": self.policy_version,
            "tier": tier,
            "logical_path": logical_path.as_posix(),
            "backend": self.backend,
            "uri": uri,
            "backend_target_path": backend_target.as_posix(),
            "bytes": backend_target.stat().st_size,
            "sha256": digest,
            "local_cache_external": self.local_cache_external,
        }
        pointer_path.write_text(json.dumps(pointer, ensure_ascii=True, indent=2), encoding="utf-8")
        return pointer_path

    def runtime_path(self, logical_path: str | Path):
        logical = Path(logical_path)
        tier = self.tier_for_path(logical)
        if tier != "external_only":
            return logical
        if self.local_cache_external and logical.exists():
            return logical
        backend_target, _ = self._backend_target(logical)
        return backend_target

    def resolve_read_path(self, logical_path: str | Path):
        logical = Path(logical_path)
        if logical.exists():
            return logical
        if self.tier_for_path(logical) == "external_only":
            backend_target, _ = self._backend_target(logical)
            if backend_target.exists():
                return backend_target
        return logical

    def write_bytes(self, logical_path: str | Path, data: bytes, append: bool = False):
        logical = Path(logical_path)
        tier = self.tier_for_path(logical)
        if tier != "external_only":
            self._write_local_bytes(logical, data, append=append)
            return {"tier": tier, "logical_path": logical.as_posix(), "runtime_path": logical.as_posix(), "pointer_path": None}

        backend_target, uri = self._backend_target(logical)
        self._write_local_bytes(backend_target, data, append=append)
        if self.local_cache_external:
            self._write_local_bytes(logical, data, append=append)
        pointer_path = self._write_pointer(logical, backend_target, uri, tier)
        runtime = logical if self.local_cache_external else backend_target
        return {
            "tier": tier,
            "logical_path": logical.as_posix(),
            "runtime_path": runtime.as_posix(),
            "backend_target_path": backend_target.as_posix(),
            "pointer_path": pointer_path.as_posix(),
        }

    def write_text(self, logical_path: str | Path, text: str, append: bool = False):
        payload = (text or "").encode("utf-8")
        return self.write_bytes(logical_path, payload, append=append)

    def write_json(self, logical_path: str | Path, data):
        payload = json.dumps(data, ensure_ascii=True, indent=2).encode("utf-8")
        return self.write_bytes(logical_path, payload, append=False)

    def append_ndjson_row(self, logical_path: str | Path, row):
        payload = (json.dumps(row, ensure_ascii=True) + "\n").encode("utf-8")
        return self.write_bytes(logical_path, payload, append=True)

    def externalize_existing_file(self, logical_path: str | Path, delete_local: bool = True):
        logical = Path(logical_path)
        if self.tier_for_path(logical) != "external_only":
            return {"externalized": False, "reason": "non_external_tier", "logical_path": logical.as_posix()}
        if not logical.exists():
            return {"externalized": False, "reason": "missing_local_file", "logical_path": logical.as_posix()}
        data = logical.read_bytes()
        result = self.write_bytes(logical, data, append=False)
        if delete_local and logical.exists():
            logical.unlink()
        result["externalized"] = True
        return result

    def prune_local_external_file(self, logical_path: str | Path):
        logical = Path(logical_path)
        if self.tier_for_path(logical) != "external_only":
            return False
        if logical.exists() and logical.is_file():
            logical.unlink()
            return True
        return False

    def prune_local_external_tree(self, logical_root: str | Path):
        root = Path(logical_root)
        removed = 0
        if not root.exists():
            return removed
        if root.is_file():
            return 1 if self.prune_local_external_file(root) else 0
        for file_path in sorted(root.rglob("*")):
            if file_path.is_file() and self.tier_for_path(file_path) == "external_only":
                file_path.unlink()
                removed += 1
        for directory in sorted([p for p in root.rglob("*") if p.is_dir()], reverse=True):
            try:
                directory.rmdir()
            except OSError:
                pass
        try:
            root.rmdir()
        except OSError:
            pass
        return removed

    def rehydrate_from_pointer(self, pointer_path: str | Path, output_path: str | Path):
        pointer = load_json(Path(pointer_path))
        source = Path(str(pointer.get("backend_target_path", "")))
        if not source.exists():
            raise FileNotFoundError(f"pointer source missing: {source}")
        output = Path(output_path)
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes(source.read_bytes())
        return {
            "pointer_path": str(pointer_path),
            "output_path": output.as_posix(),
            "bytes": output.stat().st_size,
            "sha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        }
