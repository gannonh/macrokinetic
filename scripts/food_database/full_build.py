"""Atomic, streaming construction of a complete food database snapshot."""

from __future__ import annotations

import csv
import gzip
import json
import os
import sqlite3
import tempfile
from collections.abc import Iterator, Mapping
from contextlib import closing
from dataclasses import dataclass
from json import JSONDecodeError, JSONDecoder
from pathlib import Path
from typing import Any

from .normalization import normalize_off_product, normalize_usda_food
from .schema import create_schema
from .validation import validate_database


class FullBuildError(ValueError):
    """Raised when a full-build input cannot produce a publishable snapshot."""


@dataclass(frozen=True)
class FullBuildResult:
    database_path: Path
    off_cursor: int
    rows_by_source: dict[str, int]

    @property
    def total_rows(self) -> int:
        return sum(self.rows_by_source.values())


def build_full_database(
    output_path: str | Path,
    *,
    foundation_json: str | Path,
    sr_legacy_json: str | Path,
    off_csv_gzip: str | Path,
    off_cursor: int | None,
    us_only: bool = False,
) -> FullBuildResult:
    """Build and atomically publish a complete database from source files.

    ``off_cursor`` must come from authoritative full-export metadata.  The
    builder deliberately has no fallback to download time or a live delta
    index watermark.
    """
    if off_cursor is None or off_cursor < 0:
        raise FullBuildError("An authoritative non-negative Open Food Facts cursor is required")

    foundation = _required_file(foundation_json)
    sr_legacy = _required_file(sr_legacy_json)
    off_csv = _required_file(off_csv_gzip)
    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{output.name}.", suffix=".candidate", dir=output.parent
    )
    os.close(descriptor)
    temporary = Path(temporary_name)

    rows_by_source = {"foundation": 0, "sr_legacy": 0, "openFoodFacts": 0}
    try:
        with closing(sqlite3.connect(temporary)) as connection, connection:
            create_schema(connection)
            connection.execute("BEGIN")
            next_off_id = 2_000_000
            seen_usda_ids: set[int] = set()

            for source, path, collection in (
                ("foundation", foundation, "FoundationFoods"),
                ("sr_legacy", sr_legacy, "SRLegacyFoods"),
            ):
                for food in iter_json_array_records(path, collection):
                    record = normalize_usda_food(food, source)
                    if record is None or record.fdc_id <= 0:
                        continue
                    if record.fdc_id in seen_usda_ids:
                        continue
                    seen_usda_ids.add(record.fdc_id)
                    connection.execute(
                        _insert_sql(),
                        record.to_database_row(),
                    )
                    rows_by_source[source] += 1

            with gzip.open(off_csv, "rt", encoding="utf-8", errors="replace") as source_file:
                reader = csv.reader(source_file, delimiter="\t")
                try:
                    next(reader)
                except StopIteration as error:
                    raise FullBuildError(f"Open Food Facts CSV is empty: {off_csv}") from error

                for row in reader:
                    if len(row) < 151 or (us_only and not _is_us_row(row)):
                        continue
                    record = normalize_off_product(row)
                    if record is None:
                        continue
                    row_values = record.to_database_row()
                    row_values["fdc_id"] = next_off_id
                    cursor = connection.execute(
                        _insert_sql("INSERT OR IGNORE"),
                        row_values,
                    )
                    if cursor.rowcount == 1:
                        rows_by_source["openFoodFacts"] += 1
                        next_off_id += 1

            connection.execute("INSERT INTO foods_fts(foods_fts) VALUES ('optimize')")
            connection.commit()

        validation = validate_database(temporary)
        if not validation.ok:
            raise FullBuildError("Candidate validation failed: " + "; ".join(validation.errors))
        os.replace(temporary, output)
    except Exception:
        temporary.unlink(missing_ok=True)
        raise

    return FullBuildResult(output, off_cursor, rows_by_source)


def iter_json_array_records(path: str | Path, collection_key: str) -> Iterator[Mapping[str, Any]]:
    """Yield objects from one top-level USDA array without loading the file at once."""
    source_path = Path(path)
    decoder = JSONDecoder()
    marker = f'"{collection_key}"'
    buffer = ""
    found_array = False
    end_of_file = False

    with source_path.open("r", encoding="utf-8") as source:
        while True:
            if not found_array:
                marker_position = buffer.find(marker)
                if marker_position < 0:
                    chunk = source.read(1024 * 1024)
                    if not chunk:
                        raise FullBuildError(
                            f"USDA collection '{collection_key}' not found in {source_path}"
                        )
                    buffer += chunk
                    continue
                array_position = buffer.find("[", marker_position + len(marker))
                if array_position < 0:
                    chunk = source.read(1024 * 1024)
                    if not chunk:
                        raise FullBuildError(f"Malformed USDA collection in {source_path}")
                    buffer += chunk
                    continue
                buffer = buffer[array_position + 1 :]
                found_array = True

            buffer = buffer.lstrip()
            if buffer.startswith("]"):
                return
            if not buffer:
                chunk = source.read(1024 * 1024)
                if not chunk:
                    end_of_file = True
                else:
                    buffer += chunk
                if end_of_file:
                    raise FullBuildError(f"Unterminated USDA collection in {source_path}")
                continue

            try:
                record, consumed = decoder.raw_decode(buffer)
            except JSONDecodeError:
                chunk = source.read(1024 * 1024)
                if not chunk:
                    raise FullBuildError(f"Malformed USDA record in {source_path}")
                buffer += chunk
                continue

            if not isinstance(record, Mapping):
                raise FullBuildError(f"USDA collection contains a non-object in {source_path}")
            yield record
            buffer = buffer[consumed:].lstrip()
            if buffer.startswith(","):
                buffer = buffer[1:]
            elif not buffer.startswith("]") and buffer:
                raise FullBuildError(f"Malformed USDA collection separators in {source_path}")


def _required_file(path: str | Path) -> Path:
    resolved = Path(path)
    if not resolved.is_file():
        raise FullBuildError(f"Required source file does not exist: {resolved}")
    return resolved


def _insert_sql(prefix: str = "INSERT") -> str:
    return """
        {prefix} INTO foods (
            fdc_id, barcode, name, brand, category, source,
            calories_per_100g, protein_per_100g, carbs_per_100g,
            fat_per_100g, fiber_per_100g,
            serving_size, serving_unit, serving_options
        ) VALUES (
            :fdc_id, :barcode, :name, :brand, :category, :source,
            :calories_per_100g, :protein_per_100g, :carbs_per_100g,
            :fat_per_100g, :fiber_per_100g,
            :serving_size, :serving_unit, :serving_options
        )
    """.format(prefix=prefix)


def _is_us_row(row: list[str]) -> bool:
    try:
        countries = row[40].lower()
    except IndexError:
        return False
    return "united states" in countries or "usa" in countries or "us" in countries
