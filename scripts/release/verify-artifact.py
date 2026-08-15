#!/usr/bin/env python3
"""Reject release artifacts whose provenance or checksums do not match."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from food_database.manifest import verify_manifest
from food_database.validation import validate_database


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--directory", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--commit-sha", required=True)
    parser.add_argument("--marketing-version", required=True)
    parser.add_argument("--build-number", required=True)
    args = parser.parse_args()

    directory = args.directory
    manifest_path = directory / "food-db-manifest.json"
    database = directory / "usda_foods.sqlite"
    compressed = directory / "usda_foods.sqlite.gz"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    expected = {
        "workflow_run_id": str(args.run_id),
        "commit_sha": args.commit_sha,
    }
    for key, value in expected.items():
        if manifest.get(key) != value:
            raise SystemExit(f"Manifest {key} does not match release provenance")
    if manifest.get("marketing_version") != args.marketing_version:
        raise SystemExit("Manifest marketing version does not match resolved release input")
    if str(manifest.get("build_number")) != str(args.build_number):
        raise SystemExit("Manifest build number does not match resolved release input")
    errors = verify_manifest(manifest, database, compressed)
    errors += validate_database(database, production=True).errors
    if errors:
        raise SystemExit("Artifact manifest verification failed: " + "; ".join(errors))
    print(json.dumps({"database_sha256": _sha256(database), "gzip_sha256": _sha256(compressed)}))


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


if __name__ == "__main__":
    main()
