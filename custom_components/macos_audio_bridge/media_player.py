"""Media player platform for macOS Audio Bridge."""
import logging
import aiohttp

from homeassistant.components.media_player import (
    MediaPlayerEntity,
    MediaPlayerEntityFeature,
    MediaPlayerState,
)
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import CONF_HOST, CONF_PORT, CONF_NAME
from homeassistant.core import HomeAssistant
from homeassistant.helpers.aiohttp_client import async_get_clientsession
from homeassistant.helpers.entity_platform import AddEntitiesCallback

_LOGGER = logging.getLogger(__name__)

DOMAIN = "macos_audio_bridge"

async def async_setup_entry(
    hass: HomeAssistant,
    config_entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the macOS Audio Bridge media player."""
    host = config_entry.data[CONF_HOST]
    port = config_entry.data[CONF_PORT]
    name = config_entry.data.get(CONF_NAME, "macOS Audio Bridge")
    
    async_add_entities([MacOSAudioBridgeMediaPlayer(hass, host, port, name)])

class MacOSAudioBridgeMediaPlayer(MediaPlayerEntity):
    """Representation of macOS Audio Bridge media player."""

    def __init__(self, hass: HomeAssistant, host: str, port: int, name: str):
        """Initialize the media player."""
        self.hass = hass
        self._host = host
        self._port = port
        self._name = name
        self._state = MediaPlayerState.IDLE
        self._volume = 0.5
        self._muted = False
        self._available = True

    @property
    def name(self):
        """Return the name of the device."""
        return self._name

    @property
    def unique_id(self):
        """Return a unique ID."""
        return f"{self._host}_{self._port}_macos_audio"

    @property
    def state(self):
        """Return the state of the device."""
        return self._state

    @property
    def volume_level(self):
        """Volume level of the media player (0..1)."""
        return self._volume

    @property
    def is_volume_muted(self):
        """Boolean if volume is currently muted."""
        return self._muted

    @property
    def available(self):
        """Return True if entity is available."""
        return self._available

    @property
    def supported_features(self):
        """Flag media player features that are supported."""
        return (
            MediaPlayerEntityFeature.VOLUME_SET
            | MediaPlayerEntityFeature.VOLUME_MUTE
            | MediaPlayerEntityFeature.VOLUME_STEP
            | MediaPlayerEntityFeature.PLAY
            | MediaPlayerEntityFeature.PAUSE
            | MediaPlayerEntityFeature.STOP
            | MediaPlayerEntityFeature.NEXT_TRACK
            | MediaPlayerEntityFeature.PREVIOUS_TRACK
        )

    @property
    def device_info(self):
        """Return device information."""
        return {
            "identifiers": {(DOMAIN, f"{self._host}_{self._port}")},
            "name": self._name,
            "manufacturer": "macOS Audio Bridge",
            "model": "Audio Controller",
        }

    async def async_update(self):
        """Update the media player state."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/status"
            
            async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                if response.status == 200:
                    data = await response.json()
                    
                    self._volume = data.get("volume", 50) / 100.0
                    self._muted = data.get("muted", False)
                    
                    playback_state = data.get("playback_state", "idle")
                    if playback_state == "playing":
                        self._state = MediaPlayerState.PLAYING
                    elif playback_state == "paused":
                        self._state = MediaPlayerState.PAUSED
                    else:
                        self._state = MediaPlayerState.IDLE
                    
                    self._available = True
                else:
                    self._available = False
                    
        except Exception as err:
            _LOGGER.debug("Error updating macOS Audio Bridge: %s", err)
            self._available = False

    async def async_set_volume_level(self, volume):
        """Set volume level (0..1)."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/volume"
            volume_percent = int(volume * 100)
            
            async with session.post(
                url,
                json={"level": volume_percent},
                timeout=aiohttp.ClientTimeout(total=5)
            ) as response:
                if response.status == 200:
                    self._volume = volume
                    
        except Exception as err:
            _LOGGER.error("Error setting volume: %s", err)

    async def async_mute_volume(self, mute):
        """Mute or unmute the volume."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/mute"
            
            async with session.post(
                url,
                json={"muted": mute},
                timeout=aiohttp.ClientTimeout(total=5)
            ) as response:
                if response.status == 200:
                    self._muted = mute
                    
        except Exception as err:
            _LOGGER.error("Error muting volume: %s", err)

    async def async_media_play(self):
        """Send play command."""
        await self._send_command("/api/media/play")
        self._state = MediaPlayerState.PLAYING

    async def async_media_pause(self):
        """Send pause command."""
        await self._send_command("/api/media/pause")
        self._state = MediaPlayerState.PAUSED

    async def async_media_stop(self):
        """Send stop command."""
        await self._send_command("/api/media/stop")
        self._state = MediaPlayerState.IDLE

    async def async_media_next_track(self):
        """Send next track command."""
        await self._send_command("/api/media/next")

    async def async_media_previous_track(self):
        """Send previous track command."""
        await self._send_command("/api/media/previous")

    async def _send_command(self, endpoint):
        """Send a command to the API."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}{endpoint}"
            
            async with session.post(url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                if response.status != 200:
                    _LOGGER.error("Error sending command to %s: HTTP %d", endpoint, response.status)
                    
        except Exception as err:
            _LOGGER.error("Error sending command to %s: %s", endpoint, err)
