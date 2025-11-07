# Project Restructuring Plan

## New Name: **macOS Audio Bridge**

### Current Structure Problems
- Generic name "VolumeManager"
- Mixed Swift app and HA integration in same repo
- No proper README for the Mac app
- Integration not ready for HACS

### Proposed Structure

```
macos-audio-bridge/
├── README.md                          # Main project README
├── LICENSE                            # MIT License
├── .gitignore                        # Git ignore file
│
├── macos-app/                        # Swift macOS application
│   ├── README.md                     # App-specific docs
│   ├── Package.swift                 # Swift package manifest
│   ├── Sources/
│   │   ├── main.swift
│   │   ├── AppDelegate.swift
│   │   ├── SystemVolume.swift
│   │   └── HomeAssistantServer.swift
│   ├── Resources/
│   │   └── Icon.icns                # App icon
│   └── .build/                      # Build artifacts (ignored)
│
├── homeassistant/                    # HACS-ready integration
│   ├── README.md                     # Integration docs
│   ├── hacs.json                     # HACS metadata
│   ├── custom_components/
│   │   └── macos_audio_bridge/
│   │       ├── manifest.json
│   │       ├── __init__.py
│   │       ├── config_flow.py
│   │       ├── media_player.py
│   │       ├── strings.json
│   │       └── translations/
│   │           └── en.json
│   └── .github/
│       └── workflows/
│           └── validate.yml         # HACS validation
│
└── docs/
    ├── installation.md
    ├── configuration.md
    ├── troubleshooting.md
    └── images/
        ├── screenshot-ha.png
        ├── screenshot-mac.png
        └── logo.png
```

### Naming Convention

**Repository:** `macos-audio-bridge`
**Mac App:** `macOS Audio Bridge`
**HA Integration:** `macOS Audio Bridge`
**HA Domain:** `macos_audio_bridge`
**Package Name:** `macOSAudioBridge`

### Icons

**Mac App Icon:**
- Primary: `hifispeaker.2.fill` (current)
- Alternative: `music.note.house.fill`
- Menu bar: Same as current

**Home Assistant:**
- Icon: `mdi:monitor-speaker`
- Domain icon: `mdi:apple`
- Entity icon: `mdi:speaker-wireless`

### HACS Requirements

1. ✅ Custom repository structure
2. ✅ `hacs.json` file
3. ✅ `manifest.json` with proper metadata
4. ✅ README with installation instructions
5. ✅ Proper versioning/releases
6. ✅ GitHub repository with releases
