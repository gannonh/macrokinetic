#!/bin/bash

# Run tests with pretty output
SIMULATOR="platform=iOS Simulator,id=DACB14C5-82B9-4A47-BA69-DCD22DE623FA"

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
    echo "Usage: $0 {unit|ui|all}"
    echo "  unit - Run unit tests only"
    echo "  ui   - Run UI tests only"  
    echo "  all  - Run all tests"
    exit 1
    ;;
esac