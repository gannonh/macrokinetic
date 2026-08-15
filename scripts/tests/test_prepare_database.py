import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path

from scripts.tests.test_full_build import write_sources


ROOT = Path(__file__).resolve().parents[2]


class PrepareDatabaseTests(unittest.TestCase):
    def test_full_fallback_requires_authoritative_metadata_and_packages_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            foundation, sr_legacy, off_csv = write_sources(root)
            metadata = root / "metadata.json"
            metadata.write_text(
                json.dumps(
                    {
                        "full_export_url": "https://example.test/products.csv.gz",
                        "covered_through_delta_end": 123,
                        "source_sha256": hashlib.sha256(off_csv.read_bytes()).hexdigest(),
                    }
                )
            )
            output = root / "foods.sqlite"
            artifacts = root / "artifacts"
            result = subprocess.run(
                [
                    "python3",
                    "scripts/prepare-food-database.py",
                    "--foundation-json",
                    str(foundation),
                    "--sr-legacy-json",
                    str(sr_legacy),
                    "--off-csv-gzip",
                    str(off_csv),
                    "--off-full-export-metadata",
                    str(metadata),
                    "--off-full-export-url",
                    "https://example.test/products.csv.gz",
                    "--off-index",
                    str(root / "index.txt"),
                    "--delta-directory",
                    str(root),
                    "--output",
                    str(output),
                    "--artifact-parent",
                    str(artifacts),
                    "--run-id",
                    "44",
                    "--commit-sha",
                    "a" * 40,
                    "--marketing-version",
                    "0.10.2",
                    "--build-number",
                    "17",
                ],
                cwd=ROOT,
                text=True,
                capture_output=True,
                check=True,
            )
            manifest = json.loads(
                (artifacts / "food-db-candidate-44" / "food-db-manifest.json").read_text()
            )

        self.assertEqual(manifest["off_cursor"], 123)
        self.assertEqual(manifest["workflow_run_id"], "44")
        self.assertEqual(manifest["marketing_version"], "0.10.2")
        self.assertEqual(manifest["build_number"], "17")
        self.assertIn("package", result.stdout)


if __name__ == "__main__":
    unittest.main()
