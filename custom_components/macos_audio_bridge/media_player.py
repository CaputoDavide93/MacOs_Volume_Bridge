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
            MediaPlayerEntityFeature.VOLUME_SET |
            MediaPlayerEntityFeature.VOLUME_MUTE
        )

    async def async_update(self):
        """Fetch new state data for this media player."""
        try:
            session = async_get_clientsession(self.hass)
            url = f"http://{self._host}:{self._port}/api/status"
            
            async with asyncio.timeout(5):
                async with session.get(url) as response:
                    if response.status == 200:
                        data = await response.json()
                        self._volume = data.get("volume", 50) / 100.0
                        self._muted = data.get("muted", False)
                        self._state = MediaPlayerState.IDLE
                        self._available = True
                    else:
                        self._available = False
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
