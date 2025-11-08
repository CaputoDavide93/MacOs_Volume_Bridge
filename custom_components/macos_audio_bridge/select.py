"""Select platform for macOS Audio Bridge."""
import logging
from typing import Any

from homeassistant.components.select import SelectEntity
from homeassistant.config_entries import ConfigEntry
from homeassistant.const import CONF_HOST, CONF_PORT
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
    """Set up the select platform."""
    host = entry.data[CONF_HOST]
    port = entry.data[CONF_PORT]
    session = async_get_clientsession(hass)
    
    selects = [
        MacOSAudioBridgeOutputDeviceSelect(host, port, session),
        MacOSAudioBridgeInputDeviceSelect(host, port, session),
    ]
    
    async_add_entities(selects, True)


class MacOSAudioBridgeSelectBase(SelectEntity):
    """Base class for macOS Audio Bridge selects."""

    def __init__(self, host: str, port: int, session, select_type: str, name: str, icon: str):
        """Initialize the select."""
        self._host = host
        self._port = port
        self._session = session
        self._select_type = select_type
        self._attr_name = f"macOS Audio Bridge {name}"
        self._attr_unique_id = f"macos_audio_bridge_{select_type}"
        self._attr_icon = icon
        self._attr_options = []
        self._attr_current_option = None
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
                    self._attr_available = True
                    return await response.json()
                else:
                    self._attr_available = False
        except Exception as err:
            _LOGGER.error("Error fetching data from %s: %s", url, err)
            self._attr_available = False
        return None

    async def _post_data(self, endpoint: str, data: dict[str, Any] | None = None) -> bool:
        """Post data to the API."""
        url = f"http://{self._host}:{self._port}{endpoint}"
        try:
            async with self._session.post(url, json=data, timeout=aiohttp.ClientTimeout(total=5)) as response:
                if response.status == 200:
                    self._attr_available = True
                    return True
                else:
                    self._attr_available = False
        except Exception as err:
            _LOGGER.error("Error posting data to %s: %s", url, err)
            self._attr_available = False
        return False


class MacOSAudioBridgeOutputDeviceSelect(MacOSAudioBridgeSelectBase):
    """Select for output audio device."""

    def __init__(self, host: str, port: int, session):
        """Initialize the select."""
        super().__init__(host, port, session, "output_device_select", "Output Device", "mdi:speaker")

    async def async_update(self) -> None:
        """Update the select options and current value."""
        # Get all devices
        devices_data = await self._fetch_data("/api/audio/devices")
        if devices_data and "devices" in devices_data:
            output_devices = [
                dev["name"] for dev in devices_data["devices"] 
                if dev.get("has_output", False)
            ]
            self._attr_options = output_devices
        
        # Get current device
        current_data = await self._fetch_data("/api/audio/output")
        if current_data:
            self._attr_current_option = current_data.get("name")

    async def async_select_option(self, option: str) -> None:
        """Change the selected option."""
        success = await self._post_data("/api/audio/output", {"name": option})
        if success:
            self._attr_current_option = option


class MacOSAudioBridgeInputDeviceSelect(MacOSAudioBridgeSelectBase):
    """Select for input audio device."""

    def __init__(self, host: str, port: int, session):
        """Initialize the select."""
        super().__init__(host, port, session, "input_device_select", "Input Device", "mdi:microphone")

    async def async_update(self) -> None:
        """Update the select options and current value."""
        # Get all devices
        devices_data = await self._fetch_data("/api/audio/devices")
        if devices_data and "devices" in devices_data:
            input_devices = [
                dev["name"] for dev in devices_data["devices"] 
                if dev.get("has_input", False)
            ]
            self._attr_options = input_devices
        
        # Get current device
        current_data = await self._fetch_data("/api/audio/input")
        if current_data:
            self._attr_current_option = current_data.get("name")

    async def async_select_option(self, option: str) -> None:
        """Change the selected option."""
        success = await self._post_data("/api/audio/input", {"name": option})
        if success:
            self._attr_current_option = option
