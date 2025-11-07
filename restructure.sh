#!/bin/bash

# macOS Audio Bridge - Repository Restructuring Script
# This script reorganizes the project for HACS distribution

set -e

echo "🔧 Restructuring macOS Audio Bridge repository..."

# Get the project root (parent of VolumeManager)
PROJECT_ROOT="/Users/davide.caputo/Documents/Development/Swift/macos-audio-bridge"

if [ ! -d "$PROJECT_ROOT" ]; then
    echo "❌ Project directory not found at $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"

echo "📁 Current structure:"
ls -la

echo ""
echo "✨ Creating HACS-compatible structure..."

# Create main directories if they don't exist
mkdir -p macos-app
mkdir -p custom_components/macos_audio_bridge
mkdir -p docs/images
mkdir -p .github/workflows

echo "✅ Directories created"
echo ""
echo "📦 Final structure should be:"
echo "macos-audio-bridge/"
echo "├── README.md"
echo "├── LICENSE"
echo "├── hacs.json"
echo "├── .gitignore"
echo "├──"
echo "├── macos-app/              # Swift app"
echo "│   ├── Sources/"
echo "│   └── Package.swift"
echo "├── custom_components/      # HACS integration"
echo "│   └── macos_audio_bridge/"
echo "│       ├── __init__.py"
echo "│       ├── manifest.json"
echo "│       ├── config_flow.py"
echo "│       ├── media_player.py"
echo "│       └── strings.json"
echo "└── docs/"
echo "    ├── installation.md"
echo "    └── images/"
echo ""
echo "✅ Restructuring complete!"
echo ""
echo "📝 Next steps:"
echo "1. Reopen VS Code in: $PROJECT_ROOT"
echo "2. Update Package.swift product name to 'macOSAudioBridge'"
echo "3. Create GitHub repository"
echo "4. Add to HACS as custom repository"
