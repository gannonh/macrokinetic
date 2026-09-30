import hashlib
import json
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/release/verify-food-data-bundle.py"


class FoodDataBundleTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.app = Path(self.temporary.name) / "Fixture.app"
        self.app.mkdir()
        database = b"abc"
        self.sha = hashlib.sha256(database).hexdigest()
        (self.app / "usda_foods.sqlite").write_bytes(database)
        with (self.app / "Info.plist").open("wb") as target:
            plistlib.dump({"CFBundleShortVersionString": "1.0.0", "CFBundleVersion": "18"}, target, fmt=plistlib.FMT_BINARY)
        shutil.copyfile(ROOT / "JabTracker/Resources/food-data-notices.json", self.app / "food-data-notices.json")
        self.manifest = {
            "schema_version": 2, "database_sha256": self.sha, "database_bytes": 3,
            "commit_sha": "a" * 40, "workflow_run_id": "123", "created_at": "2026-09-30T20:00:00Z",
            "created_epoch": int(datetime.fromisoformat("2026-09-30T20:00:00+00:00").timestamp()),
            "build_mode": "full", "off_cursor": 123, "applied_delta_files": [],
            "total_rows": 3, "rows_by_source": {"foundation": 1, "sr_legacy": 1, "openFoodFacts": 1},
            "usda_urls": {"foundation": "https://fdc.nal.usda.gov/foundation.zip", "sr_legacy": "https://fdc.nal.usda.gov/sr.zip"},
            "off_full_export_url": "https://static.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz",
            "marketing_version": "1.0.0", "build_number": "18"
        }
        self.write_manifest()

    def write_manifest(self):
        (self.app / "food-db-manifest.json").write_text(json.dumps(self.manifest))

    def run_check(self, expected_sha=None):
        return subprocess.run([sys.executable, str(SCRIPT), "--app", str(self.app),
                               "--expected-version", "1.0.0", "--expected-build", "18",
                               "--expected-database-sha", expected_sha or self.sha], capture_output=True, text=True)

    def test_valid_binary_plist_bundle_reports_exact_hash_and_build(self):
        result = self.run_check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout), {
            "result": "PASS", "database_sha256": "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
            "commit_sha": "a" * 40, "workflow_run_id": "123", "marketing_version": "1.0.0", "build_number": "18"
        })

    def test_missing_manifest_and_notices_fail_closed(self):
        for name in ("food-db-manifest.json", "food-data-notices.json"):
            with self.subTest(name=name):
                path = self.app / name
                content = path.read_bytes()
                path.unlink()
                self.assertEqual(self.run_check().returncode, 1)
                path.write_bytes(content)

    def test_equal_size_changed_database_and_expected_hash_fail_closed(self):
        (self.app / "usda_foods.sqlite").write_bytes(b"abd")
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("checksum differs", result.stderr)
        (self.app / "usda_foods.sqlite").write_bytes(b"abc")
        self.assertEqual(self.run_check("b" * 64).returncode, 1)

    def test_wrong_app_or_manifest_build_fails(self):
        self.manifest["build_number"] = "19"
        self.write_manifest()
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("version/build differs", result.stderr)
        self.manifest["build_number"] = "18"
        self.write_manifest()
        (self.app / "Info.plist").write_bytes(plistlib.dumps({"CFBundleShortVersionString": "1.0.1", "CFBundleVersion": "18"}))
        self.assertEqual(self.run_check().returncode, 1)

    def test_source_url_date_counts_and_schema_must_be_valid(self):
        replacements = {"off_full_export_url": "https://example.test/data.csv", "created_epoch": 1,
                        "rows_by_source": {"foundation": 1}, "schema_version": 99, "database_bytes": True, "created_at": 1}
        for key, value in replacements.items():
            with self.subTest(key=key):
                original = self.manifest[key]
                self.manifest[key] = value
                self.write_manifest()
                result = self.run_check()
                self.assertEqual(result.returncode, 1, result.stdout)
                self.assertNotIn("Traceback", result.stderr)
                self.manifest[key] = original

    def test_missing_odbl_link_cannot_pass_with_source_credit_alone(self):
        path = self.app / "food-data-notices.json"
        notices = json.loads(path.read_text())
        notices["sources"][1]["links"] = [{"label": "Open Food Facts", "url": "https://world.openfoodfacts.org/"}]
        path.write_text(json.dumps(notices))
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("license link is missing", result.stderr)

    def test_malformed_manifest_is_a_readable_failure(self):
        (self.app / "food-db-manifest.json").write_text("[]")
        result = self.run_check()
        self.assertEqual(result.returncode, 1)
        self.assertIn("must be an object", result.stderr)
        self.assertNotIn("Traceback", result.stderr)


if __name__ == "__main__":
    unittest.main()
