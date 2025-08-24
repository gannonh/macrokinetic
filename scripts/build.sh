#!/bin/bash

# Build the project with pretty output and device selection

# Available simulators
DEVICES=(
    "iPhone 15,OS=17.5"
    "iPhone 15 Pro Max,OS=17.5" 
    "iPhone SE (3rd generation),OS=17.5"
)

DEFAULT_DEVICE="iPhone 15,OS=17.5"

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
    echo "  $0 1         # Use iPhone 15,OS=17.5"
    echo "  $0 4         # Use iPhone 16,OS=18.6"
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

xcodebuild build \
  -scheme JabTracker \
  -destination "$SIMULATOR" \
  | xcpretty --color

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded"
else
    echo "❌ Build failed"
    exit 1
fi