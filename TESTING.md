# Testing Instructions

## Build & Run

To build and run the application:

```bash
swift build
.build/debug/macOSAudioBridge
```

Or build in release mode:

```bash
swift build -c release
.build/release/macOSAudioBridge
```

## Testing the API

Once the app is running, you should see a speaker icon in your menu bar.

### Test the endpoints:

1. **Get Status**
   ```bash
   curl http://localhost:8888/api/status
   ```

2. **Get Volume**
   ```bash
   curl http://localhost:8888/api/volume
   ```

3. **Set Volume (0-100)**
   ```bash
   curl -X POST http://localhost:8888/api/volume \
     -H "Content-Type: application/json" \
     -d '{"volume": 50}'
   ```

4. **Get Mute Status**
   ```bash
   curl http://localhost:8888/api/mute
   ```

5. **Toggle Mute**
   ```bash
   # Mute
   curl -X POST http://localhost:8888/api/mute \
     -H "Content-Type: application/json" \
     -d '{"muted": true}'
   
   # Unmute
   curl -X POST http://localhost:8888/api/mute \
     -H "Content-Type: application/json" \
     -d '{"muted": false}'
   ```

## Settings Window

Click on the menu bar icon and select "Settings..." to:
- Configure the API port (default: 8888)
- Enable/disable launch at startup
- View available API endpoints

## Known Issues Fixed

✅ **Mute functionality** - Now properly implemented using CoreAudio API
✅ **Settings display** - Window height and card positioning adjusted for proper display
✅ **Volume control** - Using correct CoreAudio property selectors

## Troubleshooting

If you encounter issues:

1. **Port already in use**: Change the port in Settings
2. **Audio control not working**: Ensure you have proper audio output devices configured
3. **Settings window cut off**: This has been fixed with improved layout sizing
