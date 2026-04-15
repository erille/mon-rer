from __future__ import annotations

from app.config import Settings
from app.services.departures import DepartureService
from app.services.stations import StationCatalog


class DummyIdfmClient:
    async def stop_monitoring(self, _: str) -> dict:
        return {}


class DummyScheduleIndex:
    def get_remaining_stops(self, *_args, **_kwargs) -> list[str]:
        return []


def test_visit_to_departure_skips_same_station_terminus() -> None:
    stations = StationCatalog()
    station = stations.find_by_code("GDS")
    assert station is not None

    service = DepartureService(Settings(), stations, DummyIdfmClient(), DummyScheduleIndex())
    visit = {
        "MonitoredVehicleJourney": {
            "DestinationRef": {"value": station.stop_area_ref},
            "JourneyNote": {"value": "POMA"},
            "TrainNumbers": {"TrainNumberRef": {"value": "123456"}},
            "MonitoredCall": {
                "ExpectedDepartureTime": "2026-04-15T16:27:00+02:00",
                "AimedDepartureTime": "2026-04-15T16:27:00+02:00",
                "VehicleAtStop": False,
            },
        }
    }

    assert service._visit_to_departure(station, visit) is None
