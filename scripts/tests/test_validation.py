import gzip
import json
import sqlite3
import tempfile
import unittest
from contextlib import closing
from pathlib import Path

from scripts.food_database.manifest import build_manifest, write_manifest
from scripts.food_database.validation import validate_database


def create_fixture_database(path: Path) -> None:
    with closing(sqlite3.connect(path)) as connection, connection:
        connection.executescript(
            """
            CREATE TABLE foods (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                fdc_id INTEGER NOT NULL,
                barcode TEXT DEFAULT '',
                name TEXT NOT NULL,
                brand TEXT DEFAULT '',
                category TEXT DEFAULT '',
                source TEXT DEFAULT '',
                calories_per_100g REAL DEFAULT 0,
                protein_per_100g REAL DEFAULT 0,
                carbs_per_100g REAL DEFAULT 0,
                fat_per_100g REAL DEFAULT 0,
                fiber_per_100g REAL DEFAULT 0,
                serving_size REAL DEFAULT 100,
                serving_unit TEXT DEFAULT 'g',
                serving_options TEXT DEFAULT '[]'
            );
            CREATE VIRTUAL TABLE foods_fts USING fts5(
                name, category, content=foods, content_rowid=rowid
            );
            CREATE TRIGGER foods_ai AFTER INSERT ON foods BEGIN
                INSERT INTO foods_fts(rowid, name, category)
                VALUES (new.rowid, new.name, new.category);
            END;
            CREATE TRIGGER foods_ad AFTER DELETE ON foods BEGIN
                INSERT INTO foods_fts(foods_fts, rowid, name, category)
                VALUES ('delete', old.rowid, old.name, old.category);
            END;
            CREATE TRIGGER foods_au AFTER UPDATE ON foods BEGIN
                INSERT INTO foods_fts(foods_fts, rowid, name, category)
                VALUES ('delete', old.rowid, old.name, old.category);
                INSERT INTO foods_fts(rowid, name, category)
                VALUES (new.rowid, new.name, new.category);
            END;
            CREATE INDEX idx_foods_fdc_id ON foods(fdc_id);
            CREATE INDEX idx_foods_barcode ON foods(barcode);
            CREATE INDEX idx_foods_name ON foods(name);
            CREATE INDEX idx_foods_category ON foods(category);
            CREATE INDEX idx_foods_calories ON foods(calories_per_100g);
            CREATE UNIQUE INDEX idx_foods_off_barcode
                ON foods(barcode)
                WHERE source = 'openFoodFacts' AND barcode <> '';
            """
        )
        connection.executemany(
            """
            INSERT INTO foods (
                fdc_id, barcode, name, brand, category, source,
                calories_per_100g, protein_per_100g, carbs_per_100g,
                fat_per_100g, fiber_per_100g, serving_size,
                serving_unit, serving_options
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            [
                (1, "", "Chicken breast", "", "Meat", "foundation", 165, 31, 0, 3.6, 0, 100, "g", '["100g"]'),
                (2, "", "Brown rice", "", "Grains", "sr_legacy", 123, 2.7, 25.6, 1, 1.6, 100, "g", '["100g"]'),
                (3, "001", "Chocolate cookie", "Example", "Snacks", "openFoodFacts", 480, 6, 65, 22, 3, 30, "g", '["100g"]'),
                (4, "002", "Chocolate cookie", "Other", "Snacks", "openFoodFacts", 490, 5, 66, 23, 3, 30, "g", '["100g"]'),
            ],
        )


class ValidationTests(unittest.TestCase):
    def test_valid_fixture_passes_schema_integrity_and_search_checks(self):
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foods.sqlite"
            create_fixture_database(database)

            result = validate_database(database, required_searches={"chicken": 1, "cookie": 2})

        self.assertTrue(result.ok, result.errors)
        self.assertEqual(result.counts["total"], 4)
        self.assertEqual(result.counts["openFoodFacts"], 2)

    def test_production_thresholds_are_separate_from_fixture_validation(self):
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foods.sqlite"
            create_fixture_database(database)

            result = validate_database(database, production=True)

        self.assertFalse(result.ok)
        self.assertTrue(any("USDA" in error for error in result.errors))
        self.assertTrue(any("Open Food Facts" in error for error in result.errors))

    def test_duplicate_off_barcode_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foods.sqlite"
            create_fixture_database(database)
            with closing(sqlite3.connect(database)) as connection, connection:
                connection.execute("DROP INDEX idx_foods_off_barcode")
                connection.execute(
                    "UPDATE foods SET barcode = '001' WHERE barcode = '002'"
                )

            result = validate_database(database)

        self.assertFalse(result.ok)
        self.assertTrue(any("duplicate" in error.lower() for error in result.errors))

    def test_manifest_is_deterministic_and_records_database_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            database = Path(directory) / "foods.sqlite"
            compressed = Path(directory) / "foods.sqlite.gz"
            manifest_path = Path(directory) / "manifest.json"
            create_fixture_database(database)
            with database.open("rb") as source, gzip.open(compressed, "wb") as target:
                target.write(source.read())
            compressed_bytes = compressed.stat().st_size

            arguments = {
                "database_path": database,
                "compressed_database_path": compressed,
                "created_at": "2026-08-15T17:00:00Z",
                "commit_sha": "a" * 40,
                "workflow_run_id": "1234",
                "usda_urls": {"foundation": "https://example.test/foundation.zip"},
                "off_full_export_url": "https://example.test/products.csv.gz",
                "off_cursor": 20260814,
                "build_mode": "full",
                "applied_delta_files": [],
            }
            first = build_manifest(**arguments)
            second = build_manifest(**arguments)
            write_manifest(manifest_path, first)

            loaded = json.loads(manifest_path.read_text())

        self.assertEqual(first, second)
        self.assertEqual(first, loaded)
        self.assertEqual(first["total_rows"], 4)
        self.assertEqual(first["rows_by_source"]["openFoodFacts"], 2)
        self.assertEqual(first["build_mode"], "full")
        self.assertEqual(first["gzip_bytes"], compressed_bytes)


if __name__ == "__main__":
    unittest.main()
