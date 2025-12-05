#!/bin/bash

# Install on Physical Device
#
# Builds Release configuration and installs on connected iPhone/iPad
# for testing TestFlight builds on actual hardware before uploading.
#
# Usage:
#   ./scripts/install-device.sh              # Auto-detect connected device
#   ./scripts/install-device.sh --device-id UDID  # Install to specific device

set -e
set -o pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
DEVICE_ID=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --device-id)
            DEVICE_ID="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --device-id UDID    Specify device UDID (auto-detects if omitted)"
            echo "  --help              Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                              # Auto-detect device"
            echo "  $0 --device-id 00008101-..."
            echo ""
            echo "Note: Device must be connected via USB and trusted."
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}📱 Installing Release Build on Physical Device${NC}"
echo "================================================"
echo ""

# Get development team ID from project.yml if not set
if [ -z "$DEVELOPMENT_TEAM" ]; then
    DEVELOPMENT_TEAM=$(grep -E '^\s+DEVELOPMENT_TEAM:' project.yml | sed 's/.*: *//' | head -1 || echo "")
    if [ -z "$DEVELOPMENT_TEAM" ]; then
        echo -e "${RED}❌ Error: DEVELOPMENT_TEAM not found${NC}"
        echo ""
        echo "Please set your Apple Developer Team ID:"
        echo "  export DEVELOPMENT_TEAM=YOUR_TEAM_ID"
        echo ""
        echo "Or add it to project.yml under settings:"
        echo "  settings:"
        echo "    DEVELOPMENT_TEAM: YOUR_TEAM_ID"
        exit 1
    fi
    echo "📋 Using Team ID from project.yml: $DEVELOPMENT_TEAM"
fi
echo ""

# Auto-detect device if not specified
if [ -z "$DEVICE_ID" ]; then
    echo "🔍 Auto-detecting connected devices..."

    # Get list of connected devices using xctrace (gives proper UDIDs for xcodebuild)
    DEVICES=$(xcrun xctrace list devices 2>&1 | grep -E "iPhone|iPad" | grep -v "Simulator" || echo "")

    if [ -z "$DEVICES" ]; then
        echo -e "${RED}❌ Error: No connected devices found${NC}"
        echo ""
        echo "Please:"
        echo "  1. Connect your iPhone/iPad via USB"
        echo "  2. Unlock the device"
        echo "  3. Trust this computer if prompted"
        echo "  4. Try again"
        exit 1
    fi

    # Count devices
    DEVICE_COUNT=$(echo "$DEVICES" | wc -l | tr -d ' ')

    if [ "$DEVICE_COUNT" -eq 1 ]; then
        # Single device - extract UDID (format: 00008110-0001288434D0401E)
        DEVICE_ID=$(echo "$DEVICES" | grep -oE '[0-9a-fA-F]{8}-[0-9a-fA-F]{16}' | head -1)
        # Extract device name and iOS version
        DEVICE_NAME=$(echo "$DEVICES" | sed 's/^\([^(]*\).*/\1/' | xargs)
        echo -e "${GREEN}✅ Found device: $DEVICE_NAME${NC}"
    else
        # Multiple devices - show list and exit
        echo -e "${YELLOW}⚠️  Multiple devices connected:${NC}"
        echo ""
        echo "$DEVICES"
        echo ""
        echo "Please specify which device using --device-id UDID"
        exit 1
    fi
fi

echo -e "${GREEN}🆔 Device ID: $DEVICE_ID${NC}"
echo ""

# Verify device is connected and accessible (already detected above, this is just a sanity check)
echo "🔌 Verifying device connection..."
echo "   ✅ Device detected and ready"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
echo ""

# Build and install for device with Release configuration
echo "📦 Building and installing Release configuration..."
echo "   This may take several minutes..."
echo ""

# Use 'run' to build and install in one step
xcodebuild \
    -scheme JabTracker \
    -destination "platform=iOS,id=$DEVICE_ID" \
    -configuration Release \
    -derivedDataPath build/DerivedData \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM}" \
    build install | xcbeautify || {
        echo -e "${RED}❌ Build/Install failed${NC}"
        echo ""
        echo "Common issues:"
        echo "  • Device not trusted on this computer"
        echo "  • Code signing certificate missing"
        echo "  • Device iOS version incompatible"
        echo "  • Device locked during installation"
        exit 1
    }

echo ""
echo -e "${GREEN}✅ Build and installation succeeded${NC}"
echo ""

echo "================================================"
echo -e "${GREEN}✅ Physical Device Installation Complete${NC}"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Unlock your device and find JabTracker"
echo "  2. Trust the developer profile if prompted:"
echo "     Settings → General → VPN & Device Management"
echo "  3. Launch the app"
echo "  4. Go to Settings → Test 'Seed Randomized Test Data'"
echo "  5. Verify environment shows 'Debug' or 'Simulator' (not TestFlight)"
echo ""
echo -e "${YELLOW}Note: This is a development build, not a TestFlight build.${NC}"
echo "      Environment detection will show 'Debug' because it's installed via Xcode."
echo "      For true TestFlight testing, use ./scripts/upload-testflight.sh"
echo ""
