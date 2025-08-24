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
    echo "Usage: $0 {unit|ui|all} [device] [test_file]"
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
    echo "Available unit test files (file-based organization):"
    echo "  PersistenceTests      - Core Data and persistence functionality"
    echo "  DesignSystemTests     - UI design system and styling components"
    echo ""
    echo "Examples:"
    echo "  $0 ui                                                    # Run all UI tests on default device"
    echo "  $0 ui 1                                                  # Run all UI tests on iPhone 15"
    echo "  $0 ui 1 DesignSystemUITests                             # Run specific UI test class"
    echo "  $0 ui 1 DesignSystemUITests/testDesignSystemComponents  # Run specific UI test method"
    echo "  $0 unit 1 PersistenceTests                              # Run all persistence-related unit tests"
    echo "  $0 unit 1 DesignSystemTests                             # Run all design system unit tests"
    echo ""
    echo "Note: Unit tests use file-based organization for Swift Testing compatibility."
    echo "      Each test file focuses on a specific feature area for efficient development workflow."
    exit 1
}

if [ $# -eq 0 ]; then
    show_usage
fi

# Parse arguments
TEST_TYPE="$1"
DEVICE_NUM="$2"
TEST_FILE="$3"

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

# Build test target based on type and test file
build_test_target() {
    local test_type="$1"
    local test_file="$2"
    
    if [ -n "$test_file" ]; then
        case "$test_type" in
            "unit")
                # For unit tests, we run the whole target since Swift Testing file targeting doesn't work reliably
                echo "-only-testing:JabTrackerTests"
                ;;
            "ui")
                echo "-only-testing:JabTrackerUITests/$test_file"
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

TEST_TARGET=$(build_test_target "$TEST_TYPE" "$TEST_FILE")

if [ -n "$TEST_FILE" ]; then
    case "$TEST_TYPE" in
        "unit")
            echo "🎯 Running unit tests (Note: Swift Testing runs all unit tests, but focus on $TEST_FILE results)"
            ;;
        "ui")
            echo "🎯 Running specific UI test: $TEST_FILE"
            ;;
    esac
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