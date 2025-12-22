#!/bin/bash

# update-food-database.sh
# Downloads USDA data and rebuilds the local food database
# Optionally includes Open Food Facts branded foods data
#
# Usage:
#   ./scripts/update-food-database.sh                    # Full rebuild (USDA + OFF if available)
#   ./scripts/update-food-database.sh --skip-download    # Rebuild from existing data
#   ./scripts/update-food-database.sh --usda-only        # Only USDA data, skip OFF
#   ./scripts/update-food-database.sh --verify           # Verify current database only
#
# Open Food Facts Data:
#   To include branded foods, download the CSV from:
#   https://world.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz
#   Place it in: scripts/off_data/en.openfoodfacts.org.products.csv.gz

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$SCRIPT_DIR/usda_data"
OFF_DATA_DIR="$SCRIPT_DIR/off_data"
OFF_CSV="$OFF_DATA_DIR/en.openfoodfacts.org.products.csv.gz"
OUTPUT_DB="$PROJECT_ROOT/JabTracker/Resources/usda_foods.sqlite"

# USDA download URLs (update these when new versions are released)
# Check https://fdc.nal.usda.gov/download-datasets.html for latest
FOUNDATION_URL="https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_json_2024-04-18.zip"
SR_LEGACY_URL="https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip"

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_step() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "  $1"
}

# Parse arguments
SKIP_DOWNLOAD=false
VERIFY_ONLY=false
USDA_ONLY=false

for arg in "$@"; do
    case $arg in
        --skip-download)
            SKIP_DOWNLOAD=true
            ;;
        --verify)
            VERIFY_ONLY=true
            ;;
        --usda-only)
            USDA_ONLY=true
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-download  Skip downloading USDA data, use existing files"
            echo "  --usda-only      Only process USDA data, skip Open Food Facts"
            echo "  --verify         Only verify the current database"
            echo "  --help, -h       Show this help message"
            echo ""
            echo "This script builds the local food database from:"
            echo "  1. USDA Foundation Foods + SR Legacy (~8,000 whole foods)"
            echo "  2. Open Food Facts CSV (~1.7M branded/packaged foods)"
            echo ""
            echo "Open Food Facts Data:"
            echo "  Download from: https://world.openfoodfacts.org/data"
            echo "  File: en.openfoodfacts.org.products.csv.gz"
            echo "  Place in: scripts/off_data/"
            exit 0
            ;;
    esac
done

# Verify only mode
if [ "$VERIFY_ONLY" = true ]; then
    print_header "Verifying Food Database"

    if [ ! -f "$OUTPUT_DB" ]; then
        print_error "Database not found: $OUTPUT_DB"
        exit 1
    fi

    print_step "Checking database integrity..."
    sqlite3 "$OUTPUT_DB" "PRAGMA integrity_check;" | head -1

    print_step "Counting foods by source..."
    TOTAL_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods;")
    USDA_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods WHERE source IN ('foundation', 'sr_legacy');")
    OFF_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods WHERE source = 'openFoodFacts';")
    print_info "USDA foods:           $USDA_COUNT"
    print_info "Open Food Facts:      $OFF_COUNT"
    print_info "Total foods:          $TOTAL_COUNT"

    print_step "Checking FTS5 index..."
    FTS_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods_fts;")
    print_info "FTS5 entries:         $FTS_COUNT"

    print_step "Sample search test..."
    echo "  'chicken' results:"
    sqlite3 "$OUTPUT_DB" "SELECT '    ' || name || ' (' || source || ')' FROM foods WHERE name LIKE '%chicken%' LIMIT 3;"
    echo "  'oreo' results:"
    sqlite3 "$OUTPUT_DB" "SELECT '    ' || name || ' (' || source || ')' FROM foods WHERE name LIKE '%oreo%' LIMIT 3;"

    print_step "Database file size..."
    ls -lh "$OUTPUT_DB" | awk '{print "  Size: " $5}'

    if [ "$TOTAL_COUNT" -gt 7000 ]; then
        print_success "Database verification passed ($TOTAL_COUNT foods)"
    else
        print_error "Database has fewer foods than expected ($TOTAL_COUNT < 7000)"
        exit 1
    fi

    exit 0
fi

print_header "Food Database Builder"
echo ""
echo "This script builds the local food database from:"
echo "  • USDA Foundation Foods + SR Legacy (whole foods)"
echo "  • Open Food Facts (branded/packaged foods)"
echo ""

# Create data directories
mkdir -p "$DATA_DIR"
mkdir -p "$DATA_DIR/foundation"
mkdir -p "$DATA_DIR/sr_legacy"
mkdir -p "$OFF_DATA_DIR"
mkdir -p "$(dirname "$OUTPUT_DB")"

# ============================================
# STEP 1: Download USDA Data
# ============================================
if [ "$SKIP_DOWNLOAD" = false ]; then
    print_header "Step 1: Downloading USDA Data"

    print_step "Downloading Foundation Foods..."
    if curl -L -o "$DATA_DIR/foundation_foods.zip" "$FOUNDATION_URL" --progress-bar; then
        print_success "Foundation Foods downloaded"
    else
        print_error "Failed to download Foundation Foods"
        echo "  URL: $FOUNDATION_URL"
        echo "  Check https://fdc.nal.usda.gov/download-datasets.html for updated URL"
        exit 1
    fi

    print_step "Downloading SR Legacy..."
    if curl -L -o "$DATA_DIR/sr_legacy.zip" "$SR_LEGACY_URL" --progress-bar; then
        print_success "SR Legacy downloaded"
    else
        print_error "Failed to download SR Legacy"
        exit 1
    fi

    print_header "Step 2: Extracting Archives"

    print_step "Extracting Foundation Foods..."
    unzip -o -q "$DATA_DIR/foundation_foods.zip" -d "$DATA_DIR/foundation/"
    print_success "Foundation Foods extracted"

    print_step "Extracting SR Legacy..."
    unzip -o -q "$DATA_DIR/sr_legacy.zip" -d "$DATA_DIR/sr_legacy/"
    print_success "SR Legacy extracted"
else
    print_header "Step 1-2: Skipping USDA Download (using existing data)"
fi

# ============================================
# STEP 3: Verify USDA Data Files
# ============================================
print_header "Step 3: Verifying USDA Data Files"

FOUNDATION_PATH=$(find "$DATA_DIR/foundation" -name "*.json" -type f | head -1)
SR_LEGACY_PATH=$(find "$DATA_DIR/sr_legacy" -name "*.json" -type f | head -1)

if [ -z "$FOUNDATION_PATH" ]; then
    print_error "Foundation Foods JSON not found in $DATA_DIR/foundation/"
    exit 1
fi
print_success "Foundation Foods: $(basename "$FOUNDATION_PATH")"

if [ -z "$SR_LEGACY_PATH" ]; then
    print_error "SR Legacy JSON not found in $DATA_DIR/sr_legacy/"
    exit 1
fi
print_success "SR Legacy: $(basename "$SR_LEGACY_PATH")"

# ============================================
# STEP 4: Process USDA Data
# ============================================
print_header "Step 4: Processing USDA Data"

print_step "Running process_usda_data.py..."

if [ ! -f "$SCRIPT_DIR/process_usda_data.py" ]; then
    print_error "process_usda_data.py not found"
    exit 1
fi

cd "$PROJECT_ROOT"
if python3 "$SCRIPT_DIR/process_usda_data.py"; then
    print_success "USDA database created"
else
    print_error "Failed to process USDA data"
    exit 1
fi

# Show USDA stats
USDA_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods;")
print_info "USDA foods: $USDA_COUNT"

# ============================================
# STEP 5: Process Open Food Facts Data (Optional)
# ============================================
if [ "$USDA_ONLY" = false ]; then
    print_header "Step 5: Processing Open Food Facts Data"

    if [ -f "$OFF_CSV" ]; then
        print_step "Found OFF data: $(basename "$OFF_CSV")"
        print_step "Running process-off-data.py..."
        print_info "(This may take several minutes for 4M+ products)"

        if python3 "$SCRIPT_DIR/process-off-data.py"; then
            print_success "Open Food Facts data added"
        else
            print_error "Failed to process OFF data (continuing with USDA only)"
        fi
    else
        print_step "Open Food Facts CSV not found"
        print_info "To include branded foods, download from:"
        print_info "https://world.openfoodfacts.org/data"
        print_info "File: en.openfoodfacts.org.products.csv.gz"
        print_info "Place in: $OFF_DATA_DIR/"
        print_info ""
        print_info "Continuing with USDA data only..."
    fi
else
    print_header "Step 5: Skipping Open Food Facts (--usda-only)"
fi

# ============================================
# STEP 6: Verify Output
# ============================================
print_header "Step 6: Verifying Output"

if [ ! -f "$OUTPUT_DB" ]; then
    print_error "Output database not created: $OUTPUT_DB"
    exit 1
fi

print_step "Counting foods by source..."
TOTAL_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods;")
FOUNDATION_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods WHERE source = 'foundation';")
SR_LEGACY_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods WHERE source = 'sr_legacy';")
OFF_COUNT=$(sqlite3 "$OUTPUT_DB" "SELECT COUNT(*) FROM foods WHERE source = 'openFoodFacts';")

print_info "Foundation Foods:     $FOUNDATION_COUNT"
print_info "SR Legacy:            $SR_LEGACY_COUNT"
print_info "Open Food Facts:      $OFF_COUNT"
print_info "Total:                $TOTAL_COUNT"

print_step "Database size..."
DB_SIZE=$(ls -lh "$OUTPUT_DB" | awk '{print $5}')
print_info "Size: $DB_SIZE"

print_step "Sample queries..."
echo "  USDA 'chicken' results:"
sqlite3 "$OUTPUT_DB" "SELECT '    ' || name FROM foods WHERE name LIKE '%chicken%' AND source != 'openFoodFacts' LIMIT 2;"

if [ "$OFF_COUNT" -gt 0 ]; then
    echo "  OFF 'oreo' results:"
    sqlite3 "$OUTPUT_DB" "SELECT '    ' || name || ' (' || brand || ')' FROM foods WHERE name LIKE '%oreo%' AND source = 'openFoodFacts' LIMIT 2;"
fi

# ============================================
# STEP 7: Run Tests
# ============================================
print_header "Step 7: Running Tests"

if [ -f "$SCRIPT_DIR/test.sh" ]; then
    print_step "Running LocalFoodDatabaseTests..."
    if "$SCRIPT_DIR/test.sh" unit 1 LocalFoodDatabaseTests --no-log 2>/dev/null; then
        print_success "All tests passed"
    else
        print_error "Some tests failed - check output above"
        exit 1
    fi
else
    print_step "Skipping tests (test.sh not found)"
fi

# ============================================
# Summary
# ============================================
print_header "Summary"

echo -e "Database:         ${GREEN}$OUTPUT_DB${NC}"
echo -e "USDA foods:       ${GREEN}$((FOUNDATION_COUNT + SR_LEGACY_COUNT))${NC}"
echo -e "Open Food Facts:  ${GREEN}$OFF_COUNT${NC}"
echo -e "Total foods:      ${GREEN}$TOTAL_COUNT${NC}"
echo -e "Size:             ${GREEN}$DB_SIZE${NC}"
echo ""

if [ "$TOTAL_COUNT" -gt 7000 ]; then
    print_success "Food database build complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Run full tests:  ./scripts/check-all.sh --skip-ui"
    echo "  2. Test in app:     Build and run in simulator"
    echo "  3. Commit changes:  git add JabTracker/Resources/usda_foods.sqlite"

    if [ "$OFF_COUNT" -eq 0 ]; then
        echo ""
        echo "To add branded foods:"
        echo "  1. Download: https://world.openfoodfacts.org/data/en.openfoodfacts.org.products.csv.gz"
        echo "  2. Place in: scripts/off_data/"
        echo "  3. Re-run:   ./scripts/update-food-database.sh --skip-download"
    fi
else
    print_error "Database has fewer foods than expected"
    exit 1
fi
