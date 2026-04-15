from __future__ import annotations

import json
import unicodedata
from dataclasses import dataclass
from pathlib import Path

from app.models import AutocompleteSuggestion, StationSummary

DATA_DIR = Path(__file__).resolve().parents[1] / "data"


def normalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value)
    ascii_only = normalized.encode("ascii", "ignore").decode("ascii")
    return " ".join(ascii_only.lower().split())


@dataclass(frozen=True, slots=True)
class StationRecord:
    pa_id: int
    codes: tuple[str, ...]
    primary_code: str
    name: str
    lines: tuple[str, ...]
    stop_area_ref: str | None

    @property
    def name_key(self) -> str:
        return normalize_text(self.name)

    def to_summary(self) -> StationSummary:
        return StationSummary(code=self.primary_code, name=self.name, lines=list(self.lines))

    def to_autocomplete(self) -> AutocompleteSuggestion:
        return AutocompleteSuggestion(codes=list(self.codes), name=self.name, lines=list(self.lines))


class StationCatalog:
    def __init__(self, data_path: Path | None = None) -> None:
        path = data_path or DATA_DIR / "stations.json"
        stations_raw = json.loads(path.read_text(encoding="utf-8"))
        self._stations = [
            StationRecord(
                pa_id=item["pa_id"],
                codes=tuple(item["codes"]),
                primary_code=item["primary_code"],
                name=item["name"],
                lines=tuple(item["lines"]),
                stop_area_ref=item["stop_area_ref"],
            )
            for item in stations_raw
        ]
        self._by_code = {
            code: station
            for station in self._stations
            for code in station.codes
        }
        self._by_stop_area_ref = {
            station.stop_area_ref: station
            for station in self._stations
            if station.stop_area_ref
        }

    @property
    def stations(self) -> list[StationRecord]:
        return list(self._stations)

    def count(self) -> int:
        return len(self._stations)

    def default_station(self, station_code: str) -> StationRecord:
        station = self.find_by_code(station_code)
        if station is None:
            raise ValueError(f"Unknown default station: {station_code}")
        return station

    def find_by_code(self, station_code: str | None) -> StationRecord | None:
        if not station_code:
            return None
        return self._by_code.get(station_code.strip().upper())

    def find_by_stop_area_ref(self, stop_area_ref: str | None) -> StationRecord | None:
        if not stop_area_ref:
            return None
        return self._by_stop_area_ref.get(stop_area_ref)

    def autocomplete(self, query: str, limit: int = 10) -> list[AutocompleteSuggestion]:
        query = normalize_text(query)
        if not query:
            return []

        scored: list[tuple[int, StationRecord]] = []
        for station in self._stations:
            score = self._score_station(station, query)
            if score > 0:
                scored.append((score, station))

        scored.sort(key=lambda item: (-item[0], item[1].name))
        return [station.to_autocomplete() for _, station in scored[:limit]]

    def _score_station(self, station: StationRecord, query: str) -> int:
        codes = [code.lower() for code in station.codes]
        name = station.name_key

        if query in codes:
            return 500
        if query == name:
            return 450
        if any(code.startswith(query) for code in codes):
            return 400
        if name.startswith(query):
            return 350
        if any(word.startswith(query) for word in name.split()):
            return 250
        if query in name:
            return 100
        return 0
