#!/bin/bash

# Build the project with pretty output
echo "🔨 Building JabTracker..."

xcodebuild build \
  -scheme JabTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  | xcpretty --color

if [ $? -eq 0 ]; then
    echo "✅ Build succeeded"
else
    echo "❌ Build failed"
    exit 1
fi