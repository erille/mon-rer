from __future__ import annotations

import logging
from typing import Any

import httpx

logger = logging.getLogger("rer_web.idfm")


class ServiceError(RuntimeError):
    pass


class ServiceConfigurationError(ServiceError):
    pass


class UpstreamInvalidTokenError(ServiceError):
    pass


class UpstreamRateLimitError(ServiceError):
    pass


class UpstreamUnavailableError(ServiceError):
    pass


class IdfmApiClient:
    def __init__(self, api_token: str, timeout_seconds: float) -> None:
        self._api_token = api_token
        self._client = httpx.AsyncClient(
            timeout=timeout_seconds,
            headers={
                "Accept": "application/json",
                "Accept-Encoding": "gzip, deflate",
                "User-Agent": "rer-web/2.0 (+https://ketah.info)",
            },
        )

    async def close(self) -> None:
        await self._client.aclose()

    async def stop_monitoring(self, monitoring_ref: str) -> dict[str, Any]:
        if not self._api_token:
            raise ServiceConfigurationError("IDFM_API_TOKEN is not configured.")

        try:
            response = await self._client.get(
                "https://prim.iledefrance-mobilites.fr/marketplace/stop-monitoring",
                params={"MonitoringRef": monitoring_ref},
                headers={"Apikey": self._api_token},
            )
        except httpx.TimeoutException as exc:
            logger.warning("IDFM timeout for %s", monitoring_ref)
            raise UpstreamUnavailableError("The IDFM API timed out.") from exc
        except httpx.HTTPError as exc:
            logger.warning("IDFM transport error for %s: %s", monitoring_ref, exc)
            raise UpstreamUnavailableError("The IDFM API is currently unreachable.") from exc

        if response.status_code in {401, 403}:
            logger.error("IDFM rejected the configured API token with status %s", response.status_code)
            raise UpstreamInvalidTokenError("The IDFM API token was rejected by the upstream service.")
        if response.status_code == 429:
            logger.warning("IDFM rate limit hit for %s", monitoring_ref)
            raise UpstreamRateLimitError("The IDFM API rate limit has been reached.")
        if response.status_code >= 500:
            logger.warning("IDFM upstream error for %s: %s", monitoring_ref, response.status_code)
            raise UpstreamUnavailableError("The IDFM API is temporarily unavailable.")
        if response.status_code >= 400:
            logger.warning("IDFM client error for %s: %s", monitoring_ref, response.status_code)
            raise UpstreamUnavailableError(
                f"The IDFM API returned an unexpected error ({response.status_code})."
            )

        return response.json()
