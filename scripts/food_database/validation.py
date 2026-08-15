"""Validation for candidate and promoted JabTracker food databases."""

from __future__ import annotations

import sqlite3
from contextlib import closing
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


REQUIRED_COLUMNS = {
    "fdc_id",
    "barcode",
    "name",
    "brand",
    "category",
    "source",
    "calories_per_100g",
    "protein_per_100g",
    "carbs_per_100g",
    "fat_per_100g",
    "fiber_per_100g",
    "serving_size",
    "serving_unit",
    "serving_options",
}
REQUIRED_INDEXES = {
    "idx_foods_fdc_id",
    "idx_foods_barcode",
    "idx_foods_name",
    "idx_foods_category",
    "idx_foods_calories",
    "idx_foods_off_barcode",
}
REQUIRED_TRIGGERS = {"foods_ai", "foods_ad", "foods_au"}
PRODUCTION_SEARCHES = {"chicken": 1, "oreo": 1}


@dataclass(frozen=True)
class ValidationResult:
    """Structured validation evidence suitable for logs and manifests."""

    errors: tuple[str, ...]
    counts: dict[str, int]
    integrity_check: str

    @property
    def ok(self) -> bool:
        return not self.errors


def validate_database(
    database_path: str | Path,
    *,
    production: bool = False,
    required_searches: Mapping[str, int] | None = None,
) -> ValidationResult:
    """Validate SQLite integrity, schema, identity, FTS parity, and searches."""
    path = Path(database_path)
    if not path.is_file():
        return ValidationResult((f"Database does not exist: {path}",), {}, "missing")

    errors: list[str] = []
    counts: dict[str, int] = {}
    integrity_check = "unknown"

    try:
        with closing(sqlite3.connect(path)) as connection:
            connection.row_factory = sqlite3.Row
            objects = {
                row["name"]: row["type"]
                for row in connection.execute(
                    "SELECT name, type FROM sqlite_master WHERE name NOT LIKE 'sqlite_%'"
                ).fetchall()
            }
            if "foods" not in objects:
                errors.append("Missing required foods table")
            if "foods_fts" not in objects:
                errors.append("Missing required foods_fts table")

            if "foods" in objects:
                columns = {
                    row[1] for row in connection.execute("PRAGMA table_info(foods)")
                }
                missing_columns = sorted(REQUIRED_COLUMNS - columns)
                if missing_columns:
                    errors.append(f"Missing foods columns: {', '.join(missing_columns)}")

                indexes = {
                    row[1] for row in connection.execute("PRAGMA index_list(foods)")
                }
                missing_indexes = sorted(REQUIRED_INDEXES - indexes)
                if missing_indexes:
                    errors.append(f"Missing foods indexes: {', '.join(missing_indexes)}")

                triggers = {
                    row[0]
                    for row in connection.execute(
                        "SELECT name FROM sqlite_master WHERE type = 'trigger'"
                    )
                }
                missing_triggers = sorted(REQUIRED_TRIGGERS - triggers)
                if missing_triggers:
                    errors.append(
                        f"Missing foods FTS triggers: {', '.join(missing_triggers)}"
                    )

                integrity_check = connection.execute("PRAGMA integrity_check").fetchone()[0]
                if integrity_check != "ok":
                    errors.append(f"SQLite integrity check failed: {integrity_check}")

                counts["total"] = connection.execute(
                    "SELECT COUNT(*) FROM foods"
                ).fetchone()[0]
                for source in ("foundation", "sr_legacy", "openFoodFacts"):
                    counts[source] = connection.execute(
                        "SELECT COUNT(*) FROM foods WHERE source = ?", (source,)
                    ).fetchone()[0]

                missing_barcodes = connection.execute(
                    """
                    SELECT COUNT(*) FROM foods
                    WHERE source = 'openFoodFacts' AND TRIM(COALESCE(barcode, '')) = ''
                    """
                ).fetchone()[0]
                if missing_barcodes:
                    errors.append(
                        f"Open Food Facts rows with empty barcode identity: {missing_barcodes}"
                    )

                duplicate_barcodes = connection.execute(
                    """
                    SELECT barcode, COUNT(*)
                    FROM foods
                    WHERE source = 'openFoodFacts' AND TRIM(COALESCE(barcode, '')) <> ''
                    GROUP BY barcode
                    HAVING COUNT(*) > 1
                    LIMIT 5
                    """
                ).fetchall()
                if duplicate_barcodes:
                    examples = ", ".join(f"{row[0]} ({row[1]})" for row in duplicate_barcodes)
                    errors.append(f"Duplicate Open Food Facts barcodes: {examples}")

                if production:
                    usda_count = counts["foundation"] + counts["sr_legacy"]
                    if usda_count < 7_000:
                        errors.append(
                            f"USDA row count {usda_count} is below production minimum 7000"
                        )
                    if counts["openFoodFacts"] < 1_000_000:
                        errors.append(
                            "Open Food Facts row count "
                            f"{counts['openFoodFacts']} is below production minimum 1000000"
                        )

            if "foods_fts" in objects and "foods" in objects:
                counts["fts"] = connection.execute(
                    "SELECT COUNT(*) FROM foods_fts"
                ).fetchone()[0]
                if counts["fts"] != counts.get("total", 0):
                    errors.append(
                        f"FTS row count {counts['fts']} does not match foods row count {counts['total']}"
                    )

                searches = required_searches
                if searches is None and production:
                    searches = PRODUCTION_SEARCHES
                for term, minimum in (searches or {}).items():
                    matches = connection.execute(
                        """
                        SELECT COUNT(*)
                        FROM foods_fts
                        WHERE foods_fts MATCH ?
                        """,
                        (term,),
                    ).fetchone()[0]
                    if matches < minimum:
                        errors.append(
                            f"Representative search '{term}' returned {matches}, expected at least {minimum}"
                        )
    except sqlite3.DatabaseError as error:
        errors.append(f"SQLite validation failed: {error}")

    return ValidationResult(tuple(errors), counts, integrity_check)
