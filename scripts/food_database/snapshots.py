"""Immutable food-database snapshot tags and release selection."""

from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from .manifest import BUILD_MODES
from .schema import SCHEMA_VERSION


SNAPSHOT_TAG = re.compile(r"^food-db-(\d+)-([0-9a-fA-F]{12})$")
FULL_REBUILD_AFTER_SECONDS = 30 * 24 * 60 * 60


class SnapshotSelectionError(ValueError):
    """Raised when a promoted snapshot is malformed or unverifiable."""


@dataclass(frozen=True)
class SnapshotSelection:
    tag: str
    created_epoch: int
    manifest: dict[str, Any]
    gzip_asset: Mapping[str, Any]


def snapshot_tag(created_epoch: int, commit_sha: str) -> str:
    if created_epoch < 0 or not re.fullmatch(r"[0-9a-fA-F]{40}", commit_sha):
        raise ValueError("snapshot tags require a non-negative epoch and 40-character commit SHA")
    return f"food-db-{created_epoch}-{commit_sha[:12].lower()}"


def snapshot_requires_full_rebuild(
    created_epoch: int,
    *,
    now_epoch: int,
    max_age_seconds: int = FULL_REBUILD_AFTER_SECONDS,
) -> bool:
    """Return whether a snapshot is too old for delta-only maintenance."""
    if created_epoch < 0 or now_epoch < 0 or max_age_seconds < 0:
        raise ValueError("snapshot age inputs must be non-negative")
    return now_epoch - created_epoch >= max_age_seconds


def select_snapshot(
    releases: Sequence[Mapping[str, Any]],
) -> SnapshotSelection | None:
    """Choose the newest valid non-draft, non-prerelease release."""
    candidates: list[SnapshotSelection] = []
    for release in releases:
        if release.get("draft") or release.get("prerelease"):
            continue
        tag = str(release.get("tag_name", ""))
        if not tag.startswith("food-db-"):
            continue
        match = SNAPSHOT_TAG.fullmatch(tag)
        if match is None:
            raise SnapshotSelectionError(f"Invalid food database snapshot tag: {tag}")
        created_epoch = int(match.group(1))
        tag_sha = match.group(2).lower()
        assets = _assets_by_name(release.get("assets", []))
        manifest_asset = assets.get("food-db-manifest.json")
        gzip_asset = assets.get("usda_foods.sqlite.gz")
        if manifest_asset is None or gzip_asset is None:
            raise SnapshotSelectionError(f"Snapshot {tag} is missing required assets")
        manifest = _manifest_from_asset(manifest_asset)
        _validate_manifest_shape(manifest, tag, created_epoch, tag_sha)
        _validate_gzip_asset(gzip_asset, manifest, tag)
        candidates.append(SnapshotSelection(tag, created_epoch, manifest, gzip_asset))

    if not candidates:
        return None
    candidates.sort(key=lambda candidate: candidate.created_epoch, reverse=True)
    if len(candidates) > 1 and candidates[0].created_epoch == candidates[1].created_epoch:
        raise SnapshotSelectionError("Multiple snapshots share the same created epoch")
    return candidates[0]


def _assets_by_name(assets: Any) -> dict[str, Mapping[str, Any]]:
    if isinstance(assets, Mapping):
        return {
            str(name): value
            for name, value in assets.items()
            if isinstance(value, Mapping)
        }
    if not isinstance(assets, Sequence) or isinstance(assets, (str, bytes, bytearray)):
        raise SnapshotSelectionError("Release assets are malformed")
    result: dict[str, Mapping[str, Any]] = {}
    for asset in assets:
        if not isinstance(asset, Mapping) or not asset.get("name"):
            raise SnapshotSelectionError("Release contains a malformed asset")
        result[str(asset["name"])] = asset
    return result


def _manifest_from_asset(asset: Mapping[str, Any]) -> dict[str, Any]:
    content = asset.get("content")
    if content is None and asset.get("path"):
        try:
            content = Path(str(asset["path"])).read_text(encoding="utf-8")
        except OSError as error:
            raise SnapshotSelectionError("Manifest asset cannot be read") from error
    if isinstance(content, Mapping):
        return dict(content)
    if not isinstance(content, str):
        raise SnapshotSelectionError("Manifest asset has no JSON content")
    try:
        decoded = json.loads(content)
    except json.JSONDecodeError as error:
        raise SnapshotSelectionError("Manifest asset is not valid JSON") from error
    if not isinstance(decoded, dict):
        raise SnapshotSelectionError("Manifest JSON must be an object")
    return decoded


def _validate_manifest_shape(
    manifest: Mapping[str, Any],
    tag: str,
    created_epoch: int,
    tag_sha: str,
) -> None:
    required = {
        "schema_version",
        "created_epoch",
        "commit_sha",
        "gzip_sha256",
        "gzip_bytes",
        "database_sha256",
        "database_bytes",
        "build_mode",
        "off_cursor",
    }
    missing = sorted(required - manifest.keys())
    if missing:
        raise SnapshotSelectionError(f"Snapshot {tag} manifest is missing: {', '.join(missing)}")
    if manifest["schema_version"] != SCHEMA_VERSION:
        raise SnapshotSelectionError(f"Snapshot {tag} has an incompatible schema")
    if manifest["created_epoch"] != created_epoch:
        raise SnapshotSelectionError(f"Snapshot {tag} epoch does not match its manifest")
    commit_sha = str(manifest["commit_sha"]).lower()
    if not re.fullmatch(r"[0-9a-f]{40}", commit_sha) or commit_sha[:12] != tag_sha:
        raise SnapshotSelectionError(f"Snapshot {tag} commit provenance is invalid")
    if manifest["build_mode"] not in BUILD_MODES:
        raise SnapshotSelectionError(f"Snapshot {tag} build mode is invalid")
    if not isinstance(manifest["off_cursor"], int) or manifest["off_cursor"] < 0:
        raise SnapshotSelectionError(f"Snapshot {tag} cursor is invalid")
    for key in ("gzip_sha256", "database_sha256"):
        if not re.fullmatch(r"[0-9a-fA-F]{64}", str(manifest[key])):
            raise SnapshotSelectionError(f"Snapshot {tag} has an invalid {key}")
    for key in ("gzip_bytes", "database_bytes"):
        if not isinstance(manifest[key], int) or manifest[key] < 0:
            raise SnapshotSelectionError(f"Snapshot {tag} has an invalid {key}")


def _validate_gzip_asset(
    asset: Mapping[str, Any],
    manifest: Mapping[str, Any],
    tag: str,
) -> None:
    checksum = asset.get("sha256", asset.get("digest", ""))
    if isinstance(checksum, str) and checksum.startswith("sha256:"):
        checksum = checksum[7:]
    if checksum != manifest["gzip_sha256"]:
        raise SnapshotSelectionError(f"Snapshot {tag} gzip checksum does not match its manifest")
    if "size" in asset and asset["size"] != manifest["gzip_bytes"]:
        raise SnapshotSelectionError(f"Snapshot {tag} gzip size does not match its manifest")
    path = asset.get("path")
    if path:
        file_path = Path(str(path))
        if not file_path.is_file():
            raise SnapshotSelectionError(f"Snapshot {tag} gzip asset cannot be read")
        if _sha256(file_path) != manifest["gzip_sha256"]:
            raise SnapshotSelectionError(f"Snapshot {tag} gzip file checksum is invalid")


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
