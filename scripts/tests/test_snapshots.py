import json
import tempfile
import unittest
from pathlib import Path

from scripts.food_database.packaging import package_candidate
from scripts.food_database.snapshots import (
    SnapshotSelectionError,
    select_snapshot,
    snapshot_requires_full_rebuild,
    snapshot_tag,
)
from scripts.tests.test_validation import create_fixture_database


def release_from_package(package):
    manifest = json.loads(package.manifest.read_text())
    return {
        "tag_name": snapshot_tag(manifest["created_epoch"], manifest["commit_sha"]),
        "draft": False,
        "prerelease": False,
        "assets": [
            {
                "name": "food-db-manifest.json",
                "content": json.dumps(manifest),
            },
            {
                "name": "usda_foods.sqlite.gz",
                "path": str(package.compressed_database),
                "sha256": manifest["gzip_sha256"],
                "size": manifest["gzip_bytes"],
            },
        ],
    }


class SnapshotTests(unittest.TestCase):
    def test_snapshots_at_least_thirty_days_old_require_a_full_rebuild(self):
        self.assertFalse(
            snapshot_requires_full_rebuild(1_000, now_epoch=1_000 + 30 * 24 * 60 * 60 - 1)
        )
        self.assertTrue(
            snapshot_requires_full_rebuild(1_000, now_epoch=1_000 + 30 * 24 * 60 * 60)
        )

    def test_selects_greatest_epoch_from_valid_promoted_releases(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            database = root / "foods.sqlite"
            create_fixture_database(database)
            older = package_candidate(
                database,
                root / "artifacts",
                run_id="1",
                created_at="2026-08-15T17:00:00Z",
                commit_sha="a" * 40,
                usda_urls={},
                off_full_export_url="https://example.test/products.csv.gz",
                off_cursor=100,
                build_mode="full",
                applied_delta_files=[],
            )
            newer = package_candidate(
                database,
                root / "artifacts",
                run_id="2",
                created_at="2026-08-15T18:00:00Z",
                commit_sha="b" * 40,
                usda_urls={},
                off_full_export_url="https://example.test/products.csv.gz",
                off_cursor=200,
                build_mode="delta",
                applied_delta_files=["openfoodfacts_products_100_200.json.gz"],
            )

            selection = select_snapshot([release_from_package(older), release_from_package(newer)])
            newer_tag = release_from_package(newer)["tag_name"]

        self.assertIsNotNone(selection)
        self.assertEqual(selection.manifest["off_cursor"], 200)
        self.assertEqual(selection.tag, newer_tag)

    def test_skips_draft_and_prerelease_and_returns_none_when_no_snapshot_exists(self):
        self.assertIsNone(
            select_snapshot(
                [
                    {"tag_name": "food-db-1-aaaaaaaaaaaa", "draft": True},
                    {"tag_name": "food-db-2-bbbbbbbbbbbb", "prerelease": True},
                ]
            )
        )

    def test_rejects_invalid_tag_manifest_and_asset_checksum(self):
        with self.assertRaises(SnapshotSelectionError):
            select_snapshot([{"tag_name": "food-db-invalid", "assets": []}])

        base_manifest = {
            "schema_version": 2,
            "created_epoch": 10,
            "commit_sha": "a" * 40,
            "gzip_sha256": "b" * 64,
            "gzip_bytes": 1,
            "database_sha256": "c" * 64,
            "database_bytes": 1,
            "build_mode": "full",
            "off_cursor": 1,
        }
        release = {
            "tag_name": "food-db-10-aaaaaaaaaaaa",
            "assets": [
                {"name": "food-db-manifest.json", "content": json.dumps(base_manifest)},
                {"name": "usda_foods.sqlite.gz", "sha256": "d" * 64, "size": 1},
            ],
        }
        with self.assertRaises(SnapshotSelectionError):
            select_snapshot([release])


if __name__ == "__main__":
    unittest.main()
