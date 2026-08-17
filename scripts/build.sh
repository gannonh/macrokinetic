#!/bin/bash

set -o pipefail  # Ensure pipeline failures are detected

# Build the project with pretty output on the maintained simulator.
DEFAULT_DEVICE="iPhone 17 Pro,OS=26.5"

show_usage() {
    echo "Usage: $0"
    echo "Build on: $DEFAULT_DEVICE"
    exit 1
}

if [ "$#" -gt 0 ]; then
    if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
    fi
    echo "❌ This script does not accept a device selector."
    show_usage
fi

SELECTED_DEVICE="$DEFAULT_DEVICE"

SIMULATOR="platform=iOS Simulator,name=${SELECTED_DEVICE}"

echo "🔨 Building JabTracker..."
echo "📱 Using simulator: $SELECTED_DEVICE"
echo ""

if xcodebuild build \
  -scheme JabTracker \
  -destination "$SIMULATOR" \
  | xcpretty --color; then
    echo "✅ Build succeeded"
else
    echo "❌ Build failed"
    exit 1
fi
