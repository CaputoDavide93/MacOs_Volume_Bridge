#!/bin/bash

# Build and Install macOS Audio Bridge
# This script builds the app and copies it to /Applications for proper functionality

set -e

echo "🔨 Building macOS Audio Bridge..."
swift build -c release

echo "📦 Creating app bundle..."
APP_PATH="$HOME/Applications/macOSAudioBridge.app"
BUILD_PATH=".build/release/macOSAudioBridge"

# Remove old app if exists
if [ -d "$APP_PATH" ]; then
    echo "🗑️  Removing old installation..."
    rm -rf "$APP_PATH"
fi

# Create app bundle structure
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Copy executable
echo "📋 Copying executable..."
cp "$BUILD_PATH" "$APP_PATH/Contents/MacOS/"

# Copy Info.plist
echo "📋 Copying Info.plist..."
cp Info.plist "$APP_PATH/Contents/"

# Make executable
chmod +x "$APP_PATH/Contents/MacOS/macOSAudioBridge"

echo "✅ Installation complete!"
echo ""
echo "📍 App installed to: $APP_PATH"
echo ""
echo "To run the app:"
echo "  open ~/Applications/macOSAudioBridge.app"
echo ""
echo "Note: 'Launch at Startup' should now work from ~/Applications"
