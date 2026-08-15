"""Deterministic provenance manifests for food-database artifacts."""

from __future__ import annotations

import hashlib
import json
import sqlite3
from contextlib import closing
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Sequence


SCHEMA_VERSION = 1
BUILD_MODES = frozenset({"full", "delta"})


def build_manifest(
    database_path: str | Path,
    compressed_database_path: str | Path,
    *,
    created_at: str,
    commit_sha: str,
    workflow_run_id: str,
    usda_urls: dict[str, str],
    off_full_export_url: str,
    off_cursor: int,
    build_mode: str,
    applied_delta_files: Sequence[str],
    schema_version: int = SCHEMA_VERSION,
) -> dict[str, Any]:
    """Build the complete manifest from the exact database artifacts."""
    database = Path(database_path)
    compressed = Path(compressed_database_path)
    if not database.is_file():
        raise FileNotFoundError(database)
    if not compressed.is_file():
        raise FileNotFoundError(compressed)
    if build_mode not in BUILD_MODES:
        raise ValueError(f"Unsupported build mode: {build_mode}")

    created_epoch = _created_epoch(created_at)
    counts = _row_counts(database)
    return {
        "schema_version": schema_version,
        "created_at": created_at,
        "created_epoch": created_epoch,
        "commit_sha": commit_sha,
        "workflow_run_id": str(workflow_run_id),
        "database_sha256": _sha256(database),
        "database_bytes": database.stat().st_size,
        "gzip_sha256": _sha256(compressed),
        "gzip_bytes": compressed.stat().st_size,
        "total_rows": counts["total"],
        "rows_by_source": {
            "foundation": counts["foundation"],
            "sr_legacy": counts["sr_legacy"],
            "openFoodFacts": counts["openFoodFacts"],
        },
        "usda_urls": dict(sorted(usda_urls.items())),
        "off_full_export_url": off_full_export_url,
        "off_cursor": int(off_cursor),
        "build_mode": build_mode,
        "applied_delta_files": list(applied_delta_files),
    }


def write_manifest(path: str | Path, manifest: dict[str, Any]) -> None:
    """Write a stable, reviewable JSON representation of a manifest."""
    target = Path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps(manifest, sort_keys=True, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


def _row_counts(database: Path) -> dict[str, int]:
    with closing(sqlite3.connect(database)) as connection:
        counts = {
            "total": connection.execute("SELECT COUNT(*) FROM foods").fetchone()[0]
        }
        for source in ("foundation", "sr_legacy", "openFoodFacts"):
            counts[source] = connection.execute(
                "SELECT COUNT(*) FROM foods WHERE source = ?", (source,)
            ).fetchone()[0]
    return counts


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _created_epoch(created_at: str) -> int:
    normalized = created_at[:-1] + "+00:00" if created_at.endswith("Z") else created_at
    timestamp = datetime.fromisoformat(normalized)
    if timestamp.tzinfo is None:
        timestamp = timestamp.replace(tzinfo=timezone.utc)
    return int(timestamp.timestamp())
