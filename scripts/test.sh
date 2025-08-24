#!/bin/bash

set -o pipefail  # Ensure pipeline failures are detected

# Run tests with pretty output and device selection

# Available simulators
DEVICES=(
    "iPhone 15,OS=17.5"
    "iPhone 15 Pro Max,OS=17.5" 
    "iPhone SE (3rd generation),OS=17.5"
)

DEFAULT_DEVICE="iPhone 15,OS=17.5"

show_usage() {
    echo "Usage: $0 {unit|ui|all} [device]"
    echo ""
    echo "Test types:"
    echo "  unit - Run unit tests only"
    echo "  ui   - Run UI tests only"  
    echo "  all  - Run all tests"
    echo ""
    echo "Available devices:"
    for i in "${!DEVICES[@]}"; do
        echo "  $((i+1)). ${DEVICES[$i]}"
    done
    echo ""
    echo "Examples:"
    echo "  $0 ui                    # Use default: $DEFAULT_DEVICE"
    echo "  $0 ui 1                  # Use iPhone 15,OS=17.5"
    echo "  $0 ui 4                  # Use iPhone 16,OS=18.6"
    exit 1
}

if [ $# -eq 0 ]; then
    show_usage
fi

# Select device
if [ -n "$2" ]; then
    if [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 1 ] && [ "$2" -le ${#DEVICES[@]} ]; then
        SELECTED_DEVICE="${DEVICES[$((10#$2-1))]}"
    else
        echo "❌ Invalid device number. Choose 1-${#DEVICES[@]}"
        show_usage
    fi
else
    SELECTED_DEVICE="$DEFAULT_DEVICE"
fi

SIMULATOR="platform=iOS Simulator,name=${SELECTED_DEVICE}"

echo "📱 Using simulator: $SELECTED_DEVICE"
echo ""

case "$1" in
  "unit")
    echo "🧪 Running unit tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" -only-testing:JabTrackerTests | xcpretty --color
    ;;
  "ui")
    echo "🖱️  Running UI tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" -only-testing:JabTrackerUITests | xcpretty --color
    ;;
  "all")
    echo "🎯 Running all tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" | xcpretty --color
    ;;
  *)
    show_usage
    ;;
esac