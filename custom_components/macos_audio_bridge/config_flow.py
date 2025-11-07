"""Config flow for macOS Audio Bridge integration."""
import logging
import voluptuous as vol
import aiohttp
import asyncio

from homeassistant import config_entries
from homeassistant.const import CONF_HOST, CONF_PORT, CONF_NAME
from homeassistant.core import HomeAssistant
from homeassistant.helpers.aiohttp_client import async_get_clientsession

_LOGGER = logging.getLogger(__name__)

DOMAIN = "macos_audio_bridge"
DEFAULT_PORT = 8888
DEFAULT_NAME = "macOS Audio Bridge"

class MacOSAudioBridgeConfigFlow(config_entries.ConfigFlow, domain=DOMAIN):
    """Handle a config flow for macOS Audio Bridge."""

    VERSION = 1

    async def async_step_user(self, user_input=None):
        """Handle the initial step."""
        errors = {}

        if user_input is not None:
            host = user_input[CONF_HOST]
            port = user_input[CONF_PORT]
            
            # Test connection
            try:
                session = async_get_clientsession(self.hass)
                url = f"http://{host}:{port}/api/status"
                
                async with asyncio.timeout(5):
                    async with session.get(url) as response:
                        if response.status == 200:
                            data = await response.json()
                            
                            # Create unique ID
                            await self.async_set_unique_id(f"{host}_{port}")
                            self._abort_if_unique_id_configured()
                            
                            return self.async_create_entry(
                                title=user_input.get(CONF_NAME, DEFAULT_NAME),
                                data=user_input
                            )
                        else:
                            errors["base"] = "cannot_connect"
            except asyncio.TimeoutError:
                errors["base"] = "timeout"
            except aiohttp.ClientError:
                errors["base"] = "cannot_connect"
            except Exception as err:
                _LOGGER.exception("Unexpected error: %s", err)
                errors["base"] = "unknown"

        data_schema = vol.Schema({
            vol.Required(CONF_HOST): str,
            vol.Optional(CONF_PORT, default=DEFAULT_PORT): int,
            vol.Optional(CONF_NAME, default=DEFAULT_NAME): str,
        })

        return self.async_show_form(
            step_id="user",
            data_schema=data_schema,
            errors=errors
        )
