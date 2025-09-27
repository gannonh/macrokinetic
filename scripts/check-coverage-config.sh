#!/bin/bash

# Check that all Swift files in JabTracker target are accounted for in coverage-config.json
# Usage: ./scripts/check-coverage-config.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COVERAGE_CONFIG="$PROJECT_ROOT/coverage-config.json"
TARGET_DIR="$PROJECT_ROOT/JabTracker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Checking coverage-config.json completeness..."
echo

# Check if coverage config exists
if [[ ! -f "$COVERAGE_CONFIG" ]]; then
    echo -e "${RED}Error: coverage-config.json not found at $COVERAGE_CONFIG${NC}"
    exit 1
fi

# Find all Swift files in JabTracker target (relative paths)
echo "Finding all Swift files in JabTracker target..."
SWIFT_FILES_LIST=$(find "$TARGET_DIR" -name "*.swift" -type f | sed "s|$PROJECT_ROOT/JabTracker/||" | sort)
SWIFT_FILES_COUNT=$(echo "$SWIFT_FILES_LIST" | wc -l | tr -d ' ')
echo "Found $SWIFT_FILES_COUNT Swift files in JabTracker/"
echo

# Extract all files mentioned in coverage-config.json
echo "Extracting files from coverage-config.json..."
COVERED_FILES=$(cat "$COVERAGE_CONFIG" | \
    jq -r '.policy.tiers | to_entries[] | .value.files[]' 2>/dev/null | sort | uniq)
EXCLUDED_FILES=$(cat "$COVERAGE_CONFIG" | \
    jq -r '.exclusions.files[]' 2>/dev/null | sort | uniq)

# Combine covered and excluded files
ALL_CONFIGURED_FILES=$(echo -e "$COVERED_FILES\n$EXCLUDED_FILES" | sort | uniq)

echo "Files in coverage policy tiers: $(echo "$COVERED_FILES" | wc -l | tr -d ' ')"
echo "Files in exclusions: $(echo "$EXCLUDED_FILES" | wc -l | tr -d ' ')"
echo "Total configured files: $(echo "$ALL_CONFIGURED_FILES" | wc -l | tr -d ' ')"
echo

# Find missing files (files on disk but not in config)
MISSING_FILES=""
MISSING_COUNT=0

while IFS= read -r swift_file; do
    if ! echo "$ALL_CONFIGURED_FILES" | grep -q "^$swift_file$"; then
        MISSING_FILES="$MISSING_FILES$swift_file"$'\n'
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done <<< "$SWIFT_FILES_LIST"

# Find phantom files (files in config but not on disk)
echo "Checking for phantom files in coverage-config.json..."
PHANTOM_FILES=""
PHANTOM_COUNT=0

# Check files in policy tiers and exclusions
while IFS= read -r config_file; do
    if [[ -n "$config_file" && ! -f "$TARGET_DIR/$config_file" ]]; then
        PHANTOM_FILES="$PHANTOM_FILES$config_file"$'\n'
        PHANTOM_COUNT=$((PHANTOM_COUNT + 1))
    fi
done <<< "$ALL_CONFIGURED_FILES"

# Output results
echo "📊 RESULTS:"
echo "=========="

TOTAL_ISSUES=0

# Report missing files (files on disk but not in config)
if [[ $MISSING_COUNT -gt 0 ]]; then
    echo -e "${RED}❌ Found $MISSING_COUNT Swift files missing from coverage-config.json:${NC}"
    echo
    echo -e "${YELLOW}Missing files (relative to JabTracker/):${NC}"
    echo "$MISSING_FILES" | while IFS= read -r missing_file; do
        if [[ -n "$missing_file" ]]; then
            echo "  - $missing_file"
        fi
    done
    echo
    echo -e "${YELLOW}These files need to be added to either:${NC}"
    echo "  1. A coverage tier in .policy.tiers.{tier_name}.files[]"
    echo "  2. The exclusions list in .exclusions.files[]"
    echo
    TOTAL_ISSUES=$((TOTAL_ISSUES + MISSING_COUNT))
fi

# Report phantom files (files in config but not on disk)
if [[ $PHANTOM_COUNT -gt 0 ]]; then
    echo -e "${RED}❌ Found $PHANTOM_COUNT phantom files in coverage-config.json:${NC}"
    echo
    echo -e "${YELLOW}Phantom files (in config but not on disk):${NC}"
    echo "$PHANTOM_FILES" | while IFS= read -r phantom_file; do
        if [[ -n "$phantom_file" ]]; then
            echo "  - $phantom_file"
        fi
    done
    echo
    echo -e "${YELLOW}These files should be removed from coverage-config.json${NC}"
    echo
    TOTAL_ISSUES=$((TOTAL_ISSUES + PHANTOM_COUNT))
fi

# Final result
if [[ $TOTAL_ISSUES -eq 0 ]]; then
    echo -e "${GREEN}✅ Coverage configuration is complete and accurate!${NC}"
    echo "  • All Swift files are accounted for"
    echo "  • No phantom files found"
    echo
    exit 0
else
    echo -e "${RED}❌ Coverage configuration has $TOTAL_ISSUES issue(s) that need fixing${NC}"
    echo
    exit 1
fi