#!/bin/bash

echo "🚀 Building macOS Audio Bridge..."

# Check if ICO.png exists
if [ ! -f "ICO.png" ]; then
    echo "❌ Error: ICO.png not found!"
    echo "Please add ICO.png to the project root directory."
    exit 1
fi

echo "📸 Found ICO.png"

# Build release version
echo "⚙️  Building..."
swift build -c release 2>&1 | grep -E "(error|warning|Build complete)" || true

if [ ! -f ".build/release/macOSAudioBridge" ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "✅ Build complete!"

# Create app bundle structure
APP_NAME="macOSAudioBridge"
APP_DIR="/Applications/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating app bundle at $APP_DIR..."
echo "⚠️  This will require your administrator password"

# Remove old version if exists
if [ -d "$APP_DIR" ]; then
    echo "🗑️  Removing old version..."
    sudo rm -rf "$APP_DIR"
fi

# Also remove from /Applications if exists there
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "🗑️  Removing old version from /Applications..."
    sudo rm -rf "/Applications/$APP_NAME.app"
fi

# Create directories
sudo mkdir -p "$MACOS_DIR"
sudo mkdir -p "$RESOURCES_DIR"

# Copy executable
echo "📋 Copying executable..."
sudo cp .build/release/macOSAudioBridge "$MACOS_DIR/"
sudo chmod +x "$MACOS_DIR/macOSAudioBridge"

# Create proper macOS icon (.icns)
echo "🎨 Creating app icon..."
ICONSET_DIR="/tmp/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

# Create all icon sizes (silently)
sips -z 16 16     ICO.png --out "$ICONSET_DIR/icon_16x16.png" >/dev/null 2>&1
sips -z 32 32     ICO.png --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null 2>&1
sips -z 32 32     ICO.png --out "$ICONSET_DIR/icon_32x32.png" >/dev/null 2>&1
sips -z 64 64     ICO.png --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null 2>&1
sips -z 128 128   ICO.png --out "$ICONSET_DIR/icon_128x128.png" >/dev/null 2>&1
sips -z 256 256   ICO.png --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null 2>&1
sips -z 256 256   ICO.png --out "$ICONSET_DIR/icon_256x256.png" >/dev/null 2>&1
sips -z 512 512   ICO.png --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null 2>&1
sips -z 512 512   ICO.png --out "$ICONSET_DIR/icon_512x512.png" >/dev/null 2>&1
sips -z 1024 1024 ICO.png --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null 2>&1

# Convert to icns
iconutil -c icns "$ICONSET_DIR" -o "/tmp/AppIcon.icns" >/dev/null 2>&1

# Copy icon files
sudo cp /tmp/AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
sudo cp ICO.png "$RESOURCES_DIR/icon.png"

echo "✅ Icon created successfully!"

# Copy Info.plist
echo "📋 Installing Info.plist..."
sudo cp Info.plist "$CONTENTS_DIR/"

# Set proper ownership and permissions
echo "🔐 Setting permissions..."
sudo chown -R root:wheel "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

# Clean up
rm -rf "$ICONSET_DIR" /tmp/AppIcon.icns

# Touch the app to update modification date
sudo touch "$APP_DIR"

# Clear icon cache and restart services
echo "🔄 Refreshing icon cache..."
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true

echo ""
echo "✅ Installation complete!"
echo "📍 Location: $APP_DIR"
echo ""
echo "🚀 Launching app..."
sleep 2
open "$APP_DIR"
