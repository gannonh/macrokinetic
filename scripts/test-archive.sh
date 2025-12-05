#!/bin/bash

# Test Archive Build Locally
#
# Creates and installs a Release configuration archive to simulator for testing
# before uploading to TestFlight. This simulates the exact build that will go
# to TestFlight without actually uploading.
#
# Usage:
#   ./scripts/test-archive.sh              # Build and install to default simulator
#   ./scripts/test-archive.sh --device-id UUID  # Install to specific simulator

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default simulator (iPhone 15, iOS 17.5)
DEFAULT_SIMULATOR_ID="336C70E1-7A02-4FE1-ABD8-89C2E5FD38EB"
SIMULATOR_ID="$DEFAULT_SIMULATOR_ID"

# Parse arguments
RESET_DATA=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --device-id)
            SIMULATOR_ID="$2"
            shift 2
            ;;
        --reset-data)
            RESET_DATA=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --device-id UUID    Specify simulator UUID (default: iPhone 15)"
            echo "  --reset-data        Completely erase app data before installing (recommended)"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Basic install"
            echo "  $0 --reset-data                 # Install with clean data (recommended)"
            echo "  $0 --device-id UUID --reset-data"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🧪 Testing Archive Build Locally${NC}"
echo "================================"
echo ""

# Get simulator name
SIMULATOR_NAME=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | sed 's/.*(\([^)]*\)).*/\1/' | awk '{print $1, $2, $3}' | head -1)
if [ -z "$SIMULATOR_NAME" ]; then
    echo -e "${RED}❌ Error: Simulator not found with ID: $SIMULATOR_ID${NC}"
    echo ""
    echo "Available simulators:"
    xcrun simctl list devices | grep iPhone
    exit 1
fi

echo -e "${GREEN}📱 Target Simulator: $SIMULATOR_NAME${NC}"
echo -e "${GREEN}🆔 Simulator ID: $SIMULATOR_ID${NC}"
echo ""

# Boot simulator if not already booted
echo "🚀 Ensuring simulator is booted..."
BOOT_STATUS=$(xcrun simctl list devices | grep "$SIMULATOR_ID" | grep -o "(Booted)" || echo "")
if [ -z "$BOOT_STATUS" ]; then
    echo "   Starting simulator..."
    xcrun simctl boot "$SIMULATOR_ID"
    sleep 3
else
    echo "   Simulator already booted"
fi
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
echo ""

# Build for simulator with Release configuration
echo "📦 Building Release configuration for simulator..."
echo "   This may take several minutes..."
echo ""

xcodebuild \
    -scheme JabTracker \
    -destination "id=$SIMULATOR_ID" \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    build | xcbeautify || {
        echo -e "${RED}❌ Build failed${NC}"
        exit 1
    }

echo ""
echo -e "${GREEN}✅ Build succeeded${NC}"
echo ""

# Find the built app
APP_PATH=$(find build/DerivedData/Build/Products/Release-iphonesimulator -name "JabTracker.app" -type d | head -1)

if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Error: Could not find JabTracker.app in build output${NC}"
    exit 1
fi

echo "📲 Installing to simulator..."
echo "   App path: $APP_PATH"
echo ""

# Uninstall existing app and optionally reset data
if [ "$RESET_DATA" = true ]; then
    echo "🗑️  Resetting app data (clean state)..."

    # Get app container paths before uninstalling
    APP_DATA_CONTAINER=$(xcrun simctl get_app_container "$SIMULATOR_ID" com.gannonhall.JabTracker data 2>/dev/null || echo "")

    # Uninstall the app
    xcrun simctl uninstall "$SIMULATOR_ID" com.gannonhall.JabTracker 2>/dev/null || true

    # Delete app data container if it exists
    if [ -n "$APP_DATA_CONTAINER" ] && [ -d "$APP_DATA_CONTAINER" ]; then
        echo "   Removing data container: $APP_DATA_CONTAINER"
        rm -rf "$APP_DATA_CONTAINER"
    fi

    # Also clear UserDefaults and other cached data
    SIMULATOR_DATA_DIR="$HOME/Library/Developer/CoreSimulator/Devices/$SIMULATOR_ID/data"
    if [ -d "$SIMULATOR_DATA_DIR/Library/Preferences" ]; then
        rm -f "$SIMULATOR_DATA_DIR/Library/Preferences/com.gannonhall.JabTracker.plist" 2>/dev/null || true
    fi

    echo "   ✅ App data reset complete"
else
    # Just uninstall without data reset
    xcrun simctl uninstall "$SIMULATOR_ID" com.gannonhall.JabTracker 2>/dev/null || true
fi
echo ""

# Install the app
xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"

echo ""
echo -e "${GREEN}✅ App installed successfully${NC}"
echo ""

# Launch the app
echo "🚀 Launching app..."
xcrun simctl launch "$SIMULATOR_ID" com.gannonhall.JabTracker

echo ""
echo "================================"
echo -e "${GREEN}✅ Archive Build Test Complete${NC}"
echo "================================"
echo ""
echo "Next steps:"
echo "  1. Test the app on the simulator"
echo "  2. Go to Settings → Verify 'Seed Randomized Test Data' section appears"
echo "  3. Test data seeding functionality"
echo "  4. Check 'Environment: Simulator' is shown (not TestFlight on simulator)"
echo ""
if [ "$RESET_DATA" = false ]; then
    echo -e "${YELLOW}💡 Tip: Use --reset-data flag for clean state between test runs${NC}"
    echo ""
fi
echo "Note: Environment detection in simulator will show 'Simulator', not 'TestFlight'."
echo "      The seeding UI should still be visible because it's Release configuration."
echo ""
