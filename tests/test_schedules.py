from __future__ import annotations

import json
import sqlite3
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

from app.services.schedules import ScheduleIndex


def test_schedule_index_returns_remaining_stops(tmp_path: Path) -> None:
    db_path = tmp_path / "schedule.sqlite3"
    stop_keys_path = tmp_path / "station_stop_keys.json"
    stop_keys_path.write_text(json.dumps({"ABC": [11]}), encoding="utf-8")

    connection = sqlite3.connect(db_path)
    cursor = connection.cursor()
    cursor.executescript(
        """
        CREATE TABLE services (
            service_id TEXT PRIMARY KEY,
            monday INTEGER NOT NULL,
            tuesday INTEGER NOT NULL,
            wednesday INTEGER NOT NULL,
            thursday INTEGER NOT NULL,
            friday INTEGER NOT NULL,
            saturday INTEGER NOT NULL,
            sunday INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL
        );
        CREATE TABLE service_exceptions (
            service_id TEXT NOT NULL,
            date TEXT NOT NULL,
            exception_type INTEGER NOT NULL,
            PRIMARY KEY (service_id, date)
        );
        CREATE TABLE patterns (
            pattern_id INTEGER PRIMARY KEY,
            stop_names_json TEXT NOT NULL,
            stop_sequences_json TEXT NOT NULL
        );
        CREATE TABLE trips (
            trip_key INTEGER PRIMARY KEY,
            trip_id TEXT NOT NULL UNIQUE,
            service_id TEXT NOT NULL,
            route_short_name TEXT NOT NULL,
            train_name TEXT,
            train_number TEXT NOT NULL,
            pattern_id INTEGER NOT NULL
        );
        CREATE TABLE occurrences (
            trip_key INTEGER NOT NULL,
            stop_key INTEGER NOT NULL,
            stop_sequence INTEGER NOT NULL,
            due_seconds INTEGER NOT NULL,
            PRIMARY KEY (trip_key, stop_sequence)
        );
        """
    )
    cursor.execute(
        "INSERT INTO services VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
        ("weekday", 1, 1, 1, 1, 1, 0, 0, "2026-01-01", "2026-12-31"),
    )
    cursor.execute(
        "INSERT INTO patterns VALUES (?, ?, ?)",
        (1, json.dumps(["Start", "Middle", "End"]), json.dumps([1, 5, 10])),
    )
    cursor.execute(
        "INSERT INTO trips VALUES (?, ?, ?, ?, ?, ?, ?)",
        (1, "trip-1", "weekday", "D", "TRAIN", "123456", 1),
    )
    cursor.execute(
        "INSERT INTO occurrences VALUES (?, ?, ?, ?)",
        (1, 11, 5, 8 * 3600),
    )
    connection.commit()
    connection.close()

    schedule_index = ScheduleIndex(db_path=db_path, station_stop_keys_path=stop_keys_path)
    try:
        remaining = schedule_index.get_remaining_stops(
            station_code="ABC",
            train_number="123456",
            reference_time=datetime(2026, 4, 15, 8, 5, tzinfo=ZoneInfo("Europe/Paris")),
            line="D",
        )
    finally:
        schedule_index.close()

    assert remaining == ["End"]
