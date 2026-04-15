from __future__ import annotations

import time
from typing import Generic, TypeVar

T = TypeVar("T")


class TTLCache(Generic[T]):
    def __init__(self, ttl_seconds: int) -> None:
        self.ttl_seconds = ttl_seconds
        self._values: dict[str, tuple[float, T]] = {}

    def get(self, key: str) -> T | None:
        record = self._values.get(key)
        if record is None:
            return None

        expires_at, value = record
        if expires_at <= time.monotonic():
            self._values.pop(key, None)
            return None

        return value

    def set(self, key: str, value: T) -> None:
        self._values[key] = (time.monotonic() + self.ttl_seconds, value)
