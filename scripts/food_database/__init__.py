"""Reusable food-database pipeline primitives."""

from .normalization import (
    FoodRecord,
    normalize_barcode,
    normalize_off_product,
    normalize_usda_food,
)
from .validation import ValidationResult, validate_database
from .delta import (
    DeltaInterval,
    DeltaPayloadError,
    DeltaSelection,
    apply_delta_chain,
    parse_delta_filename,
    select_delta_chain,
)
from .schema import SCHEMA_VERSION, create_schema
from .full_build import FullBuildError, FullBuildResult, build_full_database, iter_json_array_records
from .manifest import build_manifest, verify_manifest, write_manifest
from .packaging import CandidatePackage, PackagingError, package_candidate
from .snapshots import (
    SnapshotSelection,
    SnapshotSelectionError,
    select_snapshot,
    snapshot_requires_full_rebuild,
    snapshot_tag,
)
from .metadata import FullExportMetadata, FullExportMetadataError, load_full_export_metadata

__all__ = [
    "FoodRecord",
    "normalize_barcode",
    "normalize_off_product",
    "normalize_usda_food",
    "ValidationResult",
    "validate_database",
    "DeltaInterval",
    "DeltaPayloadError",
    "DeltaSelection",
    "apply_delta_chain",
    "parse_delta_filename",
    "select_delta_chain",
    "SCHEMA_VERSION",
    "create_schema",
    "FullBuildError",
    "FullBuildResult",
    "build_full_database",
    "iter_json_array_records",
    "build_manifest",
    "verify_manifest",
    "write_manifest",
    "CandidatePackage",
    "PackagingError",
    "package_candidate",
    "SnapshotSelection",
    "SnapshotSelectionError",
    "select_snapshot",
    "snapshot_tag",
    "snapshot_requires_full_rebuild",
    "FullExportMetadata",
    "FullExportMetadataError",
    "load_full_export_metadata",
]
