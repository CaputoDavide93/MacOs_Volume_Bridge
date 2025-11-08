"""Sensor platform for macOS Audio Bridge."""
import logging
from typing import Any

from homeassistant.components.sensor import SensorEntity, SensorDeviceClass
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import HomeAssistant
from homeassistant.helpers.entity_platform import AddEntitiesCallback
from homeassistant.helpers.aiohttp_client import async_get_clientsession
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
    session = async_get_clientsession(hass)
    
    sensors = [
        MacOSAudioBridgeTrackTitleSensor(host, port, session),
        MacOSAudioBridgeArtistSensor(host, port, session),
        MacOSAudioBridgeAlbumSensor(host, port, session),
        MacOSAudioBridgePlaybackStateSensor(host, port, session),
        MacOSAudioBridgeOutputDeviceSensor(host, port, session),
        MacOSAudioBridgeInputDeviceSensor(host, port, session),
    ]
    
    async_add_entities(sensors, True)


class MacOSAudioBridgeSensorBase(SensorEntity):
    """Base class for macOS Audio Bridge sensors."""

    def __init__(self, host: str, port: int, session, sensor_type: str, name: str):
        """Initialize the sensor."""
        self._host = host
        self._port = port
        self._session = session
        self._sensor_type = sensor_type
        self._attr_name = f"macOS Audio Bridge {name}"
        self._attr_unique_id = f"macos_audio_bridge_{sensor_type}"
        self._attr_native_value = None
        self._attr_available = True

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
            async with self._session.get(url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                if response.status == 200:
                    return await response.json()
                else:
                    _LOGGER.warning("Error fetching data from %s: HTTP %d", url, response.status)
                    self._attr_available = False
        except Exception as err:
            _LOGGER.error("Error fetching data from %s: %s", url, err)
            self._attr_available = False
        return None


class MacOSAudioBridgeTrackTitleSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current track title."""

    def __init__(self, host: str, port: int, session):
        """Initialize the sensor."""
        super().__init__(host, port, session, "track_title", "Track Title")
        self._attr_icon = "mdi:music-note"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_available = True
            self._attr_native_value = data.get("title") if data.get("title") else "Not Playing"
        else:
            self._attr_native_value = "Not Playing"


class MacOSAudioBridgeArtistSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current artist."""

    def __init__(self, host: str, port: int, session):
        """Initialize the sensor."""
        super().__init__(host, port, session, "artist", "Artist")
        self._attr_icon = "mdi:account-music"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_available = True
            self._attr_native_value = data.get("artist") if data.get("artist") else "Unknown"
        else:
            self._attr_native_value = "Unknown"


class MacOSAudioBridgeAlbumSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current album."""

    def __init__(self, host: str, port: int, session):
        """Initialize the sensor."""
        super().__init__(host, port, session, "album", "Album")
        self._attr_icon = "mdi:album"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_available = True
            self._attr_native_value = data.get("album") if data.get("album") else "Unknown"
        else:
            self._attr_native_value = "Unknown"


class MacOSAudioBridgePlaybackStateSensor(MacOSAudioBridgeSensorBase):
    """Sensor for playback state."""

    def __init__(self, host: str, port: int, session):
        """Initialize the sensor."""
        super().__init__(host, port, session, "playback_state", "Playback State")
        self._attr_icon = "mdi:play-pause"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/media/state")
        if data:
            self._attr_available = True
            state = data.get("state", "stopped")
            self._attr_native_value = state.capitalize()
        else:
            self._attr_native_value = "Stopped"


class MacOSAudioBridgeOutputDeviceSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current output device."""

    def __init__(self, host: str, port: int, session):
        """Initialize the sensor."""
        super().__init__(host, port, session, "output_device", "Output Device")
        self._attr_icon = "mdi:speaker"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/audio/output")
        if data:
            self._attr_available = True
            self._attr_native_value = data.get("name", "Unknown")
        else:
            self._attr_native_value = "Unknown"


class MacOSAudioBridgeInputDeviceSensor(MacOSAudioBridgeSensorBase):
    """Sensor for current input device."""

    def __init__(self, host: str, port: int, session):
        """Initialize the sensor."""
        super().__init__(host, port, session, "input_device", "Input Device")
        self._attr_icon = "mdi:microphone"

    async def async_update(self) -> None:
        """Update the sensor."""
        data = await self._fetch_data("/api/audio/input")
        if data:
            self._attr_available = True
            self._attr_native_value = data.get("name", "Unknown")
        else:
            self._attr_native_value = "Unknown"
