"""Switch platform for macOS Audio Bridge."""
import logging
from typing import Any

from homeassistant.components.switch import SwitchEntity
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
    """Set up the switch platform."""
    host = entry.data["host"]
    port = entry.data["port"]
    session = async_get_clientsession(hass)
    
    switches = [
        MacOSAudioBridgeShuffleSwitch(host, port, session),
        MacOSAudioBridgeRepeatSwitch(host, port, session),
    ]
    
    async_add_entities(switches, True)


class MacOSAudioBridgeSwitchBase(SwitchEntity):
    """Base class for macOS Audio Bridge switches."""

    def __init__(self, host: str, port: int, session, switch_type: str, name: str, icon: str):
        """Initialize the switch."""
        self._host = host
        self._port = port
        self._session = session
        self._switch_type = switch_type
        self._attr_name = f"macOS Audio Bridge {name}"
        self._attr_unique_id = f"macos_audio_bridge_{switch_type}"
        self._attr_icon = icon
        self._attr_is_on = False
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


class MacOSAudioBridgeShuffleSwitch(MacOSAudioBridgeSwitchBase):
    """Switch for shuffle mode."""

    def __init__(self, host: str, port: int, session):
        """Initialize the switch."""
        super().__init__(host, port, session, "shuffle", "Shuffle", "mdi:shuffle")

    async def async_update(self) -> None:
        """Update the switch state."""
        data = await self._fetch_data("/api/media/info")
        if data:
            self._attr_is_on = data.get("shuffle", False)

    async def async_turn_on(self, **kwargs: Any) -> None:
        """Turn on shuffle."""
        success = await self._post_data("/api/media/shuffle", {"enabled": True})
        if success:
            self._attr_is_on = True

    async def async_turn_off(self, **kwargs: Any) -> None:
        """Turn off shuffle."""
        success = await self._post_data("/api/media/shuffle", {"enabled": False})
        if success:
            self._attr_is_on = False


class MacOSAudioBridgeRepeatSwitch(MacOSAudioBridgeSwitchBase):
    """Switch for repeat mode."""

    def __init__(self, host: str, port: int, session):
        """Initialize the switch."""
        super().__init__(host, port, session, "repeat", "Repeat", "mdi:repeat")

    async def async_update(self) -> None:
        """Update the switch state."""
        data = await self._fetch_data("/api/media/info")
        if data:
            repeat_mode = data.get("repeat", "off")
            self._attr_is_on = repeat_mode != "off"

    async def async_turn_on(self, **kwargs: Any) -> None:
        """Turn on repeat."""
        success = await self._post_data("/api/media/repeat", {"mode": "all"})
        if success:
            self._attr_is_on = True

    async def async_turn_off(self, **kwargs: Any) -> None:
        """Turn off repeat."""
        success = await self._post_data("/api/media/repeat", {"mode": "off"})
        if success:
            self._attr_is_on = False
