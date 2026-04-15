from __future__ import annotations

from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_env: str = Field(default="development", alias="APP_ENV")
    host: str = Field(default="0.0.0.0", alias="HOST")
    port: int = Field(default=8000, alias="PORT")
    log_level: str = Field(default="INFO", alias="LOG_LEVEL")
    idfm_api_token: str = Field(default="", alias="IDFM_API_TOKEN")
    default_station: str = Field(default="GDS", alias="DEFAULT_STATION")
    cache_ttl_seconds: int = Field(default=20, alias="CACHE_TTL_SECONDS")
    request_timeout_seconds: float = Field(default=8.0, alias="REQUEST_TIMEOUT_SECONDS")
    max_departures: int = Field(default=6, alias="MAX_DEPARTURES")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
