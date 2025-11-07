# macOS Audio Bridge 🎵

A lightweight menu bar app that exposes your Mac's audio controls to Home Assistant via a REST API. Control your Mac's volume and mute status from anywhere in your home automation setup.

[![HACS](https://img.shields.io/badge/HACS-Custom-orange.svg)](https://github.com/hacs/integration)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Features

- 🎚️ **Volume Control** - Set system volume (0-100%)
- 🔇 **Mute Control** - Toggle mute state
- 🏠 **Home Assistant Integration** - Native media_player entity
- 📡 **Local API** - REST API for direct control
- ⚡ **Lightweight** - Minimal resource usage
- 🔒 **Privacy First** - All local, no cloud
- 🎨 **Native UI** - Clean macOS menu bar interface

## 🚀 Quick Start

### macOS App Installation

1. Download the latest release from [GitHub Releases](https://github.com/CaputoDavide93/MacOs_Volume_Bridge/releases)
2. Extract and move `macOSAudioBridge.app` to your `~/Applications` folder
3. Launch the app - you'll see a speaker icon in your menu bar
4. Click the icon to access settings

### Home Assistant Installation

#### Via HACS (One-Click)

[![Open your Home Assistant instance and open a repository inside the Home Assistant Community Store.](https://my.home-assistant.io/badges/hacs_repository.svg)](https://my.home-assistant.io/redirect/hacs_repository/?owner=CaputoDavide93&repository=MacOs_Volume_Bridge&category=integration)

Or manually:

1. Open HACS in Home Assistant
2. Go to Integrations
3. Click the three dots (⋮) → Custom repositories
4. Add repository URL: `https://github.com/CaputoDavide93/MacOs_Volume_Bridge`
5. Category: Integration
6. Click "Install"
7. Restart Home Assistant
8. Go to Settings → Devices & Services → Add Integration
9. Search for "macOS Audio Bridge"
10. Enter your Mac's IP address and port (default: 8888)

#### Manual Installation

1. Copy `custom_components/macos_audio_bridge` to your Home Assistant `config/custom_components/` directory
2. Restart Home Assistant
3. Add integration via UI

## 📱 Usage

### Home Assistant Dashboard

Add a media player card:

```yaml
type: media-control
entity: media_player.macos_audio_bridge
```

Or use in automations:

```yaml
automation:
  - alias: "Morning Volume"
    trigger:
      platform: time
      at: "08:00:00"
    action:
      service: media_player.volume_set
      target:
        entity_id: media_player.macos_audio_bridge
      data:
        volume_level: 0.5
```

### Direct API Access

```bash
# Get status
curl http://YOUR_MAC_IP:8888/api/status

# Set volume
curl -X POST http://YOUR_MAC_IP:8888/api/volume \
  -H "Content-Type: application/json" \
  -d '{"volume": 50}'

# Toggle mute
curl -X POST http://YOUR_MAC_IP:8888/api/mute \
  -H "Content-Type: application/json" \
  -d '{"muted": true}'
```

## 🔧 Configuration

### Mac App Settings

Click the menu bar icon to access:
- **Change Port...** - Modify API port (default: 8888)
- **Launch at Startup** - Auto-start with macOS

### Home Assistant

Configure via UI when adding the integration:

- **Host**: Your Mac's local IP address
- **Port**: API port (default: 8888)
- **Name**: Custom device name (optional)

## 🛠️ Development

### Requirements

- macOS 13.0+
- Swift 5.9+
- Home Assistant 2023.8+

### Building from Source

```bash
cd /path/to/MacOs_Volume_Bridge
swift build -c release
./install.sh
```

### Testing the Integration

```bash
# Test API connectivity
curl http://localhost:8888/api/status

# Run Home Assistant in development mode
hass --script check_config
```

## 📖 API Reference

### Endpoints

- `GET /api/status` - Get volume, mute status, and capabilities
- `GET /api/volume` - Get current volume (0-100)
- `POST /api/volume` - Set volume (0-100)
- `GET /api/mute` - Get mute status
- `POST /api/mute` - Set mute status (true/false)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details

## 🙏 Acknowledgments

- Built with Swift and CoreAudio
- Home Assistant integration using the media_player platform
- Icon design using SF Symbols

## 📮 Support

- **Issues**: [GitHub Issues](https://github.com/CaputoDavide93/MacOs_Volume_Bridge/issues)
- **Discussions**: [GitHub Discussions](https://github.com/CaputoDavide93/MacOs_Volume_Bridge/discussions)

---

Made with ❤️ for the Home Assistant community
