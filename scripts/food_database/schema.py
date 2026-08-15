"""SQLite schema shared by full builds and delta mutation."""

from __future__ import annotations

import sqlite3


SCHEMA_VERSION = 2


def create_schema(connection: sqlite3.Connection) -> None:
    """Create the app-compatible foods table, FTS table, and maintenance objects."""
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
