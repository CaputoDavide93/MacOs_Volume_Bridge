#!/bin/bash

APP_NAME="macOSAudioBridge"
APP_DIR="/System/Applications/$APP_NAME.app"

echo "🗑️  Uninstalling macOS Audio Bridge..."

# Check if app exists
if [ ! -d "$APP_DIR" ]; then
    echo "❌ App not found at $APP_DIR"
    
    # Check in regular Applications
    if [ -d "/Applications/$APP_NAME.app" ]; then
        echo "Found in /Applications/ instead, removing from there..."
        APP_DIR="/Applications/$APP_NAME.app"
    else
        exit 1
    fi
fi

# Kill the app if running
echo "🛑 Stopping app if running..."
killall macOSAudioBridge 2>/dev/null || true

# Disable launch at login if enabled
echo "🔓 Disabling launch at login..."
launchctl remove com.caputo.macOSAudioBridge 2>/dev/null || true

# Remove the app (requires sudo for /System/Applications)
echo "🗑️  Removing app bundle..."
sudo rm -rf "$APP_DIR"

# Remove preferences
echo "🧹 Cleaning up preferences..."
defaults delete com.caputo.macOSAudioBridge 2>/dev/null || true

# Refresh icon cache
sudo killall Finder 2>/dev/null || true

echo ""
echo "✅ macOS Audio Bridge has been uninstalled!"
echo ""
echo "If you had 'Launch at Startup' enabled, you may need to:"
echo "1. Go to System Settings → General → Login Items"
echo "2. Remove 'macOSAudioBridge' if it still appears there"
