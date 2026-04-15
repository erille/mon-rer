from __future__ import annotations

import json
import sqlite3
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta
from functools import lru_cache
from pathlib import Path
from typing import Iterable
from zoneinfo import ZoneInfo

PARIS = ZoneInfo("Europe/Paris")
DATA_DIR = Path(__file__).resolve().parents[1] / "data"


@dataclass(frozen=True, slots=True)
class ServiceCalendar:
    start_date: date
    end_date: date
    weekdays: tuple[bool, bool, bool, bool, bool, bool, bool]

    def is_active_on(self, value: date, override: int | None = None) -> bool:
        if override == 1:
            return True
        if override == 2:
            return False
        if value < self.start_date or value > self.end_date:
            return False
        return self.weekdays[value.weekday()]


class ScheduleIndex:
    def __init__(
        self,
        db_path: Path | None = None,
        station_stop_keys_path: Path | None = None,
    ) -> None:
        self._db_path = db_path or DATA_DIR / "schedule.sqlite3"
        self._station_stop_keys = json.loads(
            (station_stop_keys_path or DATA_DIR / "station_stop_keys.json").read_text(encoding="utf-8")
        )
        self._conn = sqlite3.connect(f"file:{self._db_path}?mode=ro", uri=True, check_same_thread=False)
        self._conn.row_factory = sqlite3.Row
        self._services = self._load_services()
        self._exceptions = self._load_exceptions()

    def close(self) -> None:
        self._conn.close()

    def get_remaining_stops(
        self,
        station_code: str,
        train_number: str,
        reference_time: datetime,
        line: str | None = None,
    ) -> list[str] | None:
        stop_keys = self._station_stop_keys.get(station_code.upper())
        if not stop_keys:
            return None

        reference_time = reference_time.astimezone(PARIS)
        rows = self._candidate_rows(stop_keys, self._candidate_train_numbers(train_number), line)
        if not rows:
            return None

        best_row: sqlite3.Row | None = None
        best_distance: float | None = None
        best_due_time: datetime | None = None

        for row in rows:
            for candidate_date in self._candidate_dates(reference_time.date()):
                if not self._is_service_active(row["service_id"], candidate_date):
                    continue

                due_time = datetime.combine(candidate_date, time.min, tzinfo=PARIS) + timedelta(
                    seconds=row["due_seconds"]
                )
                distance = abs((due_time - reference_time).total_seconds())
                if distance > 6 * 3600:
                    continue

                if best_distance is None or distance < best_distance:
                    best_row = row
                    best_distance = distance
                    best_due_time = due_time

        if best_row is None or best_due_time is None:
            return None

        stop_names, stop_sequences = self._pattern(best_row["pattern_id"])
        try:
            current_index = stop_sequences.index(best_row["stop_sequence"])
        except ValueError:
            return None

        remaining = self._dedupe_consecutive(stop_names[current_index + 1 :])
        return remaining or None

    def _load_services(self) -> dict[str, ServiceCalendar]:
        rows = self._conn.execute(
            """
            SELECT service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday, start_date, end_date
            FROM services
            """
        ).fetchall()
        return {
            row["service_id"]: ServiceCalendar(
                start_date=date.fromisoformat(self._as_iso_date(row["start_date"])),
                end_date=date.fromisoformat(self._as_iso_date(row["end_date"])),
                weekdays=(
                    bool(row["monday"]),
                    bool(row["tuesday"]),
                    bool(row["wednesday"]),
                    bool(row["thursday"]),
                    bool(row["friday"]),
                    bool(row["saturday"]),
                    bool(row["sunday"]),
                ),
            )
            for row in rows
        }

    def _load_exceptions(self) -> dict[tuple[str, str], int]:
        rows = self._conn.execute("SELECT service_id, date, exception_type FROM service_exceptions").fetchall()
        return {
            (row["service_id"], self._as_iso_date(row["date"])): int(row["exception_type"])
            for row in rows
        }

    def _is_service_active(self, service_id: str, value: date) -> bool:
        service = self._services.get(service_id)
        if service is None:
            return False
        override = self._exceptions.get((service_id, value.isoformat()))
        return service.is_active_on(value, override)

    def _candidate_rows(self, stop_keys: list[int], train_numbers: list[str], line: str | None) -> list[sqlite3.Row]:
        train_placeholders = ", ".join("?" for _ in train_numbers)
        stop_placeholders = ", ".join("?" for _ in stop_keys)
        line_clause = "AND trips.route_short_name = ?" if line else ""
        params: list[object] = [*train_numbers, *stop_keys]
        if line:
            params.append(line)

        return self._conn.execute(
            f"""
            SELECT trips.trip_key, trips.service_id, trips.route_short_name, trips.train_number, trips.pattern_id,
                   occurrences.stop_sequence, occurrences.due_seconds
            FROM trips
            JOIN occurrences ON occurrences.trip_key = trips.trip_key
            WHERE trips.train_number IN ({train_placeholders})
              AND occurrences.stop_key IN ({stop_placeholders})
              {line_clause}
            """,
            params,
        ).fetchall()

    @lru_cache(maxsize=2048)
    def _pattern(self, pattern_id: int) -> tuple[list[str], list[int]]:
        row = self._conn.execute(
            "SELECT stop_names_json, stop_sequences_json FROM patterns WHERE pattern_id = ?",
            (pattern_id,),
        ).fetchone()
        if row is None:
            return [], []
        return json.loads(row["stop_names_json"]), json.loads(row["stop_sequences_json"])

    def _candidate_dates(self, value: date) -> Iterable[date]:
        return (value - timedelta(days=1), value, value + timedelta(days=1))

    def _candidate_train_numbers(self, train_number: str) -> list[str]:
        candidates = {train_number}
        if train_number.isdigit() and len(train_number) == 6:
            base = train_number[:5]
            last_digit = int(train_number[-1])
            if last_digit % 2 == 0:
                paired = f"{train_number}-{base}{last_digit + 1}"
            else:
                paired = f"{base}{last_digit - 1}-{train_number}"
            candidates.add(paired)
        return sorted(candidates)

    def _dedupe_consecutive(self, stop_names: list[str]) -> list[str]:
        deduped: list[str] = []
        for stop_name in stop_names:
            if not deduped or deduped[-1] != stop_name:
                deduped.append(stop_name)
        return deduped

    def _as_iso_date(self, value: str) -> str:
        if "-" in value:
            return value
        return f"{value[0:4]}-{value[4:6]}-{value[6:8]}"
