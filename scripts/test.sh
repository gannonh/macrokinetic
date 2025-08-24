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
    echo "Usage: $0 {unit|ui|all} [device] [specific_test]"
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
    echo "  $0 ui                                                    # Run all UI tests on default device"
    echo "  $0 ui 1                                                  # Run all UI tests on iPhone 15"
    echo "  $0 ui 1 DesignSystemUITests                             # Run specific test class"
    echo "  $0 ui 1 DesignSystemUITests/testDesignSystemComponents  # Run specific test method"
    echo "  $0 unit 1 DesignSystemTests                             # Run specific unit test class"
    exit 1
}

if [ $# -eq 0 ]; then
    show_usage
fi

# Parse arguments
TEST_TYPE="$1"
DEVICE_NUM="$2"
SPECIFIC_TEST="$3"

# Select device
if [ -n "$DEVICE_NUM" ]; then
    if [[ "$DEVICE_NUM" =~ ^[0-9]+$ ]] && [ "$DEVICE_NUM" -ge 1 ] && [ "$DEVICE_NUM" -le ${#DEVICES[@]} ]; then
        SELECTED_DEVICE="${DEVICES[$((10#$DEVICE_NUM-1))]}"
    else
        echo "❌ Invalid device number. Choose 1-${#DEVICES[@]}"
        show_usage
    fi
else
    SELECTED_DEVICE="$DEFAULT_DEVICE"
fi

SIMULATOR="platform=iOS Simulator,name=${SELECTED_DEVICE}"

echo "📱 Using simulator: $SELECTED_DEVICE"

# Build test target based on type and specific test
build_test_target() {
    local test_type="$1"
    local specific_test="$2"
    
    if [ -n "$specific_test" ]; then
        case "$test_type" in
            "unit")
                echo "-only-testing:JabTrackerTests/$specific_test"
                ;;
            "ui")
                echo "-only-testing:JabTrackerUITests/$specific_test"
                ;;
        esac
    else
        case "$test_type" in
            "unit")
                echo "-only-testing:JabTrackerTests"
                ;;
            "ui")
                echo "-only-testing:JabTrackerUITests"
                ;;
            "all")
                echo ""
                ;;
        esac
    fi
}

TEST_TARGET=$(build_test_target "$TEST_TYPE" "$SPECIFIC_TEST")

if [ -n "$SPECIFIC_TEST" ]; then
    echo "🎯 Running specific test: $SPECIFIC_TEST"
else
    echo ""
fi

case "$TEST_TYPE" in
  "unit")
    echo "🧪 Running unit tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET | xcpretty --color
    ;;
  "ui")
    echo "🖱️  Running UI tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET | xcpretty --color
    ;;
  "all")
    echo "🎯 Running all tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET | xcpretty --color
    ;;
  *)
    show_usage
    ;;
esac