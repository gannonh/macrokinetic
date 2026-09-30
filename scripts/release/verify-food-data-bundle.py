#!/usr/bin/env python3
"""Check the food notices and exact provenance in an assembled app bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import plistlib
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse


def verify_bundle(app: Path, version: str, build: str, expected_sha: str) -> dict:
    with (app / "Info.plist").open("rb") as source:
        info = plistlib.load(source)
    if info.get("CFBundleShortVersionString") != version or str(info.get("CFBundleVersion")) != build:
        raise ValueError("App version/build differs from the release input")
    manifest = json.loads((app / "food-db-manifest.json").read_text(encoding="utf-8"))
    if not isinstance(manifest, dict):
        raise ValueError("Food manifest must be an object")
    if manifest.get("schema_version") != 2 or manifest.get("build_mode") not in {"full", "delta"}:
        raise ValueError("Unsupported food manifest schema/build mode")
    for key, pattern in (("database_sha256", r"[a-f0-9]{64}"), ("commit_sha", r"[a-f0-9]{40}"), ("workflow_run_id", r"[0-9]+")):
        if not isinstance(manifest.get(key), str) or not re.fullmatch(pattern, manifest[key]):
            raise ValueError(f"Invalid food manifest {key}")
    if manifest.get("marketing_version") != version or manifest.get("build_number") != build:
        raise ValueError("Food manifest version/build differs from the assembled app")
    for key in ("database_bytes", "total_rows", "created_epoch", "off_cursor"):
        if type(manifest.get(key)) is not int or manifest[key] <= 0:
            raise ValueError(f"Invalid food manifest {key}")
    if not isinstance(manifest.get("created_at"), str):
        raise ValueError("Invalid food manifest creation date")
    timestamp = datetime.fromisoformat(manifest["created_at"].replace("Z", "+00:00"))
    if timestamp.tzinfo is None or int(timestamp.timestamp()) != manifest["created_epoch"]:
        raise ValueError("Food manifest creation date/epoch differs")
    counts = manifest.get("rows_by_source")
    if not isinstance(counts, dict) or set(counts) != {"foundation", "sr_legacy", "openFoodFacts"}:
        raise ValueError("Food manifest source counts are incomplete")
    if any(type(count) is not int or count < 0 for count in counts.values()) or sum(counts.values()) != manifest["total_rows"]:
        raise ValueError("Food manifest source counts differ from its total")
    source_urls = manifest.get("usda_urls")
    if not isinstance(source_urls, dict) or set(source_urls) != {"foundation", "sr_legacy"}:
        raise ValueError("Food manifest USDA source URLs are incomplete")
    for url in source_urls.values():
        verify_source_url(url, "fdc.nal.usda.gov")
    verify_source_url(manifest.get("off_full_export_url"), "static.openfoodfacts.org")
    deltas = manifest.get("applied_delta_files")
    if not isinstance(deltas, list) or any(not isinstance(item, str) or not item for item in deltas):
        raise ValueError("Food manifest delta file list is invalid")
    verify_notices(app / "food-data-notices.json")
    database = app / "usda_foods.sqlite"
    if database.stat().st_size != manifest["database_bytes"]:
        raise ValueError("Bundled database size differs from its manifest")
    digest = hashlib.sha256()
    with database.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    actual_sha = digest.hexdigest()
    if actual_sha != manifest["database_sha256"] or actual_sha != expected_sha:
        raise ValueError("Bundled database checksum differs from its manifest or release input")
    return {"result": "PASS", "database_sha256": actual_sha, "commit_sha": manifest["commit_sha"],
            "workflow_run_id": manifest["workflow_run_id"], "marketing_version": version, "build_number": build}


def verify_source_url(value: object, hostname: str) -> None:
    if not isinstance(value, str):
        raise ValueError("Food manifest source URL must be a string")
    url = urlparse(value)
    if url.scheme != "https" or url.hostname != hostname or url.username or url.password:
        raise ValueError(f"Food source URL must use HTTPS on {hostname}")


def verify_notices(path: Path) -> None:
    notices = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(notices, dict) or notices.get("schema_version") != 1:
        raise ValueError("Unsupported food-source notices schema")
    sources = notices.get("sources")
    if not isinstance(sources, list) or len(sources) != 2 or any(not isinstance(source, dict) for source in sources):
        raise ValueError("Food-source notices must include USDA and Open Food Facts")
    if {source.get("id") for source in sources} != {"usda", "off"}:
        raise ValueError("Food-source notices must include USDA and Open Food Facts")
    required_links = {
        "usda": {"https://fdc.nal.usda.gov/", "https://fdc.nal.usda.gov/api-guide/", "https://creativecommons.org/publicdomain/zero/1.0/"},
        "off": {"https://world.openfoodfacts.org/", "https://opendatacommons.org/licenses/odbl/1-0/", "https://opendatacommons.org/licenses/dbcl/1-0/"},
    }
    for source in sources:
        for key in ("title", "notice"):
            if not isinstance(source.get(key), str) or not source[key].strip():
                raise ValueError(f"Food-source {key} is missing")
        links = source.get("links")
        if not isinstance(links, list) or any(not isinstance(link, dict) or not isinstance(link.get("label"), str) or not link["label"].strip() or not isinstance(link.get("url"), str) for link in links):
            raise ValueError("Food-source links are malformed")
        if not required_links[source["id"]].issubset({link["url"] for link in links}):
            raise ValueError("Food-source/license link is missing")
    if not isinstance(notices.get("image_notice"), str) or not notices["image_notice"].strip():
        raise ValueError("Food image-rights notice is missing")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, required=True)
    parser.add_argument("--expected-version", required=True)
    parser.add_argument("--expected-build", required=True)
    parser.add_argument("--expected-database-sha", required=True)
    args = parser.parse_args()
    try:
        report = verify_bundle(args.app, args.expected_version, args.expected_build, args.expected_database_sha)
    except (OSError, ValueError, KeyError, TypeError, plistlib.InvalidFileException) as error:
        print(f"Food bundle verification failed: {error}", file=sys.stderr)
        return 1
    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
