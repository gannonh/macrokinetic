#!/bin/bash
#
# cleanup-xcode.sh - Clean up Xcode simulator bloat and caches
#
# Usage: ./scripts/cleanup-xcode.sh [--dry-run]
#

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "=== DRY RUN MODE - No files will be deleted ==="
    echo ""
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Xcode Cleanup Script ===${NC}"
echo ""

# Function to get folder size (handles non-existent folders)
get_size() {
    if [[ -d "$1" ]]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Function to delete folder with size reporting
cleanup_folder() {
    local path="$1"
    local name="$2"

    if [[ -d "$path" ]]; then
        local size=$(get_size "$path")
        if [[ "$DRY_RUN" == true ]]; then
            echo -e "${YELLOW}[DRY RUN]${NC} Would delete $name: $size"
        else
            echo -e "${GREEN}Deleting${NC} $name: $size"
            rm -rf "$path"
        fi
    else
        echo -e "${BLUE}Skipping${NC} $name: not found"
    fi
}

# Track what we're cleaning
echo -e "${YELLOW}Checking cleanup targets...${NC}"
echo ""

# 1. XCTestDevices (parallel test execution clones) - BIGGEST culprit
echo "1. XCTestDevices (parallel test clones)"
cleanup_folder ~/Library/Developer/XCTestDevices "XCTestDevices"
echo ""

# 2. Unavailable simulators
echo "2. Unavailable Simulators"
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[DRY RUN]${NC} Would run: xcrun simctl delete unavailable"
else
    echo -e "${GREEN}Deleting${NC} unavailable simulators..."
    xcrun simctl delete unavailable 2>/dev/null || true
fi
echo ""

# 3. Xcode DerivedData
echo "3. DerivedData (build artifacts)"
cleanup_folder ~/Library/Developer/Xcode/DerivedData "DerivedData"
echo ""

# 4. iOS DeviceSupport (old device symbols)
echo "4. iOS DeviceSupport (old device symbols)"
if [[ -d ~/Library/Developer/Xcode/iOS\ DeviceSupport ]]; then
    local size=$(get_size ~/Library/Developer/Xcode/iOS\ DeviceSupport)
    echo -e "${BLUE}Found${NC} iOS DeviceSupport: $size"
    echo "   (Not auto-deleting - may need symbols for debugging old devices)"
    echo "   Manual: rm -rf ~/Library/Developer/Xcode/iOS\\ DeviceSupport"
fi
echo ""

# 5. Xcode Caches
echo "5. Xcode Caches"
cleanup_folder ~/Library/Caches/com.apple.dt.Xcode "Xcode Caches"
echo ""

# 6. CoreSimulator Caches (different from devices)
echo "6. CoreSimulator Caches"
cleanup_folder ~/Library/Developer/CoreSimulator/Caches "CoreSimulator Caches"
echo ""

# 7. Old Archives (optional - commented out by default)
# echo "7. Xcode Archives"
# cleanup_folder ~/Library/Developer/Xcode/Archives "Archives"
# echo ""

# Summary
echo -e "${BLUE}=== Cleanup Complete ===${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo "Run without --dry-run to actually delete files."
else
    echo "Freed space from Xcode caches and simulators."
    echo ""
    echo "Current disk usage:"
    df -h / | tail -1 | awk '{print "  Used: " $3 " / " $2 " (" $5 " full)"}'
fi
echo ""
echo "Tip: Run this script monthly to prevent bloat."
