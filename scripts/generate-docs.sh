#!/bin/bash

# Script to generate and open DocC documentation for the Fixtures library

set -eo pipefail

echo "🔨 Building project and generating documentation..."

# Store temporary files to avoid race conditions
BUILD_LOG=$(mktemp)
cleanup() {
    rm -f "${BUILD_LOG}"
}
trap cleanup EXIT

# Capture xcodebuild output for debugging and path extraction
echo "Running: xcodebuild docbuild -scheme Fixtures -destination 'platform=macOS'"
if ! xcodebuild docbuild -scheme Fixtures -destination 'platform=macOS' > "${BUILD_LOG}" 2>&1; then
    echo "❌ Documentation build failed!"
    echo "Build output:"
    cat "${BUILD_LOG}"
    exit 1
fi

echo "✅ Build succeeded!"

# Show the successful build output
echo "📚 Finding generated documentation..."

# Try multiple methods to find the documentation path
DOCS_PATH=""

# Method 1: Try to extract from build log (for future DocC versions that might output the path)
DOCS_PATH=$(grep -o "Generated documentation archive at:.*\.doccarchive" "${BUILD_LOG}" 2>/dev/null | sed 's/Generated documentation archive at: *//' || true)

# Method 2: Search in DerivedData (current reliable method)
if [ -z "$DOCS_PATH" ]; then
    DOCS_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Fixtures.doccarchive" -path "*/Debug/*" -newermt "1 minute ago" | head -1)
fi

# Method 3: Fallback to any recent Fixtures.doccarchive
if [ -z "$DOCS_PATH" ]; then
    DOCS_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Fixtures.doccarchive" -path "*/Debug/*" | head -1)
fi

if [ -z "$DOCS_PATH" ]; then
    echo "❌ Could not find generated documentation archive"
    echo "Expected to find Fixtures.doccarchive in ~/Library/Developer/Xcode/DerivedData"
    echo ""
    echo "Build completed successfully, but documentation archive location could not be determined."
    echo "You can manually look for Fixtures.doccarchive in:"
    echo "  ~/Library/Developer/Xcode/DerivedData/*/Build/Products/Debug/"
    exit 1
fi

echo "📖 Opening documentation at: $DOCS_PATH"
open "$DOCS_PATH"

echo "✅ Documentation opened successfully!"
echo "You can also manually open the documentation by running:"
echo "open \"$DOCS_PATH\""
