#!/bin/bash

set -e  # Exit on any error
set -o pipefail  # Ensure pipeline failures are detected

# Upload JabTracker build to TestFlight
#
# This script automates:
# 1. Archive creation with proper code signing
# 2. IPA export with distribution provisioning profile
# 3. Upload to App Store Connect
# 4. Error handling and user feedback
#
# Prerequisites:
# - Valid Apple Developer account with App Store Connect access
# - Distribution certificate and provisioning profile configured
# - App record created in App Store Connect
# - xcodebuild command-line tools installed
#
# Usage:
#   ./scripts/upload-testflight.sh [--increment-build]
#
# Options:
#   --increment-build    Automatically increment build number before archiving
#   --help              Show this help message

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Upload JabTracker to TestFlight Internal Testing"
    echo ""
    echo "Options:"
    echo "  --increment-build    Automatically increment build number in project.yml"
    echo "  --help              Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  - Valid Apple Developer account with App Store Connect access"
    echo "  - Distribution certificate and provisioning profile"
    echo "  - App record created in App Store Connect (com.gannonhall.JabTracker)"
    echo "  - xcodebuild command-line tools: xcode-select --install"
    echo ""
    echo "Manual Steps (First Time):"
    echo "  1. Create app record in App Store Connect"
    echo "  2. Configure distribution certificate and provisioning profile"
    echo "  3. Add internal testers to Apple Developer team (iTunes Connect access)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Upload current build"
    echo "  $0 --increment-build  # Increment build number and upload"
    exit 0
}

# Parse command-line arguments
INCREMENT_BUILD=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --increment-build)
            INCREMENT_BUILD=true
            shift
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            ;;
    esac
done

# Project configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCHEME="JabTracker"
ARCHIVE_PATH="$PROJECT_DIR/build/JabTracker.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
PROJECT_YML="$PROJECT_DIR/project.yml"

echo "📦 JabTracker TestFlight Upload"
echo "================================"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v xcodebuild &> /dev/null; then
    echo "❌ xcodebuild not found. Install Xcode command-line tools:"
    echo "   xcode-select --install"
    exit 1
fi

if ! command -v xcpretty &> /dev/null; then
    echo "⚠️  xcpretty not found (optional). Install with: brew install xcpretty"
    XCPRETTY_CMD="cat"
else
    XCPRETTY_CMD="xcpretty --color"
fi

if [ ! -f "$PROJECT_YML" ]; then
    echo "❌ project.yml not found at: $PROJECT_YML"
    exit 1
fi

echo "✅ Prerequisites checked"
echo ""

# Get current version info (ignore comment lines)
MARKETING_VERSION=$(grep "MARKETING_VERSION:" "$PROJECT_YML" | grep -v "^[[:space:]]*#" | sed 's/.*MARKETING_VERSION: "\(.*\)"/\1/')
CURRENT_BUILD=$(grep "CURRENT_PROJECT_VERSION:" "$PROJECT_YML" | grep -v "^[[:space:]]*#" | sed 's/.*CURRENT_PROJECT_VERSION: "\(.*\)"/\1/')

if [ -z "$MARKETING_VERSION" ] || [ -z "$CURRENT_BUILD" ]; then
    echo "❌ Failed to read version information from project.yml"
    exit 1
fi

echo "📋 Current version: $MARKETING_VERSION (build $CURRENT_BUILD)"

# Increment build number if requested
if [ "$INCREMENT_BUILD" = true ]; then
    NEW_BUILD=$((CURRENT_BUILD + 1))
    echo "🔢 Incrementing build number: $CURRENT_BUILD → $NEW_BUILD"

    # Update project.yml
    sed -i '' "s/CURRENT_PROJECT_VERSION: \"$CURRENT_BUILD\"/CURRENT_PROJECT_VERSION: \"$NEW_BUILD\"/" "$PROJECT_YML"

    # Regenerate Xcode project
    echo "🔄 Regenerating Xcode project..."
    if ! xcodegen generate --spec "$PROJECT_YML" --project "$PROJECT_DIR"; then
        echo "❌ Failed to regenerate Xcode project"
        exit 1
    fi

    CURRENT_BUILD=$NEW_BUILD
    echo "✅ Build number updated to $NEW_BUILD"
    echo ""
fi

echo "📦 Building version $MARKETING_VERSION (build $CURRENT_BUILD)"
echo ""

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf "$PROJECT_DIR/build"
mkdir -p "$PROJECT_DIR/build"

# Archive the app
echo "📦 Creating archive..."
echo "   This may take several minutes..."
echo ""

if xcodebuild archive \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -configuration Release \
    CODE_SIGN_STYLE=Automatic \
    | eval "$XCPRETTY_CMD"; then
    echo ""
    echo "✅ Archive created successfully"
else
    echo ""
    echo "❌ Archive failed"
    exit 1
fi

echo ""

# Check if archive was created
if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive not found at: $ARCHIVE_PATH"
    exit 1
fi

# Export IPA for App Store distribution
echo "📤 Exporting IPA for App Store distribution..."
echo ""

# Create ExportOptions.plist
EXPORT_OPTIONS_PLIST="$PROJECT_DIR/build/ExportOptions.plist"
cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
EOF

if xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    | eval "$XCPRETTY_CMD"; then
    echo ""
    echo "✅ IPA exported successfully"
else
    echo ""
    echo "❌ IPA export failed"
    exit 1
fi

echo ""

# Upload to App Store Connect
echo "🚀 Uploading to App Store Connect..."
echo "   This may take several minutes depending on file size and connection speed..."
echo ""

IPA_PATH="$EXPORT_PATH/JabTracker.ipa"

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA file not found at: $IPA_PATH"
    exit 1
fi

# Upload using xcrun altool (modern method)
# Uses credentials from Keychain (stored with 'APP_STORE' item name)
if xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username gannonhall@gmail.com \
    --password "@keychain:APP_STORE" \
    --verbose; then
    echo ""
    echo "✅ Upload successful!"
else
    echo ""
    echo "❌ Upload failed"
    echo ""
    echo "Common issues:"
    echo "  - App record not created in App Store Connect"
    echo "  - Invalid bundle ID (must be: com.gannonhall.JabTracker)"
    echo "  - Distribution certificate or provisioning profile issues"
    echo "  - Apple ID credentials not configured"
    echo ""
    echo "For credential setup, use:"
    echo "  xcrun altool --store-password-in-keychain-item 'APP_STORE' -u YOUR_APPLE_ID -p APP_SPECIFIC_PASSWORD"
    exit 1
fi

echo ""
echo "================================"
echo "✅ TestFlight Upload Complete"
echo "================================"
echo ""
echo "Version: $MARKETING_VERSION (build $CURRENT_BUILD)"
echo ""
echo "Next Steps:"
echo "  1. Wait 10-30 minutes for build processing"
echo "  2. Log in to App Store Connect: https://appstoreconnect.apple.com"
echo "  3. Navigate to: My Apps → JabTracker → TestFlight → Internal Testing"
echo "  4. Add build notes (optional but recommended)"
echo "  5. Answer export compliance questions (Standard encryption exemption)"
echo "  6. Assign build to internal testing group"
echo "  7. Internal testers will receive email notification"
echo ""
echo "Export Compliance (Required):"
echo "  - Uses encryption? YES"
echo "  - Type: Standard encryption (CloudKit, HTTPS)"
echo "  - Exemption: Standard encryption - no custom crypto"
echo "  - Export compliance document: NOT REQUIRED"
echo ""
echo "Internal Tester Requirements:"
echo "  - Must be Apple Developer team member"
echo "  - Must have iTunes Connect access role"
echo "  - No Beta App Review required for internal testing"
echo ""
