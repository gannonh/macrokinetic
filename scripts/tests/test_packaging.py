import json
import tempfile
import unittest
from pathlib import Path

from scripts.food_database.manifest import verify_manifest
from scripts.food_database.packaging import package_candidate
from scripts.tests.test_validation import create_fixture_database


class PackagingTests(unittest.TestCase):
    def test_packages_deterministic_gzip_and_verified_manifest(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            database = root / "foods.sqlite"
            create_fixture_database(database)
            package = package_candidate(
                database,
                root / "artifacts",
                run_id="123",
                created_at="2026-08-15T17:00:00Z",
                commit_sha="a" * 40,
                usda_urls={"foundation": "https://example.test/foundation.zip"},
                off_full_export_url="https://example.test/products.csv.gz",
                off_cursor=123,
                build_mode="full",
                applied_delta_files=[],
            )
            manifest = json.loads(package.manifest.read_text())
            errors = verify_manifest(
                manifest,
                database,
                package.compressed_database,
            )
            directory_name = package.directory.name
            asset_names = sorted(path.name for path in package.directory.iterdir())

        self.assertEqual(errors, ())
        self.assertEqual(directory_name, "food-db-candidate-123")
        self.assertEqual(asset_names, ["food-db-manifest.json", "usda_foods.sqlite.gz"])

    def test_run_scoped_candidate_cannot_be_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            database = root / "foods.sqlite"
            create_fixture_database(database)
            arguments = {
                "run_id": "123",
                "created_at": "2026-08-15T17:00:00Z",
                "commit_sha": "a" * 40,
                "usda_urls": {},
                "off_full_export_url": "https://example.test/products.csv.gz",
                "off_cursor": 123,
                "build_mode": "full",
                "applied_delta_files": [],
            }
            package_candidate(database, root / "artifacts", **arguments)
            with self.assertRaises(FileExistsError):
                package_candidate(database, root / "artifacts", **arguments)


if __name__ == "__main__":
    unittest.main()
