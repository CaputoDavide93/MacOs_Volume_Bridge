<div align="center">

<img src="ICO.png" alt="macOS Audio Bridge" width="200"/>

# macOS Audio Bridge

**Control your Mac's audio from Home Assistant**

A lightweight menu bar app that exposes your Mac's audio controls to Home Assistant via a REST API. Control your Mac's volume and mute status from anywhere in your home automation setup.

[![GitHub Release](https://img.shields.io/github/v/release/CaputoDavide93/MacOs_Volume_Bridge)](https://github.com/CaputoDavide93/MacOs_Volume_Bridge/releases)
[![HACS](https://img.shields.io/badge/HACS-Custom-orange.svg)](https://github.com/hacs/integration)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-13.0%2B-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Architecture](https://img.shields.io/badge/Architecture-ARM64%20%7C%20x86__64-green.svg)](https://github.com/CaputoDavide93/MacOs_Volume_Bridge)
[![GitHub Stars](https://img.shields.io/github/stars/CaputoDavide93/MacOs_Volume_Bridge)](https://github.com/CaputoDavide93/MacOs_Volume_Bridge/stargazers)

</div>

---

## ✨ Features

### 🎵 Media Playback Control
- ▶️ **Play/Pause/Stop** - Full playback control for Music app
- ⏭️ **Next/Previous Track** - Skip through your playlist

### 🔊 Audio Management
- 🎚️ **Volume Control** - Set system volume (0-100%)
- 🔇 **Mute Control** - Toggle mute state

### 🏠 Home Assistant Integration
- 🎮 **Simple Media Player Entity** - Native HA media_player with essential controls
- 📊 **Real-time Status** - Volume, mute, and playback state
- 🔧 **Easy Setup** - HACS integration with config flow
- ⚡ **Low Latency** - Local REST API for instant response

### 🔧 Technical Features
- 📡 **REST API** - Complete HTTP API for automation
- ⚡ **Lightweight** - Minimal resource usage (~10MB RAM)
- 🔒 **Privacy First** - 100% local, no cloud services
- 🍎 **Universal Binary** - Native support for Apple Silicon & Intel
- 🎨 **Native UI** - Clean macOS menu bar interface

## 💻 System Requirements

### macOS App
- **OS**: macOS 13.0 (Ventura) or later
- **Architecture**: Apple Silicon (ARM64) and Intel (x86_64)
- **Swift**: 5.9+

### Home Assistant
- **Version**: 2023.8.0 or later
- **HACS**: Latest version recommended

## 🚀 Quick Start

### macOS App Installation

#### Option 1: Download PKG Installer (Recommended)

1. Download `macOSAudioBridge-1.3.0.pkg` from [GitHub Releases](https://github.com/CaputoDavide93/MacOs_Volume_Bridge/releases/latest)
2. Double-click the PKG file and follow the installation wizard
3. The app will be installed to `/Applications/macOSAudioBridge.app`
4. Launch from Applications folder - you'll see a speaker icon in your menu bar

#### Option 2: Build from Source

If you prefer to build the app yourself:

```bash
git clone https://github.com/CaputoDavide93/MacOs_Volume_Bridge.git
cd MacOs_Volume_Bridge
chmod +x install.sh
./install.sh
```

After installation (either method):

- Click the menu bar icon to access settings
- Optionally enable "Launch at Startup"
- Configure port if needed (default: 8888)

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
- Xcode Command Line Tools

### Building from Source

```bash
# Clone the repository
git clone https://github.com/CaputoDavide93/MacOs_Volume_Bridge.git
cd MacOs_Volume_Bridge

# Build for your architecture (universal binary)
swift build -c release

# Install to ~/Applications
./install.sh

# Run the app
open ~/Applications/macOSAudioBridge.app
```

### Architecture Support

The app is built as a universal binary supporting:
- **Apple Silicon (ARM64)** - M1, M2, M3 Macs
- **Intel (x86_64)** - Intel-based Macs

The Swift compiler automatically builds for your current architecture.

## 📖 API Reference

### Endpoints

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/api/status` | Get volume, mute status, and capabilities | - | `{"volume": 50, "muted": false, "volume_control_available": true, "mute_control_available": true}` |
| GET | `/api/volume` | Get current volume (0-100) | - | `{"volume": 50}` |
| POST | `/api/volume` | Set volume (0-100) | `{"volume": 50}` | `{"success": true, "volume": 50}` |
| GET | `/api/mute` | Get mute status | - | `{"muted": false}` |
| POST | `/api/mute` | Set mute status | `{"muted": true}` | `{"success": true, "muted": true}` |

### Example API Calls

```bash
# Get current status
curl http://192.168.1.100:8888/api/status

# Set volume to 75%
curl -X POST http://192.168.1.100:8888/api/volume \
  -H "Content-Type: application/json" \
  -d '{"volume": 75}'

# Mute audio
curl -X POST http://192.168.1.100:8888/api/mute \
  -H "Content-Type: application/json" \
  -d '{"muted": true}'
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

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
