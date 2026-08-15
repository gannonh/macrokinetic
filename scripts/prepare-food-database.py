#!/usr/bin/env python3
"""Refresh, validate, and package the exact food database for a release run."""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path

from food_database.delta import apply_delta_chain
from food_database.full_build import build_full_database
from food_database.manifest import verify_manifest
from food_database.metadata import load_full_export_metadata
from food_database.packaging import package_candidate
from food_database.snapshots import select_snapshot_delta
from food_database.validation import validate_database


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--foundation-json", type=Path, required=True)
    parser.add_argument("--sr-legacy-json", type=Path, required=True)
    parser.add_argument("--off-csv-gzip", type=Path, required=True)
    parser.add_argument("--off-full-export-metadata", type=Path)
    parser.add_argument("--off-full-export-url", required=True)
    parser.add_argument("--off-index", type=Path, required=True)
    parser.add_argument("--delta-directory", type=Path, required=True)
    parser.add_argument("--snapshot-gzip", type=Path)
    parser.add_argument("--snapshot-manifest", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--artifact-parent", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--commit-sha", required=True)
    parser.add_argument("--marketing-version", required=True)
    parser.add_argument("--build-number", required=True)
    parser.add_argument("--created-at")
    parser.add_argument("--production", action="store_true")
    args = parser.parse_args()

    if bool(args.snapshot_gzip) != bool(args.snapshot_manifest):
        parser.error("--snapshot-gzip and --snapshot-manifest must be supplied together")

    now = int(datetime.now(timezone.utc).timestamp())
    build_mode = "full"
    applied_delta_files: list[str] = []
    used_snapshot = False
    off_cursor: int

    with tempfile.TemporaryDirectory(prefix="food-db-release-") as temporary_directory:
        working_database = Path(temporary_directory) / "usda_foods.sqlite"
        if args.snapshot_gzip and args.snapshot_manifest:
            snapshot_manifest = json.loads(
                args.snapshot_manifest.read_text(encoding="utf-8")
            )
            with gzip.open(args.snapshot_gzip, "rb") as source, working_database.open(
                "wb"
            ) as target:
                shutil.copyfileobj(source, target)
            manifest_errors = verify_manifest(
                snapshot_manifest, working_database, args.snapshot_gzip
            )
            if manifest_errors:
                raise SystemExit("Snapshot manifest verification failed: " + "; ".join(manifest_errors))

            selection = select_snapshot_delta(
                snapshot_manifest,
                args.off_index.read_text(encoding="utf-8"),
                now_epoch=now,
            )
            if selection is not None:
                delta_files = []
                for interval in selection.intervals:
                    path = args.delta_directory / interval.filename
                    if not path.is_file():
                        raise SystemExit(f"Selected delta is missing: {path}")
                    delta_files.append((interval, path))
                apply_delta_chain(
                    working_database,
                    delta_files,
                    cursor=int(snapshot_manifest["off_cursor"]),
                )
                build_mode = "delta"
                applied_delta_files = [
                    interval.filename for interval in selection.intervals
                ]
                off_cursor = selection.cursor
                used_snapshot = True

        if not used_snapshot:
            if args.off_full_export_metadata is None:
                raise SystemExit("an authoritative full-export metadata file is required for a full rebuild")
            metadata = load_full_export_metadata(
                args.off_full_export_metadata,
                expected_export_url=args.off_full_export_url,
            )
            if _sha256(args.off_csv_gzip) != metadata.source_sha256:
                raise SystemExit(
                    "Open Food Facts full export checksum does not match authoritative metadata"
                )
            build_full_database(
                working_database,
                foundation_json=args.foundation_json,
                sr_legacy_json=args.sr_legacy_json,
                off_csv_gzip=args.off_csv_gzip,
                off_cursor=metadata.covered_through_delta_end,
            )
            off_cursor = metadata.covered_through_delta_end

        validation = validate_database(working_database, production=args.production)
        if not validation.ok:
            raise SystemExit("Candidate validation failed: " + "; ".join(validation.errors))

        package = package_candidate(
            working_database,
            args.artifact_parent,
            run_id=args.run_id,
            created_at=args.created_at or datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            commit_sha=args.commit_sha,
            usda_urls={
                "foundation": "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_json_2024-04-18.zip",
                "sr_legacy": "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip",
            },
            off_full_export_url=args.off_full_export_url,
            off_cursor=off_cursor,
            build_mode=build_mode,
            applied_delta_files=applied_delta_files,
            marketing_version=args.marketing_version,
            build_number=args.build_number,
        )

    manifest = json.loads(package.manifest.read_text(encoding="utf-8"))
    print(json.dumps({"package": str(package.directory), "manifest": manifest}, sort_keys=True))


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


if __name__ == "__main__":
    main()
