# Icon Submission Guide for Home Assistant Brands

## Overview

Custom Home Assistant integrations can display icons by submitting them to the official [home-assistant/brands](https://github.com/home-assistant/brands) repository. This is how other custom integrations like HACS, Alexa Media Player, and many others show their icons.

## Prerequisites

- Icons prepared at: `/tmp/macos_audio_bridge_brand/`
  - `icon.png` (256x256px, 81KB)
  - `icon@2x.png` (512x512px, 298KB)
- GitHub account

## Submission Steps

### 1. Fork the Brands Repository

Go to https://github.com/home-assistant/brands and click "Fork"

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/brands.git
cd brands
```

### 3. Create a New Branch

```bash
git checkout -b add-macos-audio-bridge
```

### 4. Create Integration Directory

```bash
mkdir -p custom_integrations/macos_audio_bridge
```

### 5. Copy Icons

```bash
cp /tmp/macos_audio_bridge_brand/icon.png custom_integrations/macos_audio_bridge/
cp /tmp/macos_audio_bridge_brand/icon@2x.png custom_integrations/macos_audio_bridge/
```

### 6. Commit and Push

```bash
git add custom_integrations/macos_audio_bridge/
git commit -m "Add macOS Audio Bridge integration icons"
git push origin add-macos-audio-bridge
```

### 7. Create Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. **Title**: `Add macOS Audio Bridge integration icons`
4. **Description**:
   ```
   Adding icons for the macOS Audio Bridge custom integration.
   
   **Domain**: macos_audio_bridge
   **Repository**: https://github.com/CaputoDavide93/MacOs_Volume_Bridge
   
   **Icon specifications**:
   - icon.png: 256x256px, optimized PNG
   - icon@2x.png: 512x512px, optimized PNG
   - Transparent background
   - Square aspect ratio (1:1)
   - Properly compressed and optimized
   ```
5. Submit the PR

### 8. Wait for Review

The Home Assistant team will review your PR. This typically takes 2-4 weeks.

Once merged, your icons will be available at:
- `https://brands.home-assistant.io/macos_audio_bridge/icon.png`
- `https://brands.home-assistant.io/macos_audio_bridge/icon@2x.png`

Home Assistant will automatically fetch and display these icons for your integration!

## After Merge

Once the PR is merged:
- Icons will appear automatically in Home Assistant
- No changes needed to your integration code
- Icons will show in:
  - HACS integration list
  - Home Assistant integration cards
  - Configuration UI
  - Anywhere the integration is displayed

## Icon Specifications

As per [Home Assistant Brands guidelines](https://github.com/home-assistant/brands):

### General Requirements
- **Format**: PNG only
- **Optimization**: Properly compressed (lossless preferred)
- **Interlaced**: Progressive PNG preferred
- **Transparency**: Preferred
- **Background**: Optimized for white background (dark variants can be added later)
- **Trimming**: Minimum empty space on edges

### Icon Image Requirements
- **Aspect ratio**: 1:1 (square)
- **Standard size**: 256x256 pixels
- **hDPI size**: 512x512 pixels
- **Naming**: `icon.png` and `icon@2x.png`

### Logo Image Requirements (Optional)
- **Aspect ratio**: Respect brand's logo ratio
- **Shortest side**: 128-256px (standard), 256-512px (hDPI)
- **Naming**: `logo.png` and `logo@2x.png`

## Troubleshooting

### PR is Rejected
- Verify icon dimensions are exact (256x256 and 512x512)
- Ensure PNG format and proper compression
- Check that images have transparent backgrounds
- Verify domain name matches `manifest.json`

### Icons Not Showing After Merge
- Clear Home Assistant cache
- Restart Home Assistant
- Clear browser cache (Ctrl+Shift+R / Cmd+Shift+R)
- Wait 24 hours for CDN propagation

## References

- [Home Assistant Brands Repository](https://github.com/home-assistant/brands)
- [HACS Documentation](https://hacs.xyz/docs/publish/include)
- [Integration Manifest Documentation](https://developers.home-assistant.io/docs/creating_integration_manifest)

---

**Note**: This is the **official and only** way for custom integrations to display icons in Home Assistant. Icons placed in `custom_components/macos_audio_bridge/` are only used by HACS for the repository card, not by Home Assistant itself.
