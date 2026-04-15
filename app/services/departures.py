from __future__ import annotations

import json
import logging
from datetime import UTC, datetime
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

from app.config import Settings
from app.models import BoardMessage, DepartureBoard, DepartureItem
from app.services.cache import TTLCache
from app.services.idfm import IdfmApiClient
from app.services.schedules import ScheduleIndex
from app.services.stations import StationCatalog, StationRecord

logger = logging.getLogger("rer_web.departures")

DATA_DIR = Path(__file__).resolve().parents[1] / "data"
PARIS = ZoneInfo("Europe/Paris")


def parse_datetime(value: str | None) -> datetime | None:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def to_local_time(value: datetime | None) -> datetime | None:
    if value is None:
        return None
    return value.astimezone(PARIS)


def normalize_platform(value: str | None) -> str | None:
    if not value or value == "unknown":
        return None
    return value.strip() or None


def status_from_call(call: dict[str, Any]) -> str:
    raw_status = call.get("DepartureStatus") or call.get("ArrivalStatus")
    return {
        "onTime": "N",
        "cancelled": "S",
        "delayed": "R",
    }.get(raw_status, "N")


def is_vehicle_stopping(vehicle_journey: dict[str, Any]) -> bool:
    monitored_call = vehicle_journey.get("MonitoredCall", {})
    if "PlatformTraversal" in monitored_call:
        return not bool(monitored_call["PlatformTraversal"])

    expected_arrival = parse_datetime(monitored_call.get("ExpectedArrivalTime"))
    expected_departure = parse_datetime(monitored_call.get("ExpectedDepartureTime"))
    operator_ref = ((vehicle_journey.get("OperatorRef") or {}).get("value") or "").upper()

    if operator_ref.startswith("RATP"):
        return True
    if expected_arrival and expected_departure:
        return expected_departure > expected_arrival
    return True


def format_display_time(status: str, expected_time: datetime | None, at_stop: bool) -> str:
    if status == "S":
        return "Supprime"
    if status == "R":
        return "Retarde"
    if at_stop:
        return "A quai"
    local_time = to_local_time(expected_time)
    return local_time.strftime("%H:%M") if local_time else "--:--"


def format_delay(expected_time: datetime | None, planned_time: datetime | None, status: str) -> str | None:
    if not expected_time or not planned_time or status in {"R", "S"}:
        return None

    total_minutes = round((expected_time - planned_time).total_seconds() / 60)
    if total_minutes == 0:
        return "on time"

    sign = "+" if total_minutes > 0 else "-"
    absolute_minutes = abs(total_minutes)
    hours, minutes = divmod(absolute_minutes, 60)
    if hours == 0:
        return f"{sign}{minutes} min"
    return f"{sign}{hours} h {minutes:02d}"


def train_class(status: str) -> str:
    if status == "R":
        return "train delayed"
    if status == "S":
        return "train cancelled"
    return "train"


class DepartureService:
    def __init__(
        self,
        settings: Settings,
        stations: StationCatalog,
        idfm: IdfmApiClient,
        schedules: ScheduleIndex,
    ) -> None:
        self._settings = settings
        self._stations = stations
        self._idfm = idfm
        self._schedules = schedules
        self._cache: TTLCache[dict[str, Any]] = TTLCache(settings.cache_ttl_seconds)
        self._line_refs = json.loads((DATA_DIR / "line_refs.json").read_text(encoding="utf-8"))

    async def get_board(self, station: StationRecord, line_filter: str | None = None) -> DepartureBoard:
        messages: list[BoardMessage] = []

        if not station.stop_area_ref:
            messages.append(
                BoardMessage(
                    priority="high",
                    content="Real-time departures are not available for this station in the bundled dataset.",
                )
            )
            return self._board_response(station, [], messages)

        payload = self._cache.get(station.stop_area_ref)
        if payload is None:
            payload = await self._idfm.stop_monitoring(station.stop_area_ref)
            self._cache.set(station.stop_area_ref, payload)

        items = self._extract_visits(payload)
        departures = [self._visit_to_departure(station, item) for item in items]
        departures = [item for item in departures if item is not None]
        departures.sort(key=self._sort_key)

        now = datetime.now(UTC)
        departures = [
            item
            for item in departures
            if item.expected_time is None or parse_datetime(item.expected_time) is None or parse_datetime(item.expected_time) >= now
        ]

        if line_filter:
            departures = [item for item in departures if item.ligne == line_filter]

        departures = departures[: self._settings.max_departures]

        if not departures:
            messages.append(BoardMessage(priority="medium", content="No upcoming departures were found."))

        return self._board_response(station, departures, messages)

    def _board_response(
        self,
        station: StationRecord,
        departures: list[DepartureItem],
        messages: list[BoardMessage],
    ) -> DepartureBoard:
        return DepartureBoard(
            from_station=station.to_summary(),
            trains=departures,
            messages=messages,
            refreshed_at=datetime.now(PARIS).isoformat(timespec="seconds"),
        )

    def _extract_visits(self, payload: dict[str, Any]) -> list[dict[str, Any]]:
        return (
            payload.get("Siri", {})
            .get("ServiceDelivery", {})
            .get("StopMonitoringDelivery", [{}])[0]
            .get("MonitoredStopVisit", [])
        )

    def _sort_key(self, item: DepartureItem) -> tuple[datetime, str]:
        expected = parse_datetime(item.expected_time)
        planned = parse_datetime(item.planned_time)
        sort_time = expected or planned or datetime.max.replace(tzinfo=UTC)
        return sort_time, item.numero

    def _visit_to_departure(self, station: StationRecord, visit: dict[str, Any]) -> DepartureItem | None:
        journey = visit.get("MonitoredVehicleJourney", {})
        call = journey.get("MonitoredCall", {})

        if not is_vehicle_stopping(journey):
            return None

        expected_time = parse_datetime(call.get("ExpectedDepartureTime") or call.get("ExpectedArrivalTime"))
        planned_time = parse_datetime(call.get("AimedDepartureTime") or call.get("AimedArrivalTime"))
        status = status_from_call(call)
        at_stop = bool(call.get("VehicleAtStop"))
        line_ref = (journey.get("LineRef") or {}).get("value")
        line = self._line_refs.get(line_ref)

        mission = self._extract_nested_value(journey.get("JourneyNote"))
        number = self._extract_nested_value((journey.get("TrainNumbers") or {}).get("TrainNumberRef"))
        if not number:
            number = self._extract_nested_value(journey.get("VehicleJourneyName")) or "Unknown"

        reference_time = expected_time or planned_time or datetime.now(UTC)
        remaining_stops = self._schedules.get_remaining_stops(station.primary_code, number, reference_time, line)

        return DepartureItem(
            mission=mission,
            numero=number,
            time=format_display_time(status, expected_time or planned_time, at_stop),
            destination=self._destination_name(station, journey),
            dessertes=" • ".join(remaining_stops) if remaining_stops else "Desserte indisponible",
            platform=normalize_platform(
                self._extract_nested_value([call.get("DeparturePlatformName"), call.get("ArrivalPlatformName")])
            ),
            trainclass=train_class(status),
            retard=format_delay(expected_time, planned_time, status),
            ligne=line,
            status=status,
            planned_time=planned_time.isoformat() if planned_time else None,
            expected_time=(expected_time or planned_time).isoformat() if (expected_time or planned_time) else None,
        )

    def _destination_name(self, station: StationRecord, journey: dict[str, Any]) -> str:
        destination_ref = (journey.get("DestinationRef") or {}).get("value")
        destination_station = self._stations.find_by_stop_area_ref(destination_ref)
        if destination_station and destination_station.primary_code == station.primary_code:
            return f"{destination_station.name} (terminus)"
        if destination_station:
            return destination_station.name
        return self._extract_nested_value(journey.get("DestinationName")) or "Destination inconnue"

    def _extract_nested_value(self, value: Any) -> str | None:
        if isinstance(value, list):
            for item in value:
                extracted = self._extract_nested_value(item)
                if extracted:
                    return extracted
            return None
        if isinstance(value, dict):
            nested_value = value.get("value")
            if isinstance(nested_value, str):
                return nested_value.strip()
            return None
        if isinstance(value, str):
            return value.strip()
        return None
