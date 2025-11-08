"""Media player platform for macOS Audio Bridge."""
import logging
import aiohttp
import asyncio

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
        self._media_title = None
        self._media_artist = None
        self._media_album = None
        self._media_duration = None
        self._media_position = None
        self._shuffle = False
        self._repeat = "off"

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
    def media_title(self):
        """Title of current playing media."""
        return self._media_title
    
    @property
    def media_artist(self):
        """Artist of current playing media."""
        return self._media_artist
    
    @property
    def media_album_name(self):
        """Album name of current playing media."""
        return self._media_album
    
    @property
    def media_duration(self):
        """Duration of current playing media in seconds."""
        return self._media_duration
    
    @property
    def media_position(self):
        """Position of current playing media in seconds."""
        return self._media_position
    
    @property
    def shuffle(self):
        """Boolean if shuffle is enabled."""
        return self._shuffle
    
    @property
    def repeat(self):
        """Return current repeat mode."""
        return self._repeat

    @property
    def supported_features(self):
        """Flag media player features that are supported."""
        return (
            MediaPlayerEntityFeature.VOLUME_SET |
            MediaPlayerEntityFeature.VOLUME_MUTE |
            MediaPlayerEntityFeature.PLAY |
            MediaPlayerEntityFeature.PAUSE |
            MediaPlayerEntityFeature.STOP |
            MediaPlayerEntityFeature.NEXT_TRACK |
            MediaPlayerEntityFeature.PREVIOUS_TRACK |
            MediaPlayerEntityFeature.PLAY_MEDIA |
            MediaPlayerEntityFeature.SHUFFLE_SET |
            MediaPlayerEntityFeature.REPEAT_SET |
            MediaPlayerEntityFeature.SEEK
        )

    async def async_update(self):
        """Fetch new state data for this media player."""
        try:
            session = async_get_clientsession(self.hass)
            
            # Get volume and mute status
            status_url = f"http://{self._host}:{self._port}/api/status"
            async with asyncio.timeout(5):
                async with session.get(status_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        self._volume = data.get("volume", 50) / 100.0
                        self._muted = data.get("muted", False)
                        
                        # Map playback state
                        playback_state = data.get("playback_state", "stopped")
                        if playback_state == "playing":
                            self._state = MediaPlayerState.PLAYING
                        elif playback_state == "paused":
                            self._state = MediaPlayerState.PAUSED
                        else:
                            self._state = MediaPlayerState.IDLE
                        
                        self._available = True
                    else:
                        self._available = False
                        return
            
            # Get media info
            info_url = f"http://{self._host}:{self._port}/api/media/info"
            async with asyncio.timeout(5):
                async with session.get(info_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        self._media_title = data.get("title") or None
                        self._media_artist = data.get("artist") or None
                        self._media_album = data.get("album") or None
                        self._media_duration = data.get("duration")
                        self._media_position = data.get("position")
                        
        except (asyncio.TimeoutError, aiohttp.ClientError) as err:
            _LOGGER.error("Error updating macOS Audio Bridge: %s", err)
            self._available = False

    async def async_set_volume_level(self, volume: float):
        """Set volume level, range 0..1."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/volume"
            volume_percent = int(volume * 100)
            
            async with asyncio.timeout(5):
                async with session.post(url, json={"volume": volume_percent}) as response:
                    if response.status == 200:
                        self._volume = volume
                        await self.async_update_ha_state()
        except (asyncio.TimeoutError, aiohttp.ClientError) as err:
            _LOGGER.error("Error setting volume: %s", err)

    async def async_mute_volume(self, mute: bool):
        """Mute the volume."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/mute"
            
            async with asyncio.timeout(5):
                async with session.post(url, json={"muted": mute}) as response:
                    if response.status == 200:
                        self._muted = mute
                        await self.async_update_ha_state()
        except (asyncio.TimeoutError, aiohttp.ClientError) as err:
            _LOGGER.error("Error setting mute: %s", err)
    
    async def async_media_play(self):
        """Send play command."""
        await self._send_media_command("/api/media/play")
    
    async def async_media_pause(self):
        """Send pause command."""
        await self._send_media_command("/api/media/pause")
    
    async def async_media_stop(self):
        """Send stop command."""
        await self._send_media_command("/api/media/stop")
    
    async def async_media_play_pause(self):
        """Send play/pause command."""
        await self._send_media_command("/api/media/play_pause")
    
    async def async_media_next_track(self):
        """Send next track command."""
        await self._send_media_command("/api/media/next")
    
    async def async_media_previous_track(self):
        """Send previous track command."""
        await self._send_media_command("/api/media/previous")
    
    async def async_set_shuffle(self, shuffle: bool):
        """Enable/disable shuffle mode."""
        await self._send_media_command("/api/media/shuffle")
        self._shuffle = shuffle
    
    async def async_set_repeat(self, repeat: str):
        """Set repeat mode."""
        await self._send_media_command("/api/media/repeat")
        self._repeat = repeat
    
    async def async_media_seek(self, position: float):
        """Send seek command."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/media/seek"
            
            async with asyncio.timeout(5):
                async with session.post(url, json={"position": int(position)}) as response:
                    if response.status == 200:
                        self._media_position = int(position)
                        await self.async_update_ha_state()
        except (asyncio.TimeoutError, aiohttp.ClientError) as err:
            _LOGGER.error("Error seeking: %s", err)
    
    async def _send_media_command(self, endpoint: str):
        """Send a media control command to the API."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}{endpoint}"
            
            async with asyncio.timeout(5):
                async with session.post(url) as response:
                    if response.status == 200:
                        # Update state after command
                        await self.async_update()
        except (asyncio.TimeoutError, aiohttp.ClientError) as err:
            _LOGGER.error("Error sending media command %s: %s", endpoint, err)
