"""Package validated databases as run-scoped, reproducible artifacts."""

from __future__ import annotations

import gzip
import os
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path

from .manifest import build_manifest, verify_manifest, write_manifest
from .validation import validate_database


class PackagingError(ValueError):
    """Raised when a candidate cannot be safely packaged."""


@dataclass(frozen=True)
class CandidatePackage:
    directory: Path
    database: Path
    compressed_database: Path
    manifest: Path


def package_candidate(
    database_path: str | Path,
    output_parent: str | Path,
    *,
    run_id: str,
    created_at: str,
    commit_sha: str,
    usda_urls: dict[str, str],
    off_full_export_url: str,
    off_cursor: int,
    build_mode: str,
    applied_delta_files: list[str],
    marketing_version: str | None = None,
    build_number: str | None = None,
) -> CandidatePackage:
    """Create ``food-db-candidate-<run_id>`` without overwriting prior runs."""
    database = Path(database_path)
    parent = Path(output_parent)
    if not run_id or Path(run_id).name != run_id:
        raise PackagingError("run_id must be a non-empty path-safe value")
    validation = validate_database(database)
    if not validation.ok:
        raise PackagingError("Database validation failed: " + "; ".join(validation.errors))

    parent.mkdir(parents=True, exist_ok=True)
    final_directory = parent / f"food-db-candidate-{run_id}"
    if final_directory.exists():
        raise FileExistsError(final_directory)

    temporary_directory = Path(
        tempfile.mkdtemp(prefix=f".food-db-candidate-{run_id}-", dir=parent)
    )
    try:
        database_copy = temporary_directory / "usda_foods.sqlite"
        shutil.copyfile(database, database_copy)
        compressed = temporary_directory / "usda_foods.sqlite.gz"
        _gzip_database(database, compressed)
        manifest_data = build_manifest(
            database,
            compressed,
            created_at=created_at,
            commit_sha=commit_sha,
            workflow_run_id=run_id,
            usda_urls=usda_urls,
            off_full_export_url=off_full_export_url,
            off_cursor=off_cursor,
            build_mode=build_mode,
            applied_delta_files=applied_delta_files,
            marketing_version=marketing_version,
            build_number=build_number,
        )
        manifest = temporary_directory / "food-db-manifest.json"
        write_manifest(manifest, manifest_data)
        errors = verify_manifest(manifest_data, database, compressed)
        if errors:
            raise PackagingError("Manifest verification failed: " + "; ".join(errors))
        os.replace(temporary_directory, final_directory)
    except Exception:
        shutil.rmtree(temporary_directory, ignore_errors=True)
        raise

    return CandidatePackage(
        final_directory,
        final_directory / "usda_foods.sqlite",
        final_directory / "usda_foods.sqlite.gz",
        final_directory / "food-db-manifest.json",
    )


def _gzip_database(database: Path, compressed: Path) -> None:
    with database.open("rb") as source, compressed.open("wb") as raw_output:
        with gzip.GzipFile(fileobj=raw_output, mode="wb", compresslevel=9, mtime=0) as output:
            shutil.copyfileobj(source, output)
