BEGIN;

CREATE TABLE raw.stop_times_new (
  trip_id TEXT NOT NULL,
  arrival_time INTERVAL,
  departure_time INTERVAL,
  start_pickup_drop_off_window TEXT,
  end_pickup_drop_off_window TEXT,
  stop_id TEXT NOT NULL,
  stop_sequence INTEGER NOT NULL,
  pickup_type INTEGER,
  drop_off_type INTEGER,
  local_zone_id TEXT,
  stop_headsign TEXT,
  timepoint INTEGER,
  pickup_booking_rule_id TEXT,
  drop_off_booking_rule_id TEXT,
  PRIMARY KEY (trip_id, stop_sequence));

INSERT INTO raw.stop_times_new (
  trip_id, arrival_time, departure_time, stop_id, stop_sequence, pickup_type,
  drop_off_type, local_zone_id, stop_headsign, timepoint)
SELECT trip_id, arrival_time, departure_time, stop_id, stop_sequence,
       pickup_type, drop_off_type, local_zone_id, stop_headsign, timepoint
  FROM raw.stop_times;

DROP TABLE raw.stop_times;

ALTER TABLE raw.stop_times_new RENAME TO stop_times;

COMMIT;
