#!/bin/bash
#
# swift-format.sh - Convenience script for swift-format with project configuration
#
# Usage:
#   ./scripts/swift-format.sh              # Format all files (in-place)
#   ./scripts/swift-format.sh --lint       # Lint only (check without modifying)
#   ./scripts/swift-format.sh --help       # Show help
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CONFIG_FILE=".swift-format"
TARGET_DIR="."

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

show_help() {
    echo "swift-format.sh - Swift Format with Project Configuration"
    echo ""
    echo "Usage:"
    echo "  ./scripts/swift-format.sh              Format all files (DEFAULT - in-place)"
    echo "  ./scripts/swift-format.sh --format     Format all files (explicit)"
    echo "  ./scripts/swift-format.sh --lint       Lint only (check without modifying)"
    echo "  ./scripts/swift-format.sh --help       Show this help message"
    echo ""
    echo "Configuration:"
    echo "  Uses project configuration file: $CONFIG_FILE"
    echo "  Target directory: $TARGET_DIR"
    echo "  Indentation: 4 spaces, Line length: 120 characters"
    echo ""
    echo "Examples:"
    echo "  ./scripts/swift-format.sh              # Format all Swift files (DEFAULT)"
    echo "  ./scripts/swift-format.sh --lint       # Check formatting without changes"
    echo ""
}

# Check if swift-format is installed
if ! command -v swift-format &> /dev/null; then
    print_error "swift-format is not installed"
    print_info "Install with: brew install swift-format"
    exit 1
fi

# Check if configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_error "Configuration file not found: $CONFIG_FILE"
    print_info "Run from project root directory"
    exit 1
fi

# Parse command line arguments
MODE="format"  # Default mode: format all files

case "${1:-}" in
    --lint)
        MODE="lint"
        ;;
    --help|-h)
        show_help
        exit 0
        ;;
    ""|--format)
        MODE="format"
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac

# Execute swift-format based on mode
print_info "Using configuration: $CONFIG_FILE"
print_info "Target directory: $TARGET_DIR"

case "$MODE" in
    "format")
        print_info "Formatting Swift files (in-place)..."
        swift-format --configuration "$CONFIG_FILE" --in-place --recursive "$TARGET_DIR"
        print_success "Swift formatting completed"
        ;;
    "lint")
        print_info "Linting Swift files (check only)..."
        if swift-format --configuration "$CONFIG_FILE" lint --recursive "$TARGET_DIR"; then
            print_success "All files are properly formatted"
        else
            print_error "Formatting issues found"
            print_info "Run without --lint to fix automatically"
            exit 1
        fi
        ;;
esac

print_info "Project formatting standards:"
print_info "• Indentation: 4 spaces"
print_info "• Line length: 120 characters"
print_info "• Respects existing line breaks: Yes"