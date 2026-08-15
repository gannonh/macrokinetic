import json
import tempfile
import unittest
from pathlib import Path

from scripts.food_database.metadata import (
    FullExportMetadataError,
    load_full_export_metadata,
)


class MetadataTests(unittest.TestCase):
    def test_loads_matching_authoritative_full_export_boundary(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "metadata.json"
            path.write_text(
                json.dumps(
                    {
                        "full_export_url": "https://example.test/products.csv.gz",
                        "covered_through_delta_end": 123,
                        "source_sha256": "a" * 64,
                    }
                )
            )

            result = load_full_export_metadata(
                path,
                expected_export_url="https://example.test/products.csv.gz",
            )

        self.assertEqual(result.covered_through_delta_end, 123)
        self.assertEqual(result.source_sha256, "a" * 64)

    def test_rejects_missing_or_mismatched_authoritative_boundary(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "metadata.json"
            path.write_text(
                json.dumps(
                    {
                        "full_export_url": "https://example.test/products.csv.gz",
                        "source_sha256": "a" * 64,
                    }
                )
            )

            with self.assertRaises(FullExportMetadataError):
                load_full_export_metadata(
                    path,
                    expected_export_url="https://example.test/products.csv.gz",
                )

    def test_rejects_metadata_for_a_different_export(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "metadata.json"
            path.write_text(
                json.dumps(
                    {
                        "full_export_url": "https://example.test/other.csv.gz",
                        "covered_through_delta_end": 123,
                        "source_sha256": "a" * 64,
                    }
                )
            )

            with self.assertRaises(FullExportMetadataError):
                load_full_export_metadata(
                    path,
                    expected_export_url="https://example.test/products.csv.gz",
                )


if __name__ == "__main__":
    unittest.main()
