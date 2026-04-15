from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class StationSummary(BaseModel):
    code: str
    name: str
    lines: list[str]


class AutocompleteSuggestion(BaseModel):
    codes: list[str]
    name: str
    lines: list[str]


class BoardMessage(BaseModel):
    priority: Literal["low", "medium", "high"] = "medium"
    content: str


class DepartureItem(BaseModel):
    mission: str | None = None
    numero: str
    time: str
    destination: str
    dessertes: str
    platform: str | None = None
    trainclass: str
    retard: str | None = None
    ligne: str | None = None
    status: str = "N"
    planned_time: str | None = None
    expected_time: str | None = None


class DepartureBoard(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    from_station: StationSummary = Field(alias="from")
    trains: list[DepartureItem]
    messages: list[BoardMessage]
    refreshed_at: str
