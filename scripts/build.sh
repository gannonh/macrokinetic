#!/bin/bash

set -o pipefail  # Ensure pipeline failures are detected

# Build the project with pretty output and device selection

# Available simulators
DEVICES=(
    "iPhone 17 Pro,OS=26.5"
)

DEFAULT_DEVICE="iPhone 17 Pro,OS=26.5"

show_usage() {
    echo "Usage: $0 [device]"
    echo ""
    echo "Available devices:"
    for i in "${!DEVICES[@]}"; do
        echo "  $((i+1)). ${DEVICES[$i]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0           # Use default: $DEFAULT_DEVICE"
    echo "  $0 1         # Use iPhone 17 Pro,OS=26.5"
    exit 1
}

# Select device
if [ -n "$1" ]; then
    if [ "$1" = "help" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        show_usage
    elif [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge 1 ] && [ "$1" -le ${#DEVICES[@]} ]; then
        SELECTED_DEVICE="${DEVICES[$((10#$1-1))]}"
    else
        echo "❌ Invalid device number. Choose 1-${#DEVICES[@]}"
        show_usage
    fi
else
    SELECTED_DEVICE="$DEFAULT_DEVICE"
fi

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
