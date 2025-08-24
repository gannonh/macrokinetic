#!/bin/bash

# Generate Swift documentation using DocC
echo "🔨 Generating Swift documentation..."

xcodebuild docbuild \
  -scheme JabTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15'

if [ $? -eq 0 ]; then
    echo "✅ Documentation generated successfully"
    echo "📖 Open the generated documentation in Xcode's Documentation Viewer"
else
    echo "❌ Documentation generation failed"
    exit 1
fi