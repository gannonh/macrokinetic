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
ENABLE_COVERAGE=false
RESET_DEVICE=false

show_usage() {
    echo "Usage: $0 {unit|ui|all} [device] [test_file] [--coverage] [--reset]"
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
    echo "Options:"
    echo "  --coverage  Generate code coverage report and display results"
    echo "  --reset     Reset simulator before running tests (clears all permissions)"
    echo ""
    echo "Available test files:"
    echo "  Unit tests (file-based organization):"
    echo "    PersistenceTests      - Core Data and persistence functionality"  
    echo "    DesignSystemTests     - UI design system and styling components"
    echo ""
    echo "  UI tests:"
    echo "    AuthenticationUITests       - Automated authentication flow tests (using --ui-testing mode)"
    echo "    ManualAuthenticationUITests - Manual Apple ID tests (excluded from CI, run in Xcode manually)"
    echo "    OnboardingUITests           - User onboarding flow tests"
    echo "    DesignSystemUITests         - Design system component tests"
    echo ""
    echo "Examples:"
    echo "  $0 ui                                                    # Run all UI tests on default device"
    echo "  $0 ui 1                                                  # Run all UI tests on iPhone 15"
    echo "  $0 ui 1 DesignSystemUITests                             # Run specific UI test class"
    echo "  $0 ui 1 DesignSystemUITests/testDesignSystemComponents  # Run specific UI test method"
    echo "  $0 ui 1 ManualAuthenticationUITests                     # Run manual Apple ID tests (requires manual interaction)"
    echo "  $0 unit 1 PersistenceTests                              # Run all persistence-related unit tests"
    echo "  $0 unit 1 DesignSystemTests                             # Run all design system unit tests"
    echo "  $0 unit 1 --coverage                                    # Run unit tests with coverage report"
    echo "  $0 ui 1 --reset                                         # Run UI tests with fresh simulator state"
    echo "  $0 all --coverage                                       # Run all tests with coverage report (excludes manual tests)"
    echo ""
    echo "Note: Unit tests use file-based organization for Swift Testing compatibility."
    echo "      Each test file focuses on a specific feature area for efficient development workflow."
    exit 1
}

if [ $# -eq 0 ]; then
    show_usage
fi

# Parse arguments (handle --coverage flag anywhere in args)
TEST_TYPE="$1"
DEVICE_NUM=""
TEST_FILE=""

# Parse remaining arguments
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            ENABLE_COVERAGE=true
            shift
            ;;
        --reset)
            RESET_DEVICE=true
            shift
            ;;
        *)
            if [[ -z "$DEVICE_NUM" && "$1" =~ ^[0-9]+$ ]]; then
                DEVICE_NUM="$1"
            elif [[ -z "$TEST_FILE" && ! "$1" =~ ^[0-9]+$ ]]; then
                TEST_FILE="$1"
            fi
            shift
            ;;
    esac
done

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

# Reset simulator if requested
if [ "$RESET_DEVICE" = true ]; then
    echo "🔄 Resetting simulator to clear permissions..."
    # Extract device name without OS version for UUID lookup
    DEVICE_NAME="${SELECTED_DEVICE%,*}"
    SIMULATOR_UUID=$(xcrun simctl list devices | grep "$DEVICE_NAME" | grep -v "unavailable" | head -1 | grep -o '[A-F0-9-]\{36\}')
    
    if [ -n "$SIMULATOR_UUID" ]; then
        echo "🎯 Found simulator UUID: $SIMULATOR_UUID for $DEVICE_NAME"
        xcrun simctl shutdown "$SIMULATOR_UUID" 2>/dev/null || true
        xcrun simctl erase "$SIMULATOR_UUID"
        xcrun simctl boot "$SIMULATOR_UUID"
        echo "✅ Simulator reset complete"
    else
        echo "⚠️  Could not find simulator UUID for $DEVICE_NAME - continuing without reset"
    fi
fi

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
                # Run specific UI test file
                echo "-only-testing:JabTrackerUITests/$test_file"
                ;;
        esac
    else
        case "$test_type" in
            "unit")
                echo "-only-testing:JabTrackerTests"
                ;;
            "ui")
                # Exclude manual tests from automated runs
                echo "-only-testing:JabTrackerUITests -skip-testing:JabTrackerUITests/ManualAuthenticationUITests"
                ;;
            "all")
                # Exclude manual tests from automated runs
                echo "-skip-testing:JabTrackerUITests/ManualAuthenticationUITests"
                ;;
        esac
    fi
}

TEST_TARGET=$(build_test_target "$TEST_TYPE" "$TEST_FILE")

# Build coverage options
COVERAGE_OPTIONS=""
RESULT_BUNDLE_PATH=""
if [ "$ENABLE_COVERAGE" = true ]; then
    # Clean up any existing result bundle
    rm -rf /tmp/jab-tracker-coverage.xcresult
    COVERAGE_OPTIONS="-enableCodeCoverage YES"
    RESULT_BUNDLE_PATH="-resultBundlePath /tmp/jab-tracker-coverage.xcresult"
fi

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
    if [ "$ENABLE_COVERAGE" = true ]; then
        echo "📊 Coverage report will be generated after test completion"
    fi
fi

case "$TEST_TYPE" in
  "unit")
    echo "🧪 Running unit tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET $COVERAGE_OPTIONS $RESULT_BUNDLE_PATH | xcbeautify
    ;;
  "ui")
    echo "🖱️  Running UI tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET $COVERAGE_OPTIONS $RESULT_BUNDLE_PATH | xcbeautify
    ;;
  "all")
    echo "🎯 Running all tests..."
    xcodebuild test -scheme JabTracker -destination "$SIMULATOR" $TEST_TARGET $COVERAGE_OPTIONS $RESULT_BUNDLE_PATH | xcbeautify
    ;;
  *)
    show_usage
    ;;
esac

# Show coverage report if requested
if [ "$ENABLE_COVERAGE" = true ] && [ -d "/tmp/jab-tracker-coverage.xcresult" ]; then
    echo ""
    echo "📊 Code Coverage Report:"
    echo "=========================="
    xcrun xccov view --report /tmp/jab-tracker-coverage.xcresult
    echo ""
    echo "💡 Coverage data saved to: /tmp/jab-tracker-coverage.xcresult"
    echo "💡 To view detailed coverage: xcrun xccov view --file-list /tmp/jab-tracker-coverage.xcresult"
elif [ "$ENABLE_COVERAGE" = true ]; then
    echo ""
    echo "⚠️  Coverage report requested but result bundle not found."
    echo "💡 This may happen if tests fail to complete."
fi