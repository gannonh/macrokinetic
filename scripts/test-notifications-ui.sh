#!/bin/bash
# Script to run notification UI tests with automatic permission reset

set -e

# Reset notification permissions before running tests
echo "🔄 Resetting simulator notification permissions..."
xcrun simctl privacy booted reset all com.gannonhall.JabTracker

# Run the notification flow tests
echo "🧪 Running notification UI tests..."
./scripts/test.sh ui 1 OnboardingNotificationFlowUITests "$@"
