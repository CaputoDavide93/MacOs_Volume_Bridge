"""Sensor platform for macOS Audio Bridge."""
import logging
from typing import Any

from homeassistant.components.sensor import SensorEntity, SensorDeviceClass
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
import aiohttp

from . import DOMAIN

_LOGGER = logging.getLogger(__name__)


async def async_setup_entry(
    hass: HomeAssistant,
    entry: ConfigEntry,
    async_add_entities: AddEntitiesCallback,
) -> None:
    """Set up the sensor platform."""
    host = entry.data["host"]
    port = entry.data["port"]
    
    sensors = [
        MacOSAudioBridgeTrackTitleSensor(host, port),
        MacOSAudioBridgeArtistSensor(host, port),
        MacOSAudioBridgeAlbumSensor(host, port),
        MacOSAudioBridgePlaybackStateSensor(host, port),
        MacOSAudioBridgeOutputDeviceSensor(host, port),
        MacOSAudioBridgeInputDeviceSensor(host, port),
    ]
    
    async_add_entities(sensors, True)


class MacOSAudioBridgeSensorBase(SensorEntity):
    """Base class for macOS Audio Bridge sensors."""

    def __init__(self, host: str, port: int, sensor_type: str, name: str):
        """Initialize the sensor."""
        self._host = host
        self._port = port
        self._sensor_type = sensor_type
        self._attr_name = f"macOS Audio Bridge {name}"
        self._attr_unique_id = f"macos_audio_bridge_{sensor_type}"
        self._attr_native_value = None

    @property
    def device_info(self):
        """Return device information."""
        return {
            "identifiers": {(DOMAIN, f"{self._host}_{self._port}")},
            "name": "macOS Audio Bridge",
            "manufacturer": "macOS Audio Bridge",
            "model": "Audio Controller",
        }

    async def _fetch_data(self, endpoint: str) -> dict[str, Any] | None:
        """Fetch data from the API."""
        url = f"http://{self._host}:{self._port}{endpoint}"
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                    if response.status == 200:
                        return await response.json()
        except Exception as err:
            _LOGGER.debug("Error fetching data from %s: %s", url, err)
        return None


class MacOSAudioBridgeTrackTitleSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current track title."""

    def __init__(self, host: str, port: int):
        """Initialize the sensor."""
        super().__init__(host, port, "track_title", "Track Title")
        self._attr_icon = "mdi:music-note"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_native_value = data.get("title", "Unknown")
        else:
            self._attr_native_value = "Not Playing"


class MacOSAudioBridgeArtistSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current artist."""

    def __init__(self, host: str, port: int):
        """Initialize the sensor."""
        super().__init__(host, port, "artist", "Artist")
        self._attr_icon = "mdi:account-music"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_native_value = data.get("artist", "Unknown")
        else:
            self._attr_native_value = "Not Playing"


class MacOSAudioBridgeAlbumSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current album."""

    def __init__(self, host: str, port: int):
        """Initialize the sensor."""
        super().__init__(host, port, "album", "Album")
        self._attr_icon = "mdi:album"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_native_value = data.get("album", "Unknown")
        else:
            self._attr_native_value = "Not Playing"


class MacOSAudioBridgePlaybackStateSensor(MacOSAudioBridgeSensorBase):
    """Sensor for playback state."""

    def __init__(self, host: str, port: int):
        """Initialize the sensor."""
        super().__init__(host, port, "playback_state", "Playback State")
        self._attr_icon = "mdi:play-pause"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/state")
        if data:
            state = data.get("state", "stopped")
            self._attr_native_value = state.capitalize()
        else:
            self._attr_native_value = "Stopped"


class MacOSAudioBridgeOutputDeviceSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current output device."""

    def __init__(self, host: str, port: int):
        """Initialize the sensor."""
        super().__init__(host, port, "output_device", "Output Device")
        self._attr_icon = "mdi:speaker"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/audio/output")
        if data:
            self._attr_native_value = data.get("name", "Unknown")
        else:
            self._attr_native_value = "Unknown"


class MacOSAudioBridgeInputDeviceSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current input device."""

    def __init__(self, host: str, port: int):
        """Initialize the sensor."""
        super().__init__(host, port, "input_device", "Input Device")
        self._attr_icon = "mdi:microphone"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/audio/input")
        if data:
            self._attr_native_value = data.get("name", "Unknown")
        else:
            self._attr_native_value = "Unknown"
