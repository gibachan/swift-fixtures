#!/bin/bash

# Script to generate and open DocC documentation for the Fixtures library

set -e

echo "🔨 Building project and generating documentation..."
xcodebuild docbuild -scheme Fixtures -destination 'platform=macOS'

echo "📚 Finding generated documentation..."
DOCS_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Fixtures.doccarchive" -path "*/Debug/*" | head -1)

if [ -z "$DOCS_PATH" ]; then
    echo "❌ Could not find generated documentation"
    echo "Make sure the build succeeded and try again"
    exit 1
fi

echo "📖 Opening documentation at: $DOCS_PATH"
open "$DOCS_PATH"

echo "✅ Documentation opened successfully!"
echo "You can also manually open the documentation by running:"
echo "open \"$DOCS_PATH\""